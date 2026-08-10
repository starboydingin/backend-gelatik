import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gelatik_page_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../chatbot/presentation/screens/chatbot_native_screen.dart';
import '../../../email/presentation/screens/usulan_email_list_screen.dart';
import '../../../info_alat/presentation/screens/info_alat_screen.dart';
import '../../../internet/presentation/screens/layanan_internet_screen.dart';
import '../../../internet/presentation/screens/self_assessment_screen.dart';
import '../../../konsultasi/presentation/screens/konsultasi_detail_screen.dart';
import '../../../konsultasi/presentation/screens/konsultasi_list_screen.dart';
import '../../../konsultasi/models/konsultasi_model.dart';
import '../../../kritik_saran/presentation/screens/kritik_saran_screen.dart';
import '../../../peminjaman/presentation/screens/ajukan_peminjaman_screen.dart';
import '../../../peminjaman/presentation/screens/peminjaman_detail_screen.dart';
import '../../../peminjaman/presentation/screens/peminjaman_list_screen.dart';
import '../../../peminjaman/models/pinjam_model.dart';
import '../../../profil/presentation/screens/profil_screen.dart';
import '../../models/home_dashboard_model.dart';
import '../../providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(homeProvider.notifier).load());
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _loginAgain() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final data = state.data;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth >= 960
        ? (screenWidth - 920) / 2
        : 20.0;
    return Scaffold(
      appBar: const GelatikPageHeader(
        title: 'Beranda',
        actions: [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(homeProvider.notifier).refresh(),
          child: ListView(
            key: const Key('home-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            // ignore: deprecated_member_use
            cacheExtent: 2400,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              20,
              horizontalPadding,
              112,
            ),
            children: [
              _ServiceBanner(data: data),
              const SizedBox(height: 24),
              if (state.status == HomeLoadStatus.error)
                _FullErrorCard(
                  message: state.errorMessage ?? 'Data Home gagal dimuat.',
                  unauthorized: state.errorType == HomeErrorType.unauthorized,
                  onRetry: () => ref.read(homeProvider.notifier).retry(),
                  onLogin: _loginAgain,
                )
              else ...[
                _SummarySection(
                  state: state,
                  onItems: () => _open(const InfoAlatScreen()),
                  onBorrowings: () => _open(const PeminjamanListScreen()),
                  onConsultations: () => _open(const KonsultasiListScreen()),
                ),
                const SizedBox(height: 28),
                _QuickMenu(onOpen: _open),
                const SizedBox(height: 28),
                _RecentSection(
                  state: state,
                  onBorrowing: (item) =>
                      _open(PeminjamanDetailScreen(pinjam: item)),
                  onConsultation: (item) =>
                      _open(KonsultasiDetailScreen(konsultasi: item)),
                  onAllBorrowings: () => _open(const PeminjamanListScreen()),
                  onAllConsultations: () => _open(const KonsultasiListScreen()),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _open(const ChatbotNativeScreen()),
        backgroundColor: AppColors.accentNavy(context),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: Badge(
          smallSize: 10,
          backgroundColor: AppColors.accentGold(context),
          child: const Icon(Icons.chat_bubble_outline_rounded, size: 26),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        isAdmin: data.canAccessAdminPanel,
        onTap: (index) {
          if (index == 1) {
            _open(const AjukanPeminjamanScreen());
          } else if (index == 2) {
            _open(const ProfilScreen());
          } else if (index == 3 && data.canAccessAdminPanel) {
            _open(const AdminDashboardScreen());
          }
        },
      ),
    );
  }
}

class _ServiceBanner extends StatelessWidget {
  final HomeDashboardModel data;

  const _ServiceBanner({required this.data});

  @override
  Widget build(BuildContext context) {
    final primaryTeal = AppColors.primaryTeal(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3C7),
        border: Border.all(color: AppColors.cardStroke(context), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -24,
            child: Icon(
              Icons.tips_and_updates_outlined,
              size: 144,
              color: const Color(0xFFB28B18).withValues(alpha: .22),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentGold(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Layanan Gelatik',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Semua layanan TIK\ndalam satu aplikasi',
                style: TextStyle(
                  color: primaryTeal,
                  fontSize: 23,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Halo,',
                style: TextStyle(
                  color: Color(0xFF704C24),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              Text(
                data.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF704C24),
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Kelola kebutuhan TIK Anda dengan lebih mudah.',
                style: TextStyle(
                  color: Color(0xFF704C24),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.accentGold(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.accentNavy(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final HomeState state;
  final VoidCallback onItems;
  final VoidCallback onBorrowings;
  final VoidCallback onConsultations;

  const _SummarySection({
    required this.state,
    required this.onItems,
    required this.onBorrowings,
    required this.onConsultations,
  });

  @override
  Widget build(BuildContext context) {
    final loading = state.isLoading && !state.data.hasAnySectionData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan Layanan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                key: const Key('summary-items'),
                label: 'Aset Tersedia',
                value: state.data.availableItemCount,
                loading: loading,
                failed: state.sectionErrors.containsKey(HomeSection.items),
                icon: Icons.inventory_2_outlined,
                onTap: onItems,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                key: const Key('summary-borrowings'),
                label: 'Total Pinjam',
                value: state.data.totalBorrowingCount,
                loading: loading,
                failed: state.sectionErrors.containsKey(HomeSection.borrowings),
                icon: Icons.assignment_outlined,
                onTap: onBorrowings,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                key: const Key('summary-consultations'),
                label: 'Total Konsultasi',
                value: state.data.totalConsultationCount,
                loading: loading,
                failed: state.sectionErrors.containsKey(
                  HomeSection.consultations,
                ),
                icon: Icons.forum_outlined,
                onTap: onConsultations,
              ),
            ),
          ],
        ),
        if (state.hasPartialFailure) ...[
          const SizedBox(height: 8),
          const Text(
            'Sebagian ringkasan belum dapat diperbarui. Tarik ke bawah untuk mencoba lagi.',
            key: Key('home-partial-error'),
            style: TextStyle(fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int? value;
  final bool loading;
  final bool failed;
  final IconData icon;
  final VoidCallback onTap;

  const _SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.loading,
    required this.failed,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.all(10),
    child: Column(
      children: [
        Icon(icon, color: AppColors.primaryTeal(context)),
        const SizedBox(height: 6),
        if (loading)
          const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Text(
            failed && value == null ? '—' : '${value ?? 0}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    ),
  );
}

class _RecentSection extends StatelessWidget {
  final HomeState state;
  final ValueChanged<PinjamModel> onBorrowing;
  final ValueChanged<KonsultasiModel> onConsultation;
  final VoidCallback onAllBorrowings;
  final VoidCallback onAllConsultations;

  const _RecentSection({
    required this.state,
    required this.onBorrowing,
    required this.onConsultation,
    required this.onAllBorrowings,
    required this.onAllConsultations,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _RecentHeader(title: 'Peminjaman Terbaru', onAll: onAllBorrowings),
      if (state.sectionErrors.containsKey(HomeSection.borrowings) &&
          state.data.recentBorrowings.isEmpty)
        const _SectionError(message: 'Peminjaman terbaru gagal dimuat.')
      else if (state.data.recentBorrowings.isEmpty)
        const _EmptyRecent(message: 'Belum ada peminjaman.')
      else
        ...state.data.recentBorrowings.map(
          (item) => _RecentTile(
            title: item.namaPic,
            subtitle: 'Mulai ${_date(item.tanggalMulai)}',
            status: item.status,
            onTap: () => onBorrowing(item),
          ),
        ),
      const SizedBox(height: 16),
      _RecentHeader(title: 'Konsultasi Terbaru', onAll: onAllConsultations),
      if (state.sectionErrors.containsKey(HomeSection.consultations) &&
          state.data.recentConsultations.isEmpty)
        const _SectionError(message: 'Konsultasi terbaru gagal dimuat.')
      else if (state.data.recentConsultations.isEmpty)
        const _EmptyRecent(message: 'Belum ada konsultasi.')
      else
        ...state.data.recentConsultations.map(
          (item) => _RecentTile(
            title: item.judul,
            subtitle: item.topikNama,
            status: item.status,
            onTap: () => onConsultation(item),
          ),
        ),
    ],
  );

  static String _date(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';
}

class _RecentHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAll;

  const _RecentHeader({required this.title, required this.onAll});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      TextButton(onPressed: onAll, child: const Text('Lihat Semua')),
    ],
  );
}

class _RecentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final VoidCallback onTap;

  const _RecentTile({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: StatusBadge(status: status),
    ),
  );
}

class _EmptyRecent extends StatelessWidget {
  final String message;
  const _EmptyRecent({required this.message});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(message, style: TextStyle(color: AppColors.mutedText(context))),
  );
}

class _SectionError extends StatelessWidget {
  final String message;
  const _SectionError({required this.message});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(message, style: const TextStyle(color: Colors.red)),
  );
}

class _FullErrorCard extends StatelessWidget {
  final String message;
  final bool unauthorized;
  final VoidCallback onRetry;
  final VoidCallback onLogin;

  const _FullErrorCard({
    required this.message,
    required this.unauthorized,
    required this.onRetry,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        const Icon(Icons.cloud_off_rounded, size: 42),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('home-retry'),
          onPressed: unauthorized ? onLogin : onRetry,
          child: Text(unauthorized ? 'Masuk Ulang' : 'Coba Lagi'),
        ),
      ],
    ),
  );
}

class _QuickMenu extends StatelessWidget {
  final ValueChanged<Widget> onOpen;
  const _QuickMenu({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final items = <_MenuData>[
      _MenuData(
        'Pinjam Aset TIK',
        'Laptop, Proyektor, & Aksesoris',
        Icons.devices_rounded,
        AppColors.accentNavy(context),
        const AjukanPeminjamanScreen(),
      ),
      _MenuData(
        'Konsultasi TIK',
        'Tanya layanan TIK',
        Icons.support_agent_rounded,
        const Color(0xFF0284C7),
        const KonsultasiListScreen(),
      ),
      _MenuData(
        'Laporan Internet',
        'Internet & Router OPD',
        Icons.wifi_rounded,
        const Color(0xFFDC2626),
        const LayananInternetScreen(),
      ),
      _MenuData(
        'Email Dinas',
        'Usulan email resmi',
        Icons.mark_email_read_rounded,
        const Color(0xFF7E22CE),
        const UsulanEmailListScreen(),
      ),
      _MenuData(
        'Layanan Lain',
        'Katalog alat & layanan lain',
        Icons.apps_rounded,
        AppColors.primaryTeal(context),
        const InfoAlatScreen(),
      ),
      _MenuData(
        'Riwayat Pinjam',
        'Daftar & status',
        Icons.assignment_rounded,
        AppColors.actionEmerald(context),
        const PeminjamanListScreen(),
      ),
      _MenuData(
        'Kritik & Saran',
        'Evaluasi Layanan',
        Icons.rate_review_rounded,
        AppColors.accentNavy(context),
        const KritikSaranScreen(),
      ),
      _MenuData(
        'Asisten Gelatik',
        'Tanya AI layanan TIK',
        Icons.auto_awesome_rounded,
        AppColors.accentGold(context),
        const ChatbotNativeScreen(),
        'AI',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layanan Utama',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryTeal(context),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 760 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: crossAxisCount == 4 ? 1.08 : .84,
              children: items
                  .map(
                    (item) =>
                        _MenuCard(item: item, onTap: () => onOpen(item.screen)),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => onOpen(const SelfAssessmentScreen()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: Color(0xFF15803D),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bantuan & FAQ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Panduan penggunaan layanan',
                      style: TextStyle(fontSize: 12),
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
        ),
      ],
    );
  }
}

class _MenuData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;
  final String? badge;

  const _MenuData(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.screen, [
    this.badge,
  ]);
}

class _MenuCard extends StatelessWidget {
  final _MenuData item;
  final VoidCallback onTap;
  const _MenuCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 27),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTeal(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.mutedText(context),
                ),
              ),
            ],
          ),
        ),
        if (item.badge != null)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentGold(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.badge!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
