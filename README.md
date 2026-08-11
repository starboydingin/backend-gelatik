# 🚀 BACKEND TERPADU (LAYANAN TIK WEB + ULTIMOBILE GELATIK)

Aplikasi Backend Terpadu ini dikembangkan menggunakan **Laravel 11 (PHP 8.3)** dan **Node.js Realtime Service (Express + Socket.io + WhatsApp Web JS)** untuk mengelola layanan TIK Pemprov Lampung (Peminjaman Aset TIK, Konsultasi TIK, Chatbot AI Gelatik, Notifikasi Realtime & WhatsApp Gateway).

---

## 🛠️ 1. PRASYARAT SISTEM

Sebelum menjalankan aplikasi, pastikan perangkat server/lokal telah terinstall software berikut:

* **PHP:** Versi 8.2 atau 8.3+ (Ekstensi wajib: `pdo_mysql`, `mbstring`, `curl`, `json`, `openssl`, `zip`)
* **Composer:** Versi 2.x+
* **Database:** MySQL 8.0+ atau MariaDB 10.4+
* **Node.js:** Versi 18.x / 20.x+ (dengan `npm`)
* **Web Server (Opsional Production):** Nginx atau Apache (Support URL Rewriting & HTTPS)

---

## 📥 2. LANGKAH SETUP DARI NOL (PENGEMBANGAN / SERAH TERIMA LOKAL)

Ikuti langkah-langkah berikut untuk memasang aplikasi dari awal:

### Langkah A: Setup Backend Utama (Laravel)

1. **Copy/Extract Project** ke direktori kerja (misalnya `E:/Adwika/AdwikaPerkuliahan/KP-BACKEND/backend`).
2. **Install Dependensi Composer:**
   ```bash
   composer install
   ```
3. **Copy File Environment:**
   ```bash
   cp .env.example .env
   ```
4. **Buat Database MySQL Baru:**
   Buat database kosong bernama `db_layanantik` melalui phpMyAdmin atau MySQL CLI:
   ```sql
   CREATE DATABASE db_layanantik CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```
5. **Import Skema Database Lengkap:**
   Import file `database/schema_lengkap.sql` yang berisi struktur 37 tabel lengkap:
   ```bash
   mysql -u root db_layanantik < database/schema_lengkap.sql
   ```
   *(Atau import file `database/schema_lengkap.sql` secara manual lewat tab Import di phpMyAdmin)*
6. **Generate Application Key & OAuth Passport Keys:**
   ```bash
   php artisan key:generate
   php artisan passport:keys
   ```
7. **Jalankan Migrasi Tambahan (Opsional):**
   ```bash
   php artisan migrate
   ```

---

### Langkah B: Setup Service Realtime & WhatsApp (Node.js)

1. Masuk ke direktori `realtime-service`:
   ```bash
   cd ../realtime-service
   ```
2. **Install Dependensi NPM:**
   ```bash
   npm install
   ```
3. **Copy File Environment Node.js:**
   ```bash
   cp .env.example .env
   ```
4. Pastikan nilai `INTERNAL_SERVICE_API_KEY` di `realtime-service/.env` **SAMA PERSIS** dengan `INTERNAL_SERVICE_API_KEY` di file `.env` Laravel.

---

## ⚙️ 3. KONFIGURASI PRODUCTION (HANDOVER TIM TIK)

Sebelum melakukan deployment ke server production / server resmi Diskominfotik, **TIM TIK WAJIB** mengisi environment variable dengan kredensial asli (seperti IP Database Production, Key Gemini/Groq, Token SIMKI, dan Firebase Credentials).

> 📌 Silakan baca dokumen panduan terpusat:  
> **[KONFIGURASI_PRODUCTION.md](KONFIGURASI_PRODUCTION.md)**

---

## ⚡ 4. CARA MENJALANKAN APLIKASI (DUA SERVICE BERSAMAAN)

Aplikasi ini menggunakan arsitektur *micro-services* terpisah. **DUA PROSES BERIKUT HARUS DIJALANKAN BERSAMAAN**:

### Service 1: Backend Laravel (Port 8000)
Jalankan di terminal 1:
```bash
cd backend
php artisan serve
```
*Aplikasi REST API Laravel akan berjalan di `http://127.0.0.1:8000`*

### Service 2: Node.js Realtime & WA Service (Port 4000)
Jalankan di terminal 2:
```bash
cd realtime-service
npm start
```
*Service Node.js WebSocket & WA Gateway akan berjalan di `http://127.0.0.1:4000`*

---

## 📁 5. STRUKTUR FOLDER UTAMA

