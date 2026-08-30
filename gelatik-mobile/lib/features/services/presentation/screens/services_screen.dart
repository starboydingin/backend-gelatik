import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gelatik_page_header.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../calendar/presentation/screens/calendar_screen.dart';
import '../../../chatbot/presentation/screens/chatbot_native_screen.dart';
import '../../../email/presentation/screens/usulan_email_list_screen.dart';
import '../../../info_alat/presentation/screens/info_alat_screen.dart';
import '../../../internet/presentation/screens/layanan_internet_screen.dart';
import '../../../internet/presentation/screens/self_assessment_screen.dart';
import '../../../konsultasi/presentation/screens/konsultasi_list_screen.dart';
import '../../../kritik_saran/presentation/screens/kritik_saran_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../peminjaman/presentation/screens/peminjaman_list_screen.dart';
import '../../../profil/presentation/screens/profil_screen.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  final bool autofocusSearch;
  final bool embedded;

  const ServicesScreen({
    super.key,
    this.autofocusSearch = false,
    this.embedded = false,
  });

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _isOpeningService = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _open(WidgetBuilder builder) async {
    if (_isOpeningService || !mounted) return;
    _isOpeningService = true;
    try {
      await Navigator.of(context).push(MaterialPageRoute(builder: builder));
    } finally {
      _isOpeningService = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;
    final canAccessAdmin =
        user != null &&
        const {'admin', 'superadmin', 'bkd'}.contains(user.role.toLowerCase());
    final services = _serviceItems
        .where((item) => item.matches(_query))
        .toList(growable: false);

    return Scaffold(
      appBar: GelatikPageHeader(
        title: 'Layanan',
        actions: [
          IconButton(
            tooltip: 'Cari layanan',
            onPressed: () => FocusScope.of(context).requestFocus(),
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              sliver: SliverToBoxAdapter(
                child: _ServiceDirectoryHero(
                  controller: _searchController,
                  autofocus: widget.autofocusSearch,
                  query: _query,
                  onChanged: (value) => setState(() => _query = value),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
            ),
            if (services.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Layanan tidak ditemukan.')),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  widget.embedded ? 124 : 112,
                ),
                sliver: SliverList.separated(
                  itemCount: services.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _ServiceDirectoryItem(
                    item: services[index],
                    index: index,
                    onTap: () => _open(services[index].builder),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : AppBottomNav(
              currentIndex: 1,
              isAdmin: canAccessAdmin,
              onTap: (index) {
                if (index == 0) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                } else if (index == 2) {
                  _open((_) => const NotificationsScreen());
                } else if (index == 3) {
                  _open((_) => const ProfilScreen());
                } else if (index == 4 && canAccessAdmin) {
                  _open((_) => const AdminDashboardScreen());
                }
              },
            ),
    );
  }
}

class _ServiceDirectoryHero extends StatelessWidget {
  final TextEditingController controller;
  final bool autofocus;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _ServiceDirectoryHero({
    required this.controller,
    required this.autofocus,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
    decoration: BoxDecoration(
      color: AppColors.colorPrimary,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.colorAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: AppColors.colorTextPrimary,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DIREKTORI DIGITAL',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.colorAccent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Apa yang Anda butuhkan?',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          controller: controller,
          autofocus: autofocus,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Cari aset, konsultasi, email, atau bantuan',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
      ],
    ),
  );
}

class _ServiceDirectoryItem extends StatelessWidget {
  final _ServiceItem item;
  final int index;
  final VoidCallback onTap;

  const _ServiceDirectoryItem({
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: EdgeInsets.zero,
    elevation: 0,
    child: IntrinsicHeight(
      child: Row(
        children: [
          Container(
            width: 7,
            decoration: BoxDecoration(
              color: index == 0 ? AppColors.colorAccent : item.color,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(Icons.arrow_forward_rounded, size: 20),
          ),
        ],
      ),
    ),
  );
}

class _ServiceItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  const _ServiceItem(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.builder,
  );

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    return normalized.isEmpty ||
        title.toLowerCase().contains(normalized) ||
        subtitle.toLowerCase().contains(normalized);
  }
}

final _serviceItems = <_ServiceItem>[
  _ServiceItem(
    'Peminjaman Aset',
    'Ajukan dan pantau aset TIK',
    Icons.devices_outlined,
    AppColors.colorPrimary,
    (_) => const PeminjamanListScreen(),
  ),
  _ServiceItem(
    'Konsultasi TIK',
    'Konsultasi dengan petugas',
    Icons.forum_outlined,
    AppColors.colorSecondary,
    (_) => const KonsultasiListScreen(),
  ),
  _ServiceItem(
    'Email ASN',
    'Pengajuan email resmi dinas',
    Icons.alternate_email_rounded,
    AppColors.colorPrimary,
    (_) => const UsulanEmailListScreen(),
  ),
  _ServiceItem(
    'Internet & Router',
    'Status dan laporan jaringan',
    Icons.router_outlined,
    AppColors.colorError,
    (_) => const LayananInternetScreen(),
  ),
  _ServiceItem(
    'Informasi Perangkat',
    'Katalog aset dan perangkat',
    Icons.inventory_2_outlined,
    AppColors.colorSecondary,
    (_) => const InfoAlatScreen(),
  ),
  _ServiceItem(
    'Asisten Gelatik',
    'Bantuan AI layanan TIK',
    Icons.auto_awesome_outlined,
    AppColors.colorAccent,
    (_) => const ChatbotNativeScreen(),
  ),
  _ServiceItem(
    'Kritik & Saran',
    'Sampaikan evaluasi layanan',
    Icons.rate_review_outlined,
    AppColors.colorPrimary,
    (_) => const KritikSaranScreen(),
  ),
  _ServiceItem(
    'Bantuan & FAQ',
    'Panduan dan diagnosis mandiri',
    Icons.help_outline_rounded,
    AppColors.colorSuccess,
    (_) => const SelfAssessmentScreen(),
  ),
  _ServiceItem(
    'Agenda',
    'Jadwal dan kalender layanan',
    Icons.calendar_month_outlined,
    AppColors.colorSecondary,
    (_) => const CalendarScreen(),
  ),
];
