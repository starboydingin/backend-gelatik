import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../peminjaman/models/pinjam_model.dart';
import '../../../peminjaman/providers/peminjaman_provider.dart';

/// AdminPeminjamanDetailScreen — Detail Peminjaman & Aksi Khusus Admin (Setujui/Tolak/Selesai)
class AdminPeminjamanDetailScreen extends ConsumerStatefulWidget {
  final int pinjamId;

  const AdminPeminjamanDetailScreen({super.key, required this.pinjamId});

  @override
  ConsumerState<AdminPeminjamanDetailScreen> createState() =>
      _AdminPeminjamanDetailScreenState();
}

class _AdminPeminjamanDetailScreenState
    extends ConsumerState<AdminPeminjamanDetailScreen> {
  final TextEditingController _catatanController = TextEditingController();
  String? _catatanError;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(peminjamanProvider.notifier).loadDetail(widget.pinjamId),
    );
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  void _showTolakDialog(BuildContext context) {
    _catatanController.clear();
    setState(() {
      _catatanError = null;
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = isDark
        ? AppColors.statusErrorDark
        : AppColors.statusErrorLight;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tolak Pengajuan Peminjaman'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Berikan alasan/catatan penolakan untuk pemohon (WAJIB diisi):',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    labelText: 'Catatan Penolakan Admin',
                    hintText:
                        'Misal: Stok barang tidak mencukupi untuk periode tersebut.',
                    controller: _catatanController,
                    maxLines: 3,
                    errorText: _catatanError,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final notes = _catatanController.text.trim();
                    if (notes.isEmpty) {
                      setDialogState(() {
                        _catatanError = 'Catatan penolakan wajib diisi.';
                      });
                      return;
                    }

                    Navigator.of(dialogCtx).pop();

                    final messenger = ScaffoldMessenger.of(context);
                    final success = await ref
                        .read(peminjamanProvider.notifier)
                        .tolakPeminjaman(widget.pinjamId, notes);

                    if (success) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Pengajuan peminjaman telah ditolak.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Konfirmasi Tolak'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSelesaiDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Konfirmasi Tandai Selesai'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pastikan aset telah dikembalikan dalam kondisi baik.',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: Colors.teal),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Status akan diperbarui setelah pengembalian dikonfirmasi.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.actionEmerald(context),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();

                final messenger = ScaffoldMessenger.of(context);
                final success = await ref
                    .read(peminjamanProvider.notifier)
                    .selesaikanPeminjaman(widget.pinjamId);

                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Peminjaman telah ditandai selesai!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Selesaikan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTeal = AppColors.primaryTeal(context);
    final errorColor = isDark
        ? AppColors.statusErrorDark
        : AppColors.statusErrorLight;
    final strokeColor = AppColors.cardStroke(context);
    final mutedText = AppColors.mutedText(context);

    final state = ref.watch(peminjamanProvider);
    final role = ref.watch(authProvider).currentUser?.role.toLowerCase();
    final canManage = role == 'admin' || role == 'superadmin';
    PinjamModel? pinjam = state.selectedPinjam?.id == widget.pinjamId
        ? state.selectedPinjam
        : null;
    for (final item in state.listPinjam) {
      if (item.id == widget.pinjamId) pinjam ??= item;
    }

    if (state.status == PeminjamanLoadStatus.error || pinjam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Peminjaman')),
        body: Center(
          child: state.status == PeminjamanLoadStatus.error
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.errorMessage ?? 'Detail peminjaman gagal dimuat.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref
                          .read(peminjamanProvider.notifier)
                          .loadDetail(widget.pinjamId),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      );
    }

    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Detail Peminjaman #${pinjam.id}',
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal),
        ),
        centerTitle: true,
        actions: const [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card & Status
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STATUS PENGAJUAN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: mutedText,
                            letterSpacing: 0.5,
                          ),
                        ),
                        StatusBadge(status: pinjam.status),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      context,
                      'Nama Pemohon (PIC)',
                      pinjam.namaPic,
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      context,
                      'Instansi / OPD',
                      pinjam.instansiPic,
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(context, 'Jabatan PIC', pinjam.jabatanPic),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      context,
                      'Kontak WA / HP',
                      pinjam.kontakPic,
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      context,
                      'Identitas (${pinjam.jenisIdentitas})',
                      pinjam.nomorIdentitas,
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      context,
                      'Alamat Peminjam',
                      pinjam.alamatPeminjam,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Detail Waktu & Durasi Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERIODE PEMINJAMAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: mutedText,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Divider(height: 16),
                    _buildDetailRow(
                      context,
                      'Tanggal & Jam Mulai',
                      '${dateFormat.format(pinjam.tanggalMulai)} jam ${pinjam.jamMulai ?? "08:00"} WIB',
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      context,
                      'Durasi Peminjaman',
                      '${pinjam.durasiPeminjaman} ${pinjam.jenisDurasi}',
                    ),
                    if (pinjam.keterangan != null &&
                        pinjam.keterangan!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        context,
                        'Maksud & Tujuan',
                        pinjam.keterangan!,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Daftar Aset Terdaftar Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAFTAR ASET YANG DIPINJAM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: mutedText,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Divider(height: 16),
                    if (pinjam.items.isEmpty)
                      Text(
                        'Belum ada rincian aset.',
                        style: TextStyle(fontSize: 13, color: mutedText),
                      )
                    else
                      Column(
                        children: pinjam.items.map((pinjamItem) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryTeal.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.devices_rounded,
                                    size: 18,
                                    color: primaryTeal,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pinjamItem.item?.nama ?? 'Aset TIK',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        'Kondisi: ${pinjamItem.item?.kondisi ?? "Baik"}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: strokeColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${pinjamItem.quantity} unit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),

              // Jika status Ditolak dan ada catatanPetugas
              if (pinjam.catatanPetugas != null &&
                  pinjam.catatanPetugas!.isNotEmpty) ...[
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: errorColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CATATAN PENOLAKAN ADMIN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: errorColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pinjam.catatanPetugas!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ===============================================================
              // ACTION BUTTONS KHUSUS ADMIN (M-L BAGIAN 2)
              // ===============================================================
              if (canManage && pinjam.status == 'Menunggu') ...[
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Tolak',
                        icon: Icons.cancel_outlined,
                        variant: AppButtonVariant.outlined,
                        onPressed: state.isSubmitting
                            ? null
                            : () => _showTolakDialog(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: 'Setujui',
                        icon: Icons.check_circle_outline_rounded,
                        variant: AppButtonVariant.filled,
                        onPressed: state.isSubmitting
                            ? null
                            : () async {
                                final success = await ref
                                    .read(peminjamanProvider.notifier)
                                    .setujuPeminjaman(widget.pinjamId);

                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Pengajuan peminjaman telah disetujui! Status: Proses.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ] else if (canManage && pinjam.status == 'Proses') ...[
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Tandai Selesai',
                    icon: Icons.task_alt_rounded,
                    variant: AppButtonVariant.filled,
                    onPressed: state.isSubmitting
                        ? null
                        : () => _showSelesaiDialog(context),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
