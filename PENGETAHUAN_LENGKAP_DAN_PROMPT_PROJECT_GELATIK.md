# Pengetahuan Lengkap dan Prompt Project Gelatik

> Snapshot audit source: 1 September 2026, zona waktu Asia/Jakarta. Dokumen ini membaca source aktif beserta perubahan lokal yang belum di-commit. Jika isi dokumen bertentangan dengan source pada masa mendatang, gunakan source aktif sebagai sumber kebenaran.

## 1. Ringkasan Eksekutif

Gelatik adalah platform layanan TIK terpadu untuk lingkungan Pemerintah Provinsi Lampung/Diskominfotik. Sistem ini menghubungkan pegawai/OPD, petugas BKD, admin operator, dan superadmin dalam satu ekosistem layanan.

Ruang lingkup layanan utama:

- autentikasi, profil, activity log, dan pengelolaan akun;
- dashboard, kalender aktivitas, slider, dan pengumuman;
- peminjaman aset/perangkat TIK;
- konsultasi dan helpdesk TIK;
- informasi jaringan, router, dan bandwidth OPD/pengguna;
- pengajuan email resmi ASN dengan tahap verifikasi BKD dan penerbitan oleh admin;
- chatbot AI berbasis FAQ/RAG dengan fallback provider dan eskalasi ke konsultasi;
- kritik-saran, balasan admin, dan rating layanan;
- inbox notifikasi, Socket.IO realtime, FCM, dan WhatsApp opt-in;
- laporan peminjaman, konsultasi, dan usulan email dengan ekspor CSV/XLSX;
- pengelolaan master data, role, permission, dan pengaturan aplikasi.

Project adalah monorepo multi-client dengan komponen utama:

```text
Flutter Mobile/Desktop
        │
Vue Website ───────────────┐
        │                  │
        └── REST/HTTP ── Laravel API ── MySQL/MariaDB
                            │
                            ├── Queue/listener
                            ├── Firebase Cloud Messaging
                            ├── Gemini → fallback Groq
                            ├── SIMKI (opsional)
                            └── internal HTTP ── Node.js
                                                  ├── Socket.IO
                                                  └── WhatsApp/Baileys
```

Prinsip paling penting: Laravel REST API dan database adalah sumber kebenaran. Socket.IO hanya mengirim sinyal perubahan; client kemudian mengambil data terbaru melalui REST.

## 2. Struktur Repository

| Lokasi | Fungsi |
|---|---|
| `backend/` | REST API Laravel, aturan bisnis, auth, database access, notifikasi, AI, laporan |
| `website/PKL-TIK-ADIT/` | SPA Vue untuk user, BKD, admin, dan superadmin |
| `gelatik-mobile/` | aplikasi Flutter feature-first |
| `realtime-service/` | Node.js Socket.IO dan WhatsApp gateway |
| `backend/database/schema_lengkap.sql` | baseline schema database legacy |
| `backend/database/migrations/` | perubahan schema incremental |
| `layanantik-backend-api.postman_collection.json` | koleksi pengujian API |
| `docs/` | audit performa, realtime registry, IDDS upgrade, dan dokumen teknis |
| `prd_backend_baru.md`, `srs_backend_baru.md` | kebutuhan produk dan perangkat lunak historis |
| `KONFIGURASI_PRODUCTION.md` | panduan variabel/kredensial production |

Footprint source pada snapshot audit:

- 120 deklarasi route API;
- 28 controller API;
- 23 service Laravel;
- 26 model Eloquent;
- 37 view Vue;
- 43 screen Flutter.

Angka tersebut adalah inventaris snapshot, bukan batas arsitektur permanen.

Urutan sumber kebenaran:

1. source aktif dan konfigurasi runtime;
2. schema dan migration aktif;
3. automated test;
4. Postman Collection;
5. PRD/SRS terbaru;
6. README;
7. laporan audit historis.

## 3. Aktor, Role, dan Batas Kewenangan

| Role | Kewenangan utama |
|---|---|
| `user` | memakai layanan dan hanya mengakses data privat miliknya |
| `bkd` | memverifikasi atau menolak usulan email ASN; tidak menerbitkan email resmi |
| `admin` | operasi layanan, status peminjaman/konsultasi, penerbitan email, master data, notifikasi, laporan |
| `superadmin` | seluruh kemampuan admin serta pengelolaan role/akun istimewa tertentu |

Aturan otorisasi penting:

- role dari payload registrasi publik tidak dipercaya; backend selalu menetapkan role `user`;
- registrasi saat ini langsung membuat akun aktif dan mengembalikan token;
- akun existing dengan `status != 1` ditolak saat login;
- user hanya melihat peminjaman, konsultasi, usulan email, attachment, dan notifikasi yang diizinkan;
- admin/superadmin dapat melihat data operasional global sesuai policy dan middleware;
- hanya BKD yang memverifikasi/menolak usulan email;
- hanya admin/superadmin yang menerbitkan alamat email resmi setelah verifikasi BKD;
- pembuatan akun admin melalui endpoint admin dibatasi superadmin;
- `/dev/provision-account` hanya terdaftar pada environment `local`/`testing`.

## 4. Mobile Flutter

### 4.1 Arsitektur Mobile

Mobile menggunakan pola feature-first:

```text
lib/
├── core/
│   ├── network/       Dio, auth header, cache
│   ├── realtime/      Socket.IO dan invalidasi data
│   ├── storage/       secure storage
│   ├── theme/         design tokens dan Material theme
│   ├── services/      layanan lintas fitur
│   └── widgets/       reusable components
└── features/
    ├── admin, auth, calendar, chatbot, email, home
    ├── info_alat, internet, konsultasi, kritik_saran
    ├── notifications, peminjaman, profil, rating
    ├── services, shell, dan showcase
```

Riverpod menjadi state management dan dependency injection. Repository berkomunikasi dengan REST API melalui Dio. Bearer token disimpan dengan Flutter Secure Storage. GET response memakai cache in-memory dan cache persisten SharedPreferences sebagai resilience layer; realtime dapat menginvalidasi resource terkait.

Repository memiliki scaffold target Android, iOS, Windows, Linux, macOS, dan web. Kesiapan production setiap target tetap harus dibuktikan dengan build/test target tersebut; jangan menyamakan keberadaan folder platform dengan kesiapan rilis.

### 4.2 Navigasi Mobile

`MainShell` menjaga state tab dengan `IndexedStack`:

- Beranda;
- Layanan;
- Notifikasi;
- Profil;
- Admin untuk role `admin`, `superadmin`, dan saat ini juga `bkd`.

Floating action button di Beranda membuka chatbot native. Detail fitur memakai `Navigator`/`MaterialPageRoute`.

### 4.3 Fitur Mobile Pengguna

#### Autentikasi dan akun

- splash dan pemulihan sesi;
- login menggunakan email, username, atau NIP;
- show/hide password;
- registrasi nama, NIP 18 digit, email resmi, nomor HP, OPD, dan password minimal 8 karakter;
- validasi OPD dari backend;
- lupa password melalui challenge OTP WhatsApp;
- verifikasi OTP dan reset password;
- logout dan pembersihan sesi/realtime;
- pesan akun nonaktif;
- profil, edit profil, ganti password, dan activity log.

Catatan faktual: backend mengaktifkan akun hasil registrasi secara langsung dan mengembalikan access token. Komponen banner aktivasi masih tersedia untuk menampilkan kondisi akun existing yang memang berstatus nonaktif, bukan sebagai tahap wajib semua registrasi.

#### Dashboard dan navigasi layanan

- greeting personal;
- bento dashboard civic formal;
- ringkasan status layanan user;
- slider/banner pengumuman;
- pengumuman aktif;
- kalender aktivitas;
- shortcut layanan;
- informasi bandwidth OPD dan bandwidth pengguna;
- Services screen sebagai katalog layanan;
- floating chatbot assistant.

#### Peminjaman aset

- daftar pengajuan milik user;
- pencarian/filter daftar;
- informasi aset/master item dan stok;
- pilih satu atau lebih aset;
- formulir PIC, identitas, instansi, kontak, alamat, waktu, durasi, dan keterangan;
- durasi harian, jam, atau menit;
- upload dokumen PDF/gambar/DOC/DOCX maksimal sesuai validasi backend;
- detail pengajuan dan status;
- edit, tambah/hapus item, atau hapus pengajuan selama masih `Menunggu`;
- attachment terlindungi;
- status `Menunggu → Proses → Selesai` atau `Menunggu → Ditolak`.

#### Konsultasi TIK

- discovery layanan/topik;
- daftar konsultasi;
- pembuatan konsultasi dengan judul, deskripsi/pertanyaan, dan attachment;
- detail, respons petugas, dan status;
- update/hapus sesuai policy;
- status `Menunggu`, `Diproses`, `Ditolak`, `Selesai`;
- respons admin otomatis mengubah `Menunggu` menjadi `Diproses`.

#### Pengajuan email ASN

- daftar pegawai yang belum memiliki email;
- pencarian pegawai;
- user biasa hanya dapat memilih pegawai sesuai OPD akun;
- pengajuan menggunakan NIP/identifier aman tanpa harus mengekspos `ID_Peg` internal;
- daftar dan detail usulan;
- state menunggu verifikasi BKD, terverifikasi, disetujui, atau ditolak;
- user dapat mengubah usulan sebelum diverifikasi;
- admin mobile memiliki layar daftar/detail usulan.

#### Internet, router, dan bandwidth

- daftar router sesuai OPD user;
- pencarian router;
- informasi koneksi/router aktif;
- bandwidth tiap koneksi OPD;
- bandwidth pengguna dari alokasi akun, fallback dari router OPD, atau status belum tersedia;
- label sumber bandwidth dan indikator inherited dari OPD;
- self-assessment gangguan jaringan;
- arahan menuju konsultasi bila kendala tidak selesai.

Perubahan lokal belum di-commit menambahkan `bandwidth_download_mbps` dan `bandwidth_upload_mbps` pada user serta fallback ke router OPD.

#### Chatbot

- chatbot native AI;
- chatbot lama melalui WebView URL aktif;
- riwayat percakapan lintas perangkat berdasarkan percakapan terbaru server;
- FAQ-first untuk pertanyaan yang cocok;
- Gemini sebagai provider utama dan Groq sebagai fallback;
- fallback lokal jika provider tidak tersedia;
- allow-list topik TIK dan blok prompt injection;
- konteks FAQ, data user read-only, dan maksimal lima pesan aman untuk provider;
- eskalasi ke konsultasi setelah tiga saran tidak menyelesaikan kendala;
- chatbot meminta jawaban `iya/tidak`;
- jika `iya`, nama/OPD diambil dari profil dan detail kendala disusun dari keluhan terakhir;
- jika `tidak`, penawaran dibatalkan tanpa membuat tiket;
- transaksi dibuat idempotent agar retry tidak membuat tiket ganda.

#### Feedback dan komunikasi

- kirim kritik-saran;
- nomor referensi dan pencarian publik bila tersedia;
- riwayat serta detail kritik-saran milik user;
- melihat balasan admin;
- rating layanan;
- inbox notifikasi dan read/read-all;
- snackbar realtime ketika aplikasi aktif;
- status/subscribe/unsubscribe WhatsApp opt-in.

### 4.4 Fitur Mobile Admin

- dashboard admin;
- daftar dan detail peminjaman;
- perubahan status peminjaman;
- daftar konsultasi;
- daftar/detail usulan email;
- moderasi kritik-saran.

Mobile belum memiliki portal BKD khusus seperti website. Saat ini role BKD mendapat tab Admin di `MainShell`, tetapi backend tetap membatasi tindakan melalui policy.

### 4.5 Design System Mobile

- Material Design 3, light-only;
- konsep Bento Grid + Friendly Illustrative Civic;
- navy `#1E3A8A` sebagai identitas utama;
- gold `#F59E0B` sebagai highlight/CTA;
- teal `#0F766E` sebagai layanan/proses;
- background `#F8FAFC`, surface putih, border `#E2E8F0`;
- teks utama `#111827`;
- success `#16A34A`, error `#DC2626`;
- radius blok/tombol sekitar 16–20px;
- reusable civic form, bento block, personal greeting, illustration asset, dan bottom navigation;
- hero autentikasi reusable dan widget profil reusable untuk mengurangi duplikasi UI;
- ilustrasi lokal bertema Lampung/Muli-Meghanai;
- theme dark masih alias kompatibilitas ke light theme; `ThemeMode.light` dipaksa pada aplikasi.

### 4.6 Status FCM pada Mobile

