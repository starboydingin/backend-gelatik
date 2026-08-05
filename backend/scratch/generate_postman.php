<?php

$rootDir = dirname(__DIR__, 2);
$collectionPath = $rootDir . '/layanantik-backend-api.postman_collection.json';
$envPath = $rootDir . '/layanantik-local.postman_environment.json';

echo "Generating Postman Environment & Collection...\n";

// ============================================================================
// 1. GENERATE POSTMAN ENVIRONMENT
// ============================================================================
$environmentData = [
    "id" => "e8d4a678-8888-4567-89ab-cdef01234567",
    "name" => "LayananTIK Local Environment",
    "values" => [
        [
            "key" => "base_url",
            "value" => "http://localhost:8000/api",
            "type" => "default",
            "enabled" => true
        ],
        [
            "key" => "access_token",
            "value" => "",
            "type" => "secret",
            "enabled" => true
        ]
    ],
    "_postman_variable_scope" => "environment",
    "_postman_exported_at" => date('c'),
    "_postman_exported_using" => "Postman/10.0.0"
];

file_put_contents($envPath, json_encode($environmentData, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
echo "Environment written to: $envPath\n";


// ============================================================================
// 2. HELPER FUNCTIONS FOR POSTMAN REQUESTS
// ============================================================================

function makePostmanItem($name, $method, $path, $options = []) {
    $isPublic = $options['public'] ?? false;
    $body = $options['body'] ?? null;
    $description = $options['description'] ?? '';
    $testScript = $options['test_script'] ?? null;
    $queryParams = $options['query_params'] ?? [];
    $isFullUrl = $options['full_url'] ?? false;

    $headers = [
        [
            "key" => "Accept",
            "value" => "application/json",
            "type" => "text"
        ]
    ];

    if ($body !== null) {
        $headers[] = [
            "key" => "Content-Type",
            "value" => "application/json",
            "type" => "text"
        ];
    }

    $requestObj = [
        "method" => strtoupper($method),
        "header" => $headers
    ];

    if ($isPublic) {
        $requestObj["auth"] = [
            "type" => "noauth"
        ];
    } else {
        $requestObj["auth"] = [
            "type" => "bearer",
            "bearer" => [
                [
                    "key" => "token",
                    "value" => "{{access_token}}",
                    "type" => "string"
                ]
            ]
        ];
    }

    if ($body !== null) {
        $bodyStr = is_string($body) ? $body : json_encode($body, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
        $requestObj["body"] = [
            "mode" => "raw",
            "raw" => $bodyStr,
            "options" => [
                "raw" => [
                    "language" => "json"
                ]
            ]
        ];
    }

    // Build URL object
    if ($isFullUrl) {
        $rawUrl = $path;
        $requestObj["url"] = [
            "raw" => $rawUrl
        ];
    } else {
        $cleanPath = ltrim($path, '/');
        $rawUrl = "{{base_url}}/" . $cleanPath;
        
        $pathSegments = explode('/', strtok($cleanPath, '?'));
        
        $urlObj = [
            "raw" => $rawUrl,
            "host" => ["{{base_url}}"],
            "path" => $pathSegments
        ];

        if (!empty($queryParams)) {
            $queryArr = [];
            foreach ($queryParams as $k => $v) {
                $queryArr[] = [
                    "key" => $k,
                    "value" => (string)$v
                ];
            }
            $urlObj["query"] = $queryArr;
        }

        $requestObj["url"] = $urlObj;
    }

    if ($description) {
        $requestObj["description"] = $description;
    }

    $item = [
        "name" => $name,
        "request" => $requestObj,
        "response" => []
    ];

    if ($testScript) {
        $item["event"] = [
            [
                "listen" => "test",
                "script" => [
                    "type" => "text/javascript",
                    "exec" => explode("\n", $testScript)
                ]
            ]
        ];
    }

    return $item;
}

// ============================================================================
// 3. DEFINE ALL FOLDERS AND REQUESTS
// ============================================================================

$folders = [];

// ----------------------------------------------------------------------------
// FOLDER 0: PANDUAN PENGGUNAAN
// ----------------------------------------------------------------------------
$panduanDescription = <<<TEXT
# 📘 PANDUAN PENGGUNAAN POSTMAN COLLECTION LAYANAN TIK

Selamat datang di Postman Collection resmi **Layanan TIK Backend API (Diskominfotik Pemprov Lampung)**. Collection ini dirancang khusus sebagai panduan integrasi bagi **Developer Website** dan **Developer Mobile**.

---

## 1. PETUNJUK AWAL & AUTENTIKASI AUTOMATIS
1. **Import File**: Import file collection (`layanantik-backend-api.postman_collection.json`) dan environment (`layanantik-local.postman_environment.json`) ke Postman Anda.
2. **Pilih Environment**: Pastikan environment aktif disetel ke **"LayananTIK Local Environment"**.
3. **Jalankan Login**: Buka folder `00 - Auth` -> pilih request `POST /login` -> klik **Send**.
4. **Token Auto-Save**: Script otomatis di tab *Tests* akan langsung menyimpan `access_token` ke environment variable `{{access_token}}`. Seluruh request terautentikasi di folder lain akan otomatis memakai Bearer token ini.

---

## 2. DAFTAR TOPIC FCM (FIREBASE CLOUD MESSAGING)
Client Mobile & Web disarankan melakukan subscribe ke topic-topic FCM berikut untuk menerima Push Notification:
- `user_{id}` : Notifikasi personal spesifik per user (contoh: `user_2`, `user_5`).
- `admin` : Notifikasi pengajuan baru untuk seluruh Admin Operator / Petugas TIK.
- `bkd` : Notifikasi khusus tim BKD (terkait pengajuan email resmi BKD).
- `pengumuman` : Notifikasi pengumuman resmi ke seluruh pengguna.

---

## 3. PANDUAN INTEGRASI REALTIME SERVICE (SOCKET.IO)
- **URL Socket Server**: `http://localhost:4000` (atau port production yang dikonfigurasi).
- **Format Handshake Auth**:
  ```javascript
  const socket = io("http://localhost:4000", {
    auth: {
      token: access_token // Bearer token OAuth Passport dari /api/login
    }
  });
  ```
- **Daftar Event yang Bisa Didengarkan (Client Listeners)**:
  1. `pinjam.status_changed` : Notifikasi saat status pengajuan peminjaman aset berubah (`Menunggu` -> `Disetujui` / `Ditolak` / `Selesai`).
  2. `konsultasi.new_response` : Notifikasi balasan/tanggapan baru pada tiket konsultasi TIK.
  3. `usulan_email.status_changed` : Notifikasi perubahan status usulan email resmi BKD.
  4. `pengumuman.created` : Notifikasi pengumuman resmi baru yang diterbitkan admin.

---

## 4. REFERENSI DOKUMEN PRODUCTION
- Dapatkan konfigurasi environment server produksi pada file:
  `KONFIGURASI_PRODUCTION.md` (terletak di root repository).

---

## ⚠️ CATATAN PENTING KONTRAK API FINAL
- Endpoint dan path yang tertera dalam Postman Collection ini (termasuk aksi tambah/hapus item pada transaksi peminjaman seperti `POST /api/pinjam/{id}` dan `DELETE /api/pinjam/{p}/item/{id}`) adalah **SKEMA FINAL DAN RESMI SESUAI KONTRAK AKTUAL BACKEND**.
- Developer **WAJIB** menjadikan Postman Collection ini sebagai *Single Source of Truth* (satu-satunya acuan kebenaran) dan mengabaikan perbedaan path pada draft dokumen SRS/PRD lama.
TEXT;

$folders[] = [
    "name" => "00 - PANDUAN PENGGUNAAN",
    "item" => [
        makePostmanItem(
            "📘 PANDUAN DOKUMENTASI API & INTEGRASI",
            "GET",
            "{{base_url}}/panduan",
            [
                "public" => true,
                "description" => $panduanDescription
            ]
        )
    ]
];

// ----------------------------------------------------------------------------
// FOLDER 1: 00 - Auth
// ----------------------------------------------------------------------------
$loginTestScript = <<<JS
var jsonData = pm.response.json();
if (jsonData.data && jsonData.data.access_token) {
    pm.environment.set("access_token", jsonData.data.access_token);
    console.log("Access Token saved successfully: " + jsonData.data.access_token);
} else if (jsonData.access_token) {
    pm.environment.set("access_token", jsonData.access_token);
    console.log("Access Token saved successfully: " + jsonData.access_token);
}
JS;

$folders[] = [
    "name" => "00 - Auth",
    "item" => [
        makePostmanItem(
            "POST Login Pengguna / Admin",
            "POST",
            "/login",
            [
                "public" => true,
                "body" => [
                    "email" => "bkd@lampungprov.go.id",
                    "password" => "password123"
                ],
                "description" => "Fungsi: Autentikasi akun pengguna atau admin operator.\nPermission/Role: Publik.\nCatatan: Script otomatis akan menyimpan access_token dari response ke environment variable {{access_token}}.",
                "test_script" => $loginTestScript
            ]
        ),
        makePostmanItem(
            "POST Register Pengguna Baru",
            "POST",
            "/register",
            [
                "public" => true,
                "body" => [
                    "name" => "User Baru OPD Test",
                    "email" => "userbaru_test@lampungprov.go.id",
                    "username" => "userbaru_test",
                    "no_hp" => "081234567890",
                    "nama_opd" => "Dinas Komunikasi Informasi dan Statistik",
                    "password" => "password123",
                    "password_confirmation" => "password123"
                ],
                "description" => "Fungsi: Pendaftaran akun baru pengguna OPD/Pegawai.\nPermission/Role: Publik.\nCatatan: Akun yang terdaftar berstatus aktif (status=1) dan mendapatkan role 'user'."
            ]
        ),
        makePostmanItem(
            "GET Profil Saya (Me)",
            "GET",
            "/me",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil detail profil pengguna aktif beserta daftar role dan permissions.\nPermission/Role: Membutuhkan login (Bearer token)."
            ]
        ),
        makePostmanItem(
            "POST Logout Pengguna",
            "POST",
            "/logout",
            [
                "public" => false,
                "description" => "Fungsi: Revoke token autentikasi aktif pengguna.\nPermission/Role: Membutuhkan login."
            ]
        ),
        makePostmanItem(
            "GET Daftar OPD Pemprov Lampung",
            "GET",
            "/opd",
            [
                "public" => true,
                "description" => "Fungsi: Mengambil daftar Perangkat Daerah / OPD Pemprov Lampung untuk dropdown registrasi atau edit profil.\nPermission/Role: Publik."
            ]
        )
    ]
];

// ----------------------------------------------------------------------------
// FOLDER 2: 01 - Dashboard
// ----------------------------------------------------------------------------
$folders[] = [
    "name" => "01 - Dashboard",
    "item" => [
        makePostmanItem(
            "GET Dashboard Summary",
            "GET",
            "/dashboard",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil ringkasan statistik dan rekapitulasi data dashboard (peminjaman, konsultasi, pengumuman, rating).\nPermission/Role: Terautentikasi (User/Admin)."
            ]
        ),
        makePostmanItem(
            "GET Slider Banner",
            "GET",
            "/slider",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil daftar gambar banner slider yang aktif dipasang pada portal utama.\nPermission/Role: Terautentikasi."
            ]
        )
    ]
];

