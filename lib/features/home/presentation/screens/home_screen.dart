import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../chatbot/presentation/screens/chatbot_web_view_screen.dart';
import '../../../email/presentation/screens/usulan_email_list_screen.dart';
import '../../../info_alat/presentation/screens/info_alat_screen.dart';
import '../../../internet/presentation/screens/layanan_internet_screen.dart';
import '../../../konsultasi/presentation/screens/konsultasi_list_screen.dart';
import '../../../kritik_saran/presentation/screens/kritik_saran_screen.dart';
import '../../../peminjaman/presentation/screens/ajukan_peminjaman_screen.dart';
import '../../../peminjaman/presentation/screens/peminjaman_list_screen.dart';
import '../../../profil/presentation/screens/profil_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final actionEmerald = AppColors.actionEmerald(context);
    final strokeColor = AppColors.cardStroke(context);
    final mutedText = AppColors.mutedText(context);
    final accentNavy = AppColors.accentNavy(context);
    final accentGold = AppColors.accentGold(context);

    final authState = ref.watch(authProvider);
    final user = authState.currentUser;
    final role = user?.role.toLowerCase() ?? '';
    final isAdmin = role == 'admin' || role == 'superadmin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelatik Dashboard'),
        centerTitle: true,
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Banner Card (Neo-Brutalism AppCard)
              AppCard(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfilScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: strokeColor, width: 1.5),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 36,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Pengguna Gelatik',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.namaOpd ??
                                'Dinas Komunikasi, Informatika dan Statistik',
                            style: TextStyle(
                              fontSize: 12,
                              color: mutedText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: mutedText,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Layanan TIK Utama',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                ),
              ),
              const SizedBox(height: 12),

              // Service Menu Bento Grid (2 Columns)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  _buildMenuCard(
                    context: context,
                    title: 'Peminjaman Aset',
                    subtitle: 'Wizard 2-Step',
                    icon: Icons.devices_rounded,
                    color: primaryTeal,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AjukanPeminjamanScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context: context,
                    title: 'Riwayat Pinjam',
                    subtitle: 'Daftar & Status',
                    icon: Icons.assignment_rounded,
                    color: actionEmerald,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PeminjamanListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context: context,
                    title: 'Konsultasi TIK',
                    subtitle: 'Thread Chat',
                    icon: Icons.support_agent_rounded,
                    color: accentNavy,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const KonsultasiListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context: context,
                    title: 'Layanan Internet',
                    subtitle: 'Info & Router OPD',
                    icon: Icons.wifi_rounded,
                    color: accentGold,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LayananInternetScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context: context,
                    title: 'Usulan Email',
                    subtitle: 'Email Resmi BKD',
                    icon: Icons.mark_email_read_rounded,
                    color: primaryTeal,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UsulanEmailListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context: context,
                    title: 'Info Alat TIK',
                    subtitle: 'Katalog Read-Only',
                    icon: Icons.inventory_2_rounded,
                    color: actionEmerald,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const InfoAlatScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context: context,
                    title: 'Kritik & Saran',
                    subtitle: 'Evaluasi Layanan',
                    icon: Icons.rate_review_rounded,
                    color: accentNavy,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const KritikSaranScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Logout Button
              AppButton(
                text: 'Keluar (Logout)',
                icon: Icons.logout_rounded,
                variant: AppButtonVariant.outlined,
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ChatbotWebViewScreen(),
            ),
          );
        },
        backgroundColor: actionEmerald,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: Badge(
          smallSize: 10,
          backgroundColor: accentGold,
          child: const Icon(
            Icons.smart_toy_rounded,
            size: 26,
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        isAdmin: isAdmin,
        onTap: (index) {
          if (index == 0) {
            // Already home
          } else if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AjukanPeminjamanScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProfilScreen(),
              ),
            );
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AdminDashboardScreen(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.mutedText(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
