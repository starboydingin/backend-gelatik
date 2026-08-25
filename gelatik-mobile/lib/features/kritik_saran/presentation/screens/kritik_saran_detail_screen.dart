import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/realtime_socket_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gelatik_page_header.dart';
import '../../repositories/kritik_saran_repository.dart';

/// Read-only detail for feedback owned by the authenticated user.
class KritikSaranDetailScreen extends ConsumerStatefulWidget {
  final int feedbackId;

  const KritikSaranDetailScreen({super.key, required this.feedbackId});

  @override
  ConsumerState<KritikSaranDetailScreen> createState() =>
      _KritikSaranDetailScreenState();
}

class _KritikSaranDetailScreenState
    extends ConsumerState<KritikSaranDetailScreen> {
  Map<String, dynamic>? _item;
  String? _error;
  bool _loading = true;
  StreamSubscription<RealtimeEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
    _subscription = ref
        .read(realtimeSocketServiceProvider)
        .events
        .where(
          (event) =>
              event.type == 'data.sync' &&
              event.resource?.toLowerCase() == 'kritik_saran',
        )
        .listen((_) => _load());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final item = await ref
          .read(kritikSaranRepositoryProvider)
          .getMyFeedbackDetail(widget.feedbackId);
      if (mounted) setState(() => _item = item);
    } catch (_) {
      if (mounted) setState(() => _error = 'Data ini sudah tidak tersedia.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const GelatikPageHeader(
      title: 'Detail Kritik & Saran',
      showBack: true,
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(child: Text(_error!))
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dikirim ${GelatikDateFormatter.dateTime(DateTime.tryParse('${_item?['created_at']}') ?? DateTime.now())}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    const Text('Kritik', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('${_item?['kritik'] ?? '-'}'),
                    const SizedBox(height: 20),
                    const Text('Saran', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('${_item?['saran'] ?? '-'}'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: _item?['balasan'] == null
                    ? const Text('Masukan Anda sedang ditinjau petugas.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tanggapan ${_item?['responder']?['name'] ?? 'Petugas'}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text('${_item?['balasan']}'),
                        ],
                      ),
              ),
            ],
          ),
  );
}
