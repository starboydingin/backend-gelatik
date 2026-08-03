import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../models/usulan_email_model.dart';

/// UsulanEmailDetailScreen — Detail Lengkap Usulan Email Resmi (M-F)
class UsulanEmailDetailScreen extends StatelessWidget {
  final UsulanEmailModel usulan;

  const UsulanEmailDetailScreen({
    super.key,
    required this.usulan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final actionEmerald = AppColors.actionEmerald(context);
    final accentNavy = AppColors.accentNavy(context);
    final mutedText = AppColors.mutedText(context);

    final isDisetujui = usulan.status.toLowerCase() == 'disetujui';
    final isDitolak = usulan.status.toLowerCase() == 'ditolak';

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Usulan #${usulan.id}'),
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
              // Header Card Data Pegawai & Status
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accentNavy.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.badge_rounded,
                            color: accentNavy,
                            size: 22,
                          ),
                        ),
                        StatusBadge(status: usulan.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      usulan.namaPegawai,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NIP: ${usulan.nipPegawai}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    _buildInfoRow('Email Pribadi', usulan.emailPribadi, mutedText, theme),
                    const SizedBox(height: 8),

                    // Approved Email Resmi Display
                    if (isDisetujui && usulan.emailResmi != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: actionEmerald.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: actionEmerald, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.verified_user_rounded,
                                color: actionEmerald, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'EMAIL RESMI PEMPROV LAMPUNG',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: actionEmerald,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    usulan.emailResmi!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: actionEmerald,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (usulan.diverifikasiOleh != null) ...[
                      _buildInfoRow('Diverifikasi Oleh', usulan.diverifikasiOleh!, mutedText, theme),
                      const SizedBox(height: 8),
                    ],

                    if (usulan.tanggalVerifikasi != null) ...[
                      _buildInfoRow(
                        'Tanggal Verifikasi',
                        '${usulan.tanggalVerifikasi!.day}/${usulan.tanggalVerifikasi!.month}/${usulan.tanggalVerifikasi!.year}',
                        mutedText,
                        theme,
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (isDitolak && usulan.catatan != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Catatan Penolakan:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              usulan.catatan!,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color mutedText, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: mutedText),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
