import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../providers/internet_provider.dart';
import 'self_assessment_screen.dart';

/// LayananInternetScreen — Informasi Bandwidth & Router OPD (M-E)
class LayananInternetScreen extends ConsumerWidget {
  const LayananInternetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
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
                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    const SizedBox(height: 18),

                    // Download / Upload Large Statistics Numbers
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: primaryTeal.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.cardStroke(context),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_downward_rounded,
                                        size: 16, color: primaryTeal),
                                    const SizedBox(width: 4),
                                    Text(
                                      'DOWNLOAD',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: primaryTeal,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${info['download_mbps']}',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: primaryTeal,
                                  ),
                                ),
                                Text(
                                  'Mbps',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: accentGold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.cardStroke(context),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_upward_rounded,
                                        size: 16, color: accentGold),
                                    const SizedBox(width: 4),
                                    Text(
                                      'UPLOAD',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: accentGold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${info['upload_mbps']}',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: accentGold,
                                  ),
                                ),
                                Text(
                                  'Mbps',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'IP: ${r['ip_address']} • ${r['tipe']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: mutedText,
                                    ),
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
                            Icon(Icons.location_on_outlined,
                                size: 14, color: mutedText),
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
                            Text(
                              'Traffic: ${r['beban_traffic']}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryTeal,
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
            MaterialPageRoute(
              builder: (_) => const SelfAssessmentScreen(),
            ),
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
