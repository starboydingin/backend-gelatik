import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/realtime_socket_service.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/gelatik_page_header.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../peminjaman/presentation/screens/ajukan_peminjaman_screen.dart';
import '../../../profil/presentation/screens/profil_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../services/presentation/screens/services_screen.dart';
import '../../models/master_item_model.dart';
import '../../repositories/master_item_repository.dart';
import 'package:gelatik/features/info_alat/providers/info_alat_provider.dart';

/// InfoAlatScreen — Layar Informasi Katalog Aset TIK Read-Only (M-H)
class InfoAlatScreen extends ConsumerStatefulWidget {
  const InfoAlatScreen({super.key});

  @override
  ConsumerState<InfoAlatScreen> createState() => _InfoAlatScreenState();
}

class _InfoAlatScreenState extends ConsumerState<InfoAlatScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(infoAlatProvider.notifier).loadItems();
    });
    _realtimeSubscription = ref
        .read(realtimeSocketServiceProvider)
        .events
        .where((event) => event.type == 'data.sync')
        .listen((_) => ref.read(infoAlatProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _realtimeSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _scheduleSearch(String value) {
    _searchDebounce?.cancel();
    setState(() {});
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(infoAlatProvider.notifier).searchItems(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final accentNavy = AppColors.accentNavy(context);
    final accentGold = AppColors.accentGold(context);
    final mutedText = AppColors.mutedText(context);

    final state = ref.watch(infoAlatProvider);

    return Scaffold(
      appBar: GelatikPageHeader(
        title: 'Pinjam Aset TIK',
        showBack: true,
        onBack: () => Navigator.of(context).maybePop(),
        actions: const [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search card sesuai pola daftar aset pada referensi.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: accentNavy),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _scheduleSearch,
                        decoration: const InputDecoration(
                          hintText: 'Cari aset...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _scheduleSearch('');
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentGold,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (state.isRefreshing) const LinearProgressIndicator(minHeight: 2),

            Expanded(
              child: _buildContent(
                context,
                state,
                primaryTeal,
                accentNavy,
                accentGold,
                mutedText,
                theme,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            color: theme.scaffoldBackgroundColor,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AjukanPeminjamanScreen(),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Ajukan Peminjaman'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.actionEmerald(context),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: const StadiumBorder(),
              ),
            ),
          ),
          AppBottomNav(
            currentIndex: 1,
            onTap: (index) {
              final destination = switch (index) {
                0 => const HomeScreen(),
                2 => const NotificationsScreen(),
                3 => const ProfilScreen(),
                _ => const ServicesScreen(),
              };
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => destination),
                (route) => route.isFirst,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    InfoAlatState state,
    Color primaryTeal,
    Color accentNavy,
    Color accentGold,
    Color mutedText,
    ThemeData theme,
  ) {
    if (state.status == InfoAlatStatus.initial ||
        state.status == InfoAlatStatus.loading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => const LoadingSkeleton.card(height: 92),
      );
    }

    if (state.status == InfoAlatStatus.error) {
      return _refreshableState(
        EmptyState(
          title: _errorTitle(state.errorType),
          message: state.errorMessage ?? 'Katalog alat gagal dimuat.',
          icon: _errorIcon(state.errorType),
          buttonText: 'Coba Lagi',
          onButtonPressed: () => ref.read(infoAlatProvider.notifier).retry(),
        ),
      );
    }

    if (state.status == InfoAlatStatus.empty) {
      return _refreshableState(
        EmptyState(
          title: state.query.isEmpty
              ? 'Belum Ada Aset TIK'
              : 'Aset TIK Tidak Ditemukan',
          message: state.query.isEmpty
              ? 'Katalog alat masih kosong. Tarik ke bawah untuk memuat ulang.'
              : 'Tidak ada alat yang cocok dengan pencarian "${state.query}".',
          icon: state.query.isEmpty
              ? Icons.inventory_2_outlined
              : Icons.search_off_rounded,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: ref.read(infoAlatProvider.notifier).refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: state.items.length,
        itemBuilder: (context, index) => _buildItemCard(
          context,
          state.items[index],
          index,
          primaryTeal,
          accentNavy,
          accentGold,
          mutedText,
          theme,
        ),
      ),
    );
  }

  Widget _refreshableState(Widget child) {
    return RefreshIndicator(
      onRefresh: ref.read(infoAlatProvider.notifier).refresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    MasterItemModel item,
    int index,
    Color primaryTeal,
    Color accentNavy,
    Color accentGold,
    Color mutedText,
    ThemeData theme,
  ) {
    final bgColors = [
      primaryTeal.withValues(alpha: 0.12),
      accentNavy.withValues(alpha: 0.15),
      accentGold.withValues(alpha: 0.15),
    ];
    final iconColors = [primaryTeal, accentNavy, accentGold];
    final bg = bgColors[index % bgColors.length];
    final fg = iconColors[index % iconColors.length];
    final foto = item.foto?.trim();
    final stockColor = item.tersedia ? primaryTeal : theme.colorScheme.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: foto != null && foto.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        foto,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Icon(Icons.devices_rounded, color: fg, size: 32),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: .12,
                          child: Image.asset(
                            'assets/images/logo-gelatik.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        Icon(_assetIcon(item.nama), color: fg, size: 34),
                      ],
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.nama,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: primaryTeal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildBadge(
                        item.tersedia ? 'Tersedia' : 'Stok Habis',
                        item.tersedia
                            ? AppColors.actionEmerald(context)
                            : theme.colorScheme.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.deskripsi.trim().isNotEmpty
                        ? item.deskripsi
                        : 'Deskripsi belum tersedia.',
                    style: TextStyle(
                      fontSize: 12,
                      color: mutedText,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildBadge(
                        'Kondisi: ${item.kondisi.trim().isNotEmpty ? item.kondisi : 'Tidak diketahui'}',
                        AppColors.actionEmerald(context),
                      ),
                      _buildBadge('Stok: ${item.stok} unit', stockColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  IconData _assetIcon(String name) {
    final value = name.toLowerCase();
    if (value.contains('laptop')) return Icons.laptop_mac_rounded;
    if (value.contains('proyektor') || value.contains('projector')) {
      return Icons.videocam_rounded;
    }
    if (value.contains('tablet') || value.contains('ipad')) {
      return Icons.tablet_mac_rounded;
    }
    if (value.contains('headset') || value.contains('headphone')) {
      return Icons.headphones_rounded;
    }
    return Icons.devices_rounded;
  }

  String _errorTitle(MasterItemErrorType? type) {
    return switch (type) {
      MasterItemErrorType.unauthorized => 'Sesi Berakhir',
      MasterItemErrorType.forbidden => 'Akses Ditolak',
      MasterItemErrorType.network ||
      MasterItemErrorType.timeout => 'Koneksi Bermasalah',
      _ => 'Katalog Gagal Dimuat',
    };
  }

  IconData _errorIcon(MasterItemErrorType? type) {
    return switch (type) {
      MasterItemErrorType.unauthorized => Icons.lock_clock_outlined,
      MasterItemErrorType.forbidden => Icons.block_rounded,
      MasterItemErrorType.network ||
      MasterItemErrorType.timeout => Icons.cloud_off_rounded,
      _ => Icons.error_outline_rounded,
    };
  }
}
