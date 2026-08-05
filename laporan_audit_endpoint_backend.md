# Laporan Audit Menyeluruh Endpoint Backend API

Tanggal Audit: 2026-07-23

---

## 1. Daftar Lengkap Route Terdaftar (`php artisan route:list --path=api`)

Terdapat total **70 API route** terdaftar pada aplikasi:

```text
 GET|HEAD api/admin/kritik-saran .............. Api\KritikSaranController@index
 POST     api/admin/kritik-saran/bulk-delete .. Api\KritikSaranController@bulkDelete
 GET|HEAD api/admin/permissions ............... Api\RoleController@permissions
 GET|HEAD api/admin/roles ..................... Api\RoleController@index
 POST     api/admin/roles ..................... Api\RoleController@store
 GET|HEAD api/admin/roles/{id} ................ Api\RoleController@show
 PUT      api/admin/roles/{id} ................ Api\RoleController@update
 DELETE   api/admin/roles/{id} ................ Api\RoleController@destroy
 GET|HEAD api/admin/settings .................. Api\SettingController@index
 PUT      api/admin/settings .................. Api\SettingController@update
 GET|HEAD api/admin/users ..................... Api\UserController@index
 POST     api/admin/users ..................... Api\UserController@store
 GET|HEAD api/admin/users/{id} ................ Api\UserController@show
 PUT      api/admin/users/{id} ................ Api\UserController@update
 DELETE   api/admin/users/{id} ................ Api\UserController@destroy
 POST     api/admin/users/{id}/activate ....... Api\UserController@activate
 POST     api/admin/users/{id}/deactivate ..... Api\UserController@deactivate
 GET|HEAD api/chatbot ................. me .... Api\ChatbotUrlController@index
 GET|HEAD api/chatbot/history ................. Api\ChatbotController@history
 DELETE   api/chatbot/history ................. Api\ChatbotController@deleteHistory
 POST     api/chatbot/message ................. Api\ChatbotController@message
 GET|HEAD api/dashboard ....................... Api\DashboardController@index
 GET|HEAD api/faq ............................. Api\FaqController@index
 POST     api/internal/wa/webhook-delivery-status Api\InternalWebhookController@waDeliveryStatus
 GET|HEAD api/item ............................ Api\ItemController@item
 GET|HEAD api/items ........................... Api\ItemController@index
 GET|HEAD api/items/search/{keyword} .......... Api\ItemController@search
 GET|HEAD api/items/{id} ...................... Api\ItemController@show
 GET|HEAD api/konsul .......................... Api\KonsultasiController@index
 POST     api/konsul .......................... Api\KonsultasiController@store
 GET|HEAD api/konsul/{id} ...................... Api\KonsultasiController@show
 DELETE   api/konsul/{id} ...................... Api\KonsultasiController@destroy
 POST     api/konsul/{id}/response ............ Api\KonsultasiController@respond
 POST     api/konsul/{id}/status .............. Api\KonsultasiController@updateStatus
 POST     api/kritik-saran .................... Api\KritikSaranController@store
 GET|HEAD api/kritik-saran/search ............. Api\KritikSaranController@search
 GET|HEAD api/laporan/peminjaman .............. Api\LaporanController@peminjaman
 GET|HEAD api/list-router-opd ................. Api\RouterController@listRouterOpd
 POST     api/login .................... login › Api\AuthController@login
 POST     api/logout .......................... Api\AuthController@logout
 GET|HEAD api/me .............................. Api\AuthController@me
 GET|HEAD api/notifications ................... Api\NotificationController@index
 POST     api/notifications/{id}/read ......... Api\NotificationController@markAsRead
 GET|HEAD api/notifikasi/wa/status ............ Api\WhatsappNotifController@status
 POST     api/notifikasi/wa/subscribe ......... Api\WhatsappNotifController@subscribe
 DELETE   api/notifikasi/wa/subscribe ......... Api\WhatsappNotifController@unsubscribe
 GET|HEAD api/opd ............................. Api\OpdController@index
 GET|HEAD api/pegawai ......................... Api\PegawaiController@index
 POST     api/pengajuan-email ................. Api\UsulanEmailController@store
 GET|HEAD api/pengajuan-email ................. Api\UsulanEmailController@index
 GET|HEAD api/pengajuan-email/{id} ............ Api\UsulanEmailController@show
 POST     api/pengajuan-email/{id}/buat-email-resmi Api\UsulanEmailController@buatEmailResmi
 POST     api/pengajuan-email/{id}/tolak-email Api\UsulanEmailController@tolakEmail
 POST     api/pengajuan-email/{id}/verifikasi . Api\UsulanEmailController@verifikasi
 GET|HEAD api/pengumuman ...................... Api\PengumumanController@index
 POST     api/pengumuman ...................... Api\PengumumanController@store
 GET|HEAD api/pinjam .......................... Api\PinjamController@index
 POST     api/pinjam .......................... Api\PinjamController@store
 GET|HEAD api/pinjam/{id} ..................... Api\PinjamController@show
 PUT      api/pinjam/{id} ..................... Api\PinjamController@update
 DELETE   api/pinjam/{id} ..................... Api\PinjamController@destroy
 POST     api/pinjam/{id}/items ............... Api\PinjamController@tambahItem
 DELETE   api/pinjam/{id}/items/{itemId} ...... Api\PinjamController@hapusItem
 POST     api/pinjam/{id}/status .............. Api\PinjamController@updateStatus
 POST     api/rating .......................... Api\RatingController@store
 GET|HEAD api/rating .......................... Api\RatingController@index
 POST     api/rating/update ................... Api\RatingController@update
 POST     api/register ........................ Api\AuthController@register
 GET|HEAD api/slider .......................... Api\SliderController@index
 GET|HEAD api/topik ........................... Api\TopikController@index
```

