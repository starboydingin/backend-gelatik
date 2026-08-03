import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../providers/email_provider.dart';
import 'ajukan_usulan_email_screen.dart';
import 'usulan_email_list_screen.dart';

/// DaftarPegawaiScreen — List Pegawai OPD Belum Punya Email Resmi (M-F)
class DaftarPegawaiScreen extends ConsumerStatefulWidget {
  const DaftarPegawaiScreen({super.key});

  @override
  ConsumerState<DaftarPegawaiScreen> createState() =>
      _DaftarPegawaiScreenState();
}

class _DaftarPegawaiScreenState extends ConsumerState<DaftarPegawaiScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final accentNavy = AppColors.accentNavy(context);
    final accentGold = AppColors.accentGold(context);
    final mutedText = AppColors.mutedText(context);

    final state = ref.watch(emailProvider);
    final listPegawai = state.listPegawai;

    final filteredList = listPegawai.where((p) {
      final name = (p['nama'] ?? '').toString().toLowerCase();
      final nip = (p['nip_baru'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || nip.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usulkan Email Pegawai'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Riwayat Usulan',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const UsulanEmailListScreen(),
                ),
              );
            },
          ),
          const ThemeToggleButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar Bento Style (Identik PilihAsetScreen)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AppTextField(
                controller: _searchController,
                labelText: 'Pencarian Pegawai',
                hintText: 'Cari nama pegawai / NIP...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
              ),
            ),

            const Divider(height: 1),

            // Employee List Cards
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada pegawai ditemukan.',
                        style: TextStyle(color: mutedText, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final p = filteredList[index];
                        final nama = p['nama'] ?? 'Pegawai';
                        final initials = _getInitials(nama);

                        // Alternating Avatar Background Colors (accentNavy / accentGold)
                        final avatarBg = index % 2 == 0 ? accentNavy : accentGold;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: AppCard(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AjukanUsulanEmailScreen(pegawaiData: p),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Avatar Initial Circle
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: avatarBg,
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nama,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'NIP: ${p['nip_baru'] ?? '-'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: primaryTeal,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: primaryTeal,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 10),

                                // Jabatan & Unit Kerja
                                Row(
                                  children: [
                                    Icon(Icons.badge_outlined,
                                        size: 14, color: mutedText),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${p['jabatan']} • ${p['unit_kerja']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: mutedText,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // Email Usulan System Recommendation
                                Row(
                                  children: [
                                    Icon(Icons.alternate_email_rounded,
                                        size: 14, color: primaryTeal),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Rekomendasi: ${p['email_usulan'] ?? '-'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final clean = name.replaceAll(RegExp(r'(Dra\.|Ir\.|M\.Si\.|S\.IP\.|S\.Kom\.|S\.E\.|Ns\.|S\.Kep\.)'), '').trim();
    final parts = clean.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
