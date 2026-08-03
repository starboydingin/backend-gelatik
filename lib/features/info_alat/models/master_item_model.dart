/// MasterItemModel — Entitas aset/alat TIK di backend
class MasterItemModel {
  final int id;
  final String nama;
  final String deskripsi;
  final int stok;
  final String? foto;
  final String kondisi; // Baik, Rusak Sebagian, Rusak Parah, Tidak Berfungsi

  const MasterItemModel({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.stok,
    this.foto,
    required this.kondisi,
  });

  factory MasterItemModel.fromJson(Map<String, dynamic> json) {
    return MasterItemModel(
      id: json['id'] as int? ?? 0,
      nama: json['nama'] as String? ?? '',
      deskripsi: json['deskripsi'] as String? ?? '',
      stok: json['stok'] as int? ?? 0,
      foto: json['foto'] as String?,
      kondisi: json['kondisi'] as String? ?? 'Baik',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'deskripsi': deskripsi,
      'stok': stok,
      'foto': foto,
      'kondisi': kondisi,
    };
  }
}