// ----------------------------------------------------------------------------
// FOLDER 3: 02 - Peminjaman Aset
// ----------------------------------------------------------------------------
$folders[] = [
    "name" => "02 - Peminjaman Aset",
    "item" => [
        makePostmanItem(
            "GET List Pengajuan Peminjaman",
            "GET",
            "/pinjam",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil daftar riwayat pengajuan peminjaman aset TIK milik pengguna (atau seluruh peminjaman jika role Admin/Petugas).\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "POST Buat Pengajuan Peminjaman Baru",
            "POST",
            "/pinjam",
            [
                "public" => false,
                "body" => [
                    "tgl_pinjam" => date('Y-m-d'),
                    "tgl_kembali" => date('Y-m-d', strtotime('+3 days')),
                    "keterangan" => "Peminjaman Laptop & Proyektor untuk Rapat Koordinasi",
                    "items" => [
                        ["item_id" => 1, "jumlah" => 1]
                    ]
                ],
                "description" => "Fungsi: Mengajukan peminjaman aset TIK baru.\nPermission/Role: Terautentikasi.\nCatatan: Status awal pengajuan otomatis disetel ke 'Menunggu'."
            ]
        ),
        makePostmanItem(
            "GET Detail Peminjaman",
            "GET",
            "/pinjam/1",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil detail pengajuan peminjaman aset tertentu beserta item-item yang dipinjam.\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "PUT Update Data Peminjaman",
            "PUT",
            "/pinjam/1",
            [
                "public" => false,
                "body" => [
                    "keterangan" => "Peminjaman Laptop & Proyektor (Update Keterangan)"
                ],
                "description" => "Fungsi: Memperbarui keterangan atau tanggal pengajuan peminjaman.\nPermission/Role: Terautentikasi.\nCatatan: Hanya bisa diakses jika status pengajuan masih 'Menunggu'."
            ]
        ),
        makePostmanItem(
            "POST Update Status Peminjaman (Admin)",
            "POST",
            "/pinjam/1/status",
            [
                "public" => false,
                "body" => [
                    "status" => "1",
                    "catatan" => "Disetujui oleh admin operator"
                ],
                "description" => "Fungsi: Mengubah status peminjaman aset (1 = Disetujui, 2 = Ditolak, 3 = Selesai).\nPermission/Role: Admin / Superadmin / Petugas TIK."
            ]
        ),
        makePostmanItem(
            "POST Tambah Item ke Peminjaman",
            "POST",
            "/pinjam/1",
            [
                "public" => false,
                "body" => [
                    "item_id" => 1,
                    "jumlah" => 1
                ],
                "description" => "Fungsi: Menambahkan unit item/peralatan TIK baru ke transaksi peminjaman yang sudah dibuat.\nPermission/Role: Terautentikasi.\nCatatan: Menggunakan POST ke /api/pinjam/{id} sesuai kontrak backend asli."
            ]
        ),
        makePostmanItem(
            "DELETE Hapus Item dari Peminjaman",
            "DELETE",
            "/pinjam/1/item/1",
            [
                "public" => false,
                "description" => "Fungsi: Menghapus item tertentu dari daftar transaksi peminjaman.\nPermission/Role: Terautentikasi.\nCatatan: Path /pinjam/{p}/item/{id} di mana {p} adalah ID peminjaman dan {id} adalah ID pivot item (pinjam_item.id)."
            ]
        ),
        makePostmanItem(
            "DELETE Hapus/Batal Peminjaman",
            "DELETE",
            "/pinjam/1",
            [
                "public" => false,
                "description" => "Fungsi: Membatalkan/menghapus pengajuan peminjaman aset TIK.\nPermission/Role: Terautentikasi.\nCatatan: Hanya dapat dilakukan jika status pengajuan belum diproses oleh admin."
            ]
        )
    ]
];

