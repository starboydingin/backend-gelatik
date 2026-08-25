import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/core/realtime/realtime_event.dart';
import 'package:gelatik/core/realtime/realtime_socket_service.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';

class _MemoryStorage extends SecureStorageService {
  String? token;

  @override
  Future<String?> getToken() async => token;
}

class _FakeTransport implements RealtimeTransport {
  final handlers = <String, void Function(dynamic)>{};
  final removed = <String>[];
  int connectCalls = 0;
  int disconnectCalls = 0;

  @override
  void connect() => connectCalls++;

  @override
  void disconnect() => disconnectCalls++;

  @override
  void on(String event, void Function(dynamic) handler) =>
      handlers[event] = handler;

  @override
  void off(String event) {
    removed.add(event);
    handlers.remove(event);
  }

  void emit(String event, dynamic payload) => handlers[event]?.call(payload);
}

void main() {
  test('does not connect without a secure token', () async {
    final storage = _MemoryStorage();
    var factoryCalls = 0;
    final service = RealtimeSocketService(
      storage: storage,
      baseUrl: 'http://localhost:4000',
      transportFactory: (_, _) {
        factoryCalls++;
        return _FakeTransport();
      },
    );

    await service.connect();

    expect(factoryCalls, 0);
    expect(service.state, RealtimeConnectionState.disconnected);
    await service.dispose();
  });

  test('connects only once and parses valid events', () async {
    final storage = _MemoryStorage()..token = 'secure-token';
    final transport = _FakeTransport();
    var factoryCalls = 0;
    final service = RealtimeSocketService(
      storage: storage,
      baseUrl: 'http://localhost:4000',
      transportFactory: (_, token) {
        factoryCalls++;
        expect(token, 'secure-token');
        return transport;
      },
    );
    final events = <RealtimeEvent>[];
    final subscription = service.events.listen(events.add);

    await Future.wait([service.connect(), service.connect()]);
    expect(factoryCalls, 1);
    expect(transport.connectCalls, 1);
    transport.emit('connect', null);
    expect(service.state, RealtimeConnectionState.connected);
    transport.emit('reconnect_attempt', null);
    expect(service.state, RealtimeConnectionState.reconnecting);
    transport.emit('connect', null);
    expect(service.state, RealtimeConnectionState.connected);

    final payload = {
      'event_id': 'evt-12345678',
      'type': 'pinjam.status_changed',
      'entity_id': 7,
      'status': 'Proses',
      'old_status': 'Menunggu',
      'created_at': '2026-08-06T00:00:00.000Z',
      'message': 'Status berubah',
    };
    transport.emit('pinjam.status_changed', payload);
    transport.emit('pinjam.status_changed', payload);
    transport.emit('notification', {
      'event_id': 'evt-12345679',
      'type': 'notification',
      'entity_id': 12,
      'status': 'new',
      'created_at': '2026-08-24T00:00:00.000Z',
      'message': 'Ada pembaruan layanan.',
    });
    transport.emit('pinjam.status_changed', {'entity_id': 7});
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(4));
    expect(events.where((event) => event.type == 'data.sync'), hasLength(2));
    expect(events[2].entityId, 7);
    expect(events.last.type, 'notification');
    await subscription.cancel();
    await service.dispose();
  });

  test('unauthorized reconnect error disconnects safely', () async {
    final storage = _MemoryStorage()..token = 'secure-token';
    final transport = _FakeTransport();
    final service = RealtimeSocketService(
      storage: storage,
      baseUrl: 'http://localhost:4000',
      transportFactory: (_, _) => transport,
    );

    await service.connect();
    transport.emit('connect_error', 'unauthorized');
    await Future<void>.delayed(Duration.zero);

    expect(service.state, RealtimeConnectionState.disconnected);
    expect(transport.disconnectCalls, 1);
    await service.dispose();
  });

  test('disconnect removes listeners and is safe during logout', () async {
    final storage = _MemoryStorage()..token = 'secure-token';
    final transport = _FakeTransport();
    final service = RealtimeSocketService(
      storage: storage,
      baseUrl: 'http://localhost:4000',
      transportFactory: (_, _) => transport,
    );

    await service.connect();
    await service.disconnect();

    expect(transport.disconnectCalls, 1);
    expect(transport.removed, contains('pinjam.status_changed'));
    expect(service.state, RealtimeConnectionState.disconnected);
    await service.dispose();
  });

  test('resume replaces a disconnected transport without duplicate listeners', () async {
    final storage = _MemoryStorage()..token = 'secure-token';
    final firstTransport = _FakeTransport();
    final secondTransport = _FakeTransport();
    var factoryCalls = 0;
    final service = RealtimeSocketService(
      storage: storage,
      baseUrl: 'http://localhost:4000',
      transportFactory: (_, _) =>
          factoryCalls++ == 0 ? firstTransport : secondTransport,
    );

    await service.connect();
    firstTransport.emit('connect', null);
    firstTransport.emit('disconnect', null);
    service.handleLifecycle(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);

    expect(factoryCalls, 2);
    expect(firstTransport.disconnectCalls, 1);
    expect(firstTransport.removed, contains('konsultasi.responded'));
    expect(secondTransport.connectCalls, 1);
    await service.dispose();
  });
}
