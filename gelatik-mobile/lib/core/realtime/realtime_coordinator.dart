import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../../features/home/providers/home_provider.dart';
import '../../features/home/repositories/announcement_repository.dart';
import '../../features/konsultasi/providers/konsultasi_provider.dart';
import '../../features/peminjaman/providers/peminjaman_provider.dart';
import '../../features/email/providers/email_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/internet/providers/internet_provider.dart';
import '../../features/info_alat/providers/info_alat_provider.dart';
import '../../features/profil/providers/wa_notification_provider.dart';
import 'realtime_event.dart';
import 'realtime_socket_service.dart';

class RealtimeCoordinator {
  final RealtimeSocketService service;
  final ApiClient apiClient;
  final PeminjamanNotifier peminjaman;
  final KonsultasiNotifier konsultasi;
  final EmailNotifier email;
  final AuthNotifier auth;
  final InternetNotifier internet;
  final InfoAlatNotifier infoAlat;
  final WaNotificationNotifier waNotification;
  final HomeNotifier home;
  final void Function()? onAnnouncementsChanged;
  final _timers = <String, Timer>{};
  late final StreamSubscription<RealtimeEvent> _subscription;

  RealtimeCoordinator({
    required this.service,
    required this.apiClient,
    required this.peminjaman,
    required this.konsultasi,
    required this.email,
    required this.auth,
    required this.internet,
    required this.infoAlat,
    required this.waNotification,
    required this.home,
    this.onAnnouncementsChanged,
  }) {
    _subscription = service.events.listen(_onEvent);
  }

  void _onEvent(RealtimeEvent event) {
    apiClient.invalidateCacheForResource(_resourceFor(event));
    if (event.type == 'notification') {
      _schedule('notification', () => home.refreshFromRealtime());
    } else if (event.type == 'pengumuman.created') {
      onAnnouncementsChanged?.call();
    } else if (event.type == 'data.sync') {
      _syncData(event);
    } else if (event.type == 'insights.sync') {
      _schedule('insights', () => home.refreshFromRealtime());
    } else if (event.type.startsWith('pinjam.')) {
      _schedule(
        'peminjaman',
        () => peminjaman.refreshFromRealtime(event.entityId),
      );
    } else if (event.type.startsWith('konsultasi.')) {
      _schedule(
        'konsultasi',
        () => konsultasi.refreshFromRealtime(event.entityId),
      );
    } else if (event.type.startsWith('usulan_email.')) {
      _schedule('usulan_email', email.refreshFromRealtime);
    }
  }

  String _resourceFor(RealtimeEvent event) {
    if (event.type == 'insights.sync') return 'insights';
    if (event.type == 'pengumuman.created') return 'pengumuman';
    final resource = event.resource?.trim();
    if (resource != null && resource.isNotEmpty) return resource;
    if (event.type.startsWith('pinjam.')) return 'peminjaman';
    if (event.type.startsWith('konsultasi.')) return 'konsultasi';
    if (event.type.startsWith('usulan_email.')) return 'usulan_email';
    if (event.type == 'notification') return 'notification';
    if (event.type == 'insights.sync') return 'insights';
    return '';
  }

  void _syncData(RealtimeEvent event) {
    final resource = event.resource?.toLowerCase() ?? '';
    switch (resource) {
      case 'peminjaman':
        _schedule(
          'peminjaman',
          () => peminjaman.refreshFromRealtime(event.entityId),
        );
        return;
      case 'konsultasi':
        _schedule(
          'konsultasi',
          () => konsultasi.refreshFromRealtime(event.entityId),
        );
        return;
      case 'usulan_email':
        _schedule('usulan_email', email.refreshFromRealtime);
        return;
      case 'user':
        _schedule('user', auth.refreshFromRealtime);
        return;
      case 'rating':
      case 'notification':
      case 'kritik_saran':
        _schedule(resource, () => home.refreshFromRealtime());
        return;
      case 'whatsapp_subscription':
        _schedule(resource, waNotification.refreshFromRealtime);
        return;
      case 'faq':
      case 'mastertopik':
        _schedule(resource, () async {
          await konsultasi.loadTopik(force: true);
          await internet.refreshAllFromRealtime();
        });
        return;
      case 'masteritem':
        _schedule(resource, () => infoAlat.loadItems(force: true));
        return;
      case 'router':
      case 'routerlist':
        _schedule(resource, () => internet.refreshAllFromRealtime());
        return;
      case 'pengumuman':
        // The dashboard may still be served from its short-lived cache. Refresh
        // the independent feed so an announcement appears immediately.
        onAnnouncementsChanged?.call();
        return;
      case 'session':
        // A suspended mobile process may miss multiple events. Remove every
        // account-scoped cache and reconcile all providers from authoritative
        // REST endpoints, including reference data and aggregate insights.
        apiClient.clearCache();
        onAnnouncementsChanged?.call();
        _schedule('session', () async {
          await auth.refreshFromRealtime();
          await Future.wait([
            peminjaman.refreshFromRealtime(event.entityId),
            konsultasi.refreshFromRealtime(event.entityId),
            email.refreshFromRealtime(),
            home.refreshFromRealtime(),
            internet.refreshAllFromRealtime(),
            infoAlat.loadItems(force: true),
            waNotification.refreshFromRealtime(),
          ]);
        });
        return;
      case 'slider':
      case 'insights':
        _schedule(resource, () => home.refreshFromRealtime());
        return;
      default:
        return;
    }
  }

  void _schedule(String key, Future<void> Function() action) {
    _timers[key]?.cancel();
    _timers[key] = Timer(const Duration(milliseconds: 250), () {
      action().catchError((_) {});
    });
  }

  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _subscription.cancel();
  }
}

final realtimeCoordinatorProvider = Provider<RealtimeCoordinator>((ref) {
  final coordinator = RealtimeCoordinator(
    service: ref.watch(realtimeSocketServiceProvider),
    apiClient: ref.watch(apiClientProvider),
    peminjaman: ref.watch(peminjamanProvider.notifier),
    konsultasi: ref.watch(konsultasiProvider.notifier),
    email: ref.watch(emailProvider.notifier),
    auth: ref.watch(authProvider.notifier),
    internet: ref.watch(internetProvider.notifier),
    infoAlat: ref.watch(infoAlatProvider.notifier),
    waNotification: ref.watch(waNotificationProvider.notifier),
    home: ref.watch(homeProvider.notifier),
    onAnnouncementsChanged: () => ref.invalidate(activeAnnouncementsProvider),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
