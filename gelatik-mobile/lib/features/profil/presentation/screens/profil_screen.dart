import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gelatik_page_header.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../../internet/presentation/screens/self_assessment_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../services/presentation/screens/services_screen.dart';
import '../../../../core/widgets/notification_badge_button.dart';
import '../../providers/wa_notification_provider.dart';
import 'edit_profil_screen.dart';
import 'change_password_screen.dart';
import 'notifikasi_whatsapp_screen.dart';
import 'activity_log_screen.dart';
import '../../../kritik_saran/presentation/screens/kritik_saran_history_screen.dart';

/// ProfilScreen — Modul M-J Profil Pengguna Gelatik Mobile
class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  String _display(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? '-' : text;
  }

  /// Helper untuk mengambil inisial nama (maksimal 2 huruf)
  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  void _showInformasiAkunModal(BuildContext context, dynamic user) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Informasi Akun',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTeal,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow(context, 'Nama Lengkap', _display(user?.name)),
              const SizedBox(height: 12),
              _buildInfoRow(context, 'Email', _display(user?.email)),
              const SizedBox(height: 12),
              _buildInfoRow(context, 'No. WhatsApp / HP', _display(user?.noHp)),
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'NIP / Username',
                _display(user?.username),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(context, 'OPD / Instansi', _display(user?.namaOpd)),
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Role Pengguna',
                _display(user?.role).toUpperCase(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Tutup',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final mutedText = AppColors.mutedText(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: mutedText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = isDark
        ? AppColors.statusErrorDark
        : AppColors.statusErrorLight;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Anda yakin ingin keluar dari aplikasi Gelatik?'),
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
              Navigator.of(dialogCtx).pop(); // Tutup dialog
              // Call AuthNotifier.logout() (FR-38 handles unsubscribe)
              await ref.read(authProvider.notifier).logout();

              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final accentNavy = AppColors.accentNavy(context);
    final accentGold = AppColors.accentGold(context);
    final strokeColor = AppColors.cardStroke(context);
    final mutedText = AppColors.mutedText(context);
    final isDark = theme.brightness == Brightness.dark;
    final errorColor = isDark
        ? AppColors.statusErrorDark
        : AppColors.statusErrorLight;

    final authState = ref.watch(authProvider);
    final user = authState.currentUser;
    final profileName = _display(user?.name);
    final profileOpd = _display(user?.namaOpd);
    final profileEmail = _display(user?.email);
    final waState = ref.watch(waNotificationProvider);
    final waSub = waState.subscription;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth >= 760
        ? (screenWidth - 680) / 2
        : 20.0;

    return Scaffold(
      appBar: const GelatikPageHeader(
        title: 'Profil',
        actions: [NotificationBadgeButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          key: const Key('profile-scroll'),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            20,
            horizontalPadding,
            112,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Bento Card Profile Avatar
                  AppCard(
                    child: Row(
                      children: [
                        // A solid primary avatar keeps the profile identifiable
                        // without introducing a decorative gradient.
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: accentNavy,
                            shape: BoxShape.circle,
                            border: Border.all(color: strokeColor, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(
                                profileName == '-' ? 'User' : profileName,
                              ),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profileName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                profileOpd,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: mutedText,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profileEmail,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: primaryTeal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Pengaturan & Informasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryTeal,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // List Menu Bento Style
                  _buildMenuItem(
                    context: context,
                    icon: Icons.person_outline_rounded,
                    iconColor: primaryTeal,
                    title: 'Edit Profil',
                    subtitle: 'Perbarui nama, kontak, email, dan OPD',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditProfilScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildMenuItem(
                    context: context,
                    icon: Icons.history_rounded,
                    iconColor: accentGold,
                    title: 'Riwayat Kritik & Saran',
                    subtitle: 'Lihat masukan dan tanggapan petugas',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const KritikSaranHistoryScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildMenuItem(
                    context: context,
                    icon: Icons.badge_outlined,
                    iconColor: primaryTeal,
                    title: 'Informasi Akun',
                    subtitle: 'Lihat detail NIP dan akun',
                    onTap: () => _showInformasiAkunModal(context, user),
                  ),
                  const SizedBox(height: 10),

                  _buildMenuItem(
                    context: context,
                    icon: Icons.lock_outline_rounded,
                    iconColor: accentNavy,
                    title: 'Ganti Password',
                    subtitle: 'Ubah password dengan password lama',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildMenuItem(
                    context: context,
                    icon: Icons.history_rounded,
                    iconColor: primaryTeal,
                    title: 'Log Aktivitas',
                    subtitle: 'Riwayat layanan dan pembaruan pada akun Anda',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ActivityLogScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Modul F-WA: Notifikasi WhatsApp
                  _buildMenuItem(
                    context: context,
                    icon: Icons.chat_rounded,
                    iconColor: AppColors.actionEmerald(context),
                    title: 'Notifikasi WhatsApp',
                    subtitle: waSub.isSubscribed
                        ? 'Terhubung (${waSub.waNumber})'
                        : 'Non-aktif / Belum terhubung',
                    trailingIcon: Icons.arrow_forward_ios_rounded,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotifikasiWhatsAppScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  _buildMenuItem(
                    context: context,
                    icon: Icons.notifications_outlined,
                    iconColor: accentNavy,
                    title: 'Notifikasi',
                    subtitle: 'Pembaruan status dan respons layanan',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildMenuItem(
                    context: context,
                    icon: Icons.help_outline_rounded,
                    iconColor: accentGold,
                    title: 'Bantuan & FAQ',
                    subtitle: 'Pertanyaan umum & panduan layanan TIK',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SelfAssessmentScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  _buildMenuItem(
                    context: context,
                    icon: Icons.info_outline_rounded,
                    iconColor: primaryTeal,
                    title: 'Tentang Aplikasi',
                    subtitle: 'Versi 1.0.0 — Gelatik TIK Lampung',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Gelatik Mobile',
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                            '© 2026 Diskominfotik Provinsi Lampung',
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Tombol Logout Outlined Style dengan warna error
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () => _showLogoutConfirmation(context, ref),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: errorColor.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, color: errorColor),
                            const SizedBox(width: 8),
                            Text(
                              'Keluar (Logout)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        isAdmin:
            user != null &&
            const {
              'admin',
              'superadmin',
              'bkd',
            }.contains(user.role.toLowerCase()),
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (index == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ServicesScreen()),
            );
          } else if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          } else if (index == 3) {
            // Already in ProfilScreen.
          } else if (index == 4 &&
              user != null &&
              const {
                'admin',
                'superadmin',
                'bkd',
              }.contains(user.role.toLowerCase())) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    IconData trailingIcon = Icons.chevron_right_rounded,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText(context),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            trailingIcon,
            color: AppColors.mutedText(context),
            size: trailingIcon == Icons.arrow_forward_ios_rounded ? 16 : 22,
          ),
        ],
      ),
    );
  }
}
