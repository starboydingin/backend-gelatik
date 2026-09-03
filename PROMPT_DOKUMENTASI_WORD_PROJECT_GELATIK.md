# Prompt Pembuatan Dokumentasi Word Project Gelatik

> Snapshot pengetahuan: 1 September 2026, Asia/Jakarta. Prompt ini dirancang untuk digunakan bersama `README.md` dan `PENGETAHUAN_LENGKAP_DAN_PROMPT_PROJECT_GELATIK.md`.

## Cara menggunakan

1. Lampirkan file berikut ke ChatGPT:
   - `README.md`;
   - `PENGETAHUAN_LENGKAP_DAN_PROMPT_PROJECT_GELATIK.md`;
   - bila tersedia, source repository atau ZIP project;
   - bila diperlukan, `KONFIGURASI_PRODUCTION.md`, Postman Collection, PRD, dan SRS.
2. Salin prompt di bawah.
3. Ganti placeholder identitas seperti nama, NPM, instansi, pembimbing, dan periode.
4. Minta output akhir sebagai `.docx`, bukan hanya teks chat.

## Prompt siap pakai

```text
Anda bertindak sebagai analis sistem senior, software architect, technical writer, dan penyusun laporan akademik profesional. Buat sebuah dokumen Microsoft Word (.docx) yang lengkap, akurat, terstruktur, dan layak dipakai sebagai dokumentasi teknis sekaligus laporan kerja praktik untuk Project Gelatik.

BAHAN SUMBER WAJIB
1. README.md sebagai dokumentasi kanonis repository.
2. PENGETAHUAN_LENGKAP_DAN_PROMPT_PROJECT_GELATIK.md sebagai inventaris pengetahuan rinci.
3. Source code, migration, test, Postman Collection, PRD/SRS, dan dokumen teknis lain bila saya lampirkan.

URUTAN SUMBER KEBENARAN
Jika terdapat konflik informasi, gunakan urutan:
1. source code aktif dan konfigurasi runtime;
2. database schema serta migration aktif;
3. automated test;
4. Postman Collection;
5. PRD/SRS terbaru;
6. README utama;
7. dokumen audit/historis.

Jangan mengarang endpoint, tabel, relasi, status, role, payload, angka hasil pengujian, konfigurasi, atau fitur. Jangan menyatakan sebuah integrasi production-ready bila bukti source hanya berupa stub/simulasi. Jika informasi tidak dapat diverifikasi, tulis secara eksplisit “belum dapat diverifikasi dari artefak yang tersedia” dan masukkan ke bagian keterbatasan, bukan menebak.

IDENTITAS DOKUMEN
- Judul: Dokumentasi Lengkap Sistem Gelatik — Gerbang Layanan TIK Pemerintah Provinsi Lampung
- Jenis: Dokumentasi Sistem dan Laporan Kerja Praktik
- Nama: [ISI NAMA]
- NPM/NIM: [ISI NPM/NIM]
- Program studi: [ISI PROGRAM STUDI]
- Perguruan tinggi: [ISI PERGURUAN TINGGI]
- Instansi: Dinas Komunikasi, Informatika dan Statistik Provinsi Lampung
- Pembimbing lapangan: [ISI NAMA]
- Dosen pembimbing: [ISI NAMA]
- Periode: [ISI PERIODE]
- Snapshot sistem: 1 September 2026, zona waktu Asia/Jakarta

KONTEKS SISTEM YANG WAJIB DIPERTAHANKAN
Gelatik adalah platform layanan TIK terpadu untuk Pemerintah Provinsi Lampung/Diskominfotik. Aktor: user/pegawai OPD, BKD, admin, dan superadmin. Komponen: aplikasi Flutter, SPA Vue, REST API Laravel, MySQL/MariaDB, dan service Node.js untuk Socket.IO serta WhatsApp Baileys. Laravel REST API dan database adalah source of truth. Socket.IO hanya memberi sinyal perubahan dan client melakukan refetch REST.

Fitur utama mencakup autentikasi/profil/activity log, dashboard/kalender/pengumuman, peminjaman aset, konsultasi TIK, informasi router/bandwidth, pengajuan email ASN dua tahap, chatbot FAQ-first dengan fallback AI dan eskalasi konsultasi, kritik-saran, rating, notifikasi inbox/realtime/FCM/WhatsApp, laporan CSV/XLSX, master data, user, role, permission, dan settings.

CATATAN AKURASI KRITIS
- Backend memakai PHP 8.3 dan Laravel 13.8, bukan Laravel 11.
- Node WhatsApp memakai Baileys, bukan whatsapp-web.js.
- Registrasi publik menetapkan role user, memvalidasi NIP 18 digit, OPD, official domain, password minimal 8 karakter, langsung aktif, dan mengembalikan token pada source snapshot.
- Login menerima email, username, atau NIP; akun nonaktif ditolak.
- BKD hanya memverifikasi/menolak usulan email. Admin/superadmin menerbitkan email setelah verifikasi BKD.
- Bandwidth user dapat berasal dari alokasi khusus akun atau fallback router OPD.
- Chatbot menawarkan konsultasi setelah tiga saran gagal dan meminta konfirmasi iya/tidak; data profil serta keluhan terakhir dipakai untuk tiket idempotent.
- Event usulan_email.verified sudah ada pada allow-list Node di source snapshot.
- Backend FCM nyata tersedia melalui Kreait, tetapi Flutter belum memakai firebase_messaging dan website belum mempunyai Firebase Web Messaging/service worker. Karena itu push FCM client belum boleh disebut lengkap/production-ready.
- Socket.IO dapat dihilangkan tanpa mematikan transaksi inti karena REST tetap bekerja, tetapi update foreground instan hilang.
- Tanpa FCM, fitur inti tetap bekerja, tetapi push background/closed-app tidak tersedia.
- Room Socket.IO tersedia untuk user_{id}, role_admin, dan role_superadmin; belum ada room role BKD khusus.
- Mobile belum memiliki portal BKD khusus seperti website.
- Perubahan 1 September 2026 tersedia pada commit `a1bb5dc`; tetap bedakan “tersedia di source/commit” dari “sudah dideploy ke production”.

TUJUAN DOKUMEN
Dokumen harus dapat dipahami oleh dosen/penguji, pemilik sistem, operator Diskominfotik, developer baru, dan tim maintenance. Jelaskan tujuan bisnis, pengguna, arsitektur, fitur, alur data, database, keamanan, setup, operasi, pengujian, pembaruan, keterbatasan, dan rekomendasi.

STRUKTUR DOKUMEN WAJIB
Susun setidaknya bab dan subbab berikut. Boleh menambah subbab bila memang didukung sumber.

Bagian awal:
1. Sampul formal.
2. Halaman identitas/pengesahan dengan placeholder tanda tangan.
3. Kata pengantar singkat dan profesional.
4. Abstrak Bahasa Indonesia dan kata kunci.
5. Executive summary.
6. Daftar isi otomatis.
7. Daftar gambar, daftar tabel, dan daftar singkatan.

BAB I — Pendahuluan:
- latar belakang;
- identifikasi masalah;
- rumusan masalah;
- tujuan sistem dan tujuan dokumentasi;
- manfaat;
- ruang lingkup;
- batasan;
- metodologi pengumpulan pengetahuan dari source;
- sistematika penulisan.

BAB II — Gambaran Umum Sistem:
- profil singkat layanan TIK/Diskominfotik tanpa mengarang sejarah organisasi;
- definisi Gelatik;
- masalah yang diselesaikan;
- aktor dan stakeholder;
- role user, BKD, admin, superadmin;
- daftar fitur tingkat tinggi;
- kebutuhan fungsional dan nonfungsional yang dapat dibuktikan;
- asumsi dan dependency eksternal.

BAB III — Arsitektur dan Tech Stack:
- arsitektur high-level;
- penjelasan hubungan Flutter, Vue, Laravel, Node, database, FCM, AI, SIMKI, dan WhatsApp;
- prinsip REST sebagai source of truth;
- frontend/backend separation;
- penjelasan setiap teknologi dan alasan/fungsinya;
- struktur monorepo;
- deployment topology development dan production konseptual;
- data flow normal dan failure/degraded mode.

BAB IV — Dokumentasi Mobile Flutter:
- arsitektur feature-first;
- Riverpod, Dio, Secure Storage, SharedPreferences, Socket.IO, WebView, File Picker;
- navigasi dan shell;
- seluruh fitur user;
- fitur admin mobile;
- status dukungan BKD;
- design system mobile;
- cache/realtime/error handling;
- status FCM yang sebenarnya;
- kebutuhan konfigurasi/build per platform;
- daftar layar/modul yang dapat diverifikasi.

BAB V — Dokumentasi Website Vue:
- Vue SPA, Vite, Router, Pinia, Axios, Tailwind, Socket.IO;
- halaman publik;
- portal user /app;
- portal BKD /bkd;
- portal admin /admin;
- route guard dan session per tab;
- cache, error normalization, dan realtime refetch;
- GovernmentAuthLayout serta design system public-service;
- status Firebase Web Messaging;
- responsive behavior dan accessibility yang dapat dibuktikan.

BAB VI — Dokumentasi Backend Laravel:
- tanggung jawab dan struktur layer;
- Passport, role/permission, policy, validation;
- kelompok endpoint API lengkap dan tabel endpoint;
- auth/register/login/reset OTP/profile;
- peminjaman, konsultasi, email ASN, router/bandwidth;
- kritik-saran, rating, notifikasi, WhatsApp;
- chatbot FAQ-first/RAG, provider fallback, keamanan prompt, eskalasi;
- laporan CSV/XLSX;
- transaction, locking, idempotency, attachment authorization;
- FCM dan integrasi eksternal;
- audit log dan settings.

Untuk tabel API gunakan kolom: Modul, Method, Path, Auth, Role, Tujuan, Request Utama, Response Utama, Error Penting. Jika payload tidak dapat diverifikasi, jangan isi dengan tebakan.

BAB VII — Dokumentasi Backend Node.js:
- peran Express/Socket.IO/Baileys;
- endpoint health/internal broadcast/WhatsApp yang terverifikasi;
- autentikasi socket melalui Laravel /api/me;
- room dan batasannya;
- event allow-list;
- schema payload minimal dan larangan sensitive fields;
- alur Laravel → Node → client;
- WhatsApp session, QR, delivery status, dan opt-in;
- fallback bila service Node mati;
- CORS dan internal API key.

BAB VIII — Dokumentasi Database:
- strategi schema legacy + migration incremental;
- katalog seluruh tabel berdasarkan schema/migration yang dilampirkan;
- data dictionary: tabel, tujuan, primary key, foreign key, kolom penting, tipe, nullable, default, dan indeks;
- hubungan users/RBAC/Passport;
- peminjaman dan item;
- konsultasi/topik/FAQ/response;
- pegawai dan usulan email;
- router/bandwidth;
- notifications/read state;
- WhatsApp;
- chatbot;
- konten, feedback, settings, cache/jobs/audit;
- migration penting dan urutan penerapannya;
- backup, rollback, dan larangan migrate:fresh pada database existing.

Jangan membuat nama kolom atau foreign key yang tidak ada di sumber. Bila schema SQL dan migration berbeda, jelaskan baseline serta perubahan incremental.

BAB IX — Analisis Alur Bisnis:
- login/registrasi/reset OTP;
- peminjaman dari pengajuan sampai selesai/ditolak;
- konsultasi dari pembuatan sampai respons/status akhir;
- pengajuan email: user → BKD → admin;
- chatbot → tiga saran gagal → konfirmasi → tiket;
- notifikasi: durable inbox, Socket.IO, FCM, WhatsApp;
- bandwidth user dan fallback OPD;
- laporan dan ekspor.

Untuk setiap alur jelaskan trigger, aktor, precondition, langkah, validasi, perubahan status, data yang disimpan, notifikasi, error path, dan postcondition.

BAB X — Keamanan, Privasi, dan Keandalan:
- Passport bearer token;
- backend authorization dan ownership;
- role/permission;
- secret hygiene;
- internal API key;
- CORS;
- validation/upload security;
- prompt injection defense;
- payload realtime minimal;
- transaction/locking/idempotency;
- cache consistency;
- degraded mode tanpa Socket.IO/FCM/AI/WhatsApp/SIMKI;
- data pribadi ASN dan rekomendasi perlindungan;
- risiko yang benar-benar teridentifikasi.

BAB XI — Instalasi, Konfigurasi, dan Operasional:
- prasyarat;
- setup Laravel, database, Passport, Node, Vue, Flutter;
- environment variable berdasarkan example/source tanpa menampilkan secret;
- perintah menjalankan setiap service;
- port dan URL development;
- migration aman;
- queue/worker bila dibutuhkan;
- troubleshooting umum;
- checklist deployment dan handover production;
- backup/restore konseptual.

BAB XII — Pengujian dan Quality Assurance:
- strategi unit, feature, integration, UI/widget, realtime, dan build;
- perintah test tiap komponen;
- matriks skenario berdasarkan role dan workflow;
- negative tests untuk ownership/authorization/validation;
- hasil test hanya berdasarkan bukti yang tersedia;
- bedakan kegagalan source dan keterbatasan environment;
- user acceptance test checklist;
- regression checklist untuk web/mobile/backend/Node/database.

BAB XIII — Pembaruan Terbaru:
- timeline commit 25–26 Agustus, 30 Agustus, 31 Agustus 2026;
- commit `a1bb5dc` tanggal 1 September 2026;
- redesign website/mobile;
- workflow BKD;
- bandwidth user;
- chatbot tiga kegagalan;
- kontrak realtime usulan email;
- test yang ditambah/diubah;
- tandai status deployment sebagai belum terverifikasi bila tidak ada bukti deployment.

BAB XIV — Keterbatasan, Technical Debt, dan Rekomendasi:
- FCM client mobile belum nyata;
- FCM Web belum ada;
- belum ada room role BKD;
- portal BKD mobile belum khusus;
- kebutuhan tabel sessions jika database session;
- audit env example;
- dependency layanan eksternal;
- kesiapan target Flutter;
- strategi observability, backup, CI/CD, security review, dan rollout yang disarankan;
- pisahkan prioritas kritis, tinggi, sedang, dan rendah.

BAB XV — Penutup:
- kesimpulan;
- kontribusi sistem;
- saran pengembangan.

Lampiran:
- inventaris endpoint;
- data dictionary;
- event registry Socket.IO;
- matriks role-permission;
- matriks fitur per platform;
- daftar environment variable tanpa nilai secret;
- command reference;
- test checklist;
- glossary;
- daftar file sumber yang dijadikan referensi.

DIAGRAM WAJIB
Buat diagram yang rapi dan diberi nomor/judul:
1. System context diagram.
2. Component/container architecture.
3. Deployment diagram development dan konseptual production.
4. Use case diagram per role.
5. Flowchart registrasi/login/reset OTP.
6. Flowchart peminjaman.
7. Flowchart konsultasi.
8. Flowchart pengajuan email user–BKD–admin.
9. Flowchart chatbot escalation.
10. Sequence diagram REST + Socket.IO refetch.
11. Sequence diagram FCM/WhatsApp notification.
12. ERD/logical data model berdasarkan schema yang benar-benar tersedia.
13. State diagram peminjaman, konsultasi, dan usulan email.

Jika generator Word tidak mendukung Mermaid secara langsung, render diagram menjadi PNG/SVG berkualitas tinggi lalu sisipkan ke Word. Jangan menaruh source Mermaid mentah sebagai pengganti diagram final. Gunakan orientasi landscape untuk diagram/tabel lebar. Pastikan semua teks diagram terbaca saat dicetak A4.

FORMAT DAN DESAIN WORD
- Kertas A4.
- Margin akademik yang wajar; gunakan konsisten.
- Font utama Aptos/Calibri 11 atau Times New Roman 12 sesuai gaya laporan akademik.
- Heading memakai style Word Heading 1/2/3 agar daftar isi otomatis.
- Nomor bab, subbab, gambar, dan tabel konsisten.
- Header/footer profesional dan nomor halaman.
- Caption serta cross-reference untuk setiap gambar/tabel.
- Tabel tidak terpotong buruk; ulangi header row pada halaman berikutnya.
- Code/config memakai font monospaced dan shading lembut.
- Gunakan bahasa Indonesia baku, tetapi nama teknologi/endpoint tetap asli.
- Jangan memakai emoji dalam dokumen formal.
- Tambahkan callout “Catatan”, “Peringatan”, dan “Keterbatasan” bila relevan.
- Buat daftar isi, daftar gambar, dan daftar tabel sebagai field yang dapat diperbarui di Word bila alat mendukung.

ATURAN SCREENSHOT
Jangan membuat screenshot UI palsu. Jika screenshot asli tidak dilampirkan, buat kotak placeholder yang jelas, misalnya “Gambar X — Tempatkan screenshot Dashboard User di sini”, kemudian sertakan daftar screenshot yang perlu diambil dari mobile dan website.

MATRIKS YANG WAJIB ADA
1. Fitur × platform (Mobile, Website, Laravel, Node).
2. Role × permission/aksi.
3. Modul × endpoint.
4. Event × target room × pemicu × refetch resource.
5. Integrasi eksternal × fungsi × credential × fallback × dampak kegagalan.
6. Risiko × dampak × probabilitas × mitigasi × prioritas.
7. Test case × precondition × langkah × expected result.

QUALITY GATE SEBELUM MENYERAHKAN
Lakukan audit mandiri dan laporkan checklist pada akhir dokumen:
- tidak menyebut Laravel 11;
- tidak menyebut whatsapp-web.js;
- tidak mengklaim FCM client sudah production-ready;
- tidak mengklaim Socket.IO sebagai source of truth;
- role BKD dan admin tidak tertukar;
- semua status/alur cocok dengan source;
- endpoint dan tabel tidak dikarang;
- commit terbaru dan status deployment dibedakan;
- seluruh diagram konsisten dengan penjelasan;
- daftar isi/caption/cross-reference valid;
- tidak ada secret atau data pribadi nyata;
- tidak ada bagian kosong selain placeholder identitas/tanda tangan/screenshot yang memang diminta.

OUTPUT YANG DIMINTA
1. Buat file akhir bernama `Dokumentasi_Lengkap_Project_Gelatik.docx`.
2. Bila memungkinkan, buat juga PDF preview `Dokumentasi_Lengkap_Project_Gelatik.pdf` untuk pemeriksaan visual.
3. Tampilkan ringkasan isi, jumlah halaman, daftar diagram, daftar tabel, sumber yang dipakai, asumsi, dan hal yang belum dapat diverifikasi.
4. Sebelum final, render seluruh halaman dan periksa layout: tidak ada teks terpotong, tabel keluar margin, gambar buram, orphan heading, halaman kosong tidak sengaja, atau nomor/caption rusak.
5. Jangan berhenti hanya dengan outline. Isi seluruh bab dengan penjelasan substantif berdasarkan artefak yang tersedia.
```

## Prompt lanjutan untuk revisi anti-misinformasi

Gunakan setelah dokumen pertama selesai:

```text
Audit ulang dokumen Word yang baru dibuat terhadap README.md, PENGETAHUAN_LENGKAP_DAN_PROMPT_PROJECT_GELATIK.md, source code, migration, test, dan Postman Collection. Buat tabel temuan berisi lokasi dokumen, klaim, bukti source, status benar/salah/tidak terverifikasi, serta revisi. Perbaiki langsung seluruh klaim salah atau terlalu pasti. Jangan mengubah fakta menjadi lebih menarik dengan mengorbankan akurasi. Render ulang seluruh halaman dan serahkan versi final .docx serta PDF preview.
```
