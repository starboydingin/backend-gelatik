import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../peminjaman/providers/peminjaman_provider.dart';
import 'admin_peminjaman_detail_screen.dart';

/// AdminPeminjamanListScreen — Daftar Semua Pengajuan Peminjaman untuk Admin (M-L)
class AdminPeminjamanListScreen extends ConsumerStatefulWidget {
  const AdminPeminjamanListScreen({super.key});

  @override
  ConsumerState<AdminPeminjamanListScreen> createState() =>
      _AdminPeminjamanListScreenState();
}

class _AdminPeminjamanListScreenState
    extends ConsumerState<AdminPeminjamanListScreen> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = const [
    'Semua',
    'Menunggu',
    'Proses',
    'Selesai',
    'Ditolak',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final strokeColor = AppColors.cardStroke(context);
    final mutedText = AppColors.mutedText(context);

    final state = ref.watch(peminjamanProvider);
    final listPinjam = state.listPinjam;

    final filteredList = _selectedFilter == 'Semua'
        ? listPinjam
        : listPinjam.where((p) => p.status == _selectedFilter).toList();

    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Kelola Peminjaman',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryTeal,
          ),
        ),
        centerTitle: true,
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Chip Selector Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = filter == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(filter),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                      selectedColor: theme.colorScheme.primaryContainer,
                      backgroundColor: theme.colorScheme.surface,
                      side: BorderSide(
                        color: isSelected ? primaryTeal : strokeColor,
                        width: 1.5,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const Divider(height: 1),

            // List Items
            Expanded(
              child: filteredList.isEmpty
                  ? EmptyState(
                      title: 'Tidak Ada Pengajuan',
                      message: 'Tidak ada data peminjaman dengan status "$_selectedFilter".',
                      icon: Icons.assignment_late_rounded,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filteredList[index];

                        final itemsSummary = item.items.isNotEmpty
                            ? item.items.map((i) => '${i.item?.nama ?? "Aset TIK"} (${i.quantity})').join(', ')
                            : 'Belum ada aset terdaftar';

                        return AppCard(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AdminPeminjamanDetailScreen(pinjamId: item.id),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '#PINJAM-${item.id}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: primaryTeal,
                                    ),
                                  ),
                                  StatusBadge(status: item.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.namaPic,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.instansiPic} • ${item.jabatanPic}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: mutedText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 14, color: mutedText),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tgl Mulai: ${dateFormat.format(item.tanggalMulai)} (${item.durasiPeminjaman} ${item.jenisDurasi})',
                                    style: TextStyle(fontSize: 12, color: mutedText),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 14, color: primaryTeal),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      itemsSummary,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
