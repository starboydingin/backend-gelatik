import 'konsultasi_response_model.dart';
import 'konsultasi_topik_model.dart';

class KonsultasiModel {
  final int id;
  final int userId;
  final String judul;
  final String pesan;
  final int? faqId;
  final String? file;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? userName;
  final KonsultasiTopikModel? topik;
  final List<KonsultasiResponseModel> responses;

  const KonsultasiModel({
    required this.id,
    required this.userId,
    required this.judul,
    required this.pesan,
    required this.status,
    required this.createdAt,
    this.faqId,
    this.file,
    this.updatedAt,
    this.userName,
    this.topik,
    this.responses = const [],
  });

  String get topikNama => topik?.nama ?? 'Konsultasi TIK';

  KonsultasiModel copyWith({
    String? status,
    List<KonsultasiResponseModel>? responses,
    KonsultasiTopikModel? topik,
    String? userName,
  }) => KonsultasiModel(
    id: id,
    userId: userId,
    judul: judul,
    pesan: pesan,
    status: status ?? this.status,
    createdAt: createdAt,
    faqId: faqId,
    file: file,
    updatedAt: updatedAt,
    userName: userName ?? this.userName,
    topik: topik ?? this.topik,
    responses: responses ?? this.responses,
  );

  factory KonsultasiModel.fromJson(Map<String, dynamic> json) {
    final rawResponses = json['responses'];
    if (rawResponses != null && rawResponses is! List) {
      throw const FormatException('Field responses konsultasi bukan list.');
    }
    final rawTopik = json['topik'];
    if (rawTopik != null && rawTopik is! Map) {
      throw const FormatException('Field topik konsultasi bukan object.');
    }
    final rawUser = json['user'];
    if (rawUser != null && rawUser is! Map) {
      throw const FormatException('Field user konsultasi bukan object.');
    }

    return KonsultasiModel(
      id: _requiredInt(json, 'id'),
      userId: _requiredInt(json, 'user_id'),
      judul: _requiredString(json, 'judul'),
      pesan: _requiredString(json, 'pesan'),
      status: _requiredString(json, 'status'),
      createdAt: _requiredDate(json, 'created_at'),
      faqId: _nullableInt(json['faq_id']),
      file: _nullableString(json['file']),
      updatedAt: _nullableDate(json['updated_at']),
      userName: rawUser == null
          ? null
          : _nullableString(Map<dynamic, dynamic>.from(rawUser)['name']),
      topik: rawTopik == null
          ? null
          : KonsultasiTopikModel.fromJson(Map<String, dynamic>.from(rawTopik)),
      responses: rawResponses == null
          ? const []
          : rawResponses
                .map<KonsultasiResponseModel>((entry) {
                  if (entry is! Map) {
                    throw const FormatException(
                      'Salah satu response konsultasi bukan object.',
                    );
                  }
                  return KonsultasiResponseModel.fromJson(
                    Map<String, dynamic>.from(entry),
                  );
                })
                .toList(growable: false),
    );
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Field $key konsultasi tidak valid.');
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Field $key konsultasi tidak valid.');
  }

  static String? _nullableString(dynamic value) =>
      value is String && value.isNotEmpty ? value : null;

  static DateTime _requiredDate(Map<String, dynamic> json, String key) {
    final parsed = _nullableDate(json[key]);
    if (parsed == null) {
      throw FormatException('Field $key konsultasi tidak valid.');
    }
    return parsed;
  }

  static DateTime? _nullableDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
