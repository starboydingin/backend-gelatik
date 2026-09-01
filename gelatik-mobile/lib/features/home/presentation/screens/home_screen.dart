import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/bento_block.dart';
import '../../../../core/widgets/bento_dashboard_grid.dart';
import '../../../../core/widgets/notification_badge_button.dart';
import '../../../../core/widgets/personal_greeting.dart';
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
import '../../../internet/providers/internet_provider.dart';
import '../../../konsultasi/presentation/screens/konsultasi_detail_screen.dart';
import '../../../konsultasi/presentation/screens/konsultasi_list_screen.dart';
import '../../../konsultasi/models/konsultasi_model.dart';
import '../../../kritik_saran/presentation/screens/kritik_saran_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../peminjaman/presentation/screens/peminjaman_detail_screen.dart';
import '../../../peminjaman/presentation/screens/peminjaman_list_screen.dart';
import '../../../peminjaman/models/pinjam_model.dart';
import '../../../profil/presentation/screens/profil_screen.dart';
import '../../../services/presentation/screens/services_screen.dart';
import '../../models/home_dashboard_model.dart';
import '../../providers/home_provider.dart';
import '../../repositories/announcement_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const HomeScreen({super.key, this.embedded = false});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await Future.wait([
        ref.read(homeProvider.notifier).load(),
        ref.read(internetProvider.notifier).loadRouters(),
      ]);
    });
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
    final internetState = ref.watch(internetProvider);
    final data = state.data;
    // `/pengumuman` is the authoritative, independent source for the banner.
    // The dashboard response is cached for fast navigation, so use its value
    // only while the active-announcement request is still loading or fails.
    final activeAnnouncements = ref.watch(activeAnnouncementsProvider);
    final announcements = activeAnnouncements.when(
      data: (items) => items,
      loading: () => data.announcements,
      error: (_, _) => data.announcements,
    );
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth >= 960
        ? (screenWidth - 920) / 2
        : 20.0;
    final content = <Widget>[
      if (state.status == HomeLoadStatus.error) ...[
        // There is no bandwidth block in the full-error layout, so keep an
        // independently loaded announcement visible above the error card.
        if (announcements.isNotEmpty) ...[
          _AnnouncementCarousel(announcements: announcements),
          const SizedBox(height: 20),
        ],
        _FullErrorCard(
          message: state.errorMessage ?? 'Data Home gagal dimuat.',
          unauthorized: state.errorType == HomeErrorType.unauthorized,
          onRetry: () => ref.read(homeProvider.notifier).retry(),
          onLogin: _loginAgain,
        ),
      ] else ...[
        _BentoOverview(
          state: state,
          announcements: announcements,
          bandwidth: internetState.bandwidthInfo,
          bandwidthLoading: internetState.isLoading,
          bandwidthError: internetState.errorMessage,
          onBorrowings: () => _open(const PeminjamanListScreen()),
          onConsultations: () => _open(const KonsultasiListScreen()),
          onEmails: () => _open(const UsulanEmailListScreen()),
          onNotifications: () => _open(const NotificationsScreen()),
          onInternet: () => _open(const LayananInternetScreen()),
          onCriticism: () => _open(const KritikSaranScreen()),
        ),
        const SizedBox(height: 28),
        _QuickMenu(onOpen: _open),
        const SizedBox(height: 16),
        _RecentSection(
          state: state,
          onBorrowing: (item) => _open(PeminjamanDetailScreen(pinjam: item)),
          onConsultation: (item) =>
              _open(KonsultasiDetailScreen(konsultasi: item)),
          onEmail: (item) => _open(UsulanEmailDetailScreen(usulan: item)),
          onAllBorrowings: () => _open(const PeminjamanListScreen()),
          onAllConsultations: () => _open(const KonsultasiListScreen()),
          onAllEmails: () => _open(const UsulanEmailListScreen()),
        ),
        const SizedBox(height: 28),
        _ServiceInsightsSection(data: data),
      ],
    ];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeAnnouncementsProvider);
          await ref.read(homeProvider.notifier).refresh();
        },
        child: CustomScrollView(
          key: const Key('home-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          scrollCacheExtent: const ScrollCacheExtent.pixels(480),
          slivers: [
            _DashboardSliverHeader(
              data: data,
              onSearch: () =>
                  _open(const ServicesScreen(autofocusSearch: true)),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                widget.embedded ? 88 : 20,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed(content),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.embedded
          ? null
          : FloatingActionButton(
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
      bottomNavigationBar: widget.embedded
          ? null
          : AppBottomNav(
              currentIndex: 0,
              isAdmin: data.canAccessAdminPanel,
              onTap: (index) {
                if (index == 1) {
                  _open(const ServicesScreen());
                } else if (index == 2) {
                  _open(const NotificationsScreen());
                } else if (index == 3) {
                  _open(const ProfilScreen());
                } else if (index == 4 && data.canAccessAdminPanel) {
                  _open(const AdminDashboardScreen());
                }
              },
            ),
    );
  }
}

class _DashboardSliverHeader extends StatelessWidget {
  final HomeDashboardModel data;
  final VoidCallback onSearch;

  const _DashboardSliverHeader({required this.data, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      toolbarHeight: 76,
      backgroundColor: AppColors.colorPrimary,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: const Text(
        'Beranda',
        style: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Cari layanan',
          onPressed: onSearch,
          icon: const Icon(Icons.search_rounded),
        ),
        NotificationBadgeButton(
          initialUnread: data.unreadNotificationCount ?? 0,
        ),
        const SizedBox(width: 8),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(4),
        child: ColoredBox(
          color: AppColors.colorAccent,
          child: SizedBox(height: 4, width: double.infinity),
        ),
      ),
    );
  }
}

class _BentoOverview extends StatelessWidget {
  final HomeState state;
  final List<Announcement> announcements;
  final Map<String, dynamic> bandwidth;
  final bool bandwidthLoading;
  final String? bandwidthError;
  final VoidCallback onBorrowings;
  final VoidCallback onConsultations;
  final VoidCallback onEmails;
  final VoidCallback onNotifications;
  final VoidCallback onInternet;
  final VoidCallback onCriticism;

  const _BentoOverview({
    required this.state,
    required this.announcements,
    required this.bandwidth,
    required this.bandwidthLoading,
    required this.bandwidthError,
    required this.onBorrowings,
    required this.onConsultations,
    required this.onEmails,
    required this.onNotifications,
    required this.onInternet,
    required this.onCriticism,
  });

  @override
  Widget build(BuildContext context) {
    final data = state.data;
    final organization = data.namaOpd?.trim().isNotEmpty == true
        ? data.namaOpd!
        : 'Pemerintah Provinsi Lampung';
    final loading = state.isLoading && !data.hasAnySectionData;
    final bandwidthAvailable = bandwidth['available'] == true;
    final download = bandwidth['download_mbps']?.toString() ?? '-';
    final upload = bandwidth['upload_mbps']?.toString() ?? '-';
    final userBandwidth = bandwidth['user'] is Map
        ? Map<String, dynamic>.from(bandwidth['user'] as Map)
        : const <String, dynamic>{};
    final userBandwidthAvailable = userBandwidth['available'] == true;
    final userBandwidthDetected = userBandwidth['detected'] == true;
    final userDownload = userBandwidth['download_mbps']?.toString() ?? '-';
    final userUpload = userBandwidth['upload_mbps']?.toString() ?? '-';
    final userBandwidthSource =
        userBandwidth['source_label']?.toString() ??
        'Belum ada sumber bandwidth';
    final recent = data.recentBorrowings.isNotEmpty
        ? ('Peminjaman', data.recentBorrowings.first.status)
        : data.recentConsultations.isNotEmpty
        ? ('Konsultasi', data.recentConsultations.first.status)
        : data.recentEmailRequests.isNotEmpty
        ? ('Usulan email', data.recentEmailRequests.first.status)
        : null;

    return BentoDashboardGrid(
      items: [
        BentoDashboardItem(
          span: 2,
          child: BentoBlock(
            tone: BentoBlockTone.navy,
            minHeight: 148,
            child: PersonalGreeting(
              name: data.userName,
              organization: organization,
            ),
          ),
        ),
        if (announcements.isNotEmpty)
          BentoDashboardItem(
            span: 2,
            child: _AnnouncementCarousel(announcements: announcements),
          ),
        BentoDashboardItem(
          span: 2,
          child: BentoBlock(
            key: const Key('bandwidth-traffic-block'),
            tone: BentoBlockTone.teal,
            onTap: onInternet,
            semanticLabel: 'Informasi bandwidth OPD',
            child: _OpdTrafficBlock(
              available: bandwidthAvailable,
              loading: bandwidthLoading,
              download: download,
              upload: upload,
              source:
                  '${bandwidth['opd'] ?? organization} • ${bandwidth['connection_name'] ?? 'Router OPD'}',
              hasError: bandwidthError != null,
            ),
          ),
        ),
        BentoDashboardItem(
          child: BentoBlock(
            tone: BentoBlockTone.gold,
            minHeight: 154,
            child: _UserBandwidthBlock(
              available: userBandwidthAvailable,
              detected: userBandwidthDetected,
              loading: bandwidthLoading,
              download: userDownload,
              upload: userUpload,
              source: userBandwidthSource,
            ),
          ),
        ),
        BentoDashboardItem(
          child: BentoBlock(
            minHeight: 154,
            child: _LatestStatusBlock(recent: recent),
          ),
        ),
        BentoDashboardItem(
          child: _BentoMetricBlock(
            key: const Key('summary-borrowings'),
            label: 'Peminjaman aktif',
            value: data.activeBorrowingCount ?? data.totalBorrowingCount,
            loading: loading,
            icon: Icons.inventory_2_outlined,
            tone: BentoBlockTone.gold,
            onTap: onBorrowings,
          ),
        ),
        BentoDashboardItem(
          child: _BentoMetricBlock(
            key: const Key('summary-consultations'),
            label: 'Konsultasi aktif',
            value: data.activeConsultationCount ?? data.totalConsultationCount,
            loading: loading,
            icon: Icons.forum_outlined,
            tone: BentoBlockTone.teal,
            onTap: onConsultations,
          ),
        ),
        BentoDashboardItem(
          child: _BentoMetricBlock(
            key: const Key('summary-email'),
            label: 'Usulan email',
            value: data.emailRequestCount,
            loading: loading,
            icon: Icons.alternate_email_rounded,
            tone: BentoBlockTone.navy,
            onTap: onEmails,
          ),
        ),
        BentoDashboardItem(
          child: _BentoMetricBlock(
            key: const Key('summary-notifications'),
            label: 'Notifikasi baru',
            value: data.unreadNotificationCount,
            loading: loading,
            icon: Icons.notifications_none_rounded,
            tone: BentoBlockTone.white,
            onTap: onNotifications,
          ),
        ),
        BentoDashboardItem(
          span: 2,
          child: BentoBlock(
            onTap: onCriticism,
            semanticLabel: 'Kualitas layanan dan kritik saran',
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3C7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppColors.colorAccent,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kualitas layanan',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        data.serviceRatingCount == 0
                            ? 'Belum ada penilaian pengguna'
                            : '${data.serviceRatingAverage.toStringAsFixed(1)}/5 dari ${data.serviceRatingCount} penilaian',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ),
        if (state.hasPartialFailure)
          const BentoDashboardItem(
            span: 2,
            child: Text(
              'Sebagian ringkasan belum dapat diperbarui. Tarik ke bawah untuk mencoba lagi.',
              key: Key('home-partial-error'),
              style: TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _OpdTrafficBlock extends StatelessWidget {
  final bool available;
  final bool loading;
  final String download;
  final String upload;
  final String source;
  final bool hasError;

  const _OpdTrafficBlock({
    required this.available,
    required this.loading,
    required this.download,
    required this.upload,
    required this.source,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Icon(Icons.monitor_heart_outlined, size: 27),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Trafik bandwidth OPD',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
          Icon(Icons.arrow_forward_rounded, size: 20),
        ],
      ),
      const SizedBox(height: 18),
      if (loading)
        const LinearProgressIndicator(
          minHeight: 5,
          color: Colors.white,
          backgroundColor: Colors.white24,
        )
      else
        Row(
          children: [
            Expanded(
              child: _BandwidthValue(
                label: 'DOWNLOAD',
                value: available ? download : '-',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BandwidthValue(
                label: 'UPLOAD',
                value: available ? upload : '-',
              ),
            ),
          ],
        ),
      const SizedBox(height: 12),
      Text(
        hasError
            ? 'Data belum dapat diperbarui. Ketuk untuk mencoba kembali.'
            : available
            ? source
            : 'Data kapasitas router OPD belum tersedia.',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: Colors.white70),
      ),
    ],
  );
}

class _BandwidthValue extends StatelessWidget {
  final String label;
  final String value;

  const _BandwidthValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            letterSpacing: .8,
            color: Colors.white70,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$value Mbps',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _UserBandwidthBlock extends StatelessWidget {
  final bool available;
  final bool detected;
  final bool loading;
  final String download;
  final String upload;
  final String source;

  const _UserBandwidthBlock({
    required this.available,
    required this.detected,
    required this.loading,
    required this.download,
    required this.upload,
    required this.source,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.speed_rounded, size: 25),
          const Spacer(),
          if (detected && !loading)
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Color(0xFF16A34A),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      const SizedBox(height: 18),
      const Text(
        'Bandwidth saya',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      if (loading)
        const Text(
          'Mendeteksi koneksi...',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        )
      else if (available)
        Text(
          '↓ $download Mbps\n↑ $upload Mbps',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        )
      else
        const Text('Belum terdeteksi', style: TextStyle(fontSize: 12)),
      const SizedBox(height: 8),
      Text(
        source,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 9.5, color: Color(0xB3111827)),
      ),
    ],
  );
}

class _LatestStatusBlock extends StatelessWidget {
  final (String, String)? recent;

  const _LatestStatusBlock({required this.recent});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.track_changes_rounded, color: AppColors.colorPrimary),
      const SizedBox(height: 24),
      const Text(
        'Status terbaru',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 5),
      if (recent == null)
        Text(
          'Belum ada aktivitas',
          style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
        )
      else ...[
        Text(recent!.$1, style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 3),
        StatusBadge(status: recent!.$2),
      ],
    ],
  );
}

class _BentoMetricBlock extends StatelessWidget {
  final String label;
  final int? value;
  final bool loading;
  final IconData icon;
  final BentoBlockTone tone;
  final VoidCallback onTap;

  const _BentoMetricBlock({
    super.key,
    required this.label,
    required this.value,
    required this.loading,
    required this.icon,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => BentoBlock(
    tone: tone,
    minHeight: 136,
    onTap: onTap,
    semanticLabel: label,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 26),
        const SizedBox(height: 24),
        if (loading)
          const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Text(
            '${value ?? 0}',
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
          ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _AnnouncementCarousel extends StatefulWidget {
  final List<Announcement> announcements;

  const _AnnouncementCarousel({required this.announcements});

  @override
  State<_AnnouncementCarousel> createState() => _AnnouncementCarouselState();
}

class _AnnouncementCarouselState extends State<_AnnouncementCarousel> {
  static const _slideInterval = Duration(seconds: 5);
  static const _slideDuration = Duration(milliseconds: 420);

  final PageController _controller = PageController();
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _startAutoplay();
  }

  @override
  void didUpdateWidget(covariant _AnnouncementCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage >= widget.announcements.length) {
      _currentPage = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(0);
      });
    }
    _startAutoplay();
  }

  void _startAutoplay() {
    _timer?.cancel();
    if (widget.announcements.length < 2) return;
    _timer = Timer.periodic(_slideInterval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final nextPage = (_currentPage + 1) % widget.announcements.length;
      _controller.animateToPage(
        nextPage,
        duration: _slideDuration,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _pageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _restartAutoplayAfterInteraction() => _startAutoplay();

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 132,
        child: NotificationListener<ScrollEndNotification>(
          onNotification: (notification) {
            if (notification.dragDetails != null) {
              _restartAutoplayAfterInteraction();
            }
            return false;
          },
          child: PageView.builder(
            key: const Key('announcement-carousel'),
            controller: _controller,
            itemCount: widget.announcements.length,
            onPageChanged: _pageChanged,
            itemBuilder: (context, index) => _AnnouncementBanner(
              announcement: widget.announcements[index],
              position: index + 1,
              total: widget.announcements.length,
            ),
          ),
        ),
      ),
      if (widget.announcements.length > 1) ...[
        const SizedBox(height: 9),
        Semantics(
          label:
              'Pengumuman ${_currentPage + 1} dari ${widget.announcements.length}',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.announcements.length, (index) {
              final selected = index == _currentPage;
              return AnimatedContainer(
                key: Key('announcement-indicator-$index'),
                duration: const Duration(milliseconds: 220),
                width: selected ? 22 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.accentNavy(context)
                      : AppColors.cardStroke(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ),
      ],
    ],
  );
}

class _AnnouncementBanner extends StatelessWidget {
  final Announcement announcement;
  final int position;
  final int total;

  const _AnnouncementBanner({
    required this.announcement,
    required this.position,
    required this.total,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 1),
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
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pengumuman terbaru',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (total > 1)
                    Text(
                      '$position/$total',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
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

// Kept as a compatibility layout for focused widget consumers outside Home.
// ignore: unused_element
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
              // Two-column cards need enough vertical room for the icon,
              // value, and a two-line label on 320 px devices.
              childAspectRatio: columns == 4 ? 1.55 : 1.2,
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
          'Infografis Layanan',
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
  // Nullable untuk menjaga dashboard tetap aman bila state lama hasil hot
  // reload belum memiliki statistik rating dari endpoint dashboard.
  final Map<int, int>? distribution;

  const _RatingInsightCard({
    required this.average,
    required this.count,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    final ratingDistribution = distribution ?? const <int, int>{};

    return AppCard(
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
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 300;
              final scoreWidth = compact
                  ? constraints.maxWidth
                  : constraints.maxWidth - 140;
              return Wrap(
                spacing: 12,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(
                    width: scoreWidth,
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
                    width: compact ? constraints.maxWidth : 128,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentNavy(
                        context,
                      ).withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(12),
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
              );
            },
          ),
          const SizedBox(height: 22),
          ...List.generate(5, (index) {
            final score = 5 - index;
            final votes = ratingDistribution[score] ?? 0;
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
        'Laporan Internet',
        Icons.wifi_rounded,
        const Color(0xFFDC2626),
        const LayananInternetScreen(),
      ),
      _MenuData(
        'Info Aset',
        Icons.apps_rounded,
        AppColors.primaryTeal(context),
        const InfoAlatScreen(),
      ),
      _MenuData(
        'Agenda',
        Icons.calendar_month_outlined,
        AppColors.primaryTeal(context),
        const CalendarScreen(),
      ),
      _MenuData(
        'Asisten Gelatik',
        Icons.auto_awesome_rounded,
        AppColors.accentGold(context),
        const ChatbotNativeScreen(),
      ),
      _MenuData(
        'Bantuan & FAQ',
        Icons.help_outline_rounded,
        const Color(0xFF16A34A),
        const SelfAssessmentScreen(),
      ),
      _MenuData(
        'Semua Layanan',
        Icons.grid_view_rounded,
        AppColors.accentNavy(context),
        const ServicesScreen(),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Akses cepat lainnya',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Fitur pendukung tanpa mengulang ringkasan di atas',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText(context),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.bolt_rounded, color: AppColors.colorAccent),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            final columnCount = wide ? 3 : 2;
            const spacing = 10.0;
            final cardWidth =
                (constraints.maxWidth - (spacing * (columnCount - 1))) /
                columnCount;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: items.map((item) {
                return SizedBox(
                  width: cardWidth,
                  height: wide ? 72 : 94,
                  child: _CompactActionCard(
                    item: item,
                    onTap: () => onOpen(item.screen),
                  ),
                );
              }).toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _CompactActionCard extends StatelessWidget {
  final _MenuData item;
  final VoidCallback onTap;

  const _CompactActionCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    elevation: 0,
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(item.icon, color: item.color, size: 19),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _MenuData {
  final String title;
  final IconData icon;
  final Color color;
  final Widget screen;

  const _MenuData(this.title, this.icon, this.color, this.screen);
}