Backend memiliki pengiriman FCM nyata melalui Firebase Admin/Kreait. Namun mobile belum memasang `firebase_messaging`; `FcmTopicService` saat ini hanya menyimpan daftar topik di memory dan `debugPrint`. Artinya push notification FCM nyata ke device belum lengkap. Topik yang disimulasikan: `user_{id}`, `pengumuman`, `admin`, dan `bkd`.

## 5. Website Vue

### 5.1 Arsitektur Website

Website adalah SPA mandiri, bukan Blade/Inertia/Filament. Semua data bisnis berasal dari Laravel API.

Lapisan utama:

- Vue component/view untuk UI;
- Vue Router untuk route dan guard;
- Pinia `auth` store untuk sesi/role;
- Axios wrapper untuk API, cache, dan normalisasi response;
- Socket.IO client untuk realtime;
- reusable layout/components;
- Tailwind CSS dan `design-system.css` untuk visual.
- `GovernmentAuthLayout` untuk pengalaman login/registrasi resmi dengan panel informasi, trust indicators, dan ilustrasi Muli-Meghanai.

Komponen penting meliputi AppLayout, AppSidebar, AppHeader, MobileBottomNav, NotificationDropdown, ServiceHero, ScheduleCalendar, SearchableSelect, StatusBadge, pagination, modal, empty/loading/error state, chart, dan form controls.

### 5.2 Halaman Publik

- landing page informasi layanan;
- login;
- registrasi;
- lupa password;
- verifikasi OTP reset password;
- reset password;
- halaman 404.

### 5.3 Portal User `/app`

- dashboard;
- kalender;
- pengumuman;
- peminjaman dan detail;
- konsultasi dan detail;
- pengajuan email resmi dan detail;
- notifikasi;
- FAQ;
- router/bandwidth OPD;
- rating;
- WhatsApp opt-in;
- chatbot;
- profil;
- form umpan balik;
- riwayat kritik-saran.

### 5.4 Portal BKD `/bkd`

- dashboard antrean verifikasi;
- jumlah menunggu, diteruskan ke admin, dan ditolak;
- daftar/detail usulan email;
- verifikasi dokumen;
- penolakan usulan;
- notifikasi yang dibatasi pada broadcast usulan email;
- profil.

BKD tidak dapat menerbitkan alamat email resmi. Sesudah BKD memverifikasi, usulan diteruskan ke admin.

### 5.5 Portal Admin `/admin`

- dashboard KPI operasional;
- peminjaman dan halaman kelola;
- konsultasi dan detail/respons;
- daftar/detail usulan email serta penerbitan email setelah verifikasi BKD;
- pengguna, aktivasi/nonaktivasi, dan bandwidth khusus per akun pada perubahan lokal;
- role dan permission;
- notifikasi admin;
- kritik-saran dan balasan/bulk delete;
- pengaturan aplikasi;
- data pegawai;
- laporan peminjaman;
- laporan konsultasi;
- laporan usulan email;
- pengumuman;
- katalog referensi: item, topik, FAQ, slider, dan router.

### 5.6 Routing dan Sesi Website

- route component di-lazy-load;
- guard mengecek autentikasi serta role user/admin/BKD;
- user tidak dapat masuk portal admin/BKD;
- admin/BKD diarahkan ke portal role masing-masing;
- stale Vite chunk dipulihkan satu kali melalui reload terkontrol;
- token/sesi disimpan per tab menggunakan session storage;
- logout membersihkan session dan koneksi realtime.

### 5.7 Realtime Website

Socket.IO menerima event minimal lalu menginvalidasi cache/resource dan refetch REST. Website tetap dapat dipakai bila socket mati; data diperbarui saat halaman dimuat/refresh.

Website belum memasang Firebase Web Messaging maupun service worker FCM. Jadi push browser melalui FCM belum tersedia; notifikasi website berasal dari inbox REST dan Socket.IO saat portal aktif.

### 5.8 Design System Website

- formal public-service UI, light-only;
- font Urbanist;
- navy `#1E3A8A` sebagai brand/primary action;
- navy kuat `#172E6E` untuk sidebar/header;
- gold `#F59E0B` sebagai highlight;
- teal `#0F766E` sebagai accent/focus;
- background `#F8FAFC`, surface putih;
- border `#E2E8F0`, text `#0F172A`;
- success `#15803D`, warning `#B45309`, danger `#DC2626`, info `#0284C7`;
- control radius 10px, surface radius 14px, soft shadow;
- focus ring 3px teal dan dukungan prefers-reduced-motion.
- landing page, shell, sidebar, dashboard, auth, state components, serta halaman user/BKD/admin telah diselaraskan ke bahasa visual pemerintahan yang konsisten pada perubahan source 1 September 2026.

## 6. Backend Laravel

### 6.1 Peran Laravel

Laravel menangani:

- autentikasi dan otorisasi;
- validasi request;
- aturan dan transaksi bisnis;
- query serta persistence database;
- attachment access;
- event/listener dan queue;
- inbox notifikasi, realtime trigger, FCM, dan WhatsApp orchestration;
- chatbot AI dan RAG;
- dashboard, kalender, serta laporan;
- API contract bagi website dan mobile.

### 6.2 Struktur Backend

| Lapisan | Tanggung jawab |
|---|---|
| Controller | menerima request, validasi sederhana, response JSON |
| Form Request | validasi kompleks peminjaman/konsultasi/email |
| Service | proses bisnis dan transaksi |
| Model | mapping tabel legacy, relasi, casts, scopes |
| Policy/middleware | ownership, role, permission |
| Event/listener | FCM dan efek samping asynchronous |
| Observer | sinyal sinkronisasi model lintas client |
| Export/query | laporan dan ekspor |

Service utama: PinjamService, KonsultasiService, UsulanEmailService, ChatbotService, DashboardService, LayananInternetService, KritikSaranService, RatingService, PengumumanService, FaqService, MasterItemService, PasswordResetOtpService, FcmNotificationService, UserWhatsAppNotificationService, NotificationRealtimeService, RealtimeDataSyncService, AdminNotificationService, AdminAuditService, NodeServiceClient, OfficialEmailValidator, ServiceReportQuery, dan LaporanPeminjamanService.

### 6.3 Autentikasi

- Laravel Passport Bearer token;
- login dengan email, username, atau NIP;
- password hashed;
- status akun wajib aktif;
- registrasi memvalidasi NIP 18 digit, OPD, dan domain email resmi;
- domain resmi dikonfigurasi melalui `OFFICIAL_EMAIL_ALLOWED_DOMAINS` dan default-nya kosong;
- registrasi gagal aman jika daftar domain belum dikonfigurasi;
- registrasi membuat role `user`, status aktif, dan token;
- `/me` memuat relasi roles untuk client/realtime;
- logout me-revoke token aktif;
- reset password me-revoke seluruh token lama.

