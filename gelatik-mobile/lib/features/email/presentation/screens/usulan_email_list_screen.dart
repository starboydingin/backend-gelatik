import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../providers/email_provider.dart';
import 'daftar_pegawai_screen.dart';
import 'usulan_email_detail_screen.dart';

/// UsulanEmailListScreen — Daftar Riwayat Pengajuan Email Resmi (M-F)
class UsulanEmailListScreen extends ConsumerStatefulWidget {
  const UsulanEmailListScreen({super.key});

  @override
  ConsumerState<UsulanEmailListScreen> createState() =>
      _UsulanEmailListScreenState();
}

class _UsulanEmailListScreenState extends ConsumerState<UsulanEmailListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(emailProvider.notifier).loadUsulan());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final actionEmerald = AppColors.actionEmerald(context);
    final mutedText = AppColors.mutedText(context);

    final state = ref.watch(emailProvider);
    final list = state.listUsulanEmail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Usulan Email'),
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
        child: list.isEmpty
            ? EmptyState(
                title: 'Belum Ada Usulan Email',
                message: 'Belum ada transaksi pengajuan usulan email resmi.',
                icon: Icons.mark_email_read_outlined,
                buttonText: 'Buat Usulan Baru',
                onButtonPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DaftarPegawaiScreen(),
                    ),
                  );
                },
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: AppCard(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                UsulanEmailDetailScreen(usulan: item),
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
                                'USULAN-#${item.id.toString().padLeft(4, '0')}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTeal,
                                ),
                              ),
                              // StatusBadge with case-insensitive status matching
                              StatusBadge(status: item.status),
                            ],
                          ),
                          const SizedBox(height: 10),
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
                            style: TextStyle(fontSize: 12, color: mutedText),
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 14,
                                color: primaryTeal,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.emailResmi ?? item.emailPribadi,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: item.emailResmi != null
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: item.emailResmi != null
                                        ? actionEmerald
                                        : theme.colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
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
            MaterialPageRoute(builder: (_) => const DaftarPegawaiScreen()),
          );
        },
        backgroundColor: actionEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Usul Email Baru',
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
