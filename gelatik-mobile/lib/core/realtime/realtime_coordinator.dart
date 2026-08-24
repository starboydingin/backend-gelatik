import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/providers/home_provider.dart';
import '../../features/konsultasi/providers/konsultasi_provider.dart';
import '../../features/peminjaman/providers/peminjaman_provider.dart';
import 'realtime_event.dart';
import 'realtime_socket_service.dart';

class RealtimeCoordinator {
  final RealtimeSocketService service;
  final PeminjamanNotifier peminjaman;
  final KonsultasiNotifier konsultasi;
  final HomeNotifier home;
  final _timers = <String, Timer>{};
  late final StreamSubscription<RealtimeEvent> _subscription;

  RealtimeCoordinator({
    required this.service,
    required this.peminjaman,
    required this.konsultasi,
    required this.home,
  }) {
    _subscription = service.events.listen(_onEvent);
  }

  void _onEvent(RealtimeEvent event) {
    if (event.type.startsWith('pinjam.')) {
      _schedule('pinjam', () async {
        await peminjaman.refreshFromRealtime(event.entityId);
        await home.refreshFromRealtime();
      });
    } else if (event.type.startsWith('konsultasi.')) {
      _schedule('konsultasi', () async {
        await konsultasi.refreshFromRealtime(event.entityId);
        await home.refreshFromRealtime();
      });
    } else if (event.type.startsWith('usulan_email.')) {
      _schedule('usulan_email', () => home.refreshFromRealtime());
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
    peminjaman: ref.watch(peminjamanProvider.notifier),
    konsultasi: ref.watch(konsultasiProvider.notifier),
    home: ref.watch(homeProvider.notifier),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