### 6.4 Reset Password OTP WhatsApp

- hanya memakai nomor WhatsApp subscription yang sudah opt-in;
- OTP 6 digit di-hash;
- berlaku 10 menit;
- cooldown kirim ulang 60 detik;
- maksimal lima percobaan;
- challenge dan reset token sekali pakai;
- reset token 64 karakter disimpan dalam bentuk SHA-256;
- password baru tidak dikirim melalui WhatsApp;
- response forgot-password dibuat generik untuk mengurangi account enumeration;
- alur OTP memerlukan Node.js dan WhatsApp berstatus `connected`.

### 6.5 API Inventory

Semua endpoint berada di prefix `/api`.

#### Publik/internal

- `POST /internal/wa/webhook-delivery-status`
- `POST /login`
- `POST /register`
- `POST /forgot-password`
- `POST /forgot-password/verify`
- `POST /reset-password`
- `POST /dev/provision-account` hanya local/testing
- `GET /opd`
- `POST /kritik-saran`
- `GET /kritik-saran/search`

#### Akun terautentikasi

- `GET/PATCH /me`
- `POST /me/change-password`
- `GET /me/activity-log`
- `POST /logout`

#### Dashboard dan informasi

- `GET /slider`
- `GET /dashboard`
- `GET /dashboard/calendar`
- `GET /pengumuman`

#### Kritik-saran dan rating

- `GET /kritik-saran/mine`
- `GET /kritik-saran/mine/{id}`
- `POST /rating`
- `POST /rating/update`
- `GET /rating`

#### Peminjaman

- `GET/POST /pinjam`
- `GET/PUT/DELETE /pinjam/{id}`
- `POST /pinjam/{id}/status`
- `POST /pinjam/{id}` untuk tambah item
- `DELETE /pinjam/{p}/item/{id}`
- `GET /pinjam/{id}/attachment/{kind?}`
- `GET /item`, `GET /items`, `GET /items/search/{keyword}`, `GET /items/{id}`

#### Konsultasi

- `GET/POST /konsul`
- `GET/PUT/DELETE /konsul/{id}`
- `POST /konsul/{id}/response`
- `POST /konsul/{id}/status`
- attachment konsultasi dan attachment respons;
- `GET /topik`, `GET /faq`.

#### Internet dan email ASN

- `GET /list-router-opd`
- `GET /pegawai`
- `GET/POST /pengajuan-email`
- `GET/PUT /pengajuan-email/{id}`
- `POST /pengajuan-email/{id}/verifikasi`
- `POST /pengajuan-email/{id}/buat-email-resmi`
- `POST /pengajuan-email/{id}/tolak-email`

#### Notifikasi, WhatsApp, dan chatbot

- `GET /notifications`
- `POST /notifications/{id}/read`
- `POST /notifications/read-all`
- `GET/POST/DELETE /notifikasi/wa/...`
- `GET /chatbot` untuk config WebView;
- `POST /chatbot/message`
- `GET /chatbot/conversations/latest`
- `GET/DELETE /chatbot/history`.

#### Admin

- dashboard admin;
- CRUD notifikasi admin;
- CRUD item, topik, FAQ, slider, router, pengumuman;
- daftar/reply/bulk-delete kritik-saran;
- CRUD user serta activate/deactivate;
- CRUD role dan daftar permission;
- GET/PUT settings.

#### Laporan

- `GET /laporan/peminjaman` kompatibilitas lama;
- `GET /laporan/{peminjaman|konsultasi|usulan-email}/data`;
- `GET /laporan/{type}/export?format=csv|xlsx`, throttle 10 request/menit.

### 6.6 Workflow Peminjaman

1. User memilih aset dan mengirim data PIC/durasi.
2. Backend menghitung tanggal selesai.
3. Ketersediaan diperiksa terhadap stok dan overlap pengajuan `Menunggu/Proses`.
4. Header dan item disimpan dalam transaksi.
5. Status awal `Menunggu`.
6. Admin mengubah ke `Proses` atau `Ditolak`.
7. `Proses` dapat menjadi `Selesai`.
8. Bukti pengembalian dapat diunggah saat selesai.
9. User menerima inbox/realtime dan channel eksternal bila tersedia.

Tanggal lampau ditolak. Untuk hari ini, jam mulai harus setelah waktu server Asia/Jakarta. Edit/item/delete hanya diizinkan ketika masih `Menunggu`.

### 6.7 Workflow Konsultasi

1. User memilih topik aktif dan membuat tiket.
2. Status awal `Menunggu`.
3. Admin merespons; status otomatis dapat menjadi `Diproses`.
4. Transisi valid: `Menunggu → Diproses/Ditolak/Selesai`; `Diproses → Selesai/Ditolak`.
5. Status terminal tidak dapat diproses kembali.
6. Owner dan admin menerima data sesuai policy.

### 6.8 Workflow Email Resmi ASN

1. User mencari pegawai sesuai OPD.
2. Usulan dibuat dengan status `diajukan`.
3. BKD memverifikasi dokumen atau menolak.
4. Verifikasi BKD mengisi tanggal/verifikator tetapi status tetap `diajukan`.
5. Admin/superadmin menerbitkan email resmi; tindakan ini ditolak bila belum diverifikasi BKD.
6. Hasil final `disetujui` atau `ditolak`.
7. User mendapat inbox, realtime, FCM/WhatsApp bila tersedia.

Lock database (`lockForUpdate`) dipakai untuk mencegah dua petugas memproses usulan yang sama secara bersamaan.

### 6.9 Chatbot AI

Standar chatbot:

- persona terbatas pada layanan TIK Gelatik;
- FAQ aktif adalah sumber resmi utama;
- RAG mengambil FAQ/master data/konteks user yang relevan;
- pertanyaan di luar scope dan prompt injection diblok sebelum provider;
- temperature rendah dan timeout/cooldown provider;
- maksimal lima pesan aman dalam history provider;
- quick FAQ dapat dijawab tanpa memanggil AI;
- Gemini utama, Groq fallback;
- provider gagal menghasilkan jawaban lokal yang transparan;
- perubahan data tidak boleh diklaim kecuali transaksi benar-benar berhasil;
- eskalasi konsultasi hanya setelah tiga kendala unresolved dan konfirmasi eksplisit.

