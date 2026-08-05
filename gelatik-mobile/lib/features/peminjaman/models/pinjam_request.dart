class PinjamRequest {
  final String namaPic;
  final String jabatanPic;
  final String instansiPic;
  final String kontakPic;
  final String jenisIdentitas;
  final String nomorIdentitas;
  final String alamatPeminjam;
  final String jenisDurasi;
  final DateTime tanggalMulai;
  final String? jamMulai;
  final int durasiPeminjaman;
  final String? keterangan;
  final String? urlDokumen;
  final Map<int, int> itemQuantities;

  const PinjamRequest({
    required this.namaPic,
    required this.jabatanPic,
    required this.instansiPic,
    required this.kontakPic,
    required this.jenisIdentitas,
    required this.nomorIdentitas,
    required this.alamatPeminjam,
    required this.jenisDurasi,
    required this.tanggalMulai,
    this.jamMulai,
    required this.durasiPeminjaman,
    this.keterangan,
    this.urlDokumen,
    required this.itemQuantities,
  });

  Map<String, dynamic> toJson() => {
    'nama_pic': namaPic,
    'jabatan_pic': jabatanPic,
    'instansi_pic': instansiPic,
    'kontak_pic': kontakPic,
    'jenis_identitas': jenisIdentitas,
    'nomor_identitas': nomorIdentitas,
    'alamat_peminjam': alamatPeminjam,
    'jenis_durasi': jenisDurasi,
    'tanggal_mulai':
        '${tanggalMulai.year.toString().padLeft(4, '0')}-${tanggalMulai.month.toString().padLeft(2, '0')}-${tanggalMulai.day.toString().padLeft(2, '0')}',
    if (jamMulai != null) 'jam_mulai': jamMulai,
    'durasi_peminjaman': durasiPeminjaman,
    if (keterangan != null && keterangan!.isNotEmpty) 'keterangan': keterangan,
    if (urlDokumen != null && urlDokumen!.isNotEmpty) 'url_dokumen': urlDokumen,
    'items': itemQuantities.entries
        .map((entry) => {'item_id': entry.key, 'quantity': entry.value})
        .toList(),
  };
}
