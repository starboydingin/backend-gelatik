import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dummy/dummy_data.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/pending_activation_banner.dart';
import '../../core/theme/app_theme.dart';

class ComponentShowcaseScreen extends ConsumerStatefulWidget {
  const ComponentShowcaseScreen({super.key});

  @override
  ConsumerState<ComponentShowcaseScreen> createState() =>
      _ComponentShowcaseScreenState();
}

class _ComponentShowcaseScreenState
    extends ConsumerState<ComponentShowcaseScreen> {
  int _navIndex = 0;
  bool _showBannerInline = true;
  bool _btnLoading = false;
  final TextEditingController _sampleTextController = TextEditingController(
    text: 'Dinas Komunikasi, Informatika dan Statistik Provinsi Lampung',
  );

  @override
  void dispose() {
    _sampleTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Showcase Komponen — Gelatik'),
        actions: [
          Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                size: 20,
              ),
              const SizedBox(width: 4),
              Switch(
                value: isDark,
                onChanged: (val) {
                  ref.read(themeModeProvider.notifier).state = val
                      ? ThemeMode.dark
                      : ThemeMode.light;
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: (idx) {
          setState(() {
            _navIndex = idx;
          });
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------------------
            // Header Info
            // -----------------------------------------------------------------
            Text(
              'Design System M3 — "Siger & Pesisir"',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Galeri peninjauan komponen UI reusable & sampel data dummy backend.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // 1. Pending Activation Banner (FR-35)
            // -----------------------------------------------------------------
            _buildSectionHeader(
              context,
              '1. Pending Activation Component (FR-35)',
            ),
            if (_showBannerInline) ...[
              PendingActivationBanner(
                title: 'Akun Belum Aktif (User: ${DummyData.pendingUser.name})',
                message:
                    'Status Akun: nonaktif (${DummyData.pendingUser.status}). Akun Anda sedang menunggu verifikasi admin sebelum dapat digunakan untuk login.',
                onDismiss: () {
                  setState(() {
                    _showBannerInline = false;
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                if (!_showBannerInline)
                  AppButton(
                    text: 'Tampilkan Banner Inline',
                    isFullWidth: false,
                    onPressed: () {
                      setState(() {
                        _showBannerInline = true;
                      });
                    },
                  ),
                if (!_showBannerInline) const SizedBox(width: 12),
                AppButton(
                  text: 'Buka Dialog Peringatan FR-35',
                  variant: AppButtonVariant.outlined,
                  isFullWidth: false,
                  onPressed: () {
                    PendingActivationBanner.show(
                      context,
                      title: 'Akses Ditolak (403)',
                      message:
                          'Akun Anda belum aktif atau telah dinonaktifkan. Silakan hubungi admin Diskominfotik Provinsi Lampung.',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),

            // -----------------------------------------------------------------
            // 2. AppButton Showcase
            // -----------------------------------------------------------------
            _buildSectionHeader(
              context,
              '2. AppButton (Filled & Outlined, Radius 24px)',
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppButton(
                  text: 'Primary Navy Button',
                  icon: Icons.check_circle_outline_rounded,
                  isFullWidth: false,
                  onPressed: () {},
                ),
                AppButton(
                  text: 'Emerald Custom Button',
                  backgroundColor: const Color(0xFF10B981),
                  textColor: Colors.white,
                  icon: Icons.send_rounded,
                  isFullWidth: false,
                  onPressed: () {},
                ),
                AppButton(
                  text: 'Outlined Button',
                  variant: AppButtonVariant.outlined,
                  icon: Icons.file_upload_outlined,
                  isFullWidth: false,
                  onPressed: () {},
                ),
                AppButton(
                  text: _btnLoading ? 'Memuat...' : 'Simulasi Loading',
                  isLoading: _btnLoading,
                  isFullWidth: false,
                  onPressed: () async {
                    setState(() => _btnLoading = true);
                    await Future.delayed(const Duration(seconds: 2));
                    if (mounted) setState(() => _btnLoading = false);
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),

            // -----------------------------------------------------------------
            // 3. StatusBadge Showcase
            // -----------------------------------------------------------------
            _buildSectionHeader(
              context,
              '3. StatusBadge (Pill Stadium Colors)',
            ),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                StatusBadge(status: 'Menunggu'),
                StatusBadge(status: 'Proses'),
                StatusBadge(status: 'Diproses'),
                StatusBadge(status: 'Selesai'),
                StatusBadge(status: 'Ditolak'),
                StatusBadge(status: 'draft'),
                StatusBadge(status: 'diajukan'),
                StatusBadge(status: 'disetujui'),
              ],
            ),
            const SizedBox(height: 28),

            // -----------------------------------------------------------------
            // 4. AppTextField Showcase
            // -----------------------------------------------------------------
            _buildSectionHeader(context, '4. AppTextField (M3 Filled Style)'),
            AppTextField(
              labelText: 'Nama Instansi / OPD Pemprov Lampung',
              controller: _sampleTextController,
              prefixIcon: const Icon(Icons.business_rounded),
            ),
            const SizedBox(height: 12),
            const AppTextField(
              labelText: 'Catatan Petugas (M-C Pinjam Ditolak)',
              hintText: 'Masukkan catatan petugas untuk peminjam...',
              prefixIcon: Icon(Icons.edit_note_rounded),
              maxLines: 2,
            ),
            const SizedBox(height: 28),

            // -----------------------------------------------------------------
            // 5. AppCard & Real Model Data Showcase
            // -----------------------------------------------------------------
            _buildSectionHeader(
              context,
              '5. AppCard (Surface, Radius 16px) & Real Data',
            ),

            // Item Peminjaman Real Data
            Text(
              'Sample Record Peminjaman (Model: PinjamModel):',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            AppCard(
              onTap: () {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Peminjaman #${DummyData.pinjamList[0].id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      StatusBadge(status: DummyData.pinjamList[0].status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'PIC: ${DummyData.pinjamList[0].namaPic} (${DummyData.pinjamList[0].instansiPic})',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Item: ${DummyData.pinjamList[0].items.map((i) => "${i.quantity}x ${i.item?.nama ?? 'Aset'}").join(', ')}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Durasi: ${DummyData.pinjamList[0].durasiPeminjaman} ${DummyData.pinjamList[0].jenisDurasi} (Mulai: ${DummyData.pinjamList[0].tanggalMulai.toString().split(' ')[0]})',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Item Konsultasi Real Data
            Text(
              'Sample Tiket Konsultasi (Model: KonsultasiModel):',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          DummyData.konsultasiList[0].judul,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: DummyData.konsultasiList[0].status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DummyData.konsultasiList[0].pesan,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.support_agent_rounded, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Respon (${DummyData.konsultasiList[0].responses[0].userName}): "${DummyData.konsultasiList[0].responses[0].pesan}"',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // -----------------------------------------------------------------
            // 6. LoadingSkeleton Showcase
            // -----------------------------------------------------------------
            _buildSectionHeader(
              context,
              '6. LoadingSkeleton (Shimmer Placeholder)',
            ),
            AppCard(
              child: Row(
                children: [
                  const LoadingSkeleton(
                    width: 48,
                    height: 48,
                    borderRadius: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        LoadingSkeleton.text(width: 180, height: 16),
                        SizedBox(height: 8),
                        LoadingSkeleton.text(width: 120, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // -----------------------------------------------------------------
            // 7. EmptyState Showcase
            // -----------------------------------------------------------------
            _buildSectionHeader(
              context,
              '7. EmptyState (Ilustrasi Data Kosong)',
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: EmptyState(
                title: 'Belum Ada Pengajuan Email',
                message:
                    'Silakan ajukan usulan email resmi @lampungprov.go.id baru untuk pegawai OPD Anda.',
                icon: Icons.mark_email_unread_outlined,
                buttonText: 'Buat Usulan Email',
                onButtonPressed: () {},
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