// ----------------------------------------------------------------------------
// FOLDER 4: 03 - Konsultasi TIK
// ----------------------------------------------------------------------------
$folders[] = [
    "name" => "03 - Konsultasi TIK",
    "item" => [
        makePostmanItem(
            "GET List Tiket Konsultasi",
            "GET",
            "/konsul",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil daftar tiket konsultasi TIK milik pengguna (atau seluruh tiket jika Admin/Petugas).\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "POST Buat Tiket Konsultasi Baru",
            "POST",
            "/konsul",
            [
                "public" => false,
                "body" => [
                    "topik_id" => 1,
                    "judul" => "Konsultasi Integrasi Domain OPD",
                    "keluhan" => "Meminta arahan mengenai konfigurasi DNS dan SSL wildcard."
                ],
                "description" => "Fungsi: Membuat tiket permohonan konsultasi TIK baru.\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "GET Detail Tiket Konsultasi",
            "GET",
            "/konsul/1",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil detail tiket konsultasi beserta riwayat balasan/tanggapan dari tim teknis.\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "POST Balas Tiket Konsultasi",
            "POST",
            "/konsul/1/response",
            [
                "public" => false,
                "body" => [
                    "pesan" => "Tanggapan awal dari tim teknis Diskominfotik."
                ],
                "description" => "Fungsi: Mengirimkan pesan balasan/tanggapan baru pada tiket konsultasi.\nPermission/Role: Terautentikasi (Pemilik tiket / Tim teknis)."
            ]
        ),
        makePostmanItem(
            "POST Update Status Tiket Konsultasi (Admin)",
            "POST",
            "/konsul/1/status",
            [
                "public" => false,
                "body" => [
                    "status" => "selesai"
                ],
                "description" => "Fungsi: Memperbarui status tiket konsultasi (proses / selesai / tutup).\nPermission/Role: Admin / Petugas TIK."
            ]
        ),
        makePostmanItem(
            "DELETE Hapus Tiket Konsultasi",
            "DELETE",
            "/konsul/1",
            [
                "public" => false,
                "description" => "Fungsi: Menghapus tiket konsultasi TIK.\nPermission/Role: Terautentikasi."
            ]
        )
    ]
];

// ----------------------------------------------------------------------------
// FOLDER 5: 04 - Item/Alat TIK
// ----------------------------------------------------------------------------
$folders[] = [
    "name" => "04 - Item/Alat TIK",
    "item" => [
        makePostmanItem(
            "GET List Singkat Item",
            "GET",
            "/item",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil daftar singkat item/peralatan TIK.\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "GET Katalog Lengkap Item",
            "GET",
            "/items",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil katalog lengkap inventaris peralatan TIK yang tersedia untuk dipinjam.\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "GET Cari Item Berdasarkan Keyword",
            "GET",
            "/items/search/laptop",
            [
                "public" => false,
                "description" => "Fungsi: Mencari inventaris peralatan TIK berdasarkan nama/kata kunci (contoh: 'laptop', 'proyektor').\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "GET Detail Item Peralatan TIK",
            "GET",
            "/items/1",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil detail spesifikasi dan kondisi peralatan TIK berdasarkan ID.\nPermission/Role: Terautentikasi."
            ]
        )
    ]
];

// ----------------------------------------------------------------------------
// FOLDER 6: 05 - Topik & FAQ
// ----------------------------------------------------------------------------
$folders[] = [
    "name" => "05 - Topik & FAQ",
    "item" => [
        makePostmanItem(
            "GET Daftar Topik Konsultasi",
            "GET",
            "/topik",
            [
                "public" => true,
                "description" => "Fungsi: Mengambil daftar topik kategori layanan dan konsultasi TIK.\nPermission/Role: Publik / Terautentikasi."
            ]
        ),
        makePostmanItem(
            "GET Daftar FAQ",
            "GET",
            "/faq",
            [
                "public" => true,
                "description" => "Fungsi: Mengambil daftar pertanyaan umum (FAQ) dan solusi masalah TIK.\nPermission/Role: Publik / Terautentikasi."
            ]
        )
    ]
];

// ----------------------------------------------------------------------------
// FOLDER 7: 06 - Rating
// ----------------------------------------------------------------------------
$folders[] = [
    "name" => "06 - Rating",
    "item" => [
        makePostmanItem(
            "GET List Rating & Ulasan",
            "GET",
            "/rating",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil daftar ulasan dan rating kepuasan yang telah dikirim oleh pengguna.\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "POST Submit Rating Kepuasan",
            "POST",
            "/rating",
            [
                "public" => false,
                "body" => [
                    "layanan_type" => "peminjaman",
                    "layanan_id" => 1,
                    "bintang" => 5,
                    "ulasan" => "Sangat memuaskan dan cepat"
                ],
                "description" => "Fungsi: Mengirimkan penilaian bintang (1-5) dan ulasan setelah selesai menerima layanan.\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "POST Update Rating Kepuasan",
            "POST",
            "/rating/update",
            [
                "public" => false,
                "body" => [
                    "layanan_type" => "peminjaman",
                    "layanan_id" => 1,
                    "bintang" => 4,
                    "ulasan" => "Pelayanan bagus, dikembangkan lebih baik lagi"
                ],
                "description" => "Fungsi: Memperbarui ulasan dan penilaian bintang yang pernah dikirim sebelumnya.\nPermission/Role: Terautentikasi."
            ]
        )
    ]
];

// ----------------------------------------------------------------------------
// FOLDER 8: 07 - Layanan Internet (Router)
// ----------------------------------------------------------------------------
$folders[] = [
    "name" => "07 - Layanan Internet (Router)",
    "item" => [
        makePostmanItem(
            "GET List Router OPD",
            "GET",
            "/list-router-opd",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil data daftar router dan status perangkat jaringan pada lokasi Perangkat Daerah (OPD).\nPermission/Role: Terautentikasi."
            ]
        )
    ]
];

// ----------------------------------------------------------------------------
// FOLDER 9: 08 - Usulan Email Resmi
// ----------------------------------------------------------------------------
$folders[] = [
    "name" => "08 - Usulan Email Resmi",
    "item" => [
        makePostmanItem(
            "GET Data Pegawai Tanpa Email Resmi (FR-B07)",
            "GET",
            "/pegawai",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil daftar data pegawai BKD yang belum terdaftar memiliki email resmi @lampungprov.go.id.\nPermission/Role: Terautentikasi (BKD/Admin)."
            ]
        ),
        makePostmanItem(
            "POST Buat Pengajuan Email Resmi Baru",
            "POST",
            "/pengajuan-email",
            [
                "public" => false,
                "body" => [
                    "nama_pegawai" => "Ahmad Subardjo",
                    "nip" => "198501012010011001",
                    "jabatan" => "Pranata Komputer",
                    "email_diusulkan" => "ahmad.subardjo@lampungprov.go.id",
                    "no_hp" => "081298765432"
                ],
                "description" => "Fungsi: Mengajukan permohonan pembuatan email resmi instansi baru untuk pegawai.\nPermission/Role: Terautentikasi (User/BKD)."
            ]
        ),
        makePostmanItem(
            "GET List Pengajuan Email Resmi",
            "GET",
            "/pengajuan-email",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil daftar pengajuan permohonan email resmi BKD.\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "GET Detail Usulan Email Resmi",
            "GET",
            "/pengajuan-email/1",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil detail usulan pengajuan email resmi berdasarkan ID.\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "POST Verifikasi Pengajuan Email (BKD)",
            "POST",
            "/pengajuan-email/1/verifikasi",
            [
                "public" => false,
                "body" => [
                    "catatan" => "Dokumen pendukung valid"
                ],
                "description" => "Fungsi: Memverifikasi keabsahan berkas usulan email resmi.\nPermission/Role: Tim Verifikator BKD / Admin."
            ]
        ),
        makePostmanItem(
            "POST Buat Email Resmi (Admin Operator)",
            "POST",
            "/pengajuan-email/1/buat-email-resmi",
            [
                "public" => false,
                "body" => [
                    "email_resmi" => "ahmad.subardjo@lampungprov.go.id",
                    "catatan" => "Email resmi berhasil dibuat di cPanel/Mail Server"
                ],
                "description" => "Fungsi: Menyetujui dan mencatat akun email resmi yang telah berhasil di-generate pada mail server.\nPermission/Role: Admin Operator Diskominfotik."
            ]
        ),
        makePostmanItem(
            "POST Tolak Pengajuan Email",
            "POST",
            "/pengajuan-email/1/tolak-email",
            [
                "public" => false,
                "body" => [
                    "alasan_penolakan" => "NIP tidak sesuai dengan pangkalan data BKD"
                ],
                "description" => "Fungsi: Menolak pengajuan permohonan email resmi beserta catatan/alasan penolakan.\nPermission/Role: Admin / Verifikator BKD."
            ]
        )
    ]
];

