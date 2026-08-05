import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../providers/peminjaman_provider.dart';
import 'ajukan_peminjaman_screen.dart';
import 'peminjaman_detail_screen.dart';

/// PeminjamanListScreen — Layar Daftar Riwayat Pengajuan Peminjaman Aset TIK
class PeminjamanListScreen extends ConsumerStatefulWidget {
  const PeminjamanListScreen({super.key});

  @override
  ConsumerState<PeminjamanListScreen> createState() =>
      _PeminjamanListScreenState();
}

class _PeminjamanListScreenState extends ConsumerState<PeminjamanListScreen> {
  String _selectedStatusFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(peminjamanProvider.notifier).loadPeminjaman(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final actionEmerald = AppColors.actionEmerald(context);
    final mutedText = AppColors.mutedText(context);

    final state = ref.watch(peminjamanProvider);
    final allList = state.listPinjam;

    final filteredList = _selectedStatusFilter == 'Semua'
        ? allList
        : allList
              .where(
                (p) =>
                    p.status.toLowerCase() ==
                    _selectedStatusFilter.toLowerCase(),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Peminjaman Aset'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          },
        ),
        actions: const [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Filter Bar Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: ['Semua', 'Menunggu', 'Proses', 'Selesai', 'Ditolak']
                    .map((status) {
                      final isSelected = _selectedStatusFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(status),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                          selectedColor: primaryTeal,
                          backgroundColor: theme
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: isSelected
                                  ? primaryTeal
                                  : AppColors.cardStroke(context),
                              width: 1.5,
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatusFilter = status;
                            });
                          },
                        ),
                      );
                    })
                    .toList(),
              ),
            ),

            const Divider(height: 1),

            // List View Items
            Expanded(
              child: state.status == PeminjamanLoadStatus.loading
                  ? const Center(child: CircularProgressIndicator())
                  : state.status == PeminjamanLoadStatus.error
                  ? _PeminjamanErrorView(
                      message:
                          state.errorMessage ??
                          'Daftar peminjaman gagal dimuat.',
                      onRetry: () =>
                          ref.read(peminjamanProvider.notifier).retry(),
                    )
                  : filteredList.isEmpty
                  ? EmptyState(
                      title: 'Tidak Ada Data Peminjaman',
                      message: _selectedStatusFilter == 'Semua'
                          ? 'Belum ada transaksi peminjaman yang diajukan.'
                          : 'Tidak ada peminjaman dengan status "$_selectedStatusFilter".',
                      icon: Icons.assignment_outlined,
                      buttonText: 'Buat Pengajuan Baru',
                      onButtonPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AjukanPeminjamanScreen(),
                          ),
                        );
                      },
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(peminjamanProvider.notifier).refresh(),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final pinjam = filteredList[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: AppCard(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PeminjamanDetailScreen(pinjam: pinjam),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header: ID & Status Badge
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'TRX-${pinjam.id.toString().padLeft(4, '0')}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: primaryTeal,
                                        ),
                                      ),
                                      StatusBadge(status: pinjam.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Instansi PIC & Nama PIC
                                  Text(
                                    pinjam.instansiPic,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'PIC: ${pinjam.namaPic}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: mutedText,
                                    ),
                                  ),

                                  const SizedBox(height: 10),
                                  const Divider(height: 1),
                                  const SizedBox(height: 10),

                                  // Items List Brief
                                  Text(
                                    'Aset Dipinjam (${pinjam.items.length} jenis):',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: mutedText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...pinjam.items.map((itemDetail) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            size: 14,
                                            color: primaryTeal,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '${itemDetail.item?.nama ?? 'Aset TIK'} (${itemDetail.quantity} unit)',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),

                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_month_outlined,
                                            size: 14,
                                            color: mutedText,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${pinjam.tanggalMulai.day}/${pinjam.tanggalMulai.month}/${pinjam.tanggalMulai.year} (${pinjam.durasiPeminjaman} ${pinjam.jenisDurasi})',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: mutedText,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Detail >',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: primaryTeal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AjukanPeminjamanScreen()),
          );
        },
        backgroundColor: actionEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Ajukan Pinjam',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (index == 1) {
            // Already here / Ajukan
          } else if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        },
      ),
    );
  }
}

class _PeminjamanErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PeminjamanErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
