import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/realtime_socket_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gelatik_page_header.dart';
import '../../repositories/kritik_saran_repository.dart';
import 'kritik_saran_detail_screen.dart';

class KritikSaranHistoryScreen extends ConsumerStatefulWidget {
  const KritikSaranHistoryScreen({super.key});

  @override
  ConsumerState<KritikSaranHistoryScreen> createState() =>
      _KritikSaranHistoryScreenState();
}

class _KritikSaranHistoryScreenState
    extends ConsumerState<KritikSaranHistoryScreen> {
  List<Map<String, dynamic>> _items = const [];
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
      final items = await ref
          .read(kritikSaranRepositoryProvider)
          .getMyFeedback();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      // Retain the previous list while a transient fetch is retried later.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const GelatikPageHeader(
      title: 'Riwayat Kritik & Saran',
      showBack: true,
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 180),
                      Center(child: Text('Belum ada kritik dan saran.')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final id = int.tryParse('${item['id'] ?? ''}');
                      return AppCard(
                        onTap: id == null
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      KritikSaranDetailScreen(feedbackId: id),
                                ),
                              ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['balasan'] == null
                                        ? 'Menunggu tanggapan'
                                        : 'Sudah dibalas',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: item['balasan'] == null
                                          ? Colors.orange.shade800
                                          : Colors.green.shade800,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${item['kritik'] ?? '-'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              GelatikDateFormatter.dateTime(
                                DateTime.tryParse('${item['created_at']}') ??
                                    DateTime.now(),
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
  );
}
