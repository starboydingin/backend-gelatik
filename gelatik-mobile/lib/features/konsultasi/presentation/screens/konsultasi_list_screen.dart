import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../profil/presentation/screens/profil_screen.dart';
import '../../../services/presentation/screens/services_screen.dart';
import '../../providers/konsultasi_provider.dart';
import 'konsultasi_discovery_screen.dart';
import 'konsultasi_detail_screen.dart';

class KonsultasiListScreen extends ConsumerStatefulWidget {
  const KonsultasiListScreen({super.key});

  @override
  ConsumerState<KonsultasiListScreen> createState() =>
      _KonsultasiListScreenState();
}

class _KonsultasiListScreenState extends ConsumerState<KonsultasiListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(konsultasiProvider.notifier).loadKonsultasi(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(konsultasiProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konsultasi TIK'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: const [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(child: _body(state)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isSubmitting
            ? null
            : () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const KonsultasiDiscoveryScreen(),
                  ),
                );
              },
        backgroundColor: AppColors.actionEmerald(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Buat Konsultasi'),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: (index) {
          final destination = switch (index) {
            0 => const HomeScreen(),
            2 => const NotificationsScreen(),
            3 => const ProfilScreen(),
            _ => const ServicesScreen(),
          };
          if (index != 1) {
            Navigator.of(
              context,
            ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
          }
        },
      ),
    );
  }

  Widget _body(KonsultasiState state) {
    if (state.status == KonsultasiLoadStatus.loading &&
        state.listKonsultasi.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == KonsultasiLoadStatus.error &&
        state.listKonsultasi.isEmpty) {
      return _ErrorView(
        message: state.errorMessage ?? 'Gagal memuat konsultasi.',
        onRetry: () => ref.read(konsultasiProvider.notifier).retry(),
      );
    }
    if (state.listKonsultasi.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(konsultasiProvider.notifier).refresh(),
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: 'Belum Ada Konsultasi',
                message: 'Konsultasi yang Anda ajukan akan tampil di sini.',
                icon: Icons.forum_outlined,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(konsultasiProvider.notifier).refresh(),
      child: ListView.builder(
        key: const Key('konsultasi-list'),
        padding: const EdgeInsets.all(16),
        itemCount: state.listKonsultasi.length,
        itemBuilder: (context, index) {
          final item = state.listKonsultasi[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => KonsultasiDetailScreen(konsultasi: item),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(item.topikNama)),
                      StatusBadge(status: item.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.judul,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.pesan,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.mutedText(context)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    GelatikDateFormatter.date(item.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    ),
  );
}
