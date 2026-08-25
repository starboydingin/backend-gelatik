import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/realtime/realtime_coordinator.dart';
import 'package:gelatik/core/realtime/realtime_socket_service.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/features/home/models/home_dashboard_model.dart';
import 'package:gelatik/features/home/providers/home_provider.dart';
import 'package:gelatik/features/auth/providers/auth_provider.dart';
import 'package:gelatik/features/email/providers/email_provider.dart';
import 'package:gelatik/features/email/repositories/email_repository.dart';
import 'package:gelatik/features/info_alat/providers/info_alat_provider.dart';
import 'package:gelatik/features/info_alat/repositories/master_item_repository.dart';
import 'package:gelatik/features/internet/providers/internet_provider.dart';
import 'package:gelatik/features/internet/repositories/internet_repository.dart';
import 'package:gelatik/features/konsultasi/providers/konsultasi_provider.dart';
import 'package:gelatik/features/konsultasi/repositories/konsultasi_repository.dart';
import 'package:gelatik/features/peminjaman/providers/peminjaman_provider.dart';
import 'package:gelatik/features/peminjaman/repositories/peminjaman_repository.dart';
import 'package:gelatik/features/profil/providers/wa_notification_provider.dart';
import 'package:gelatik/features/profil/repositories/wa_notification_repository.dart';

class _Storage extends SecureStorageService {
  @override
  Future<String?> getToken() async => 'test-token';
}

class _Transport implements RealtimeTransport {
  final handlers = <String, void Function(dynamic)>{};

  @override
  void connect() => handlers['connect']?.call(null);

  @override
  void disconnect() {}

  @override
  void on(String event, void Function(dynamic) handler) {
    handlers[event] = handler;
  }

  @override
  void off(String event) => handlers.remove(event);

  void emit(String event, Map<String, dynamic> payload) {
    handlers[event]?.call(payload);
  }
}

ApiClient _client() => ApiClient(secureStorageService: _Storage());

class _TrackingPeminjaman extends PeminjamanNotifier {
  int refreshCalls = 0;
  int? lastEntityId;

  _TrackingPeminjaman()
    : super(repository: PeminjamanRepository(apiClient: _client()));

  @override
  Future<void> refreshFromRealtime(int entityId) async {
    refreshCalls++;
    lastEntityId = entityId;
  }
}

class _TrackingKonsultasi extends KonsultasiNotifier {
  int refreshCalls = 0;
  int? lastEntityId;

  _TrackingKonsultasi()
    : super(repository: KonsultasiRepository(apiClient: _client()));

  @override
  Future<void> refreshFromRealtime(int entityId) async {
    refreshCalls++;
    lastEntityId = entityId;
  }

  @override
  Future<void> loadTopik({bool force = false}) async {}
}

class _TrackingEmail extends EmailNotifier {
  _TrackingEmail() : super(repository: EmailRepository(apiClient: _client()));

  @override
  Future<void> refreshFromRealtime() async {}
}

class _TrackingAuth extends AuthNotifier {
  @override
  Future<void> refreshFromRealtime() async {}
}

class _TrackingInternet extends InternetNotifier {
  _TrackingInternet()
    : super(repository: InternetRepository(apiClient: _client()));

  @override
  Future<void> refreshAllFromRealtime() async {}
}

class _TrackingInfoAlat extends InfoAlatNotifier {
  _TrackingInfoAlat()
    : super(repository: MasterItemRepository(apiClient: _client()));

  @override
  Future<void> loadItems({bool force = false}) async {}
}

class _TrackingWaNotification extends WaNotificationNotifier {
  _TrackingWaNotification()
    : super(repository: WaNotificationRepository(apiClient: _client()));

  @override
  Future<void> refreshFromRealtime() async {}
}

class _TrackingHome extends HomeNotifier {
  int refreshCalls = 0;

  _TrackingHome()
    : super.preview(
        const HomeDashboardModel(
          userName: 'Admin Test',
          userRole: 'admin',
          availableItemCount: 0,
          totalBorrowingCount: 0,
          totalConsultationCount: 0,
        ),
      );

  @override
  Future<void> refreshFromRealtime() async {
    refreshCalls++;
  }
}

Map<String, dynamic> _payload({
  required String eventId,
  required String type,
  required int entityId,
}) => {
  'event_id': eventId,
  'type': type,
  'entity_id': entityId,
  'status': type.endsWith('status_changed') ? 'Diproses' : 'Menunggu',
  'old_status': 'Menunggu',
  'created_at': '2026-08-10T00:00:00.000Z',
  'message': 'Data berubah',
};

void main() {
  test(
    'admin events refresh matching providers once and coalesce bursts',
    () async {
      final transport = _Transport();
      final service = RealtimeSocketService(
        storage: _Storage(),
        baseUrl: 'http://localhost:4000',
        transportFactory: (_, _) => transport,
      );
      final peminjaman = _TrackingPeminjaman();
      final konsultasi = _TrackingKonsultasi();
      final email = _TrackingEmail();
      final auth = _TrackingAuth();
      final internet = _TrackingInternet();
      final infoAlat = _TrackingInfoAlat();
      final waNotification = _TrackingWaNotification();
      final home = _TrackingHome();
      final coordinator = RealtimeCoordinator(
        service: service,
        apiClient: _client(),
        peminjaman: peminjaman,
        konsultasi: konsultasi,
        email: email,
        auth: auth,
        internet: internet,
        infoAlat: infoAlat,
        waNotification: waNotification,
        home: home,
      );

      await service.connect();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      home.refreshCalls = 0;
      final pinjam = _payload(
        eventId: 'pinjam-event-0001',
        type: 'pinjam.created',
        entityId: 41,
      );
      transport.emit('pinjam.created', pinjam);
      transport.emit('pinjam.created', pinjam);
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(peminjaman.refreshCalls, 1);
      expect(peminjaman.lastEntityId, 41);
      expect(konsultasi.refreshCalls, 0);
      expect(home.refreshCalls, 0);

      transport.emit(
        'insights.sync',
        _payload(
          eventId: 'insights-event-0001',
          type: 'insights.sync',
          entityId: 1,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(home.refreshCalls, 1);

      transport.emit(
        'konsultasi.created',
        _payload(
          eventId: 'consult-event-0001',
          type: 'konsultasi.created',
          entityId: 51,
        ),
      );
      transport.emit(
        'konsultasi.status_changed',
        _payload(
          eventId: 'consult-event-0002',
          type: 'konsultasi.status_changed',
          entityId: 52,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(konsultasi.refreshCalls, 1);
      expect(konsultasi.lastEntityId, 52);
      expect(home.refreshCalls, 1);

      coordinator.dispose();
      await service.dispose();
    },
  );
}
