import '../../features/auth/models/user_model.dart';
import '../../features/info_alat/models/master_item_model.dart';
import '../../features/peminjaman/models/pinjam_item_model.dart';
import '../../features/peminjaman/models/pinjam_model.dart';
import '../../features/konsultasi/models/konsultasi_model.dart';
import '../../features/konsultasi/models/konsultasi_response_model.dart';
import '../../features/konsultasi/models/konsultasi_topik_model.dart';
import '../../features/email/models/usulan_email_model.dart';

/// DummyData — Data contoh yang realistis berbasis OPD Lampung & Aset TIK Nyata
class DummyData {
  DummyData._();

  // ---------------------------------------------------------------------------
  // OPD Lampung List
  // ---------------------------------------------------------------------------
  static const List<String> listOpd = [
    'Dinas Komunikasi, Informatika dan Statistik Provinsi Lampung',
    'Dinas Pendidikan dan Kebudayaan Provinsi Lampung',
    'Badan Kepegawaian Daerah Provinsi Lampung',
    'Dinas Kesehatan Provinsi Lampung',
    'Dinas Pekerjaan Umum dan Penataan Ruang Provinsi Lampung',
    'Badan Perencanaan Pembangunan Daerah Provinsi Lampung',
    'Dinas Sosial Provinsi Lampung',
    'Dinas Perhubungan Provinsi Lampung',
  ];

  // ---------------------------------------------------------------------------
  // User Dummy
  // ---------------------------------------------------------------------------
  static const UserModel activeUser = UserModel(
    id: 1,
    name: 'Ahmad Subagja, S.Kom.',
    email: 'ahmad.subagja@lampungprov.go.id',
    username: 'ahmadsubagja',
    noHp: '081272345678',
    namaOpd: 'Dinas Komunikasi, Informatika dan Statistik Provinsi Lampung',
    role: 'user',
    status: '1', // Aktif
  );

  /// User KHUSUS Testing Akun Belum Aktif (FR-35)
  static const UserModel pendingUser = UserModel(
    id: 2,
    name: 'Budi Santoso, S.STP.',
    email: 'budi.santoso@lampungprov.go.id',
    username: 'budisantoso',
    noHp: '085381992233',
    namaOpd: 'Dinas Pendidikan dan Kebudayaan Provinsi Lampung',
    role: 'user',
    status: '0', // Nonaktif / Pending Aktivasi Admin
  );

  static const UserModel adminUser = UserModel(
    id: 3,
    name: 'Operator Helpdesk TIK',
    email: 'helpdesk@lampungprov.go.id',
    username: 'admin_tik',
    noHp: '081179001122',
    namaOpd: 'Dinas Komunikasi, Informatika dan Statistik Provinsi Lampung',
    role: 'admin',
    status: '1',
  );

  static const List<UserModel> dummyUsers = [
    activeUser,
    pendingUser,
    adminUser,
  ];