### 6.10 Notifikasi dan Realtime

Satu perubahan bisnis dapat menghasilkan:

1. data/status di database;
2. inbox `notification` yang durable;
3. event Socket.IO untuk client aktif;
4. FCM queued listener;
5. WhatsApp jika user opt-in dan event mendukungnya.

Kegagalan Socket.IO, FCM, AI, atau WhatsApp umumnya tidak membatalkan transaksi bisnis utama. Pengecualian: OTP reset password membutuhkan WhatsApp berhasil dikirim.

### 6.11 Laporan

Jenis laporan:

- peminjaman;
- konsultasi;
- usulan email.

Filter mencakup tanggal, status, user, OPD, topik konsultasi, dan aset sesuai tipe. Output data JSON, CSV, atau XLSX. Akses dibatasi admin/superadmin.

## 7. Backend Node.js

### 7.1 Peran Node.js

Node.js tidak menyimpan data bisnis. Fungsinya:

- server Socket.IO;
- verifikasi identitas socket ke Laravel `/api/me`;
- pembentukan room berdasarkan identitas terverifikasi;
- internal broadcast dari Laravel;
- WhatsApp gateway menggunakan Baileys;
- QR terminal untuk pairing;
- reconnect dengan exponential backoff;
- callback status delivery ke Laravel;
- health endpoint.

### 7.2 Endpoint Node

- `GET /health`: status service, jumlah koneksi socket, status WhatsApp;
- `POST /internal/broadcast`: target user, admin role, atau all;
- `POST /internal/wa/send`: kirim WhatsApp;
- seluruh `/internal/*` memakai Bearer `INTERNAL_SERVICE_API_KEY`.

### 7.3 Autentikasi Socket dan Room

Client mengirim token Passport pada handshake:

```json
{ "auth": { "token": "access-token" } }
```

Node memverifikasi token melalui Laravel. Room:

- `user_{id}` untuk setiap user;
- `role_admin` untuk admin;
- `role_superadmin` untuk superadmin.

Target logical `admin` mengirim ke kedua room admin dan superadmin. Client tidak boleh memilih room sendiri. Saat ini belum ada room role BKD khusus; BKD tetap memiliki room personal.

### 7.4 Event Realtime

Event yang diizinkan mencakup:

- `notification`, `data.sync`, `insights.sync`;
- `pinjam.created`, `pinjam.status_changed`;
- `konsultasi.created`, `konsultasi.responded`, `konsultasi.status_changed`;
- `pengumuman.created`;
- `usulan_email.created`, `usulan_email.status_changed`;
- `kritik_saran.created`;
- `chatbot.conversation.created/updated/deleted`;
- `chatbot.message.created`.

Payload dibatasi pada metadata minimal seperti event ID, type, entity ID, status, old status, response ID, timestamp, message, dan resource. Token/password/authorization ditolak.

Catatan integrasi: Laravel pada perubahan email BKD juga menggunakan nama `usulan_email.verified`; registry Node saat ini belum mencantumkan event tersebut. Ini perlu diselaraskan agar broadcast tersebut tidak ditolak.

### 7.5 WhatsApp Gateway

- Baileys multi-file auth state;
- QR ditampilkan di terminal;
- nomor Indonesia dinormalisasi menjadi format `628...`;
- reconnect berhenti saat logged-out atau conflict tertentu;
- delivery key digunakan untuk idempotency;
- callback status dikirim asynchronous agar tidak deadlock dengan `php artisan serve` single process;
- session path harus dipersistenkan di production;
- health hanya menyatakan `connected` atau `disconnected`.

## 8. Database

### 8.1 Strategi Database

Database production ditujukan untuk MySQL 8/MariaDB. Project memakai strategi kode baru di atas schema legacy:

- nama tabel/kolom legacy dipertahankan;
- Eloquent model membuat mapping eksplisit;
- migration bersifat incremental;
- jangan menjalankan `migrate:fresh`, `migrate:reset`, atau operasi destruktif pada database existing;
- lakukan backup dan `php artisan migrate:status` sebelum migration.

SQLite `:memory:` digunakan untuk test, tetapi PHP CLI environment yang diaudit belum memuat driver PDO SQLite untuk feature test.

### 8.2 Katalog Tabel Baseline

#### Identitas, role, dan audit

- `users`: akun, profil, OPD, status, role legacy, dan perubahan lokal bandwidth user;
- `roles`, `permissions`, `model_has_roles`, `model_has_permissions`, `role_has_permissions`: Spatie RBAC;
- `activity_log`: Spatie activity log;
- `admin_audit_logs`: audit tindakan admin/superadmin dari migration.

#### OAuth dan password

- `oauth_access_tokens`, `oauth_auth_codes`, `oauth_clients`, `oauth_personal_access_clients`, `oauth_refresh_tokens`: Passport;
- `personal_access_tokens`: token legacy/kompatibilitas;
- `password_resets`: reset legacy;
- `password_reset_tokens`: reset token framework;
- `password_reset_otps`: challenge OTP WhatsApp.

#### Peminjaman

- `master_item`: katalog aset dan stok;
- `tr_permintaan_pinjam`: header pengajuan;
- `pinjam_item`: pivot item, kuantitas, dan relasi pengajuan-aset.

Relasi: user hasMany pinjam; pinjam belongsToMany master_item melalui pinjam_item.

#### Konsultasi dan FAQ

- `master_topik`: topik layanan;
- `faq`: pertanyaan/jawaban resmi dan status aktif;
- `tr_konsultasi`: tiket konsultasi;
- `tr_konsultasi_response`: respons petugas/user;
- `chatbot_conversations`, `chatbot_messages`, `chatbot_urls`: sesi, pesan, dan config chatbot lama.

Relasi: topik hasMany FAQ; konsultasi belongsTo user/topik dan hasMany response; conversation belongsTo user dan hasMany message.

#### Email ASN

- `PegawaiBelumPunyaEMail`/baseline DDL `pegawaibelumpunyaemail`: pegawai target;
- `usulan_email`: pengajuan, email pribadi/resmi, status, verifikator, tanggal, catatan, creator/updater.

Relasi: pegawai hasMany usulan_email; usulan_email belongsTo creator user dan pegawai BKD.

#### Internet dan OPD

- `unker_list_router`: daftar/mapping OPD, identity router, bandwidth download/upload;
- `unker_router`: detail router/koneksi;
- perubahan lokal migration menambah bandwidth download/upload per `users`.