// ----------------------------------------------------------------------------
// FOLDER 10: 09 - Pengumuman
// ----------------------------------------------------------------------------
$folders[] = [
    "name" => "09 - Pengumuman",
    "item" => [
        makePostmanItem(
            "GET List Pengumuman Resmi",
            "GET",
            "/pengumuman",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil daftar pengumuman resmi portal layanan TIK.\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "POST Buat Pengumuman Baru (Admin)",
            "POST",
            "/pengumuman",
            [
                "public" => false,
                "body" => [
                    "judul" => "Pemeliharaan Jaringan Utama TIK",
                    "isi" => "Diberitahukan bahwa akan dilakukan maintenance jaringan pada hari Sabtu jam 20:00 WIB.",
                    "status" => "1"
                ],
                "description" => "Fungsi: Menerbitkan pengumuman resmi baru ke seluruh pengguna.\nPermission/Role: Admin / Superadmin."
            ]
        )
    ]
];

// ----------------------------------------------------------------------------
// FOLDER 11: 10 - Kritik & Saran
// ----------------------------------------------------------------------------
$folders[] = [
    "name" => "10 - Kritik & Saran",
    "item" => [
        makePostmanItem(
            "POST Kirim Kritik & Saran (Publik)",
            "POST",
            "/kritik-saran",
            [
                "public" => true,
                "body" => [
                    "nama" => "Pengunjung Test",
                    "email" => "pengunjung@test.com",
                    "subjek" => "Saran Layanan",
                    "pesan" => "Mohon tingkatkan kecepatan layanan server."
                ],
                "description" => "Fungsi: Mengirimkan masukan, kritik, atau saran masyarakat ke pengelola portal.\nPermission/Role: Publik."
            ]
        ),
        makePostmanItem(
            "GET Pencarian Kritik & Saran Publik",
            "GET",
            "/kritik-saran/search?keyword=Saran",
            [
                "public" => true,
                "description" => "Fungsi: Mencari masukan kritik & saran publik berdasarkan kata kunci.\nPermission/Role: Publik."
            ]
        ),
        makePostmanItem(
            "GET Admin List Kritik & Saran",
            "GET",
            "/admin/kritik-saran",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil seluruh pesan kritik & saran untuk kebutuhan manajemen panel admin.\nPermission/Role: Admin Operator."
            ]
        ),
        makePostmanItem(
            "POST Admin Hapus Masal Kritik & Saran",
            "POST",
            "/admin/kritik-saran/bulk-delete",
            [
                "public" => false,
                "body" => [
                    "ids" => [1]
                ],
                "description" => "Fungsi: Menghapus beberapa baris pesan kritik & saran sekaligus.\nPermission/Role: Admin Operator."
            ]
        )
    ]
];

