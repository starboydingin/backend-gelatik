import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../konsultasi/presentation/screens/konsultasi_detail_screen.dart';
import '../../../konsultasi/providers/konsultasi_provider.dart';

/// AdminKonsultasiListScreen — Daftar Seluruh Konsultasi TIK untuk Admin (M-L)
class AdminKonsultasiListScreen extends ConsumerStatefulWidget {
  const AdminKonsultasiListScreen({super.key});

  @override
  ConsumerState<AdminKonsultasiListScreen> createState() =>
      _AdminKonsultasiListScreenState();
}

class _AdminKonsultasiListScreenState
    extends ConsumerState<AdminKonsultasiListScreen> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = const [
    'Semua',
    'Menunggu Balasan',
    'Selesai',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final strokeColor = AppColors.cardStroke(context);
    final mutedText = AppColors.mutedText(context);

    final state = ref.watch(konsultasiProvider);
    final listKonsultasi = state.listKonsultasi;

    final filteredList = listKonsultasi.where((k) {
      if (_selectedFilter == 'Semua') return true;
      if (_selectedFilter == 'Menunggu Balasan') return k.status == 'Menunggu';
      if (_selectedFilter == 'Selesai') return k.status == 'Selesai';
      return true;
    }).toList();

    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Kelola Konsultasi TIK',
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

            // List Konsultasi
            Expanded(
              child: filteredList.isEmpty
                  ? EmptyState(
                      title: 'Tidak Ada Tiket',
                      message: 'Tidak ada tiket konsultasi dengan filter "$_selectedFilter".',
                      icon: Icons.support_agent_rounded,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filteredList[index];

                        return AppCard(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => KonsultasiDetailScreen(
                                  konsultasi: item,
                                  isAdminView: true, // REUSE SAMA DENGAN FLAG ADMIN
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primaryTeal.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.topikNama,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: primaryTeal,
                                      ),
                                    ),
                                  ),
                                  StatusBadge(status: item.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.judul,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.pesan,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: mutedText,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.forum_outlined,
                                          size: 14, color: mutedText),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item.responses.length} balasan',
                                        style: TextStyle(
                                            fontSize: 11, color: mutedText),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    dateFormat.format(item.createdAt),
                                    style: TextStyle(
                                        fontSize: 11, color: mutedText),
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
