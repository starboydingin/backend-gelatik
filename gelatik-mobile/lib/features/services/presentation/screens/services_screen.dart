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

  const ServicesScreen({super.key, this.autofocusSearch = false});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pusat Layanan TIK',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Temukan layanan, riwayat, dan bantuan dalam satu tempat.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedText(context),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _searchController,
                      autofocus: widget.autofocusSearch,
                      onChanged: (value) => setState(() => _query = value),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Cari layanan TIK',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Hapus pencarian',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ],
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: .9,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = services[index];
                    return AppCard(
                      onTap: () => _open(item.page),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: .11),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(item.icon, color: item.color),
                          ),
                          const Spacer(),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.mutedText(context)),
                          ),
                        ],
                      ),
                    );
                  }, childCount: services.length),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        isAdmin: canAccessAdmin,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (index == 2) {
            _open(const NotificationsScreen());
          } else if (index == 3) {
            _open(const ProfilScreen());
          } else if (index == 4 && canAccessAdmin) {
            _open(const AdminDashboardScreen());
          }
        },
      ),
    );
  }
}

class _ServiceItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;

  const _ServiceItem(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.page,
  );

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    return normalized.isEmpty ||
        title.toLowerCase().contains(normalized) ||
        subtitle.toLowerCase().contains(normalized);
  }
}

const _serviceItems = <_ServiceItem>[
  _ServiceItem(
    'Peminjaman Aset',
    'Ajukan dan pantau aset TIK',
    Icons.devices_outlined,
    AppColors.colorPrimary,
    PeminjamanListScreen(),
  ),
  _ServiceItem(
    'Konsultasi TIK',
    'Konsultasi dengan petugas',
    Icons.forum_outlined,
    AppColors.colorSecondary,
    KonsultasiListScreen(),
  ),
  _ServiceItem(
    'Email ASN',
    'Pengajuan email resmi dinas',
    Icons.alternate_email_rounded,
    AppColors.colorPrimary,
    UsulanEmailListScreen(),
  ),
  _ServiceItem(
    'Internet & Router',
    'Status dan laporan jaringan',
    Icons.router_outlined,
    AppColors.colorError,
    LayananInternetScreen(),
  ),
  _ServiceItem(
    'Informasi Perangkat',
    'Katalog aset dan perangkat',
    Icons.inventory_2_outlined,
    AppColors.colorSecondary,
    InfoAlatScreen(),
  ),
  _ServiceItem(
    'Asisten Gelatik',
    'Bantuan AI layanan TIK',
    Icons.auto_awesome_outlined,
    AppColors.colorAccent,
    ChatbotNativeScreen(),
  ),
  _ServiceItem(
    'Kritik & Saran',
    'Sampaikan evaluasi layanan',
    Icons.rate_review_outlined,
    AppColors.colorPrimary,
    KritikSaranScreen(),
  ),
  _ServiceItem(
    'Bantuan & FAQ',
    'Panduan dan diagnosis mandiri',
    Icons.help_outline_rounded,
    AppColors.colorSuccess,
    SelfAssessmentScreen(),
  ),
  _ServiceItem(
    'Agenda',
    'Jadwal dan kalender layanan',
    Icons.calendar_month_outlined,
    AppColors.colorSecondary,
    CalendarScreen(),
  ),
];
