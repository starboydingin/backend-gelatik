# Gelatik Vue Web

Frontend web terpadu untuk pengguna dan administrator Gelatik. Project ini menggunakan Vue 3, Vite, Tailwind CSS, Vue Router, Pinia, Axios, dan Socket.IO client. Tidak ada Laravel, Blade, Inertia, Filament, database, atau backend duplikat di repository ini.

## Prasyarat dan setup

- Node.js 20.19+ atau 22.12+
- Backend Gelatik berjalan dan dapat diakses melalui REST API
- Realtime service bersifat opsional

```bash
cp .env.example .env
npm install
npm run dev
```

Windows PowerShell yang memblokir `npm.ps1` dapat menggunakan `npm.cmd` sebagai pengganti `npm`.

```bash
npm run format
npm run format:check
npm run lint
npm run build
```

## Environment

```env
VITE_APP_NAME=Gelatik
VITE_API_BASE_URL=http://127.0.0.1:8000/api
VITE_REALTIME_URL=http://127.0.0.1:4000
VITE_APP_ENV=local
VITE_ENABLE_REALTIME=true
```

Semua variabel `VITE_*` masuk ke bundle dan dapat terlihat di browser. Jangan menyimpan token Passport, password database, API key, credential Firebase/WhatsApp/SMTP, atau secret backend di environment frontend.

## Struktur

```text
src/
├── assets/images/       # logo dan motif Gelatik yang digunakan
├── components/          # design system, shell, state, dialog, navigasi
├── layouts/             # layout portal user dan admin
├── lib/                 # Axios dan realtime client
├── router/              # route dan access guard
├── stores/              # Pinia auth store
└── views/
    ├── admin/           # page administrator
    ├── shared/          # konsultasi, peminjaman, dan email
    └── user/            # page pengguna
```

Splash screen tidak digunakan pada web. Aplikasi langsung merender route aktif.

## Route frontend

Route publik: `/`, `/login`, `/register`, `/forgot-password`, `/reset-password`.

Route pengguna berada di `/app`: dashboard, kalender, pengumuman, peminjaman, konsultasi, email resmi, router OPD, kritik-saran, rating, notifikasi, FAQ, WhatsApp, chatbot, dan profil.

Route administrator berada di `/admin`: dashboard, pengguna, peran/izin, konsultasi, peminjaman, email resmi, pegawai, laporan peminjaman, kritik-saran, pengumuman, notifikasi, referensi layanan, dan pengaturan. Akses admin/superadmin berasal dari `GET /me`; pembuatan admin hanya tersedia melalui endpoint yang dilindungi role superadmin.

Login user dan admin menggunakan halaman yang sama di `/login`. Backend membaca role akun dari `GET /api/me`; user diarahkan ke `/app/dashboard`, sedangkan admin/superadmin diarahkan ke `/admin/dashboard`. Sesi disimpan per tab browser, sehingga akun user dan admin dapat dibuka bersamaan pada dua tab untuk pengujian tanpa saling menimpa token.

## Membuat akun admin melalui Postman

### Bootstrap akun presentasi lokal (tanpa akun lama)

Untuk demo/testing lokal, endpoint berikut dapat membuat akun `superadmin` atau `admin` baru tanpa mengubah akun lama. Endpoint hanya terdaftar saat `APP_ENV=local` atau `testing` dan memerlukan key lokal.

1. Tambahkan sendiri key acak pada `backend/.env` (file ini tidak di-commit):

```env
LOCAL_PROVISION_KEY=buat-key-acak-panjang-sendiri
```

2. Jalankan `php artisan optimize:clear`, lalu di Postman kirim `POST http://127.0.0.1:8000/api/dev/provision-account` dengan header:

```text
Accept: application/json
Content-Type: application/json
X-Local-Provision-Key: nilai-LOCAL_PROVISION_KEY-Anda
```

3. Buat superadmin presentasi memakai JSON berikut:

```json
{
  "name": "Superadmin Presentasi",
  "email": "superadmin.demo@example.test",
  "username": "superadmin.demo",
  "password": "PasswordDemo123!",
  "nama_opd": "Diskominfotik",
  "role": "superadmin"
}
```

Ulangi request dengan email/username berbeda dan `"role": "admin"` untuk akun admin presentasi. Kedua akun login melalui `POST /api/login` atau halaman `/login` yang sama. Endpoint ini tidak tersedia ketika production.

Pembuatan admin tidak tersedia pada registrasi publik. Hanya akun `superadmin` yang dapat membuatnya.

1. Login sebagai superadmin melalui `POST http://127.0.0.1:8000/api/login`.
2. Ambil `access_token` dari respons tanpa menyalinnya ke source code atau dokumentasi.
3. Kirim `POST http://127.0.0.1:8000/api/admin/users` dengan header `Authorization: Bearer <access_token>` dan `Accept: application/json`.
4. Gunakan body JSON berikut, dengan password yang dikonfigurasi secara lokal:

```json
{
  "name": "Admin Gelatik",
  "email": "admin.local@example.test",
  "username": "admin.local",
  "password": "<configured-locally>",
  "nama_opd": "Dinas Komunikasi, Informatika dan Statistik"
}
```

Respons `201` berarti akun aktif dibuat dengan role `admin`. Akun tersebut selanjutnya login melalui halaman `/login` yang sama. Role dari body request diabaikan; endpoint selalu membuat admin dan dilindungi middleware superadmin.

## Endpoint API

| Modul | Endpoint utama |
|---|---|
| Auth dan profil | `POST /login`, `/register`, `/logout`, `/forgot-password`, `/reset-password`; `GET/PATCH /me` |
| Dashboard | `GET /dashboard`, `/dashboard/calendar`, `/pengumuman` |
| Peminjaman | `GET/POST /pinjam`, `GET/PUT/DELETE /pinjam/{id}`, `/pinjam/{id}/status`, `/items` |
| Konsultasi | `GET/POST /konsul`, `GET/DELETE /konsul/{id}`, `/konsul/{id}/response`, `/konsul/{id}/status`, `/topik` |
| Email ASN | `GET/POST /pengajuan-email`, `GET/PUT /pengajuan-email/{id}`, endpoint verifikasi/pembuatan/penolakan, `/pegawai` |
| Informasi user | `/faq`, `/list-router-opd`, `/rating`, `/kritik-saran` |
| Notifikasi | `/notifications`, `/notifications/{id}/read`, `/notifications/read-all` |
| WhatsApp | `/notifikasi/wa/status`, `/notifikasi/wa/subscribe` |
| Chatbot | `/chatbot/message`, `/chatbot/history` |
| Admin | `/admin/dashboard`, `/admin/users`, `/admin/roles`, `/admin/permissions`, `/admin/notifications`, `/admin/kritik-saran`, `/admin/settings`, CRUD `/admin/items`, `/admin/topik`, `/admin/faq`, `/admin/sliders`, `/admin/routers` |
| Laporan | `/laporan/peminjaman` |

Axios menambahkan Bearer token pada request terautentikasi. Respons `401` menghapus sesi; error `403`, `422`, timeout, network, dan `5xx` diterjemahkan menjadi pesan yang aman. REST tetap berfungsi ketika realtime dimatikan atau tidak tersedia.

## Gap integrasi

- CRUD admin untuk item/aset, topik, FAQ, slider, dan daftar router OPD sudah tersedia. Manajemen domain belum tersedia sebagai endpoint admin terpisah.
- `PATCH /me` saat ini mendukung data profil dasar; endpoint khusus avatar, ganti password dari profil, dan log aktivitas akun belum tersedia.
- Kontrak event realtime selain event `notification` belum terdokumentasi, sehingga frontend tidak membuat nama event baru.
- Font Montserrat/Inter pada mobile berasal dari Google Fonts dependency dan tidak tersedia sebagai file lokal. Web menggunakan fallback system dan wordmark logo resmi tanpa mengunduh font eksternal.