#### Notifikasi dan komunikasi

- `notification`: inbox personal atau broadcast (`user_id = 0`);
- `notification_reads`: read state per user untuk broadcast;
- `whatsapp_subscriptions`: satu subscription opt-in per user;
- `whatsapp_delivery_logs`: audit/idempotency pengiriman WhatsApp.

#### Konten dan feedback

- `sliders`: banner dashboard;
- `pengumumans`: pengumuman aktif/masa berlaku;
- `ratings`: rating user;
- `kritik_sarans`: kritik-saran, nomor referensi, balasan admin;
- `m_settings`: pengaturan key-value aplikasi.

#### Infrastruktur

- `jobs`, `failed_jobs`: queue;
- `cache`, `cache_locks`: cache database;
- `migrations`: riwayat migration.

Konfigurasi session default memakai database, tetapi keberadaan tabel `sessions` harus diverifikasi pada database target karena tidak tampak pada baseline schema yang diaudit.

### 8.3 Migration Incremental Penting

- WhatsApp subscriptions dan delivery logs;
- chatbot conversations/messages;
- data pegawai belum punya email;
- NIP user;
- cache tables;
- unique subscription per user;
- notification reads;
- password reset tokens dan OTP;
- chatbot lookup indexes;
- state eskalasi dan offer chatbot;
- bandwidth router OPD;
- admin audit logs;
- hardening WhatsApp delivery logs;
- reply fields kritik-saran;
- realtime read-path indexes;
- perubahan lokal 31 Agustus 2026: bandwidth download/upload pada users.

## 9. Tech Stack dan Fungsinya

### 9.1 Mobile

| Teknologi | Fungsi |
|---|---|
| Flutter/Dart `^3.12.2` | aplikasi lintas platform |
| Material 3 | komponen dan theme UI |
| Riverpod | state management dan dependency injection |
| Dio | HTTP client/interceptor/cache |
| Flutter Secure Storage | menyimpan token dan state sensitif |
| Shared Preferences | cache GET persisten non-sensitif |
| Socket.IO Client | realtime saat aplikasi aktif |
| WebView Flutter | chatbot URL lama |
| File Picker | attachment peminjaman/konsultasi |
| Intl | locale/tanggal Indonesia |
| Google Fonts/Flutter SVG | tipografi dan asset visual |

### 9.2 Website

| Teknologi | Fungsi |
|---|---|
| Vue 3 | reactive component UI |
| Vite 7 | development server dan production bundler |
| Vue Router | route, lazy loading, dan guard |
| Pinia | auth/session state |
| Axios | REST API client |
| Socket.IO Client | realtime portal aktif |
| Tailwind CSS | utility styling |
| Heroicons Vue | ikon konsisten |
| ESLint/Prettier | kualitas dan format source |

### 9.3 Laravel

| Teknologi | Fungsi |
|---|---|
| PHP `^8.3` | runtime backend |
| Laravel `^13.8` | framework REST, validation, ORM, queue, event |
| Eloquent ORM | mapping model dan database |
| Laravel Passport `^13.7` | OAuth2 Bearer token |
| Spatie Permission `^8.3` | role/permission |
| Spatie Activity Log `^5` | activity logging |
| Kreait Laravel Firebase `^7.2` | Firebase Admin/FCM |
| Laravel Excel `^3.1` | CSV/XLSX report |
| Snappy | dukungan render PDF berbasis wkhtmltopdf |
| Yajra DataTables | dukungan query/data table server-side |
| PHPUnit 12 | automated test |
| Laravel Pint | formatting PHP |

### 9.4 Node.js

| Teknologi | Fungsi |
|---|---|
| Node.js CommonJS | runtime realtime service |
| Express 5 | HTTP internal API dan health check |
| Socket.IO 4 | WebSocket/realtime rooms |
| Baileys 7 RC | WhatsApp Web gateway |
| Axios | verifikasi token/callback Laravel |
| CORS | origin allow-list |
| Dotenv | konfigurasi environment |
| QRCode Terminal | pairing WhatsApp |
| Node Test Runner | test service |

### 9.5 Database dan Infrastruktur

| Teknologi | Fungsi |
|---|---|
| MySQL/MariaDB | database utama production |
| SQLite memory | database automated test bila driver tersedia |
| Database Queue | memproses listener/FCM asynchronous |
| Database/Redis Cache | cache dashboard, FAQ, circuit breaker |
| Firebase Cloud Messaging | push notification backend |
| Socket.IO | update UI realtime foreground |
| WhatsApp | notifikasi opt-in dan OTP reset password |

## 10. Konfigurasi Penting

### Laravel

- APP environment, key, URL, frontend URL, timezone Asia/Jakarta;
- DB connection/host/port/database/user/password;
- Passport keys/client;
- queue dan cache;
- `NODE_SERVICE_URL` dan `INTERNAL_SERVICE_API_KEY`;
- Firebase credentials;
- Gemini/Groq key, model, timeout, cooldown;
- official email allowed domains;
- SIMKI URL/key bila integrasi dipakai;
- mail;
- local provisioning key.

Catatan: `NodeServiceClient` membutuhkan `NODE_SERVICE_URL` dan `INTERNAL_SERVICE_API_KEY`, tetapi kedua key tersebut tidak tampak pada `backend/.env.example` snapshot ini. Tambahkan saat deployment dan selaraskan dengan Node.

### Node

- `PORT` default 4000;
- `LARAVEL_BASE_URL`;
- `INTERNAL_SERVICE_API_KEY` harus sama dengan Laravel;
- `SOCKET_CORS_ORIGINS` explicit allow-list;
- WhatsApp session path dan instance;
- log level/Node environment.

Jangan menaruh secret di source frontend, dokumentasi publik, log, atau payload realtime.

## 11. Cara Menjalankan

### Backend Laravel

```powershell
cd backend
composer install
Copy-Item .env.example .env
php artisan key:generate
php artisan passport:keys
php artisan migrate:status
php artisan migrate
php artisan serve
```

Queue worker pada terminal terpisah:

```powershell
php artisan queue:work
```

### Website

```powershell
cd website/PKL-TIK-ADIT
npm install
npm run dev
```

### Node realtime/WhatsApp

```powershell
cd realtime-service
npm install
Copy-Item .env.example .env
npm start
```

Scan QR WhatsApp pada startup pertama dan persist session folder.

### Flutter

