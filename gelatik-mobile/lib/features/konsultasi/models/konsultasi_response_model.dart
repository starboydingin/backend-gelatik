/// KonsultasiResponseModel — Balasan / tanggapan pada tiket konsultasi
class KonsultasiResponseModel {
  final int id;
  final int konsultasiId;
  final int userId;
  final String pesan;
  final DateTime createdAt;
  final String? namaPengirim;
  final bool isAdminUser;

  const KonsultasiResponseModel({
    required this.id,
    required this.konsultasiId,
    required this.userId,
    required this.pesan,
    required this.createdAt,
    this.namaPengirim,
    this.isAdminUser = false,
  });

  bool get isAdmin => isAdminUser;

  factory KonsultasiResponseModel.fromJson(Map<String, dynamic> json) {
    return KonsultasiResponseModel(
      id: json['id'] as int? ?? 0,
      konsultasiId: (json['konsultasi_id'] ?? json['konsultasiId']) as int? ?? 0,
      userId: (json['user_id'] ?? json['userId']) as int? ?? 0,
      pesan: json['pesan'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : DateTime.now()),
      namaPengirim: (json['nama_pengirim'] ?? json['namaPengirim']) as String?,
      isAdminUser: (json['is_admin'] ?? json['isAdminUser']) as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'konsultasi_id': konsultasiId,
      'user_id': userId,
      'pesan': pesan,
      'created_at': createdAt.toIso8601String(),
      'nama_pengirim': namaPengirim,
      'is_admin': isAdminUser,
    };
  }
}
