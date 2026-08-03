import 'konsultasi_response_model.dart';

/// KonsultasiModel — Entitas tiket konsultasi TIK (backend schema final)
class KonsultasiModel {
  final int id;
  final int userId;
  final String judul;
  final String pesan;
  final int? faqId;
  final String? file;
  final String status; // Menunggu, Diproses, Ditolak, Selesai (Diproses!)
  final DateTime createdAt;
  final Map<String, dynamic>? topik;
  final List<KonsultasiResponseModel> responses;

  const KonsultasiModel({
    required this.id,
    required this.userId,
    required this.judul,
    required this.pesan,
    this.faqId,
    this.file,
    required this.status,
    required this.createdAt,
    this.topik,
    this.responses = const [],
  });

  String get topikNama => topik?['nama'] as String? ?? 'Konsultasi TIK';

  factory KonsultasiModel.fromJson(Map<String, dynamic> json) {
    return KonsultasiModel(
      id: json['id'] as int? ?? 0,
      userId: (json['user_id'] ?? json['userId']) as int? ?? 0,
      judul: json['judul'] as String? ?? '',
      pesan: (json['pesan'] ?? json['deskripsi']) as String? ?? '',
      faqId: (json['faq_id'] ?? json['faqId']) as int?,
      file: json['file'] as String?,
      status: json['status'] as String? ?? 'Menunggu',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : DateTime.now()),
      topik: json['topik'] as Map<String, dynamic>?,
      responses: json['responses'] != null
          ? (json['responses'] as List)
              .map((e) => KonsultasiResponseModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'judul': judul,
      'pesan': pesan,
      'faq_id': faqId,
      'file': file,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'topik': topik,
      'responses': responses.map((e) => e.toJson()).toList(),
    };
  }
}
