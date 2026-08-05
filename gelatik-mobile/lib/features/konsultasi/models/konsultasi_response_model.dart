class KonsultasiResponseModel {
  final int id;
  final int konsultasiId;
  final int userId;
  final String pesan;
  final String? file;
  final DateTime createdAt;
  final String? userName;

  const KonsultasiResponseModel({
    required this.id,
    required this.konsultasiId,
    required this.userId,
    required this.pesan,
    required this.createdAt,
    this.file,
    this.userName,
  });

  factory KonsultasiResponseModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    if (rawUser != null && rawUser is! Map) {
      throw const FormatException('Field user response bukan object.');
    }
    return KonsultasiResponseModel(
      id: _int(json, 'id'),
      konsultasiId: _int(json, 'konsultasi_id'),
      userId: _int(json, 'user_id'),
      pesan: _string(json, 'pesan'),
      createdAt: _date(json, 'created_at'),
      file: json['file'] is String && (json['file'] as String).isNotEmpty
          ? json['file'] as String
          : null,
      userName: rawUser is Map && rawUser['name'] is String
          ? rawUser['name'] as String
          : null,
    );
  }

  static int _int(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
    throw FormatException('Field $key response konsultasi tidak valid.');
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Field $key response konsultasi tidak valid.');
  }

  static DateTime _date(Map<String, dynamic> json, String key) {
    final value = json[key];
    final parsed = value is DateTime
        ? value
        : DateTime.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
    throw FormatException('Field $key response konsultasi tidak valid.');
  }
}
