import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/realtime_socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../providers/internet_provider.dart';
import 'self_assessment_screen.dart';

/// LayananInternetScreen — Informasi Bandwidth & Router OPD (M-E)
class LayananInternetScreen extends ConsumerStatefulWidget {
  const LayananInternetScreen({super.key});

  @override
  ConsumerState<LayananInternetScreen> createState() =>
      _LayananInternetScreenState();
}

class _LayananInternetScreenState extends ConsumerState<LayananInternetScreen> {
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(internetProvider.notifier).loadRouters());
    _realtimeSubscription = ref
        .read(realtimeSocketServiceProvider)
        .events
        .where((event) => event.type == 'data.sync')
        .listen(
          (_) => ref.read(internetProvider.notifier).refreshFromRealtime(),
        );
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final actionEmerald = AppColors.actionEmerald(context);
    final accentNavy = AppColors.accentNavy(context);
    final accentGold = AppColors.accentGold(context);
    final mutedText = AppColors.mutedText(context);

    final state = ref.watch(internetProvider);
    final info = state.bandwidthInfo;
    final routers = state.listRouter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Layanan Internet OPD'),
        centerTitle: true,
        actions: const [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------------------
              // Bento Card: Bandwidth Status OPD
              // ---------------------------------------------------------------
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: accentNavy.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.speed_rounded,
                            color: accentNavy,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                info['opd'] ?? 'OPD Provinsi Lampung',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                info['provider'] ?? 'Bandwidth Dedicated',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(status: info['status'] ?? 'Normal'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryTeal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        info['available'] == true
                            ? 'Download ${info['download_mbps']} Mbps • Upload ${info['upload_mbps']} Mbps'
                            : 'Informasi bandwidth untuk OPD Anda belum tersedia.',
                        style: TextStyle(fontSize: 12, color: mutedText),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section Header: Infrastructure Router OPD
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Perangkat Router OPD (${routers.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryTeal,
                    ),
                  ),
                  Icon(Icons.router_outlined, color: primaryTeal, size: 20),
                ],
              ),
              const SizedBox(height: 12),

              // Router Cards List
              ...routers.asMap().entries.map((entry) {
                final idx = entry.key;
                final r = entry.value;

                // Color variation for icons
                final iconBgColor = idx % 2 == 0
                    ? primaryTeal.withValues(alpha: 0.12)
                    : accentGold.withValues(alpha: 0.15);
                final iconColor = idx % 2 == 0 ? primaryTeal : accentGold;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: iconBgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.router_rounded,
                                color: iconColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['nama_router'] ?? 'Router OPD',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'IP: ${r['ip_address']} • ${r['tipe']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: mutedText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(status: r['status'] ?? 'Aktif'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: mutedText,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                r['lokasi'] ?? '-',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: mutedText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                'Traffic: ${r['beban_traffic']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTeal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SelfAssessmentScreen()),
          );
        },
        backgroundColor: actionEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.report_problem_rounded),
        label: const Text(
          'Buat Pengaduan Internet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
