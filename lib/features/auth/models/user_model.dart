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

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.noHp,
    required this.namaOpd,
    required this.role,
    required this.status,
  });

  bool get isActive => status == '1';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      noHp: (json['no_hp'] ?? json['noHp']) as String? ?? '',
      namaOpd: (json['nama_opd'] ?? json['namaOpd']) as String? ?? '',
      role: json['role'] as String? ?? 'user',
      status: json['status'] as String? ?? '1',
    );
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
    };
  }
}
