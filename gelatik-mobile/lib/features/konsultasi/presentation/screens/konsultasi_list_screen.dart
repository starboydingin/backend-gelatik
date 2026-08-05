import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../providers/konsultasi_provider.dart';
import 'buat_konsultasi_screen.dart';
import 'konsultasi_detail_screen.dart';

class KonsultasiListScreen extends ConsumerWidget {
  const KonsultasiListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final actionEmerald = AppColors.actionEmerald(context);
    final mutedText = AppColors.mutedText(context);

    final state = ref.watch(konsultasiProvider);
    final listKonsultasi = state.listKonsultasi;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konsultasi TIK'),
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
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: listKonsultasi.length,
          itemBuilder: (context, index) {
            final k = listKonsultasi[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: AppCard(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => KonsultasiDetailScreen(konsultasi: k),
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
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            k.topik?['nama'] ?? 'Umum',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        StatusBadge(
                          status: k.status,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      k.judul,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      k.pesan,
                      style: TextStyle(
                        fontSize: 13,
                        color: mutedText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${k.createdAt.day}/${k.createdAt.month}/${k.createdAt.year}',
                          style: TextStyle(fontSize: 12, color: mutedText),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const BuatKonsultasiScreen(),
            ),
          );
        },
        backgroundColor: actionEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text(
          'Buat Konsultasi',
          style: TextStyle(fontWeight: FontWeight.bold),
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
