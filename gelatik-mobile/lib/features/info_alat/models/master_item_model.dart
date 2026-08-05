// ignore_for_file: prefer_initializing_formals

/// MasterItemModel — Entitas aset/alat TIK di backend
class MasterItemModel {
  final int id;
  final String nama;
  final String? _deskripsi;
  final int stok;
  final String? foto;
  final String? _kondisi;
  final bool? _tersedia;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MasterItemModel({
    required this.id,
    required this.nama,
    String? deskripsi,
    required this.stok,
    this.foto,
    String? kondisi,
    bool? tersedia,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  }) : _deskripsi = deskripsi,
       _kondisi = kondisi,
       _tersedia = tersedia;

  String get deskripsi => _deskripsi ?? '';
  String get kondisi => _kondisi ?? '';
  bool get tersedia => _tersedia ?? stok > 0;

  factory MasterItemModel.fromJson(Map<String, dynamic> json) {
    return MasterItemModel(
      id: _requiredInt(json, 'id'),
      nama: _requiredString(json, 'nama'),
      deskripsi: _optionalString(json, 'deskripsi'),
      stok: _requiredInt(json, 'stok'),
      foto: _optionalString(json, 'foto'),
      kondisi: _optionalString(json, 'kondisi'),
      tersedia: _optionalBool(json, 'tersedia'),
      createdBy: _optionalInt(json, 'created_by'),
      updatedBy: _optionalInt(json, 'updated_by'),
      createdAt: _optionalDateTime(json, 'created_at'),
      updatedAt: _optionalDateTime(json, 'updated_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'deskripsi': _deskripsi,
      'stok': stok,
      'foto': foto,
      'kondisi': _kondisi,
      'tersedia': tersedia,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = _parseInt(json[key]);
    if (value == null) {
      throw FormatException('Field "$key" wajib berupa angka bulat.');
    }
    return value;
  }

  static int? _optionalInt(Map<String, dynamic> json, String key) {
    final raw = json[key];
    if (raw == null) return null;
    final value = _parseInt(raw);
    if (value == null) {
      throw FormatException('Field "$key" harus berupa angka bulat atau null.');
    }
    return value;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'Field "$key" wajib berupa teks yang tidak kosong.',
      );
    }
    return value;
  }

  static String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('Field "$key" harus berupa teks atau null.');
    }
    return value;
  }

  static bool? _optionalBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! bool) {
      throw FormatException('Field "$key" harus berupa boolean atau null.');
    }
    return value;
  }

  static DateTime? _optionalDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Field "$key" harus berupa tanggal valid atau null.');
  }
}
