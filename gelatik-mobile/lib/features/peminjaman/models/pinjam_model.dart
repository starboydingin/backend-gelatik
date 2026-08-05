import 'pinjam_item_model.dart';

enum PinjamStatus { menunggu, proses, ditolak, selesai, unknown }

class PinjamModel {
  final int id;
  final int userId;
  final String namaPic;
  final String jabatanPic;
  final String instansiPic;
  final String kontakPic;
  final String jenisIdentitas;
  final String nomorIdentitas;
  final String alamatPeminjam;
  final String jenisDurasi;
  final DateTime tanggalMulai;
  final String? jamMulai;
  final int durasiPeminjaman;
  final String? keterangan;
  final String status;
  final String? catatanPetugas;
  final DateTime? tanggalSelesai;
  final DateTime? waktuPengembalian;
  final String? buktiPengembalian;
  final String? urlDokumen;
  final List<PinjamItemModel> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PinjamModel({
    required this.id,
    required this.userId,
    required this.namaPic,
    required this.jabatanPic,
    required this.instansiPic,
    required this.kontakPic,
    required this.jenisIdentitas,
    required this.nomorIdentitas,
    required this.alamatPeminjam,
    required this.jenisDurasi,
    required this.tanggalMulai,
    this.jamMulai,
    required this.durasiPeminjaman,
    this.keterangan,
    required this.status,
    this.catatanPetugas,
    this.tanggalSelesai,
    this.waktuPengembalian,
    this.buktiPengembalian,
    this.urlDokumen,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  PinjamStatus get statusType => switch (status.toLowerCase()) {
    'menunggu' => PinjamStatus.menunggu,
    'proses' => PinjamStatus.proses,
    'ditolak' => PinjamStatus.ditolak,
    'selesai' => PinjamStatus.selesai,
    _ => PinjamStatus.unknown,
  };

  PinjamModel copyWith({
    String? status,
    String? catatanPetugas,
    DateTime? waktuPengembalian,
    String? buktiPengembalian,
    List<PinjamItemModel>? items,
  }) => PinjamModel(
    id: id,
    userId: userId,
    namaPic: namaPic,
    jabatanPic: jabatanPic,
    instansiPic: instansiPic,
    kontakPic: kontakPic,
    jenisIdentitas: jenisIdentitas,
    nomorIdentitas: nomorIdentitas,
    alamatPeminjam: alamatPeminjam,
    jenisDurasi: jenisDurasi,
    tanggalMulai: tanggalMulai,
    jamMulai: jamMulai,
    durasiPeminjaman: durasiPeminjaman,
    keterangan: keterangan,
    status: status ?? this.status,
    catatanPetugas: catatanPetugas ?? this.catatanPetugas,
    tanggalSelesai: tanggalSelesai,
    waktuPengembalian: waktuPengembalian ?? this.waktuPengembalian,
    buktiPengembalian: buktiPengembalian ?? this.buktiPengembalian,
    urlDokumen: urlDokumen,
    items: items ?? this.items,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  factory PinjamModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['pinjam_items'] ?? json['items'] ?? const [];
    if (rawItems is! List) {
      throw const FormatException('Field pinjam_items harus berupa list.');
    }
    return PinjamModel(
      id: _requiredInt(json, 'id'),
      userId: _requiredInt(json, 'user_id'),
      namaPic: _requiredString(json, 'nama_pic'),
      jabatanPic: _requiredString(json, 'jabatan_pic'),
      instansiPic: _requiredString(json, 'instansi_pic'),
      kontakPic: _requiredString(json, 'kontak_pic'),
      jenisIdentitas: _requiredString(json, 'jenis_identitas'),
      nomorIdentitas: _requiredString(json, 'nomor_identitas'),
      alamatPeminjam: _requiredString(json, 'alamat_peminjam'),
      jenisDurasi: _requiredString(json, 'jenis_durasi'),
      tanggalMulai: _requiredDate(json, 'tanggal_mulai'),
      jamMulai: _optionalString(json, 'jam_mulai'),
      durasiPeminjaman: _requiredInt(json, 'durasi_peminjaman'),
      keterangan: _optionalString(json, 'keterangan'),
      status: _requiredString(json, 'status'),
      catatanPetugas: _optionalString(json, 'catatan_petugas'),
      tanggalSelesai: _optionalDate(json, 'tanggal_selesai'),
      waktuPengembalian: _optionalDate(json, 'waktu_pengembalian'),
      buktiPengembalian: _optionalString(json, 'bukti_pengembalian'),
      urlDokumen: _optionalString(json, 'url_dokumen'),
      items: rawItems
          .map((entry) {
            if (entry is! Map) {
              throw const FormatException(
                'Rincian peminjaman harus berupa object.',
              );
            }
            return PinjamItemModel.fromJson(Map<String, dynamic>.from(entry));
          })
          .toList(growable: false),
      createdAt: _optionalDate(json, 'created_at'),
      updatedAt: _optionalDate(json, 'updated_at'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'nama_pic': namaPic,
    'jabatan_pic': jabatanPic,
    'instansi_pic': instansiPic,
    'kontak_pic': kontakPic,
    'jenis_identitas': jenisIdentitas,
    'nomor_identitas': nomorIdentitas,
    'alamat_peminjam': alamatPeminjam,
    'jenis_durasi': jenisDurasi,
    'tanggal_mulai': _dateOnly(tanggalMulai),
    'jam_mulai': jamMulai,
    'durasi_peminjaman': durasiPeminjaman,
    'keterangan': keterangan,
    'status': status,
    'catatan_petugas': catatanPetugas,
    'tanggal_selesai': tanggalSelesai?.toIso8601String(),
    'waktu_pengembalian': waktuPengembalian?.toIso8601String(),
    'bukti_pengembalian': buktiPengembalian,
    'url_dokumen': urlDokumen,
    'pinjam_items': items.map((item) => item.toJson()).toList(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Field "$key" wajib berupa angka bulat.');
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Field "$key" wajib berupa teks tidak kosong.');
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

  static DateTime _requiredDate(Map<String, dynamic> json, String key) {
    final value = _parseDate(json[key]);
    if (value == null) {
      throw FormatException('Field "$key" wajib berupa tanggal valid.');
    }
    return value;
  }

  static DateTime? _optionalDate(Map<String, dynamic> json, String key) {
    if (json[key] == null) return null;
    final value = _parseDate(json[key]);
    if (value == null) {
      throw FormatException(
        'Field "$key" harus berupa tanggal valid atau null.',
      );
    }
    return value;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
