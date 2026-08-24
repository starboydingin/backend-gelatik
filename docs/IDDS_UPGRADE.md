# Gelatik IDDS Upgrade

## Arsitektur

Vue dan Flutter tetap menjadi client dari Laravel REST API. Laravel adalah source of truth; Node.js hanya menangani sinyal Socket.IO dan gateway WhatsApp. Kegagalan realtime/AI/FCM/WhatsApp tidak membatalkan mutasi bisnis, kecuali WhatsApp memang diperlukan sebagai kanal verifikasi OTP reset password.

## Website dan branding

Website memakai semantic design tokens pada `website/PKL-TIK-ADIT/src/design-system.css`: navy `#1E3A8A` sebagai brand dan primary action, gold `#F59E0B` sebagai highlight, teal `#0F766E` sebagai accent, serta emerald `#10B981` khusus semantic success. Token status, surface, text, border, focus, dan dark mode berada pada sumber yang sama. Branding menggunakan komposisi resmi yang secara visual memuat wordmark pada `gelatik-logo.png` serta `siger.png`; file repository bernama `gelatik-wordmark.png` hanya memuat bird mark sehingga tidak dipakai sebagai wordmark utama.

Public page, shell user/admin, sidebar, header, form, card, table, alert, badge, kalender, dashboard, dan laporan memakai pola reusable yang sama. Navigation tetap role-based dari identitas backend; superadmin dibedakan melalui capability dan audit activity, bukan logo berbeda.

## Fitur lintas aplikasi

- Dashboard user hanya mengagregasi data pemilik akun. Dashboard admin menampilkan KPI operasional; superadmin juga menerima aktivitas administrator.
- Kalender user dibatasi ke data sendiri. Admin/superadmin melihat aktivitas global sesuai role, dengan rentang maksimal 93 hari.
- Chatbot tetap dibatasi pada layanan TIK, memakai FAQ aktif sebagai konteks, menjaga riwayat multi-turn, dan membuat konsultasi setelah dua follow-up unresolved. Hanya ringkasan konteks terbatas yang disimpan pada konsultasi.
- Bandwidth disimpan opsional pada `unker_list_router`. Jika mapping tidak tersedia, API mengirim status `available: false`, bukan angka nol palsu. Website dan mobile memakai response yang sama.
- Reset password memakai OTP WhatsApp enam digit yang hashed, kedaluwarsa 10 menit, cooldown 60 detik, maksimal lima percobaan, sekali pakai, dan menghasilkan reset token sementara. Password baru tidak pernah dikirim melalui WhatsApp.
- Tanggal mulai peminjaman hanya hari ini atau besok; waktu hari ini harus berada setelah waktu server. End date hasil durasi tetap dapat melewati besok.
- Laporan peminjaman, konsultasi, dan usulan email tersedia sebagai data terfilter serta ekspor CSV/XLSX untuk admin/superadmin.

## Migration incremental

Jalankan hanya pada database development/target yang sudah dibackup:

```powershell
cd backend
php artisan migrate:status
php artisan migrate
```

Migration baru membuat `password_reset_otps`, menambah state eskalasi chatbot, dan menambah bandwidth nullable. Jangan gunakan `migrate:fresh` atau `migrate:reset` pada database existing.

## Endpoint baru/berubah

```text
POST /api/forgot-password
POST /api/forgot-password/verify
POST /api/reset-password
GET  /api/laporan/{peminjaman|konsultasi|usulan-email}/data
GET  /api/laporan/{peminjaman|konsultasi|usulan-email}/export?format=csv|xlsx
```

Contoh request, auth requirement, filter, dan error aman tersedia dalam `layanantik-backend-api.postman_collection.json` folder **16 - IDDS Upgrade**.

## Batasan runtime eksternal

Respons OTP live membutuhkan Node.js port 4000 dengan sesi WhatsApp berstatus `connected`. Respons AI live membutuhkan provider yang valid. Source dan automated test tidak boleh dianggap sebagai bukti bahwa dependency eksternal sedang tersedia.
