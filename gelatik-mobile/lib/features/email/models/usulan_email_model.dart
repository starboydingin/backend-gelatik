/// UsulanEmailModel — Entitas pengajuan email resmi Pemprov Lampung (backend schema final)
class UsulanEmailModel {
  final int id;
  final int userId;
  final int idPegBkd;
  final String emailPribadi;
  final String? emailResmi;
  final DateTime? tanggalVerifikasi;
  final String? diverifikasiOleh;
  final String? catatan;
  final String status; // MUST BE LOWERCASE: draft, diajukan, disetujui, ditolak
  final Map<String, dynamic>? pegawai; // Nested relation pegawai BKD untuk UI

  const UsulanEmailModel({
    required this.id,
    required this.userId,
    required this.idPegBkd,
    required this.emailPribadi,
    this.emailResmi,
    this.tanggalVerifikasi,
    this.diverifikasiOleh,
    this.catatan,
    required this.status,
    this.pegawai,
  });

  UsulanEmailModel copyWith({
    int? id,
    int? userId,
    int? idPegBkd,
    String? emailPribadi,
    String? emailResmi,
    DateTime? tanggalVerifikasi,
    String? diverifikasiOleh,
    String? catatan,
    String? status,
    Map<String, dynamic>? pegawai,
  }) {
    return UsulanEmailModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      idPegBkd: idPegBkd ?? this.idPegBkd,
      emailPribadi: emailPribadi ?? this.emailPribadi,
      emailResmi: emailResmi ?? this.emailResmi,
      tanggalVerifikasi: tanggalVerifikasi ?? this.tanggalVerifikasi,
      diverifikasiOleh: diverifikasiOleh ?? this.diverifikasiOleh,
      catatan: catatan ?? this.catatan,
      status: status ?? this.status,
      pegawai: pegawai ?? this.pegawai,
    );
  }

  String get namaPegawai => pegawai?['nama'] as String? ?? 'Pegawai OPD';
  String get nipPegawai =>
      (pegawai?['nip_baru'] ?? pegawai?['nip']) as String? ?? '-';

  factory UsulanEmailModel.fromJson(Map<String, dynamic> json) {
    // The regular endpoint may expose `pegawai`, while the aggregate
    // dashboard serializes the same relation as `pegawai_bkd`.
    final rawPegawai = json['pegawai'] ?? json['pegawai_bkd'];
    final pegawai = rawPegawai is Map
        ? {
            'nama': rawPegawai['nama'] ?? rawPegawai['Nama'] ?? '',
            'nip_baru':
                rawPegawai['nip_baru'] ??
                rawPegawai['NIP_Baru'] ??
                rawPegawai['nip'] ??
                '',
          }
        : null;
    return UsulanEmailModel(
      id: json['id'] as int? ?? 0,
      userId: (json['user_id'] ?? json['userId']) as int? ?? 0,
      idPegBkd: (json['id_peg_bkd'] ?? json['idPegBkd']) as int? ?? 0,
      emailPribadi:
          (json['email_pribadi'] ??
                  json['emailPribadi'] ??
                  json['email_diusulkan'])
              as String? ??
          '',
      emailResmi: (json['email_resmi'] ?? json['emailResmi']) as String?,
      tanggalVerifikasi: json['tanggal_verifikasi'] != null
          ? DateTime.parse(json['tanggal_verifikasi'].toString())
          : (json['tanggalVerifikasi'] is DateTime
                ? json['tanggalVerifikasi'] as DateTime
                : null),
      diverifikasiOleh:
          (json['diverifikasi_oleh'] ?? json['diverifikasiOleh']) as String?,
      catatan: json['catatan'] as String?,
      status: (json['status'] as String? ?? 'draft').toLowerCase(),
      pegawai: pegawai,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'id_peg_bkd': idPegBkd,
      'email_pribadi': emailPribadi,
      'email_resmi': emailResmi,
      'tanggal_verifikasi': tanggalVerifikasi?.toIso8601String(),
      'diverifikasi_oleh': diverifikasiOleh,
      'catatan': catatan,
      'status': status,
      'pegawai': pegawai,
    };
  }
}