```powershell
cd gelatik-mobile
flutter pub get
flutter run
```

Base URL API dan Socket harus cocok dengan device/emulator. `127.0.0.1` pada perangkat fisik menunjuk ke perangkat itu sendiri, bukan PC development.

## 12. Pengujian dan Status Verifikasi Snapshot

Perintah utama:

- Laravel: `php artisan test`;
- Node: `npm test`;
- Website: `npm run build`, `npm run lint`, `npm run format:check`;
- Flutter: `flutter analyze`, `flutter test`.

Hasil audit 31 Agustus 2026:

- website production build berhasil, 848 modul ditransformasi;
- Node realtime: 15/15 test lulus;
- Laravel unit: 21/21 test lulus, 46 assertions;
- full Laravel suite: unit berjalan, 49 feature test error karena PDO SQLite tidak tersedia pada PHP CLI environment;
- Flutter test tidak menghasilkan progres/output pada environment audit dan dihentikan; bukan bukti test gagal.

## 13. Pembaruan Terbaru

### Perubahan source aktif 1 September 2026 (belum di-commit pada snapshot)

- website mengalami penyelarasan visual besar pada landing page, autentikasi, shell, sidebar, header, dashboard, state components, dan halaman operasional user/BKD/admin;
- website menambahkan `GovernmentAuthLayout`, aset Muli-Meghanai, serta identitas visual pemerintah/Diskominfotik;
- mobile mengekstrak hero autentikasi dan komponen profil menjadi widget reusable, merapikan pencarian pilihan, header halaman, shell, dan halaman WhatsApp;
- dashboard/profil/internet mobile kini membaca bandwidth personal dari backend dan menjelaskan apakah sumbernya alokasi akun atau fallback router OPD;
- admin website dapat mengisi `bandwidth_download_mbps` dan `bandwidth_upload_mbps` untuk akun;
- backend menambahkan migration bandwidth user dan fallback bandwidth router OPD;
- password registrasi publik dinaikkan menjadi minimal delapan karakter;
- eskalasi chatbot diubah menjadi setelah tiga saran gagal, dengan konfirmasi eksplisit `iya/tidak`, profil akun, dan perumusan natural dari keluhan terakhir;
- event realtime `usulan_email.verified` telah ditambahkan ke allow-list Node dan invalidasi resource observer diseragamkan;
- test baru/penyesuaian test mencakup auth, authorization, chatbot escalation, bandwidth, event realtime, shell, profil, serta dashboard mobile.

### Commit 31 Agustus 2026

- redesign mobile civic formal menjadi Bento Grid + Friendly Illustrative;
- shell navigasi persistent dan Services screen;
- dashboard personal, shortcut, bandwidth, dan slider/pengumuman;
- pencarian aset dan penyempurnaan formulir;
- ilustrasi lokal Lampung/Muli-Meghanai;
- peningkatan test dashboard, bandwidth, shell, dan peminjaman.

### Commit 30 Agustus 2026

- portal BKD dan workflow email dua tahap;
- validasi domain email resmi saat registrasi;
- filter pegawai berdasarkan OPD;
- pencarian/filter/pagination usulan email;
- perubahan besar design system mobile;
- cache persisten mobile;
- penyesuaian notifikasi/route lintas portal.

### Commit 25–26 Agustus 2026

- chatbot FAQ-first, fallback provider, dan pemulihan history;
- sinkronisasi chatbot web/mobile;
- eskalasi chatbot ke konsultasi;
- pemulihan notifikasi mobile dan WhatsApp;
- stabilisasi realtime, cache dashboard, navigation, dan feedback history;
- sinkronisasi slider pengumuman.

### Ringkasan perubahan lokal lintas komponen

- bandwidth download/upload khusus per user;
- admin website dapat mengelola bandwidth akun;
- layanan internet mengembalikan bandwidth user dan fallback router OPD;
- UI mobile profil/dashboard/internet menampilkan bandwidth personal;
- chatbot menawarkan konsultasi setelah tiga kegagalan, cukup konfirmasi iya/tidak;
- detail konsultasi chatbot dibentuk dari profil dan keluhan terakhir;
- unit test baru untuk eskalasi chatbot dan layanan internet;
- refactor widget auth/profil dan beberapa penyempurnaan mobile;
- redesign konsisten website lintas halaman publik dan portal role;
- kontrak realtime email ASN diperbarui agar event verifikasi diterima Node.

## 14. Risiko, Gap, dan Hal yang Harus Dijelaskan dalam Laporan

- FCM backend sudah nyata, tetapi Flutter masih simulasi subscription dan website belum FCM Web.
- Room Socket.IO khusus BKD belum ada; BKD hanya room personal.
- `.env.example` Laravel belum mencantumkan seluruh key Node/SIMKI/Firebase yang dipakai source.
- session driver default database perlu tabel `sessions`, tetapi tabel itu tidak terlihat pada baseline schema.
- mobile memberi role BKD tab Admin generik, belum portal BKD khusus.
- source target Flutter tersedia lintas platform, tetapi readiness production tiap platform harus dibuktikan dengan build/test platform.
- ketergantungan Gemini, Groq, FCM, SIMKI, WhatsApp, dan jaringan harus dibedakan dari fitur yang tersedia di source.
- perubahan bandwidth user masih belum di-commit dan migration wajib dijalankan sebelum field digunakan.

## 15. Prompt Pengetahuan Siap Pakai

Salin seluruh blok berikut ke Project Instructions atau awal percakapan ChatGPT:

