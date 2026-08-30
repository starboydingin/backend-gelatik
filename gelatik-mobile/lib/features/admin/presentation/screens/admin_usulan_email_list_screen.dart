import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../email/providers/email_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import 'admin_usulan_email_detail_screen.dart';

/// AdminUsulanEmailListScreen — Daftar Seluruh Usulan Email Resmi untuk Admin (M-L)
class AdminUsulanEmailListScreen extends ConsumerStatefulWidget {
  const AdminUsulanEmailListScreen({super.key});

  @override
  ConsumerState<AdminUsulanEmailListScreen> createState() =>
      _AdminUsulanEmailListScreenState();
}

class _AdminUsulanEmailListScreenState
    extends ConsumerState<AdminUsulanEmailListScreen> {
  String _selectedFilter = 'semua';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filters => const [
    'semua',
    'menunggu',
    'terverifikasi',
    'disetujui',
    'ditolak',
  ];

  Future<void> _load({bool append = false}) {
    final page = append ? ref.read(emailProvider).currentPage + 1 : 1;
    return ref
        .read(emailProvider.notifier)
        .loadOperational(
          page: page,
          search: _searchController.text,
          status: const {'disetujui', 'ditolak'}.contains(_selectedFilter)
              ? _selectedFilter
              : null,
          verification: _selectedFilter == 'menunggu'
              ? 'waiting'
              : _selectedFilter == 'terverifikasi'
              ? 'verified'
              : null,
          append: append,
        );
  }

  void _searchChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final strokeColor = AppColors.cardStroke(context);
    final mutedText = AppColors.mutedText(context);

    final state = ref.watch(emailProvider);
    final listUsulan = state.listUsulanEmail;
    final role = ref.watch(authProvider).currentUser?.role.toLowerCase();
    final filteredList = listUsulan;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          role == 'bkd' ? 'Verifikasi Usulan Email' : 'Kelola Usulan Email',
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal),
        ),
        centerTitle: true,
        actions: const [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchController,
                onChanged: _searchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari nama, NIP, OPD, atau email',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            _load();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
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
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
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
                        _load();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const Divider(height: 1),

            // List Usulan
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: state.isLoading && listUsulan.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.errorMessage != null && listUsulan.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.errorMessage!,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => ref
                                    .read(emailProvider.notifier)
                                    .refreshFromRealtime(),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Coba lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredList.isEmpty
                    ? EmptyState(
                        title: 'Tidak Ada Usulan Email',
                        message:
                            'Tidak ada usulan email dengan status "$_selectedFilter".',
                        icon: Icons.mark_email_read_rounded,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            filteredList.length +
                            (state.currentPage < state.lastPage ? 1 : 0),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == filteredList.length) {
                            return Center(
                              child: OutlinedButton.icon(
                                onPressed: state.isLoading
                                    ? null
                                    : () => _load(append: true),
                                icon: state.isLoading
                                    ? const SizedBox.square(
                                        dimension: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.expand_more_rounded),
                                label: Text(
                                  'Muat berikutnya (${state.total - filteredList.length})',
                                ),
                              ),
                            );
                          }
                          final item = filteredList[index];

                          return AppCard(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AdminUsulanEmailDetailScreen(
                                    usulanId: item.id,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '#EMAIL-${item.id}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: primaryTeal,
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      flex: 2,
                                      child: Wrap(
                                        alignment: WrapAlignment.end,
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          StatusBadge(status: item.status),
                                          if (item.verificationState ==
                                              'verified')
                                            const StatusBadge(
                                              status: 'Terverifikasi BKD',
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.namaPegawai,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'NIP: ${item.nipPegawai}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: mutedText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 14,
                                      color: mutedText,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Email Diusulkan: ${item.emailPribadi}',
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
                                if (item.emailResmi != null &&
                                    item.emailResmi!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.verified_user_outlined,
                                        size: 14,
                                        color: primaryTeal,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Email Resmi: ${item.emailResmi}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: primaryTeal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
