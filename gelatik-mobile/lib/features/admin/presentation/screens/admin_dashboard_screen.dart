import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gelatik_page_header.dart';
import '../../../../core/widgets/notification_badge_button.dart';
import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/realtime_socket_service.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../calendar/presentation/screens/calendar_screen.dart';
import '../../../email/providers/email_provider.dart';
import '../../../konsultasi/providers/konsultasi_provider.dart';
import '../../../peminjaman/providers/peminjaman_provider.dart';
import '../../repositories/admin_dashboard_repository.dart';
import 'admin_konsultasi_list_screen.dart';
import 'admin_peminjaman_list_screen.dart';
import 'admin_usulan_email_list_screen.dart';

/// AdminDashboardScreen — Halaman Utama Panel Admin (M-L) untuk Admin & Superadmin
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  Map<String, dynamic> _dashboard = const {};
  String? _dashboardError;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDashboard);
    _realtimeSubscription = ref
        .read(realtimeSocketServiceProvider)
        .events
        .where(
          (event) => event.type == 'notification' ||
              event.type.startsWith('konsultasi.') ||
              event.type.startsWith('pinjam.') ||
              event.type.startsWith('usulan_email.'),
        )
        .listen((_) => _loadDashboard(fresh: true));
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard({bool fresh = false}) async {
    final role = ref.read(authProvider).currentUser?.role.toLowerCase();
    if (role != 'admin' && role != 'superadmin') return;
    try {
      final data = await ref
          .read(adminDashboardRepositoryProvider)
          .getDashboard(bypassCache: fresh);
      if (mounted) {
        setState(() {
          _dashboard = data;
          _dashboardError = null;
        });
      }
    } catch (_) {
      // Existing list-based navigation still works if the compact dashboard
      // endpoint is briefly unavailable. Do not replace the screen with an
      // opaque exception or stale zeroes.
      if (mounted) {
        setState(() => _dashboardError = 'Ringkasan terbaru belum tersedia.');
      }
    }
  }

  int _count(String key, int fallback) {
    final summary = _dashboard['summary'];
    final value = summary is Map ? summary[key] : null;
    return value is int ? value : int.tryParse('$value') ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final actionEmerald = AppColors.actionEmerald(context);
    final accentNavy = AppColors.accentNavy(context);
    final accentGold = AppColors.accentGold(context);
    final strokeColor = AppColors.cardStroke(context);
    final mutedText = AppColors.mutedText(context);

    final user = ref.watch(authProvider).currentUser;
    final role = user?.role.toLowerCase();
    final canManageServices = role == 'admin' || role == 'superadmin';
    final canAccessAdmin = canManageServices || role == 'bkd';

    if (!canAccessAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Akses Ditolak')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Halaman ini hanya tersedia untuk admin.',
              key: Key('admin-access-denied'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Stream / watch 3 provider data untuk metric ringkas
    final peminjamanList = ref.watch(peminjamanProvider).listPinjam;
    final konsultasiList = ref.watch(konsultasiProvider).listKonsultasi;
    final emailList = ref.watch(emailProvider).listUsulanEmail;

    final fallbackPinjamCount = peminjamanList
        .where((p) => p.status == 'Menunggu')
        .length;
    final fallbackKonsultasiCount = konsultasiList
        .where((k) => k.status == 'Menunggu')
        .length;
    final fallbackEmailCount = emailList
        .where((e) => e.status == 'diajukan')
        .length;
    final pendingPinjamCount = _count('peminjaman_open', fallbackPinjamCount);
    final pendingKonsultasiCount =
        _count('konsultasi_open', fallbackKonsultasiCount);
    final pendingEmailCount =
        _count('usulan_email_pending', fallbackEmailCount);

    return Scaffold(
      appBar: const GelatikPageHeader(
        title: 'Panel Admin',
        actions: [NotificationBadgeButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_dashboardError != null) ...[
                Text(
                  _dashboardError!,
                  style: TextStyle(fontSize: 12, color: mutedText),
                ),
                const SizedBox(height: 12),
              ],
              // Admin Profile Greeting Banner
              AppCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentNavy.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: strokeColor, width: 1.5),
                      ),
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 32,
                        color: accentNavy,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user?.name ?? 'Admin TIK',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: accentGold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: accentGold,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  user?.role.toUpperCase() ?? 'ADMIN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: accentGold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pusat Kendali Service Desk Diskominfotik',
                            style: TextStyle(fontSize: 12, color: mutedText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Area Pengelolaan Layanan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                ),
              ),
              const SizedBox(height: 12),

              // 3 Cards Bento Navigasi Kelola Area
              if (canManageServices) ...[
                _buildAdminBentoCard(
                  context: context,
                  title: 'Kelola Peminjaman Aset',
                  subtitle: 'Pengajuan alat, verifikasi & bukti pengembalian',
                  badgeText: '$pendingPinjamCount menunggu persetujuan',
                  badgeColor: pendingPinjamCount > 0 ? primaryTeal : mutedText,
                  icon: Icons.devices_other_rounded,
                  iconColor: primaryTeal,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminPeminjamanListScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildAdminBentoCard(
                  context: context,
                  title: 'Kelola Konsultasi TIK',
                  subtitle: 'Thread obrolan & balasan tiket konsultasi OPD',
                  badgeText: '$pendingKonsultasiCount tiket menunggu balasan',
                  badgeColor: pendingKonsultasiCount > 0
                      ? accentNavy
                      : mutedText,
                  icon: Icons.support_agent_rounded,
                  iconColor: accentNavy,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminKonsultasiListScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              _buildAdminBentoCard(
                context: context,
                title: 'Kelola Usulan Email',
                subtitle: 'Persetujuan usulan email resmi BKD & pembuatan akun',
                badgeText: '$pendingEmailCount usulan diajukan',
                badgeColor: pendingEmailCount > 0 ? actionEmerald : mutedText,
                icon: Icons.mark_email_read_rounded,
                iconColor: actionEmerald,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminUsulanEmailListScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),
              _buildAdminBentoCard(
                context: context,
                title: 'Agenda Operasional',
                subtitle: 'Jadwal pengajuan layanan sesuai peran Anda',
                badgeText: 'Buka kalender layanan',
                badgeColor: primaryTeal,
                icon: Icons.calendar_month_outlined,
                iconColor: primaryTeal,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CalendarScreen()),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        isAdmin: true,
        onTap: (index) {
          if (index == 0 || index == 1 || index == 2) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      ),
    );
  }

  Widget _buildAdminBentoCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedText(context),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.mutedText(context),
          ),
        ],
      ),
    );
  }
}
