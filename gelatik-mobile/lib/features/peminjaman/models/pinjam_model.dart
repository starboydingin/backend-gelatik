import 'pinjam_item_model.dart';

/// PinjamModel — Entitas transaksi peminjaman aset TIK (backend schema final)
class PinjamModel {
  final int id;
  final int userId;
  final String namaPic;
  final String jabatanPic;
  final String instansiPic;
  final String kontakPic;
  final String jenisIdentitas; // KTP, SIM, Passport, NIP
  final String nomorIdentitas;
  final String alamatPeminjam;
  final String jenisDurasi; // harian, jam, menit
  final DateTime tanggalMulai;
  final String? jamMulai;
  final int durasiPeminjaman;
  final String? keterangan;
  final String status; // Menunggu, Proses, Ditolak, Selesai
  final String? catatanPetugas;
  final DateTime? tanggalSelesai;
  final DateTime? waktuPengembalian;
  final String? buktiPengembalian;
  final String? urlDokumen; // Map ke field url_dokumen (dokumen pengajuan)
  final List<PinjamItemModel> items;

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
  });

  PinjamModel copyWith({
    int? id,
    int? userId,
    String? namaPic,
    String? jabatanPic,
    String? instansiPic,
    String? kontakPic,
    String? jenisIdentitas,
    String? nomorIdentitas,
    String? alamatPeminjam,
    String? jenisDurasi,
    DateTime? tanggalMulai,
    String? jamMulai,
    int? durasiPeminjaman,
    String? keterangan,
    String? status,
    String? catatanPetugas,
    DateTime? tanggalSelesai,
    DateTime? waktuPengembalian,
    String? buktiPengembalian,
    String? urlDokumen,
    List<PinjamItemModel>? items,
  }) {
    return PinjamModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      namaPic: namaPic ?? this.namaPic,
      jabatanPic: jabatanPic ?? this.jabatanPic,
      instansiPic: instansiPic ?? this.instansiPic,
      kontakPic: kontakPic ?? this.kontakPic,
      jenisIdentitas: jenisIdentitas ?? this.jenisIdentitas,
      nomorIdentitas: nomorIdentitas ?? this.nomorIdentitas,
      alamatPeminjam: alamatPeminjam ?? this.alamatPeminjam,
      jenisDurasi: jenisDurasi ?? this.jenisDurasi,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      jamMulai: jamMulai ?? this.jamMulai,
      durasiPeminjaman: durasiPeminjaman ?? this.durasiPeminjaman,
      keterangan: keterangan ?? this.keterangan,
      status: status ?? this.status,
      catatanPetugas: catatanPetugas ?? this.catatanPetugas,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      waktuPengembalian: waktuPengembalian ?? this.waktuPengembalian,
      buktiPengembalian: buktiPengembalian ?? this.buktiPengembalian,
      urlDokumen: urlDokumen ?? this.urlDokumen,
      items: items ?? this.items,
    );
  }

  factory PinjamModel.fromJson(Map<String, dynamic> json) {
    return PinjamModel(
      id: json['id'] as int? ?? 0,
      userId: (json['user_id'] ?? json['userId']) as int? ?? 0,
      namaPic: (json['nama_pic'] ?? json['namaPic']) as String? ?? '',
      jabatanPic: (json['jabatan_pic'] ?? json['jabatanPic']) as String? ?? '',
      instansiPic: (json['instansi_pic'] ?? json['instansiPic']) as String? ?? '',
      kontakPic: (json['kontak_pic'] ?? json['kontakPic']) as String? ?? '',
      jenisIdentitas: (json['jenis_identitas'] ?? json['jenisIdentitas']) as String? ?? 'KTP',
      nomorIdentitas: (json['nomor_identitas'] ?? json['nomorIdentitas']) as String? ?? '',
      alamatPeminjam: (json['alamat_peminjam'] ?? json['alamatPeminjam']) as String? ?? '',
      jenisDurasi: (json['jenis_durasi'] ?? json['jenisDurasi']) as String? ?? 'harian',
      tanggalMulai: json['tanggal_mulai'] != null
          ? DateTime.parse(json['tanggal_mulai'].toString())
          : (json['tanggalMulai'] is DateTime
              ? json['tanggalMulai'] as DateTime
              : DateTime.now()),
      jamMulai: (json['jam_mulai'] ?? json['jamMulai']) as String?,
      durasiPeminjaman: (json['durasi_peminjaman'] ?? json['durasiPeminjaman']) as int? ?? 1,
      keterangan: json['keterangan'] as String?,
      status: json['status'] as String? ?? 'Menunggu',
      catatanPetugas: (json['catatan_petugas'] ?? json['catatanPetugas']) as String?,
      tanggalSelesai: json['tanggal_selesai'] != null
          ? DateTime.parse(json['tanggal_selesai'].toString())
          : (json['tanggalSelesai'] is DateTime ? json['tanggalSelesai'] as DateTime : null),
      waktuPengembalian: json['waktu_pengembalian'] != null
          ? DateTime.parse(json['waktu_pengembalian'].toString())
          : (json['waktuPengembalian'] is DateTime ? json['waktuPengembalian'] as DateTime : null),
      buktiPengembalian: (json['bukti_pengembalian'] ?? json['buktiPengembalian']) as String?,
      urlDokumen: (json['url_dokumen'] ?? json['urlDokumen']) as String?,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((e) => PinjamItemModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      'tanggal_mulai': tanggalMulai.toIso8601String(),
      'jam_mulai': jamMulai,
      'durasi_peminjaman': durasiPeminjaman,
      'keterangan': keterangan,
      'status': status,
      'catatan_petugas': catatanPetugas,
      'tanggal_selesai': tanggalSelesai?.toIso8601String(),
      'waktu_pengembalian': waktuPengembalian?.toIso8601String(),
      'bukti_pengembalian': buktiPengembalian,
      'url_dokumen': urlDokumen,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
