/// UserModel — Entity User Gelatik dengan field status pendukung FR-35
class UserModel {
  final int id;
  final String name;
  final String email;
  final String username;
  final String noHp;
  final String namaOpd;
  final String role;
  final String status; // '0' = pending/nonaktif, '1' = aktif
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.noHp,
    required this.namaOpd,
    required this.role,
    required this.status,
    this.createdAt,
  });

  bool get isActive => status == '1';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final directRole = json['role']?.toString().trim();
    final roles = json['roles'];
    final roleFromRelation =
        roles is List && roles.isNotEmpty && roles.first is Map
        ? (roles.first as Map)['name']?.toString().trim()
        : null;

    return UserModel(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      email: _asString(json['email']),
      username: _asString(json['username']),
      noHp: _asString(json['no_hp'] ?? json['noHp']),
      namaOpd: _asString(json['nama_opd'] ?? json['namaOpd']),
      role: directRole?.isNotEmpty == true
          ? directRole!
          : (roleFromRelation?.isNotEmpty == true ? roleFromRelation! : 'user'),
      status: _asString(json['status'], fallback: '1'),
      createdAt: _asDate(json['created_at'] ?? json['createdAt']),
    );
  }

  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse('$value') ?? 0;

  static String _asString(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'no_hp': noHp,
      'nama_opd': namaOpd,
      'role': role,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
