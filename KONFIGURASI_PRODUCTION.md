# ⚙️ PANDUAN KONFIGURASI PRODUCTION (HANDOVER TIM TIK)

Dokumen ini mendata seluruh environment variable yang membutuhkan pengisian/penyesuaian kredensial asli sebelum aplikasi **Backend Terpadu (Layanan TIK Web + UltiMobile Gelatik)** diserahterimakan dan dijalankan di lingkungan *Production / Server Resmi Diskominfotik*.

---

## Tabel Daftar Environment Variable Production

| Nama Variable | Lokasi | Nilai Saat Ini (Lokal) | Keterangan yang Perlu Diisi TIM TIK | Dampak Jika Belum Diisi |
| :--- | :--- | :--- | :--- | :--- |
| **`DB_HOST`** | `.env` (Laravel) | `127.0.0.1` | IP/Host Server Database Production utama Diskominfotik. | Laravel tidak dapat terhubung ke database utama aplikasi. |
| **`DB_DATABASE`** | `.env` (Laravel) | `db_layanantik` | Nama Database MySQL Production yang digunakan. | Database tidak ditemukan, API mengembalikan error 500. |
| **`DB_USERNAME`** | `.env` (Laravel) | `root` | Username MySQL Production dengan hak akses CRUD. | Akses database ditolak (*Access Denied*). |
| **`DB_PASSWORD`** | `.env` (Laravel) | *(kosong)* | Password user MySQL Production. | Akses database ditolak (*Access Denied*). |
| **`APP_URL`** | `.env` (Laravel) | `http://localhost:8000` | URL Domain/IP Publik resmi Backend Laravel (misal `https://api-layanantik.lampungprov.go.id`). | URL asset, upload file, dan callback OAuth Passport tidak sesuai. |
| **`URL_API_SIMKI`** | `.env` (Laravel) | `"https://apisimki.diskominfotik.lampungprov.go.id"` | Base URL API SIMKI resmi Diskominfotik. | Data widget SIMKI di Dashboard bernilai `null` (API tetap 200 OK). |
| **`TOKEN_SIMKI`** | `.env` (Laravel) | *(configured locally; not documented)* | Token/API Key resmi untuk mengakses SIMKI API. | Request SIMKI ditolak/unauthorized (`null`). |
| **`DB_HOST_PEGAWAI`** | `.env` (Laravel) *(Opsional)* | `<internal-host>` | Host database pegawai jika ingin mengganti tabel statis `PegawaiBelumPunyaEMail` ke koneksi live. | Tetap menggunakan data lokal statis `PegawaiBelumPunyaEMail`. |
| **`DB_DATABASE_PEGAWAI`** | `.env` (Laravel) *(Opsional)* | `<database-name>` | Nama database pegawai. | Tetap menggunakan data lokal statis `PegawaiBelumPunyaEMail`. |
| **`DB_USERNAME_PEGAWAI`** | `.env` (Laravel) *(Opsional)* | *(configured locally; not documented)* | Username database pegawai. | Tetap menggunakan data lokal statis `PegawaiBelumPunyaEMail`. |
| **`DB_PASSWORD_PEGAWAI`** | `.env` (Laravel) *(Opsional)* | *(configured locally; not documented)* | Password database pegawai. | Tetap menggunakan data lokal statis `PegawaiBelumPunyaEMail`. |
| **`GEMINI_API_KEY`** | `.env` (Laravel) | *(configured locally; not documented)* | API Key resmi Google Gemini dari Google AI Studio. | Chatbot AI tidak dapat merespons (fallback ke Groq / safe unavailable message). |
| **`GEMINI_MODEL`** | `.env` (Laravel) | `gemini-flash-latest` | Model Gemini yang digunakan (misal `gemini-1.5-flash` atau `gemini-2.0-flash`). | Chatbot menggunakan model default. |
| **`GROQ_API_KEY`** | `.env` (Laravel) | *(configured locally; not documented)* | API Key resmi Groq Cloud sebagai backup AI provider. | Chatbot tidak memiliki fallback AI jika Gemini limit/down. |
| **`GROQ_MODEL`** | `.env` (Laravel) | `llama-3.3-70b-versatile` | Model LLM Groq yang aktif. | Chatbot menggunakan model default. |
| **`INTERNAL_SERVICE_API_KEY`** | `.env` (Laravel) & `.env` (Node.js) | *(configured locally; not documented)* | Shared Secret Key (token rahasia) antar Backend Laravel dan Realtime-Service Node.js. **Wajib SAMA di kedua `.env`**. | Notifikasi WebSocket & WhatsApp Gateway ditolak (*Unauthorized*). |
| **`NODE_SERVICE_URL`** | `.env` (Laravel) | `http://127.0.0.1:4000` | URL Internal Service Node.js (misal `http://127.0.0.1:4000` atau IP lokal server node). | Laravel gagal mengirim request broadcast & WA ke Node.js. |
| **`LARAVEL_BASE_URL`** | `.env` (Node.js) | `http://127.0.0.1:8000` | Base URL Backend Laravel yang dipanggil oleh Node.js (untuk webhook/status callback WA). | Realtime service Node.js tidak bisa meneruskan webhook ke Laravel. |
| **`WHATSAPP_GATEWAY_INSTANCE`** | `.env` (Laravel) & `.env` (Node.js) | `layanantik-gateway` | Nama Instance WhatsApp Gateway yang terdaftar di engine gateway. | Pesan WhatsApp Notifikasi gagal terikirim. |
| **`FIREBASE_CREDENTIALS`** | `.env` (Laravel) | `storage/app/firebase/service-account.json` | Path relatif ke file JSON Service Account Firebase Cloud Messaging (FCM) resmi. | Push Notification ke aplikasi UltiMobile Gelatik tidak terkirim. |
| **`PASSPORT_PERSONAL_ACCESS_CLIENT_ID`** | `.env` (Laravel) | *(diisi otomatis)* | Client ID Personal Access Laravel Passport (hasil `php artisan passport:install`). | Autentikasi token API gagal jika belum di-generate. |
| **`PASSPORT_PERSONAL_ACCESS_CLIENT_SECRET`** | `.env` (Laravel) | *(diisi otomatis)* | Client Secret Personal Access Laravel Passport. | Autentikasi token API gagal jika belum di-generate. |
| **`CHATBOT_AI_REQUEST_TIMEOUT`** | `.env` (Laravel) | `8` | Batas waktu tiap provider AI; pertahankan lebih rendah dari timeout klien Chatbot. | Provider lambat diputus aman dan fallback/error 504 dikembalikan. |

---

> [!IMPORTANT]
> - Kredensial `INTERNAL_SERVICE_API_KEY` harus berupa string acak yang kuat (minimal 64 karakter) dan disamakan pada file `.env` Laravel serta `.env` Node.js.
> - Seluruh kegagalan service eksternal (SIMKI, Gemini, WA Gateway, Firebase) dirancang dengan try-catch defensif sehingga **TIDAK AKAN memutus atau menggagalkan (500 Error)** fungsi utama peminjaman/konsultasi pada aplikasi.
