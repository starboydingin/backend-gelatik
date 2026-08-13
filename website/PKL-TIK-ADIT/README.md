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

Route administrator berada di `/admin`: dashboard, pengguna, peran/izin, konsultasi, peminjaman, email resmi, pegawai, laporan peminjaman, kritik-saran, pengumuman, notifikasi, referensi layanan, dan pengaturan. Akses admin/superadmin berasal dari `GET /me`; pembuatan admin hanya ditampilkan untuk superadmin.

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
| Admin | `/admin/dashboard`, `/admin/users`, `/admin/roles`, `/admin/permissions`, `/admin/notifications`, `/admin/kritik-saran`, `/admin/settings` |
| Laporan | `/laporan/peminjaman` |

Axios menambahkan Bearer token pada request terautentikasi. Respons `401` menghapus sesi; error `403`, `422`, timeout, network, dan `5xx` diterjemahkan menjadi pesan yang aman. REST tetap berfungsi ketika realtime dimatikan atau tidak tersedia.

## Gap integrasi

- Backend belum menyediakan endpoint admin untuk CRUD FAQ, router OPD, domain, master item, topik, dan slider. Frontend tidak membuat approval atau data palsu untuk fitur tersebut.
- `PATCH /me` saat ini mendukung data profil dasar; endpoint khusus avatar, ganti password dari profil, dan log aktivitas akun belum tersedia.
- Kontrak event realtime selain event `notification` belum terdokumentasi, sehingga frontend tidak membuat nama event baru.
- Font Montserrat/Inter pada mobile berasal dari Google Fonts dependency dan tidak tersedia sebagai file lokal. Web menggunakan fallback system dan wordmark logo resmi tanpa mengunduh font eksternal.
