class BuatKonsultasiRequest {
  final int topikId;
  final String judul;
  final String deskripsi;
  final String? filePath;

  const BuatKonsultasiRequest({
    required this.topikId,
    required this.judul,
    required this.deskripsi,
    this.filePath,
  });

  Map<String, dynamic> toJson() => {
    'topik_id': topikId,
    'judul': judul.trim(),
    'deskripsi': deskripsi.trim(),
  };
}

class BalasKonsultasiRequest {
  final String isiRespon;
  final String? filePath;

  const BalasKonsultasiRequest({required this.isiRespon, this.filePath});

  Map<String, dynamic> toJson() => {'isi_respon': isiRespon.trim()};
}