// ----------------------------------------------------------------------------
// FOLDER 12: 11 - Chatbot Lama (Chatbase)
// ----------------------------------------------------------------------------
$folders[] = [
    "name" => "11 - Chatbot Lama (Chatbase)",
    "item" => [
        makePostmanItem(
            "GET Config & URL Chatbase Iframe",
            "GET",
            "/chatbot",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil URL iframe & data konfigurasi Chatbot legacy (integrasi Chatbase.co).\nPermission/Role: Terautentikasi."
            ]
        )
    ]
];

// ----------------------------------------------------------------------------
// FOLDER 13: 12 - Panel Admin
// ----------------------------------------------------------------------------
$folders[] = [
    "name" => "12 - Panel Admin (User, Role, Slider, Setting, Notification)",
    "item" => [
        makePostmanItem(
            "GET List Notifikasi System",
            "GET",
            "/notifications",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil daftar notifikasi sistem milik pengguna / admin.\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "POST Tandai Notifikasi Dibaca",
            "POST",
            "/notifications/1/read",
            [
                "public" => false,
                "description" => "Fungsi: Mengubah status notifikasi menjadi sudah dibaca (read=1).\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "GET List User Sistem",
            "GET",
            "/admin/users",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil daftar seluruh pengguna terdaftar dalam sistem.\nPermission/Role: Admin / Superadmin."
            ]
        ),
        makePostmanItem(
            "POST Buat User Sistem Baru",
            "POST",
            "/admin/users",
            [
                "public" => false,
                "body" => [
                    "name" => "User Admin Created",
                    "email" => "useradmincreated@lampungprov.go.id",
                    "username" => "useradmincreated",
                    "no_hp" => "081234123412",
                    "nama_opd" => "Dinas Komunikasi Informasi dan Statistik",
                    "password" => "password123",
                    "role" => "user"
                ],
                "description" => "Fungsi: Menambahkan akun pengguna baru secara manual dari panel admin.\nPermission/Role: Admin / Superadmin."
            ]
        ),
        makePostmanItem(
            "GET Detail User",
            "GET",
            "/admin/users/2",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil detail profil dan role pengguna berdasarkan ID.\nPermission/Role: Admin / Superadmin."
            ]
        ),
        makePostmanItem(
            "PUT Update Data User",
            "PUT",
            "/admin/users/2",
            [
                "public" => false,
                "body" => [
                    "name" => "Updated Name Test User",
                    "no_hp" => "081299998888"
                ],
                "description" => "Fungsi: Memperbarui data pengguna dari panel admin.\nPermission/Role: Admin / Superadmin."
            ]
        ),
        makePostmanItem(
            "POST Aktivasi Akun User",
            "POST",
            "/admin/users/2/activate",
            [
                "public" => false,
                "description" => "Fungsi: Mengubah status akun pengguna menjadi aktif (status='1').\nPermission/Role: Admin / Superadmin."
            ]
        ),
        makePostmanItem(
            "POST Nonaktifkan Akun User",
            "POST",
            "/admin/users/2/deactivate",
            [
                "public" => false,
                "description" => "Fungsi: Mengubah status akun pengguna menjadi non-aktif (status='0').\nPermission/Role: Admin / Superadmin."
            ]
        ),
        makePostmanItem(
            "DELETE Hapus Akun User",
            "DELETE",
            "/admin/users/2",
            [
                "public" => false,
                "description" => "Fungsi: Menghapus akun pengguna dari database.\nPermission/Role: Admin / Superadmin."
            ]
        ),
        makePostmanItem(
            "GET List Roles",
            "GET",
            "/admin/roles",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil daftar Role (hak akses) terdaftar.\nPermission/Role: Admin / Superadmin."
            ]
        ),
        makePostmanItem(
            "POST Buat Role Baru",
            "POST",
            "/admin/roles",
            [
                "public" => false,
                "body" => [
                    "name" => "operator_test",
                    "permissions" => ["view dashboard"]
                ],
                "description" => "Fungsi: Membuat Role baru beserta penetapan daftar permission.\nPermission/Role: Admin / Superadmin."
            ]
        ),
        makePostmanItem(
            "GET Detail Role & Permission",
            "GET",
            "/admin/roles/1",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil detail Role beserta daftar permission terikat.\nPermission/Role: Admin / Superadmin."
            ]
        ),
        makePostmanItem(
            "PUT Update Role & Permission",
            "PUT",
            "/admin/roles/1",
            [
                "public" => false,
                "body" => [
                    "name" => "operator_updated",
                    "permissions" => ["view dashboard"]
                ],
                "description" => "Fungsi: Memperbarui nama Role dan daftar permission terkait.\nPermission/Role: Admin / Superadmin."
            ]
        ),
        makePostmanItem(
            "DELETE Hapus Role",
            "DELETE",
            "/admin/roles/1",
            [
                "public" => false,
                "description" => "Fungsi: Menghapus Role hak akses.\nPermission/Role: Admin / Superadmin."
            ]
        ),
        makePostmanItem(
            "GET List All Permissions",
            "GET",
            "/admin/permissions",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil daftar seluruh Permission sistem yang tersedia (Spatie Laravel Permission).\nPermission/Role: Admin / Superadmin."
            ]
        ),
        makePostmanItem(
            "GET System Settings (m_settings)",
            "GET",
            "/admin/settings",
            [
                "public" => false,
                "description" => "Fungsi: Mengambil konfigurasi variabel aplikasi dari tabel m_settings.\nPermission/Role: Admin / Superadmin."
            ]
        ),
        makePostmanItem(
            "PUT Update System Settings",
            "PUT",
            "/admin/settings",
            [
                "public" => false,
                "body" => [
                    "app_name" => "Layanan TIK Lampung",
                    "running_text" => "Selamat Datang di Portal TIK Diskominfotik Provinsi Lampung"
                ],
                "description" => "Fungsi: Memperbarui nilai variabel konfigurasi aplikasi (nama aplikasi, running text, dll).\nPermission/Role: Admin / Superadmin."
            ]
        )
    ]
];