```text
Anda adalah asisten teknis, analis sistem, dan penulis dokumentasi khusus Project Gelatik. Jawab dalam Bahasa Indonesia kecuali diminta lain. Gunakan pengetahuan berikut sebagai konteks utama, tetapi jika source aktif tersedia maka source selalu lebih benar daripada prompt ini.

IDENTITAS PROJECT
Gelatik adalah platform layanan TIK terpadu untuk Pemerintah Provinsi Lampung/Diskominfotik. Aktor utama adalah user/pegawai OPD, BKD, admin, dan superadmin. Sistem terdiri dari Flutter, website Vue, REST API Laravel, MySQL/MariaDB, serta Node.js Socket.IO dan WhatsApp gateway.

PRINSIP ARSITEKTUR
Laravel REST dan database adalah source of truth. Socket.IO hanya sinyal perubahan; client harus refetch REST. Kegagalan realtime, FCM, AI, atau WhatsApp tidak boleh membatalkan transaksi bisnis utama, kecuali OTP reset password memang membutuhkan WhatsApp. Aturan bisnis harus berada di backend dan sama untuk web/mobile.

MOBILE
Flutter memakai Riverpod, Dio, Secure Storage, SharedPreferences cache, Socket.IO client, WebView, File Picker, Intl, SVG, dan Material 3. Struktur feature-first. Fitur user: auth, OTP reset, dashboard bento, kalender, slider/pengumuman, peminjaman, konsultasi, email ASN, info aset, router/bandwidth, self-assessment, chatbot native/WebView, kritik-saran, rating, inbox notifikasi, WhatsApp, profil, change password, activity log. Fitur admin mobile: dashboard, peminjaman, konsultasi, email, feedback. Mobile light-only dengan navy/gold/teal dan civic illustrative design. FCM mobile belum nyata karena firebase_messaging belum dipasang; FcmTopicService masih simulasi.

WEBSITE
Vue 3 SPA memakai Vite, Router, Pinia, Axios, Socket.IO client, Tailwind, Heroicons, Urbanist. Portal user /app berisi dashboard, kalender, pengumuman, peminjaman, konsultasi, email, notifikasi, FAQ, router, rating, WhatsApp, chatbot, profil, feedback. Portal BKD /bkd untuk dashboard/verifikasi/penolakan usulan email. Portal admin /admin untuk seluruh operasi, master data, user/role, feedback, laporan, settings. Website belum memiliki FCM Web; notifikasi aktif memakai REST inbox dan Socket.IO.

LARAVEL
PHP 8.3, Laravel 13.8, Passport, Spatie Permission, Activity Log, Kreait Firebase, Laravel Excel, Snappy, Yajra. Laravel menangani auth, policy, validation, transaction, database, notification, AI, report, dan orchestration Node. Registrasi memvalidasi NIP 18 digit, OPD, official domain, password minimal 8 karakter, menetapkan role user, langsung aktif, dan mengembalikan token. Login menerima email/username/NIP. Akun status nonaktif ditolak.

ROLE
User hanya data sendiri. BKD hanya memverifikasi/menolak usulan email. Admin/superadmin menerbitkan email setelah verifikasi BKD dan mengelola layanan. Superadmin memiliki kewenangan role/akun khusus. Jangan percaya role dari client.

WORKFLOW PEMINJAMAN
Status awal Menunggu. Transisi Menunggu→Proses→Selesai atau Menunggu→Ditolak. Stok dicek terhadap overlap. Edit/item/delete hanya ketika Menunggu. Attachment harus tetap diotorisasi.

WORKFLOW KONSULTASI
Status Menunggu, Diproses, Ditolak, Selesai. Admin merespons dan mengelola status. Respons admin dapat mengubah Menunggu menjadi Diproses. User hanya tiket sendiri.

WORKFLOW EMAIL
User memilih pegawai sesuai OPD dan membuat status diajukan. BKD memverifikasi atau menolak. Setelah verifikasi, admin/superadmin menerbitkan email. Approval sebelum verifikasi BKD ditolak. Gunakan transaction/lock untuk race condition.

CHATBOT
FAQ-first/RAG, persona TIK ketat, allow-list scope, block prompt injection, temperature rendah, history maksimal 5 pesan aman, Gemini utama, Groq fallback, local fallback. Setelah 3 kegagalan chatbot menawarkan konsultasi iya/tidak. Jika iya, data profil dan keluhan terakhir membentuk tiket. Jangan klaim tiket dibuat sebelum transaksi sukses.

REALTIME DAN NOTIFIKASI
Laravel menyimpan inbox durable. Node memverifikasi token socket ke /api/me dan membuat room user_{id}, role_admin, role_superadmin. Payload minimal dan dilarang mengandung token/password. Allow-list mencakup lifecycle peminjaman/konsultasi, pengumuman, email ASN termasuk usulan_email.verified, chatbot, notification, kritik-saran, dan event sinkronisasi. FCM backend topic-based. WhatsApp Baileys menangani opt-in serta OTP. Mobile/web tetap harus bekerja melalui REST tanpa socket.

DATABASE
MySQL/MariaDB legacy dengan migration incremental. Tabel utama: users/RBAC/Passport, master_item/tr_permintaan_pinjam/pinjam_item, master_topik/faq/tr_konsultasi/tr_konsultasi_response, pegawai/usulan_email, router OPD, notification/notification_reads, WhatsApp, chatbot, slider/pengumuman/settings, rating/kritik-saran, jobs/cache/audit. Jangan gunakan migrate:fresh pada database existing.

DESIGN
Mobile: Bento Grid + Friendly Illustrative Civic, Material 3 light-only, navy #1E3A8A, gold #F59E0B, teal #0F766E, radius 16–20. Website: formal public-service light-only, Urbanist, navy primary, teal focus, gold highlight, surface putih, border halus, soft shadow.

ATURAN MENJAWAB
1. Bedakan fakta source, requirement, perubahan belum di-commit, dan dependency eksternal.
2. Jangan mengarang endpoint, tabel, payload, hasil test, atau runtime availability.
3. Untuk perubahan fitur, jelaskan dampak Laravel, database, Vue, Flutter, Node, realtime, notification, test, Postman, dan docs.
4. Terapkan authorization backend, ownership, transaction, idempotency, dan secret hygiene.
5. Pertahankan backward compatibility dengan schema legacy dan kedua client.
6. Jika ada konflik informasi, periksa source, migration, test, Postman, lalu dokumentasi.
7. FCM mobile dan web belum boleh disebut production-ready tanpa implementasi client nyata.
8. Jelaskan bahwa perubahan bandwidth per user, chatbot 3 kegagalan, dan redesign lintas website/mobile adalah perubahan lokal snapshot 1 September 2026 bila belum di-commit.

FORMAT JAWABAN PERUBAHAN
Mulai dari tujuan, komponen terdampak, alur data, role/otorisasi, kontrak API/database, dampak web/mobile, realtime/notifikasi, risiko, dan skenario test. Berikan file/lapisan yang perlu diubah dan jangan mengganti arsitektur tanpa alasan.
```

## 16. Penutup

Dokumen ini dapat dipakai sebagai lampiran laporan, bahan presentasi arsitektur, basis knowledge ChatGPT, atau panduan onboarding developer. Untuk laporan akademik, pisahkan antara fitur yang sudah ada di source, fitur yang memerlukan layanan eksternal, dan perubahan lokal yang belum menjadi baseline commit.
