import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gelatik_page_header.dart';
import '../../../../core/widgets/notification_badge_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../chatbot/presentation/screens/chatbot_native_screen.dart';
import '../../../calendar/presentation/screens/calendar_screen.dart';
import '../../../email/models/usulan_email_model.dart';
import '../../../email/presentation/screens/usulan_email_detail_screen.dart';
import '../../../email/presentation/screens/usulan_email_list_screen.dart';
import '../../../info_alat/presentation/screens/info_alat_screen.dart';
import '../../../internet/presentation/screens/layanan_internet_screen.dart';
import '../../../internet/presentation/screens/self_assessment_screen.dart';
import '../../../konsultasi/presentation/screens/konsultasi_detail_screen.dart';
import '../../../konsultasi/presentation/screens/konsultasi_list_screen.dart';
import '../../../konsultasi/models/konsultasi_model.dart';
import '../../../kritik_saran/presentation/screens/kritik_saran_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../peminjaman/presentation/screens/ajukan_peminjaman_screen.dart';
import '../../../peminjaman/presentation/screens/peminjaman_detail_screen.dart';
import '../../../peminjaman/presentation/screens/peminjaman_list_screen.dart';
import '../../../peminjaman/models/pinjam_model.dart';
import '../../../profil/presentation/screens/profil_screen.dart';
import '../../models/home_dashboard_model.dart';
import '../../providers/home_provider.dart';
import '../../repositories/announcement_repository.dart';

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
    final announcement = data.announcements.firstOrNull;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth >= 960
        ? (screenWidth - 920) / 2
        : 20.0;
    return Scaffold(
      appBar: GelatikPageHeader(
        title: 'Beranda',
        actions: [const NotificationBadgeButton(), const SizedBox(width: 8)],
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
              // The Gelatik service banner remains the page's primary entry.
              // Announcements follow it so they do not push the brand message
              // above the main service context.
              _ServiceBanner(data: data),
              const SizedBox(height: 14),
              if (announcement != null) ...[
                _AnnouncementBanner(announcement: announcement),
                const SizedBox(height: 24),
              ],
              if (announcement == null) const SizedBox(height: 10),
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
                  onBorrowings: () => _open(const PeminjamanListScreen()),
                  onConsultations: () => _open(const KonsultasiListScreen()),
                  onEmails: () => _open(const UsulanEmailListScreen()),
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
                  onEmail: (item) =>
                      _open(UsulanEmailDetailScreen(usulan: item)),
                  onAllBorrowings: () => _open(const PeminjamanListScreen()),
                  onAllConsultations: () => _open(const KonsultasiListScreen()),
                  onAllEmails: () => _open(const UsulanEmailListScreen()),
                ),
                const SizedBox(height: 28),
                _ServiceInsightsSection(data: data),
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

class _AnnouncementBanner extends StatelessWidget {
  final Announcement announcement;
  const _AnnouncementBanner({required this.announcement});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3C7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardStroke(context), width: 1.5),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.campaign_outlined, color: AppColors.accentGold(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pengumuman terbaru',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                announcement.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.primaryTeal(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (announcement.content.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  announcement.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
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
  final VoidCallback onBorrowings;
  final VoidCallback onConsultations;
  final VoidCallback onEmails;

  const _SummarySection({
    required this.state,
    required this.onBorrowings,
    required this.onConsultations,
    required this.onEmails,
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
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: columns == 4 ? 1.55 : 1.42,
              children: [
                _SummaryCard(
                  key: const Key('summary-borrowings'),
                  label: 'Peminjaman aktif',
                  value:
                      state.data.activeBorrowingCount ??
                      state.data.totalBorrowingCount,
                  loading: loading,
                  failed: state.sectionErrors.containsKey(
                    HomeSection.borrowings,
                  ),
                  icon: Icons.assignment_outlined,
                  onTap: onBorrowings,
                ),
                _SummaryCard(
                  key: const Key('summary-consultations'),
                  label: 'Konsultasi aktif',
                  value:
                      state.data.activeConsultationCount ??
                      state.data.totalConsultationCount,
                  loading: loading,
                  failed: state.sectionErrors.containsKey(
                    HomeSection.consultations,
                  ),
                  icon: Icons.forum_outlined,
                  onTap: onConsultations,
                ),
                _SummaryCard(
                  key: const Key('summary-email'),
                  label: 'Usulan email',
                  value: state.data.emailRequestCount,
                  loading: loading,
                  failed: state.sectionErrors.containsKey(
                    HomeSection.dashboard,
                  ),
                  icon: Icons.mark_email_unread_outlined,
                  onTap: onEmails,
                ),
                _SummaryCard(
                  key: const Key('summary-notifications'),
                  label: 'Notifikasi baru',
                  value: state.data.unreadNotificationCount,
                  loading: loading,
                  failed: state.sectionErrors.containsKey(
                    HomeSection.dashboard,
                  ),
                  icon: Icons.notifications_none_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                ),
              ],
            );
          },
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
  final ValueChanged<UsulanEmailModel> onEmail;
  final VoidCallback onAllBorrowings;
  final VoidCallback onAllConsultations;
  final VoidCallback onAllEmails;

  const _RecentSection({
    required this.state,
    required this.onBorrowing,
    required this.onConsultation,
    required this.onEmail,
    required this.onAllBorrowings,
    required this.onAllConsultations,
    required this.onAllEmails,
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
      const SizedBox(height: 16),
      _RecentHeader(title: 'Usulan Email Terbaru', onAll: onAllEmails),
      if (state.sectionErrors.containsKey(HomeSection.dashboard) &&
          state.data.recentEmailRequests.isEmpty)
        const _SectionError(message: 'Usulan email terbaru gagal dimuat.')
      else if (state.data.recentEmailRequests.isEmpty)
        const _EmptyRecent(message: 'Belum ada usulan email.')
      else
        ...state.data.recentEmailRequests.map(
          (item) => _RecentTile(
            title: item.pegawai == null ? item.emailPribadi : item.namaPegawai,
            subtitle: item.emailResmi?.isNotEmpty == true
                ? item.emailResmi!
                : 'Menunggu pemrosesan email resmi',
            status: item.status,
            onTap: () => onEmail(item),
          ),
        ),
    ],
  );

  static String _date(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';
}

/// Compact, anonymous service insights. These match the website dashboard
/// data without exposing another user's transaction details on mobile.
class _ServiceInsightsSection extends StatelessWidget {
  final HomeDashboardModel data;

  const _ServiceInsightsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final points = data.serviceActivity.length > 7
        ? data.serviceActivity.sublist(data.serviceActivity.length - 7)
        : data.serviceActivity;
    final maximum = points.fold<int>(1, (value, point) {
      return point.total > value ? point.total : value;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Insight Layanan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aktivitas layanan 7 hari terakhir',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Ringkasan seluruh pengguna tanpa menampilkan data pribadi.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedText(context),
                ),
              ),
              const SizedBox(height: 18),
              if (points.isEmpty)
                const _EmptyRecent(message: 'Aktivitas layanan belum tersedia.')
              else
                SizedBox(
                  height: 118,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: points
                        .map(
                          (point) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        width: double.infinity,
                                        constraints: const BoxConstraints(
                                          minHeight: 4,
                                        ),
                                        height: 74 * point.total / maximum,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryTeal(context),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    point.date.length >= 10
                                        ? point.date.substring(8, 10)
                                        : '–',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.mutedText(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final cards = [
              _UsageCard(
                title: 'Topik konsultasi',
                icon: Icons.forum_outlined,
                data: data.consultationTopics,
                emptyText: 'Belum ada topik.',
              ),
              _UsageCard(
                title: 'Aset populer',
                icon: Icons.devices_other_outlined,
                data: data.assetUsage,
                emptyText: 'Belum ada aset dipinjam.',
              ),
            ];
            final usageCards = isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: cards
                        .map(
                          (card) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: card,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  )
                : Column(
                    children: cards
                        .map(
                          (card) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: card,
                          ),
                        )
                        .toList(growable: false),
                  );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                usageCards,
                const SizedBox(height: 12),
                _RatingInsightCard(
                  average: data.serviceRatingAverage,
                  count: data.serviceRatingCount,
                  distribution: data.serviceRatingDistribution,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _UsageCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<ServiceUsageMetric> data;
  final String emptyText;

  const _UsageCard({
    required this.title,
    required this.icon,
    required this.data,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryTeal(context)),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (data.isEmpty)
          Text(emptyText, style: TextStyle(color: AppColors.mutedText(context)))
        else
          ...data
              .take(3)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.total}',
                        style: TextStyle(
                          color: AppColors.accentNavy(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    ),
  );
}

class _RatingInsightCard extends StatelessWidget {
  final double average;
  final int count;
  final Map<int, int> distribution;

  const _RatingInsightCard({
    required this.average,
    required this.count,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KUALITAS LAYANAN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppColors.primaryTeal(context),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Rating pengguna',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        average.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 52,
                          height: .9,
                          color: AppColors.accentNavy(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 3, bottom: 4),
                        child: Text(
                          '/5',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _RatingStars(value: average),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 122),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.accentNavy(context).withValues(alpha: .08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 23,
                      color: AppColors.accentNavy(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'penilaian pengguna',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.accentNavy(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        ...List.generate(5, (index) {
          final score = 5 - index;
          final votes = distribution[score] ?? 0;
          final percentage = count == 0 ? 0.0 : votes / count;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(width: 76, child: Text('$score bintang')),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 12,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.accentGold(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 20,
                  child: Text('$votes', textAlign: TextAlign.right),
                ),
              ],
            ),
          );
        }),
      ],
    ),
  );
}

class _RatingStars extends StatelessWidget {
  final double value;

  const _RatingStars({required this.value});

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(5, (index) {
      final fill = (value - index).clamp(0.0, 1.0).toDouble();
      return SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFE2E8F0), size: 28),
            ClipRect(
              child: Align(
                widthFactor: fill,
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.star_rounded,
                  color: AppColors.accentGold(context),
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      );
    }),
  );
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
        'Agenda',
        'Jadwal layanan Anda',
        Icons.calendar_month_outlined,
        AppColors.primaryTeal(context),
        const CalendarScreen(),
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
      _MenuData(
        'Bantuan & FAQ',
        'Panduan layanan TIK',
        Icons.help_outline_rounded,
        const Color(0xFF16A34A),
        const SelfAssessmentScreen(),
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
    child: Container(
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(12),
      ),
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
    ),
  );
}