```text
KP-BACKEND/
├── backend/                              # Main Application (Laravel 11)
│   ├── app/
│   │   ├── Http/Controllers/Api/         # 70+ Endpoint Controllers (API)
│   │   ├── Models/                       # Eloquent ORM Models (37 Tabel)
│   │   ├── Services/                     # Business Logic Layer (Dashboard, Pinjam, Chatbot, dll)
│   │   └── Listeners/                    # Event Listeners (WA Notif & FCM Push)
│   ├── database/
│   │   ├── schema_lengkap.sql            # Export DDL Struktur 37 Tabel Database
│   │   └── migrations/                   # Database Migrations
│   ├── routes/
│   │   └── api.php                       # Seluruh Route API Laravel
│   ├── KONFIGURASI_PRODUCTION.md         # Tabel Panduan Kredensial Tim TIK
│   └── README.md                         # Dokumen Panduan Utama
└── realtime-service/                     # Microservice Node.js (Socket.io & WA Gateway)
    ├── src/                              # Source Code Express & Baileys/WA Web JS
    ├── package.json                      # NPM Dependencies
    └── .env.example                      # Environment Node.js
```

---

## 🛡️ 6. KEAMANAN & TOLERANSI KEGAGALAN (DEFENSIVE DESIGN)

* **Standalone Local Mode:** Seluruh endpoint utama (Peminjaman Aset, Konsultasi TIK, Auth, Pengumuman, Laporan) dapat berjalan 100% tanpa jaringan internal/VPN Diskominfotik.
* **Defensive Fallback:** Kegagalan service opsional (Node.js WA service mati, SIMKI API offline, Gemini AI limit) diproteksi menggunakan `try-catch` dan `timeout(5)` sehingga **TIDAK AKAN memutus respon HTTP (tidak ada Error 500)** pada request utama klien.

---

## 7. BASIS PENGETAHUAN FAQ CHATBOT

Chatbot mengambil maksimal tiga FAQ aktif yang paling relevan berdasarkan judul, topik, dan isi FAQ. FAQ tersebut menjadi konteks resmi bagi Gemini/Groq saat menjawab, bersama riwayat percakapan dan konteks data pengguna yang sesuai. Perubahan pada FAQ aktif di database akan digunakan pada pertanyaan berikutnya tanpa pelatihan ulang model AI.

Snapshot FAQ aktif pada database development:

| Pertanyaan | Ringkasan jawaban resmi |
| --- | --- |
| Cara mendapatkan akun email resmi Pemprov Lampung | Ajukan surat permohonan melalui BKD dengan fotokopi e-KTP dan SK jabatan terakhir. |
| Cara pinjam aset/perangkat untuk video conference | Login, buka Pinjam Aset, isi formulir dan tanggal, pilih perangkat; gunakan Logitech Group dan Operator Vicon bila diperlukan. |
| Cara request Room ID Zoom | Melalui Pinjam Aset: isi formulir/tanggal, pilih item Akun Zoom Meeting, lalu simpan. |
| Cara pinjam aset/perangkat live streaming | Isi formulir, tulis kebutuhan live streaming, pilih perangkat; gunakan Logitech Group dan Operator Live Streaming bila diperlukan. |
| Cara melihat hasil live streaming | Lihat melalui kanal YouTube resmi Pemprov Lampung. |
| Cara mengajukan sertifikat elektronik/TTE | Login, buka Konsultasi TIK, lengkapi data pejabat, unggah surat instansi, lalu kirim. |
| Cara memakai TTE pada E-Sughat | Buka e-sughat.lampungprov.go.id, login, pilih dokumen, pilih Tandatangani, lalu masukkan passphrase. |
| Kustomisasi website perangkat daerah | Kirim surat permintaan custom website beserta rancangan dan proses bisnis ke Bagian SPBE Diskominfotik. |
| Pengajuan reset kata sandi email resmi | Pastikan email ASN dan pribadi terdaftar di SIMPEDU, isi formulir reset, lalu ikuti instruksi yang masuk ke email pribadi. |
| Regulasi penggunaan email resmi Pemprov Lampung | Email resmi digunakan untuk komunikasi dan administrasi kedinasan berbasis TIK. |
| Apa itu hosting web/aplikasi? | Layanan penyimpanan website atau aplikasi agar dapat diakses secara online. |
| Cara mengajukan alokasi hosting Pemprov Lampung | Pastikan dokumen SPBE dan uji keamanan/fungsi tersedia, lalu ajukan lewat Konsultasi TIK pada topik Hosting dan unggah surat permohonan. |
| Cara mengajukan subdomain resmi Pemprov Lampung | Isi formulir pengajuan, lalu ajukan melalui Konsultasi TIK pada topik Subdomain Resmi. |
| WiFi di ruangan mati | Cek perangkat, router/access point, kabel, dan gangguan jaringan; bila belum selesai hubungi helpdesk di `+62 813-7330-4040`. |
| WiFi terhubung tetapi tidak ada internet | Uji perangkat lain, restart/lupakan WiFi, cek indikator, DNS, dan DHCP; hubungi helpdesk bila masalah berlanjut. |
| Pertanyaan Test 1 | Jawaban Test 1. Ini adalah data testing yang masih aktif dan sebaiknya dinonaktifkan atau dihapus melalui admin sebelum production. |
