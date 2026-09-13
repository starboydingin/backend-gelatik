import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/discussion_section.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../email/providers/email_provider.dart';

/// AdminUsulanEmailDetailScreen — Detail Usulan Email & Aksi Khusus Admin (Setujui/Tolak)
class AdminUsulanEmailDetailScreen extends ConsumerStatefulWidget {
  final int usulanId;

  const AdminUsulanEmailDetailScreen({super.key, required this.usulanId});

  @override
  ConsumerState<AdminUsulanEmailDetailScreen> createState() =>
      _AdminUsulanEmailDetailScreenState();
}

class _AdminUsulanEmailDetailScreenState
    extends ConsumerState<AdminUsulanEmailDetailScreen> {
  final TextEditingController _emailResmiController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  String? _emailResmiError;
  String? _catatanError;

  void _showVerifikasiDialog(BuildContext context) {
    _catatanController.clear();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Verifikasi Dokumen'),
        content: AppTextField(
          labelText: 'Catatan Verifikasi (Opsional)',
          hintText: 'Contoh: Dokumen pendukung telah sesuai.',
          controller: _catatanController,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('confirm-email-verification'),
            onPressed: () async {
              final notes = _catatanController.text.trim();
              Navigator.of(dialogCtx).pop();
              final success = await ref
                  .read(emailProvider.notifier)
                  .verifikasiUsulanEmail(
                    id: widget.usulanId,
                    catatan: notes.isEmpty ? null : notes,
                  );
              if (success && context.mounted) {
                AppNotification.showSuccess(
                  context,
                  'Dokumen usulan berhasil diverifikasi.',
                );
              }
            },
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailResmiController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _showSetujuDialog(BuildContext context, String nip) {
    // Auto populate suggestion email
    final cleanNip = nip.replaceAll(RegExp(r'\s+'), '');
    _emailResmiController.text = cleanNip.isNotEmpty && cleanNip != '-'
        ? '$cleanNip@lampungprov.go.id'
        : 'pegawai@lampungprov.go.id';

    setState(() {
      _emailResmiError = null;
    });

    final actionEmerald = AppColors.actionEmerald(context);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Setujui & Buat Email Resmi'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan alamat email resmi domain @lampungprov.go.id yang dibuatkan:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    labelText: 'Alamat Email Resmi (WAJIB)',
                    hintText: 'nip@lampungprov.go.id',
                    controller: _emailResmiController,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailResmiError,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionEmerald,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final email = _emailResmiController.text.trim();
                    if (email.isEmpty) {
                      setDialogState(() {
                        _emailResmiError = 'Alamat email resmi wajib diisi.';
                      });
                      return;
                    }

                    if (!email.contains('@')) {
                      setDialogState(() {
                        _emailResmiError =
                            'Format email tidak valid (harus mengandung @).';
                      });
                      return;
                    }

                    Navigator.of(dialogCtx).pop();

                    final adminUser = ref.read(authProvider).currentUser;
                    final success = await ref
                        .read(emailProvider.notifier)
                        .setujuUsulanEmail(
                          id: widget.usulanId,
                          emailResmi: email,
                          adminName: adminUser?.name ?? 'Admin BKD',
                        );

                    if (success && context.mounted) {
                      AppNotification.showSuccess(
                        context,
                        'Usulan disetujui! Email resmi: $email',
                      );
                    }
                  },
                  child: const Text('Setujui & Buat'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTolakDialog(BuildContext context) {
    _catatanController.clear();
    setState(() {
      _catatanError = null;
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = isDark
        ? AppColors.statusErrorDark
        : AppColors.statusErrorLight;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tolak Usulan Email'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Berikan alasan/catatan penolakan usulan email (WAJIB diisi):',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    labelText: 'Catatan Penolakan Admin',
                    hintText:
                        'Misal: Data NIP pegawai tidak cocok dengan database BKD.',
                    controller: _catatanController,
                    maxLines: 3,
                    errorText: _catatanError,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final notes = _catatanController.text.trim();
                    if (notes.isEmpty) {
                      setDialogState(() {
                        _catatanError = 'Catatan penolakan wajib diisi.';
                      });
                      return;
                    }

                    Navigator.of(dialogCtx).pop();

                    final adminUser = ref.read(authProvider).currentUser;
                    final success = await ref
                        .read(emailProvider.notifier)
                        .tolakUsulanEmail(
                          id: widget.usulanId,
                          catatan: notes,
                          adminName: adminUser?.name ?? 'Admin BKD',
                        );

                    if (success && context.mounted) {
                      AppNotification.showSuccess(
                        context,
                        'Usulan email telah ditolak.',
                      );
                    }
                  },
                  child: const Text('Konfirmasi Tolak'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTeal = AppColors.primaryTeal(context);
    final errorColor = isDark
        ? AppColors.statusErrorDark
        : AppColors.statusErrorLight;
    final mutedText = AppColors.mutedText(context);

    final state = ref.watch(emailProvider);
    final role = ref.watch(authProvider).currentUser?.role.toLowerCase();
    final canVerify = role == 'bkd';
    final canApprove = role == 'admin' || role == 'superadmin';
    final canReject = role == 'bkd';
    final usulan = state.listUsulanEmail.firstWhere(
      (e) => e.id == widget.usulanId,
      orElse: () => state.listUsulanEmail.first,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Detail Usulan Email #${usulan.id}',
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal),
        ),
        centerTitle: true,
        actions: const [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card Status Usulan
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STATUS USULAN EMAIL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: mutedText,
                            letterSpacing: 0.5,
                          ),
                        ),
                        StatusBadge(status: usulan.status),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      context,
                      'Nama Pegawai BKD',
                      usulan.namaPegawai,
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(context, 'NIP Pegawai', usulan.nipPegawai),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      context,
                      'Email Pribadi / Kontak',
                      usulan.emailPribadi,
                    ),
                    if (usulan.emailResmi != null &&
                        usulan.emailResmi!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        context,
                        'Email Resmi Terbuat',
                        usulan.emailResmi!,
                      ),
                    ],
                    if (usulan.tanggalVerifikasi != null) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        context,
                        'Tanggal Verifikasi',
                        GelatikDateFormatter.dateTime(
                          usulan.tanggalVerifikasi!,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        context,
                        'Diverifikasi Oleh',
                        usulan.diverifikasiOleh ?? 'Admin BKD',
                      ),
                    ],
                  ],
                ),
              ),

              // Jika status ditolak & ada catatan
              if (usulan.status == 'ditolak' &&
                  usulan.catatan != null &&
                  usulan.catatan!.isNotEmpty) ...[
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: errorColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CATATAN PENOLAKAN ADMIN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: errorColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        usulan.catatan!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              DiscussionSection(
                serviceType: 'usulan_email',
                recordId: widget.usulanId,
                status: usulan.status,
              ),

              const SizedBox(height: 32),

              // ===============================================================
              // ACTION BUTTONS KHUSUS ADMIN (M-L BAGIAN 4)
              // ===============================================================
              if (usulan.status == 'diajukan' &&
                  canVerify &&
                  usulan.canBeVerified) ...[
                AppButton(
                  key: const Key('verify-email-proposal'),
                  text: 'Verifikasi Dokumen',
                  icon: Icons.fact_check_outlined,
                  variant: AppButtonVariant.outlined,
                  onPressed: state.isLoading
                      ? null
                      : () => _showVerifikasiDialog(context),
                ),
                const SizedBox(height: 12),
              ],
              if (usulan.status == 'diajukan' && (canReject || canApprove)) ...[
                Row(
                  children: [
                    if (canReject)
                      Expanded(
                        child: AppButton(
                          text: 'Tolak',
                          icon: Icons.cancel_outlined,
                          variant: AppButtonVariant.outlined,
                          onPressed: state.isLoading
                              ? null
                              : () => _showTolakDialog(context),
                        ),
                      ),
                    if (canReject && canApprove) const SizedBox(width: 12),
                    if (canApprove)
                      Expanded(
                        child: AppButton(
                          text: 'Setujui & Buat',
                          icon: Icons.check_circle_outline_rounded,
                          variant: AppButtonVariant.filled,
                          onPressed: state.isLoading || !usulan.canBePublished
                              ? null
                              : () => _showSetujuDialog(
                                  context,
                                  usulan.nipPegawai,
                                ),
                        ),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
