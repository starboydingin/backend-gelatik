import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../storage/secure_storage_service.dart';
import 'realtime_event.dart';

enum RealtimeConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

abstract class RealtimeTransport {
  void connect();
  void disconnect();
  void on(String event, void Function(dynamic) handler);
  void off(String event);
}

class SocketIoRealtimeTransport implements RealtimeTransport {
  final socket_io.Socket _socket;

  SocketIoRealtimeTransport(String url, String token)
    : _socket = socket_io.io(
        url,
        socket_io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .disableAutoConnect()
            .setReconnectionDelay(500)
            .setReconnectionDelayMax(10000)
            .build(),
      );

  @override
  void connect() => _socket.connect();

  @override
  void disconnect() => _socket.disconnect();

  @override
  void on(String event, void Function(dynamic) handler) =>
      _socket.on(event, handler);

  @override
  void off(String event) => _socket.off(event);
}

typedef RealtimeTransportFactory =
    RealtimeTransport Function(String url, String token);

class RealtimeSocketService {
  static const _eventNames = RealtimeEvent.supportedTypes;

  final SecureStorageService storage;
  final String baseUrl;
  final RealtimeTransportFactory transportFactory;
  final _events = StreamController<RealtimeEvent>.broadcast();
  final _connectionStates =
      StreamController<RealtimeConnectionState>.broadcast();
  final _seenEventIds = <String>{};
  final _seenEventOrder = <String>[];

  RealtimeTransport? _transport;
  Future<void>? _connectOperation;
  RealtimeConnectionState _state = RealtimeConnectionState.disconnected;
  bool _disposed = false;
  bool _hasConnectedAtLeastOnce = false;
  int _connectionVersion = 0;

  RealtimeSocketService({
    required this.storage,
    required this.baseUrl,
    RealtimeTransportFactory? transportFactory,
  }) : transportFactory =
           transportFactory ??
           ((url, token) => SocketIoRealtimeTransport(url, token));

  Stream<RealtimeEvent> get events => _events.stream;
  Stream<RealtimeConnectionState> get connectionStates =>
      _connectionStates.stream;
  RealtimeConnectionState get state => _state;

  Future<void> connect() {
    if (_disposed ||
        _state == RealtimeConnectionState.connected ||
        _state == RealtimeConnectionState.connecting ||
        _state == RealtimeConnectionState.reconnecting) {
      return _connectOperation ?? Future<void>.value();
    }
    return _connectOperation ??= _connect().whenComplete(() {
      _connectOperation = null;
    });
  }

  Future<void> _connect() async {
    final connectionVersion = _connectionVersion;
    final token = await storage.getToken();
    if (_disposed ||
        connectionVersion != _connectionVersion ||
        token == null ||
        token.isEmpty) {
      return;
    }

    _setState(RealtimeConnectionState.connecting);
    final previousTransport = _transport;
    if (previousTransport != null) {
      _detachTransport(previousTransport);
    }
    final transport = transportFactory(baseUrl, token);
    _transport = transport;
    transport.on('connect', (_) {
      _setState(RealtimeConnectionState.connected);
      if (_hasConnectedAtLeastOnce) _emitSessionResync();
      _hasConnectedAtLeastOnce = true;
    });
    transport.on(
      'reconnect_attempt',
      (_) => _setState(RealtimeConnectionState.reconnecting),
    );
    transport.on('connect_error', (error) {
      if (error.toString().toLowerCase().contains('unauthorized')) {
        unawaited(disconnect());
      } else {
        _setState(RealtimeConnectionState.reconnecting);
      }
    });
    transport.on(
      'disconnect',
      (_) => _setState(RealtimeConnectionState.disconnected),
    );
    for (final eventName in _eventNames) {
      transport.on(eventName, (payload) => _handleEvent(eventName, payload));
    }
    transport.connect();
  }

  Future<void> disconnect() async {
    _connectionVersion++;
    final transport = _transport;
    _transport = null;
    if (transport != null) {
      _detachTransport(transport);
    }
    _hasConnectedAtLeastOnce = false;
    _setState(RealtimeConnectionState.disconnected);
  }

  void _detachTransport(RealtimeTransport transport) {
    for (final eventName in _eventNames) {
      transport.off(eventName);
    }
    transport.off('connect');
    transport.off('reconnect_attempt');
    transport.off('connect_error');
    transport.off('disconnect');
    transport.disconnect();
  }

  void handleLifecycle(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      // A mobile OS may suspend network delivery while retaining the socket's
      // connected flag. Always ask every provider to re-read authoritative
      // data on resume, including aggregate insights from other users.
      if (_state == RealtimeConnectionState.connected) {
        _emitSessionResync();
      }
      unawaited(connect());
    }
  }

  void _handleEvent(String eventName, dynamic payload) {
    final event = RealtimeEvent.tryParse(eventName, payload);
    if (event == null || !_seenEventIds.add(event.eventId)) return;
    _seenEventOrder.add(event.eventId);
    if (_seenEventOrder.length > 200) {
      _seenEventIds.remove(_seenEventOrder.removeAt(0));
    }
    _events.add(event);
  }

  void _emitSessionResync() {
    if (_events.isClosed) return;
    _events.add(
      RealtimeEvent(
        eventId: 'session-${DateTime.now().microsecondsSinceEpoch}',
        type: 'data.sync',
        entityId: 1,
        status: 'updated',
        resource: 'session',
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  void _setState(RealtimeConnectionState value) {
    if (_state == value) return;
    _state = value;
    if (!_connectionStates.isClosed) _connectionStates.add(value);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await disconnect();
    await _events.close();
    await _connectionStates.close();
  }
}

class RealtimeConfig {
  static String get baseUrl {
    const configured = String.fromEnvironment('REALTIME_BASE_URL');
    if (configured.isNotEmpty) return configured;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:4000';
    return 'http://localhost:4000';
  }
}

final realtimeSocketServiceProvider = Provider<RealtimeSocketService>((ref) {
  final service = RealtimeSocketService(
    storage: ref.watch(secureStorageServiceProvider),
    baseUrl: RealtimeConfig.baseUrl,
  );
  ref.onDispose(service.dispose);
  return service;
});
