import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../models/pinjam_model.dart';

/// PeminjamanDetailScreen — Layar Detail Rincian Transaksi Peminjaman Aset TIK
class PeminjamanDetailScreen extends StatelessWidget {
  final PinjamModel pinjam;

  const PeminjamanDetailScreen({
    super.key,
    required this.pinjam,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final accentNavy = AppColors.accentNavy(context);
    final strokeColor = AppColors.cardStroke(context);
    final mutedText = AppColors.mutedText(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Peminjaman TRX-${pinjam.id.toString().padLeft(4, '0')}'),
        centerTitle: true,
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card Status
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status Pengajuan',
                          style: TextStyle(
                            fontSize: 12,
                            color: mutedText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TRX-${pinjam.id.toString().padLeft(4, '0')}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryTeal,
                          ),
                        ),
                      ],
                    ),
                    StatusBadge(
                      status: pinjam.status,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Catatan Petugas (jika ada)
              if (pinjam.catatanPetugas != null &&
                  pinjam.catatanPetugas!.isNotEmpty) ...[
                AppCard(
                  backgroundColor:
                      accentNavy.withValues(alpha: 0.08),
                  border: Border.all(color: accentNavy.withValues(alpha: 0.4), width: 1.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.rate_review_outlined,
                              size: 18, color: accentNavy),
                          const SizedBox(width: 8),
                          Text(
                            'Catatan Petugas Helpdesk:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: accentNavy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pinjam.catatanPetugas!,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Card Rincian Aset Dipinjam
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rincian Aset Terpilih',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...pinjam.items.map((itemDetail) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: strokeColor, width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.devices_rounded,
                                  color: primaryTeal, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemDetail.item?.nama ?? 'Aset TIK',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (itemDetail.item?.deskripsi != null)
                                      Text(
                                        itemDetail.item!.deskripsi,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: mutedText,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryTeal,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${itemDetail.quantity} unit',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Card Informas PIC & Lokasi
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Penanggung Jawab & Waktu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(context, 'Nama PIC', pinjam.namaPic),
                    _buildDetailRow(context, 'Jabatan PIC', pinjam.jabatanPic),
                    _buildDetailRow(context, 'Instansi', pinjam.instansiPic),
                    _buildDetailRow(context, 'Kontak WA', pinjam.kontakPic),
                    _buildDetailRow(
                        context, 'Identitas', '${pinjam.jenisIdentitas}: ${pinjam.nomorIdentitas}'),
                    _buildDetailRow(context, 'Alamat Lokasi', pinjam.alamatPeminjam),
                    const Divider(height: 20),
                    _buildDetailRow(
                        context,
                        'Tanggal Mulai',
                        '${pinjam.tanggalMulai.day}/${pinjam.tanggalMulai.month}/${pinjam.tanggalMulai.year} (${pinjam.jamMulai ?? '08:00'})'),
                    _buildDetailRow(
                        context, 'Durasi', '${pinjam.durasiPeminjaman} ${pinjam.jenisDurasi}'),
                    if (pinjam.keterangan != null &&
                        pinjam.keterangan!.isNotEmpty)
                      _buildDetailRow(context, 'Keterangan', pinjam.keterangan!),
                    if (pinjam.urlDokumen != null &&
                        pinjam.urlDokumen!.isNotEmpty)
                      _buildDetailRow(
                          context, 'Url Dokumen (url_dokumen)', pinjam.urlDokumen!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final mutedText = AppColors.mutedText(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: mutedText,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