// ----------------------------------------------------------------------------
// FOLDER 14: 13 - Fitur Baru - WhatsApp (F-WA)
// ----------------------------------------------------------------------------
$folders[] = [
    "name" => "13 - Fitur Baru - WhatsApp (F-WA)",
    "item" => [
        makePostmanItem(
            "POST Subscribe Notifikasi WhatsApp",
            "POST",
            "/notifikasi/wa/subscribe",
            [
                "public" => false,
                "body" => [
                    "nomor_wa" => "081234567890"
                ],
                "description" => "Fungsi: Fitur Baru F-WA: Mendaftarkan nomor WhatsApp pengguna untuk menerima notifikasi pesan otomatis.\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "GET Status Notifikasi WhatsApp",
            "GET",
            "/notifikasi/wa/status",
            [
                "public" => false,
                "description" => "Fungsi: Fitur Baru F-WA: Mengambil status pendaftaran notifikasi WhatsApp pengguna aktif.\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "DELETE Unsubscribe Notifikasi WhatsApp",
            "DELETE",
            "/notifikasi/wa/subscribe",
            [
                "public" => false,
                "description" => "Fungsi: Fitur Baru F-WA: Membatalkan/opt-out layanan pengiriman notifikasi WhatsApp.\nPermission/Role: Terautentikasi."
            ]
        )
    ]
];

// ----------------------------------------------------------------------------
// FOLDER 15: 14 - Fitur Baru - Chatbot Native (F-BOT)
// ----------------------------------------------------------------------------
$folders[] = [
    "name" => "14 - Fitur Baru - Chatbot Native (F-BOT)",
    "item" => [
        makePostmanItem(
            "POST Kirim Pesan Chatbot AI Gelatik",
            "POST",
            "/chatbot/message",
            [
                "public" => false,
                "body" => [
                    "message" => "Bagaimana cara mengajukan peminjaman aset TIK?"
                ],
                "description" => "Fungsi: Fitur Baru F-BOT: Mengirim pesan pertanyaan ke engine AI Chatbot Gelatik Native dan memperoleh jawaban otomatis.\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "GET Riwayat Chatbot Native",
            "GET",
            "/chatbot/history",
            [
                "public" => false,
                "description" => "Fungsi: Fitur Baru F-BOT: Mengambil riwayat percakapan interaktif pengguna dengan AI Chatbot Gelatik.\nPermission/Role: Terautentikasi."
            ]
        ),
        makePostmanItem(
            "DELETE Hapus Riwayat Chatbot Native",
            "DELETE",
            "/chatbot/history",
            [
                "public" => false,
                "description" => "Fungsi: Fitur Baru F-BOT: Menghapus seluruh riwayat obrolan pengguna dengan AI Chatbot.\nPermission/Role: Terautentikasi."
            ]
        )
    ]
];

// ----------------------------------------------------------------------------
// FOLDER 16: 15 - Fitur Baru - Laporan (F-LAPORAN)
// ----------------------------------------------------------------------------
$folders[] = [
    "name" => "15 - Fitur Baru - Laporan (F-LAPORAN)",
    "item" => [
        makePostmanItem(
            "GET Laporan Rekapitulasi Peminjaman Aset",
            "GET",
            "/laporan/peminjaman",
            [
                "public" => false,
                "query_params" => [
                    "bulan" => "07",
                    "tahun" => "2026"
                ],
                "description" => "Fungsi: Fitur Baru F-LAPORAN: Mengambil laporan rekapitulasi data peminjaman aset TIK.\nPermission/Role: Admin / BKD / Superadmin.\nCatatan: Mendukung filter query string 'bulan' dan 'tahun' atau 'filter' dan 'tanggal'."
            ]
        ),
        makePostmanItem(
            "GET Realtime Service Health Check",
            "GET",
            "http://127.0.0.1:4000/health",
            [
                "public" => true,
                "full_url" => true,
                "description" => "Fungsi: Memeriksa status kesehatan server Socket.io & Realtime Express service (Port 4000).\nPermission/Role: Publik."
            ]
        )
    ]
];


// ============================================================================
// 4. ASSEMBLE POSTMAN COLLECTION JSON
// ============================================================================

$collectionData = [
    "info" => [
        "_postman_id" => "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "name" => "LayananTIK Backend API",
        "description" => "Postman Collection Lengkap Kontrak API Backend Layanan TIK (Laravel 11 + Realtime Service Socket.io + WA Gateway) untuk Developer Web & Mobile.",
        "schema" => "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    ],
    "item" => $folders
];

file_put_contents($collectionPath, json_encode($collectionData, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
echo "Collection written to: $collectionPath\n";

// Count total requests
$totalRequests = 0;
foreach ($folders as $f) {
    $totalRequests += count($f['item']);
}

echo "SUCCESS! Total requests created in collection: $totalRequests\n";