  // ---------------------------------------------------------------------------
  // Master Item (Aset TIK)
  // ---------------------------------------------------------------------------
  static const List<MasterItemModel> masterItems = [
    MasterItemModel(
      id: 101,
      nama: 'Laptop Lenovo ThinkPad L14 Gen 3',
      deskripsi: 'Intel Core i5-1235U, RAM 16GB, SSD 512GB, Windows 11 Pro',
      stok: 5,
      foto:
          'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=500',
      kondisi: 'Baik',
    ),
    MasterItemModel(
      id: 102,
      nama: 'Proyektor Epson EB-X05',
      deskripsi: '3300 Lumens, XGA Resolution, HDMI & VGA Input, Portable Bag',
      stok: 3,
      foto:
          'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=500',
      kondisi: 'Baik',
    ),
    MasterItemModel(
      id: 103,
      nama: 'Access Point Aruba AP-505',
      deskripsi: 'Wi-Fi 6 (802.11ax), Dual-Radio 2x2:2 MIMO, PoE Powered',
      stok: 8,
      foto: null,
      kondisi: 'Baik',
    ),
    MasterItemModel(
      id: 104,
      nama: 'Switch Cisco Catalyst 2960-X',
      deskripsi: '24 Port Gigabit Ethernet, 4x 1G SFP Uplinks, LAN Base',
      stok: 2,
      foto: null,
      kondisi: 'Baik',
    ),
    MasterItemModel(
      id: 105,
      nama: 'Webcam Logitech C920 HD Pro',
      deskripsi: 'Full HD 1080p video calling, Stereo audio with dual mics',
      stok: 4,
      foto: null,
      kondisi: 'Baik',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Pinjam Aset TIK Dummy
  // ---------------------------------------------------------------------------
  static List<PinjamModel> pinjamList = [
    PinjamModel(
      id: 1,
      userId: 1,
      namaPic: 'Ahmad Subagja, S.Kom.',
      jabatanPic: 'Pranata Komputer Ahli Muda',
      instansiPic:
          'Dinas Komunikasi, Informatika dan Statistik Provinsi Lampung',
      kontakPic: '081272345678',
      jenisIdentitas: 'NIP',
      nomorIdentitas: '198804122014031002',
      alamatPeminjam: 'Jl. Wolter Monginsidi No. 69, Bandar Lampung',
      jenisDurasi: 'harian',
      tanggalMulai: DateTime.now().subtract(const Duration(days: 2)),
      jamMulai: '08:00',
      durasiPeminjaman: 3,
      keterangan:
          'Peminjaman peralatan TIK untuk Rapat Koordinasi SPBE Pemprov Lampung',
      status: 'Menunggu',
      catatanPetugas: null,
      items: [
        PinjamItemModel(
          id: 1,
          pinjamId: 1,
          itemId: 101,
          quantity: 2,
          item: masterItems[0],
        ),
        PinjamItemModel(
          id: 2,
          pinjamId: 1,
          itemId: 102,
          quantity: 1,
          item: masterItems[1],
        ),
      ],
    ),
    PinjamModel(
      id: 2,
      userId: 1,
      namaPic: 'Rina Wijaya, S.E.',
      jabatanPic: 'Kasubbag Umum & Kepegawaian',
      instansiPic: 'Dinas Pendidikan dan Kebudayaan Provinsi Lampung',
      kontakPic: '081369112233',
      jenisIdentitas: 'NIP',
      nomorIdentitas: '198509202010012005',
      alamatPeminjam: 'Jl. Drs. Warsito No. 72, Bandar Lampung',
      jenisDurasi: 'harian',
      tanggalMulai: DateTime.now().subtract(const Duration(days: 7)),
      jamMulai: '09:00',
      durasiPeminjaman: 2,
      keterangan: 'Kegiatan Pelatihan Digitalisasi Sekolah Tingkat SMA',
      status: 'Proses',
      catatanPetugas: 'Aset telah diserahterimakan pada tanggal 23 Juli 2026.',
      items: [
        PinjamItemModel(
          id: 3,
          pinjamId: 2,
          itemId: 102,
          quantity: 2,
          item: masterItems[1],
        ),
      ],
    ),
    PinjamModel(
      id: 3,
      userId: 1,
      namaPic: 'Ahmad Subagja, S.Kom.',
      jabatanPic: 'Pranata Komputer Ahli Muda',
      instansiPic:
          'Dinas Komunikasi, Informatika dan Statistik Provinsi Lampung',
      kontakPic: '081272345678',
      jenisIdentitas: 'NIP',
      nomorIdentitas: '198804122014031002',
      alamatPeminjam: 'Jl. Wolter Monginsidi No. 69, Bandar Lampung',
      jenisDurasi: 'harian',
      tanggalMulai: DateTime.now().subtract(const Duration(days: 15)),
      jamMulai: '08:30',
      durasiPeminjaman: 1,
      keterangan:
          'Zoom Webinar Nasional Sistem Pemerintahan Berbasis Elektronik',
      status: 'Selesai',
      catatanPetugas: 'Peralatan dikembalikan dalam kondisi lengkap dan baik.',
      tanggalSelesai: DateTime.now().subtract(const Duration(days: 14)),
      waktuPengembalian: DateTime.now().subtract(const Duration(days: 14)),
      items: [
        PinjamItemModel(
          id: 4,
          pinjamId: 3,
          itemId: 105,
          quantity: 1,
          item: masterItems[4],
        ),
      ],
    ),
    PinjamModel(
      id: 4,
      userId: 1,
      namaPic: 'Hendra Gunawan, S.T.',
      jabatanPic: 'Staff Infrastruktur',
      instansiPic: 'Dinas Kesehatan Provinsi Lampung',
      kontakPic: '082188776655',
      jenisIdentitas: 'NIP',
      nomorIdentitas: '199201152019031008',
      alamatPeminjam: 'Jl. Dr. Susilo No. 45, Bandar Lampung',
      jenisDurasi: 'harian',
      tanggalMulai: DateTime.now().subtract(const Duration(days: 20)),
      jamMulai: '10:00',
      durasiPeminjaman: 5,
      keterangan: 'Peminjaman unit laptop untuk input data vaksinasi massal',
      status: 'Ditolak',
      catatanPetugas:
          'Pengajuan ditolak karena stok laptop sedang terpakai seluruhnya untuk agenda Gubernur.',
      items: [
        PinjamItemModel(
          id: 5,
          pinjamId: 4,
          itemId: 101,
          quantity: 4,
          item: masterItems[0],
        ),
      ],
    ),
  ];

  // ---------------------------------------------------------------------------
  // Konsultasi TIK Dummy
  // ---------------------------------------------------------------------------
  static List<KonsultasiModel> konsultasiList = [
    KonsultasiModel(
      id: 1,
      userId: 1,
      judul: 'Kendala Koneksi Wi-Fi Jaringan Lampung Smart di Lantai 2',
      pesan:
          'Sinyal Wi-Fi sering terputus (intermittent) saat jam kerja tinggi di ruang rapat Dishub.',
      faqId: 39,
      file: null,
      status: 'Diproses',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      topik: const KonsultasiTopikModel(id: 1, nama: 'Jaringan & Internet'),
      responses: [
        KonsultasiResponseModel(
          id: 1,
          konsultasiId: 1,
          userId: 3,
          pesan:
              'Halo Pak Ahmad, tim teknis Jaringan Diskominfotik sedang mengecek Access Point di lokasi.',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          userName: 'Petugas Helpdesk TIK',
        ),
      ],
    ),
    KonsultasiModel(
      id: 2,
      userId: 1,
      judul: 'Permohonan Integrasi Subdomain opd.lampungprov.go.id',
      pesan:
          'Mohon arahan dan persyaratan teknis untuk pendaftaran SSL certificate subdomain baru.',
      faqId: null,
      file: 'persyaratan_ssl.pdf',
      status: 'Selesai',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      topik: const KonsultasiTopikModel(id: 2, nama: 'Domain & Hosting'),
      responses: [
        KonsultasiResponseModel(
          id: 2,
          konsultasiId: 2,
          userId: 3,
          pesan:
              'DNS record dan SSL Certificate Let\'s Encrypt telah aktif untuk subdomain Anda.',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          userName: 'Admin Infrastructure',
        ),
      ],
    ),
    KonsultasiModel(
      id: 3,
      userId: 1,
      judul: 'Lupa Password Akun E-Office Pemprov Lampung',
      pesan:
          'Mohon reset password akun e-office NIP 198804122014031002 karena terblokir.',
      faqId: 12,
      file: null,
      status: 'Menunggu',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      topik: const KonsultasiTopikModel(id: 3, nama: 'Aplikasi Pegawai'),
      responses: [],
    ),
  ];

  // ---------------------------------------------------------------------------
  // Usulan Email Resmi Dummy
  // ---------------------------------------------------------------------------
  static List<UsulanEmailModel> usulanEmailList = [
    UsulanEmailModel(
      id: 1,
      userId: 1,
      idPegBkd: 501,
      emailPribadi: 'ahmad.subagja@gmail.com',
      emailResmi: 'ahmad.subagja@lampungprov.go.id',
      tanggalVerifikasi: DateTime.now().subtract(const Duration(days: 1)),
      diverifikasiOleh: 'Tim BKD Provinsi Lampung',
      catatan: 'Verifikasi identitas dan NIP berhasil.',
      status: 'disetujui', // LOWERCASE
      pegawai: {
        'nama': 'Ahmad Subagja, S.Kom.',
        'nip_baru': '198804122014031002',
        'jabatan': 'Pranata Komputer Ahli Muda',
        'opd': 'Dinas Komunikasi, Informatika dan Statistik',
      },
    ),
    UsulanEmailModel(
      id: 2,
      userId: 1,
      idPegBkd: 502,
      emailPribadi: 'rina.wijaya.edu@gmail.com',
      emailResmi: null,
      tanggalVerifikasi: null,
      diverifikasiOleh: null,
      catatan: null,
      status: 'diajukan', // LOWERCASE
      pegawai: {
        'nama': 'Rina Wijaya, S.E.',
        'nip_baru': '198509202010012005',
        'jabatan': 'Kasubbag Umum & Kepegawaian',
        'opd': 'Dinas Pendidikan dan Kebudayaan',
      },
    ),
    UsulanEmailModel(
      id: 3,
      userId: 1,
      idPegBkd: 503,
      emailPribadi: 'budi.santoso88@yahoo.com',
      emailResmi: null,
      tanggalVerifikasi: DateTime.now().subtract(const Duration(days: 4)),
      diverifikasiOleh: 'Verifikator BKD',
      catatan: 'NIP tidak cocok dengan database SIMPEG BKD.',
      status: 'ditolak', // LOWERCASE
      pegawai: {
        'nama': 'Budi Santoso, S.STP.',
        'nip_baru': '199001012015011001',
        'jabatan': 'Staf Kepegawaian',
        'opd': 'Dinas Sosial',
      },
    ),
  ];

  // ---------------------------------------------------------------------------
  // Pegawai Belum Memiliki Email Resmi BKD Dummy (M-F)
  // ---------------------------------------------------------------------------
  static List<Map<String, dynamic>> pegawaiBelumPunyaEmail = [
    {
      'id_peg_bkd': 601,
      'nama': 'Dra. Endang Rahmawati, M.Si.',
      'nip_baru': '197903152006042003',
      'opd': 'Dinas Komunikasi, Informatika dan Statistik',
      'unit_kerja': 'Bidang Layanan E-Government',
      'jabatan': 'Kepala Bidang Layanan E-Gov',
      'email_usulan': 'endang.rahmawati@lampungprov.go.id',
      'email_pribadi': 'endang.rahmawati79@gmail.com',
    },
    {
      'id_peg_bkd': 602,
      'nama': 'Ir. Bambang Triyono, M.T.',
      'nip_baru': '198211042009021004',
      'opd': 'Dinas Pekerjaan Umum dan Penataan Ruang',
      'unit_kerja': 'Bidang Bina Marga',
      'jabatan': 'Teknik Jalan dan Jembatan Ahli Madya',
      'email_usulan': 'bambang.triyono@lampungprov.go.id',
      'email_pribadi': 'bambang_triyono82@yahoo.co.id',
    },
    {
      'id_peg_bkd': 603,
      'nama': 'Siti Nurhaliza, S.Kep., Ns.',
      'nip_baru': '199307222018012002',
      'opd': 'Dinas Kesehatan Provinsi Lampung',
      'unit_kerja': 'Seksi Pelayanan Kesehatan',
      'jabatan': 'Perawat Ahli Pertama',
      'email_usulan': 'siti.nurhaliza@lampungprov.go.id',
      'email_pribadi': 'siti.nurhaliza.health@gmail.com',
    },
    {
      'id_peg_bkd': 604,
      'nama': 'Dedi Kurniawan, S.IP.',
      'nip_baru': '199505102020121006',
      'opd': 'Badan Kepegawaian Daerah',
      'unit_kerja': 'Subbid Pengadaan & Mutasi',
      'jabatan': 'Analis Kepegawaian Pertama',
      'email_usulan': 'dedi.kurniawan@lampungprov.go.id',
      'email_pribadi': 'dedi_kurniawan95@outlook.com',
    },
  ];

  // ---------------------------------------------------------------------------
  // Internet Bandwidth & Router Dummy (M-E)
  // ---------------------------------------------------------------------------
  static const Map<String, dynamic> internetBandwidthInfo = {
    'download_mbps': 500,
    'upload_mbps': 500,
    'provider': 'Astinet Telkom Indonesia (Dedicated 1:1)',
    'ip_publik': '103.14.120.1',
    'status': 'Normal / Prima',
    'opd': 'Dinas Komunikasi, Informatika dan Statistik',
  };

  static const List<Map<String, dynamic>> listRouterOpd = [
    {
      'id': 1,
      'nama_router': 'Router Core Datacenter Diskominfotik',
      'lokasi': 'Ruang Server Lt. 3 Gedung Diskominfotik',
      'ip_address': '192.168.10.1',
      'tipe': 'MikroTik CCR2004-16G-2S+',
      'status': 'Aktif',
      'beban_traffic': '42%',
    },
    {
      'id': 2,
      'nama_router': 'Access Router Gedung B (Bidang E-Gov)',
      'lokasi': 'Ruang Swtich Lt. 2 Gedung B',
      'ip_address': '192.168.20.1',
      'tipe': 'Cisco ISR 4331',
      'status': 'Aktif',
      'beban_traffic': '65%',
    },
    {
      'id': 3,
      'nama_router': 'Backup Router FO Diskominfotik',
      'lokasi': 'Ruang Network Operations Center (NOC)',
      'ip_address': '192.168.30.1',
      'tipe': 'MikroTik RB3011UiAS-RM',
      'status': 'Standby',
      'beban_traffic': '0%',
    },
  ];

  static const List<Map<String, dynamic>> internetFaqList = [
    {
      'id': 1,
      'pertanyaan': 'Koneksi internet melambat saat jam kantor?',
      'jawaban':
          'Pastikan perangkat tidak sedang melakukan download/stream video 4K tanpa batasan bandwidth, atau lakukan restart pada Adaptor Wi-Fi Anda.',
    },
    {
      'id': 2,
      'pertanyaan': 'Sinyal Wi-Fi terhubung tetapi "No Internet Connection"?',
      'jawaban':
          'Periksa apakah IP Address Anda mendapatkan DHCP otomatis atau hubungi tim Helpdesk untuk verifikasi subnet gateway OPD.',
    },
    {
      'id': 3,
      'pertanyaan': 'Layanan aplikasi SIMPEG / E-Office tidak dapat dibuka?',
      'jawaban':
          'Gunakan jaringan internal Lampung Smart atau VPN Resmi Pemprov Lampung jika mengakses dari luar kantor.',
    },
  ];
}
