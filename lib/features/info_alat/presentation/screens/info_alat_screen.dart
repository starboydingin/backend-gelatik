import 'package:flutter/material.dart';
import '../../../../core/dummy/dummy_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../home/presentation/screens/home_screen.dart';

/// InfoAlatScreen — Layar Informasi Katalog Aset TIK Read-Only (M-H)
class InfoAlatScreen extends StatefulWidget {
  const InfoAlatScreen({super.key});

  @override
  State<InfoAlatScreen> createState() => _InfoAlatScreenState();
}

class _InfoAlatScreenState extends State<InfoAlatScreen> {
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

    final items = DummyData.masterItems;
    final filteredItems = items.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.nama.toLowerCase().contains(query) ||
          item.deskripsi.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog Alat TIK'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          },
        ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar Bento-style
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AppTextField(
                controller: _searchController,
                labelText: 'Pencarian Alat TIK',
                hintText: 'Cari alat TIK (Laptop, Proyektor...)...',
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

            // Item List Cards (Read-only mode)
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        'Aset TIK tidak ditemukan.',
                        style: TextStyle(color: mutedText, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];

                        // Alternating Icon Background Color (primaryTeal / accentNavy / accentGold)
                        final bgColors = [
                          primaryTeal.withValues(alpha: 0.12),
                          accentNavy.withValues(alpha: 0.15),
                          accentGold.withValues(alpha: 0.15),
                        ];
                        final iconColors = [primaryTeal, accentNavy, accentGold];

                        final bg = bgColors[index % bgColors.length];
                        final fg = iconColors[index % iconColors.length];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: AppCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Item Thumbnail / Category Icon Container
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: item.foto != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            item.foto!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Icon(
                                              Icons.devices_rounded,
                                              color: fg,
                                              size: 32,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.devices_rounded,
                                          color: fg,
                                          size: 32,
                                        ),
                                ),
                                const SizedBox(width: 14),

                                // Item Details Info (Read-only)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.nama,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.deskripsi,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: mutedText,
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),

                                      // Badges: Condition & Stock
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.actionEmerald(context)
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Kondisi: ${item.kondisi}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.actionEmerald(context),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: primaryTeal
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Stok: ${item.stok} unit',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: primaryTeal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (index) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
      ),
    );
  }
}