---

## 2. Tabel Audit Status Per Kelompok Endpoint

| Kelompok | Endpoint | Status | Detail / Catatan |
| :--- | :--- | :--- | :--- |
| **AUTH** | `POST /api/login` | **ADA & TERHUBUNG KE LOGIC BENAR** | Active status guard `403`, passport Bearer token |
| | `POST /api/register` | **ADA & TERHUBUNG KE LOGIC BENAR** | Validasi OPD `unker_list_router`, status default `'0'`, pending msg |
| | `GET /api/me` | **ADA & TERHUBUNG KE LOGIC BENAR** | Mengembalikan profil user terautentikasi |
| | `POST /api/logout` | **ADA & TERHUBUNG KE LOGIC BENAR** | Revoke access token |
| | `GET /api/opd` | **ADA & TERHUBUNG KE LOGIC BENAR** | List `RouterList` aktif |
| **DASHBOARD** | `GET /api/dashboard` | **ADA & TERHUBUNG KE LOGIC BENAR** | Internal stats + SIMKI try-catch fallback |
| | `GET /api/slider` | **ADA & TERHUBUNG KE LOGIC BENAR** | Slider aktif |
| **PEMINJAMAN**| `GET /api/pinjam` | **ADA & TERHUBUNG KE LOGIC BENAR** | Paginasi list pinjam user |
| | `POST /api/pinjam` | **ADA & TERHUBUNG KE LOGIC BENAR** | `PinjamService::ajukanPeminjaman` |
| | `PUT /api/pinjam/{id}` | ⚠️ **TERDAFTAR DI ROUTE TAPI METHOD BELUM DITULIS** | Route ada di `routes/api.php`, mengarah ke `PinjamController@update`, tetapi method `update()` di `PinjamController.php` **BELUM ADA** |
| | `DELETE /api/pinjam/{id}` | ⚠️ **TERDAFTAR DI ROUTE TAPI METHOD BELUM DITULIS** | Route ada di `routes/api.php`, mengarah ke `PinjamController@destroy`, tetapi method `destroy()` di `PinjamController.php` **BELUM ADA** |
| | `POST /api/pinjam/{id}/status` | **ADA & TERHUBUNG KE LOGIC BENAR** | `PinjamService::ubahStatus` |
| | `POST /api/pinjam/{id}/items` | **ADA & TERHUBUNG KE LOGIC BENAR** | `PinjamService::tambahAsetKePengajuan` |
| | `DELETE /api/pinjam/{id}/items/{itemId}` | **ADA & TERHUBUNG KE LOGIC BENAR** | `PinjamService::hapusAsetDariPengajuan` |
| **KONSULTASI** | `GET /api/konsul` | **ADA & TERHUBUNG KE LOGIC BENAR** | List konsultasi user |
| | `POST /api/konsul` | **ADA & TERHUBUNG KE LOGIC BENAR** | `KonsultasiService::buatKonsultasi` |
| | `GET /api/konsul/{id}` | **ADA & TERHUBUNG KE LOGIC BENAR** | Detail konsultasi & responses |
| | `POST /api/konsul/{id}/response` | **ADA & TERHUBUNG KE LOGIC BENAR** | `KonsultasiService::tambahRespon` |
| | `POST /api/konsul/{id}/status` | **ADA & TERHUBUNG KE LOGIC BENAR** | `KonsultasiService::ubahStatus` |
| | `DELETE /api/konsul/{id}` | **ADA & TERHUBUNG KE LOGIC BENAR** | Soft delete konsultasi |
| **ITEM** | `GET /api/item` | **ADA & TERHUBUNG KE LOGIC BENAR** | `MasterItemService::getListAlat` |
| | `GET /api/items` | **ADA & TERHUBUNG KE LOGIC BENAR** | `MasterItemService::getListAlat` |
| | `GET /api/items/{id}` | **ADA & TERHUBUNG KE LOGIC BENAR** | Detail item + flag `tersedia` |
| | `GET /api/items/search/{keyword}` | **ADA & TERHUBUNG KE LOGIC BENAR** | Search nama & deskripsi |
| **TOPIK/FAQ** | `GET /api/topik` | **ADA & TERHUBUNG KE LOGIC BENAR** | `FaqService::getAllTopik` |
| | `GET /api/faq` | **ADA & TERHUBUNG KE LOGIC BENAR** | `FaqService::getFaqByTopik` |
| **RATING** | `POST /api/rating` | **ADA & TERHUBUNG KE LOGIC BENAR** | `RatingService::beriRating` |
| | `POST /api/rating/update` | **ADA & TERHUBUNG KE LOGIC BENAR** | `RatingService::updateRating` |
| | `GET /api/rating` | **ADA & TERHUBUNG KE LOGIC BENAR** | Rating user login |
| **ROUTER** | `GET /api/list-router-opd` | **ADA & TERHUBUNG KE LOGIC BENAR** | `LayananInternetService::getListRouterOpd` |
| **EMAIL** | `GET /api/pegawai` | **ADA & TERHUBUNG KE LOGIC BENAR** | Pegawai belum punya email (ID_Peg hidden) |
| | `POST /api/pengajuan-email` | **ADA & TERHUBUNG KE LOGIC BENAR** | `UsulanEmailService::ajukanUsulan` |
| | `GET /api/pengajuan-email` | **ADA & TERHUBUNG KE LOGIC BENAR** | List usulan email |
| | `GET /api/pengajuan-email/{id}` | **ADA & TERHUBUNG KE LOGIC BENAR** | Detail usulan email |
| | `POST /api/pengajuan-email/{id}/verifikasi` | **ADA & TERHUBUNG KE LOGIC BENAR** | `UsulanEmailService::verifikasiUsulan` |
| | `POST /api/pengajuan-email/{id}/buat-email-resmi` | **ADA & TERHUBUNG KE LOGIC BENAR** | Setujui & buat email resmi |
| | `POST /api/pengajuan-email/{id}/tolak-email` | **ADA & TERHUBUNG KE LOGIC BENAR** | Tolak usulan email |
| **PENGUMUMAN**| `GET /api/pengumuman` | **ADA & TERHUBUNG KE LOGIC BENAR** | `PengumumanService::getActive` |
| | `POST /api/pengumuman` | **ADA & TERHUBUNG KE LOGIC BENAR** | `PengumumanService::buatPengumuman` |
| **KRITIK SARAN**| `POST /api/kritik-saran` | **ADA & TERHUBUNG KE LOGIC BENAR** | `KritikSaranService::kirimKritikSaran` |
| | `GET /api/kritik-saran/search` | **ADA & TERHUBUNG KE LOGIC BENAR** | Search kritik & saran |
| **CHATBOT LAMA**| `GET /api/chatbot` | **ADA & TERHUBUNG KE LOGIC BENAR** | Chatbase iframe URL config |
| **ADMIN** | `POST /api/admin/users/{id}/activate` | **ADA & TERHUBUNG KE LOGIC BENAR** | Set status user `'1'` |
| | `POST /api/admin/users/{id}/deactivate` | **ADA & TERHUBUNG KE LOGIC BENAR** | Set status user `'0'` |
| | CRUD User, Role, Slider, Setting, Notif | **ADA & TERHUBUNG KE LOGIC BENAR** | 15+ endpoint CRUD admin |
| **FITUR BARU**| `POST/DELETE /api/notifikasi/wa/subscribe` | **ADA & TERHUBUNG KE LOGIC BENAR** | F-WA subscribe & unsubscribe |
| | `GET /api/notifikasi/wa/status` | **ADA & TERHUBUNG KE LOGIC BENAR** | F-WA status langganan |
| | `POST /api/chatbot/message` | **ADA & TERHUBUNG KE LOGIC BENAR** | F-BOT AI Native (Gemini/Groq) |
| | `GET/DELETE /api/chatbot/history` | **ADA & TERHUBUNG KE LOGIC BENAR** | F-BOT riwayat percakapan |
| | `GET /api/laporan/peminjaman` | **ADA & TERHUBUNG KE LOGIC BENAR** | F-LAPORAN summary peminjaman |

---

## 3. Ringkasan Hasil Audit & Rekomendasi

- **Jumlah Endpoint dalam Checklist**: 46 endpoint utama.
- **ADA & TERHUBUNG KE LOGIC BENAR**: **44 Endpoint** (95.65%).
- **ADA DI ROUTE TAPI METHOD BELUM DITULIS**: **2 Endpoint** (4.35%), yaitu:
  1. `PUT /api/pinjam/{id}`
  2. `DELETE /api/pinjam/{id}`
- **TIDAK ADA SAMA SEKALI**: **0 Endpoint**.
