# Laporan Inspeksi Struktur Database & Package (db_layanantik)

Tanggal Inspeksi: 2026-07-23

---

## 1. Struktur Lengkap Kolom Tabel `users`

| Nama Kolom | Tipe Data | Nullable | Default | Keterangan |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint(20) unsigned` | NO | *NULL* | Primary Key |
| `name` | `varchar(255)` | NO | *NULL* | |
| `nama_opd` | `varchar(255)` | YES | *NULL* | |
| `username` | `varchar(50)` | NO | *NULL* | |
| `email` | `varchar(255)` | NO | *NULL* | |
| `email_verified_at` | `timestamp` | YES | *NULL* | |
| `password` | `varchar(255)` | NO | *NULL* | |
| `remember_token` | `varchar(100)` | YES | *NULL* | |
| `no_hp` | `varchar(20)` | YES | *NULL* | |
| `status` | `enum('1','0')` | NO | `'0'` | Status akun |
| `picture` | `varchar(255)` | YES | *NULL* | |
| `created_by` | `smallint(6)` | YES | *NULL* | |
| `updated_by` | `smallint(6)` | YES | *NULL* | |
| `created_at` | `timestamp` | YES | *NULL* | |
| `updated_at` | `timestamp` | YES | *NULL* | |
| `deleted_at` | `timestamp` | YES | *NULL* | Soft Deletes |
| `avatar` | `varchar(255)` | YES | *NULL* | |

---

## 2. Struktur Lengkap Kolom Tabel `notification`

| Nama Kolom | Tipe Data | Nullable | Default | Keterangan |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint(20) unsigned` | NO | *NULL* | Primary Key |
| `user_id` | `bigint(20) unsigned` | NO | *NULL* | Foreign Key ke `users.id` |
| `judul` | `varchar(255)` | NO | *NULL* | Judul notifikasi |
| `message` | `varchar(255)` | NO | *NULL* | Pesan notifikasi |
| `item_id` | `bigint(20)` | NO | *NULL* | ID terkait entitas |
| `type` | `varchar(20)` | NO | `'konsultasi'` | Tipe notifikasi |
| `read` | `tinyint(4)` | NO | `0` | Flag status dibaca (0/1) |
| `created_at` | `timestamp` | YES | *NULL* | |
| `updated_at` | `timestamp` | YES | *NULL* | |

---

## 3. Contoh Data Tabel `notification` (3 Baris Pertama)

1. **Data #1**:
   - `id`: `1`
   - `user_id`: `0`
   - `judul`: `"Permintaan Konsultasi"`
   - `message`: `"Sebuah permintaan konsultasi telah diminta."`
   - `item_id`: `1`
   - `type`: `"konsultasi"`
   - `read`: `1`
   - `created_at`: `"2022-08-26 11:22:52"`
   - `updated_at`: `"2022-08-26 11:25:13"`

2. **Data #2**:
   - `id`: `2`
   - `user_id`: `0`
   - `judul`: `"Peminjaman Asset"`
   - `message`: `"Sebuah permintaan peminjaman asset telah diminta."`
   - `item_id`: `1`
   - `type`: `"pinjam"`
   - `read`: `1`
   - `created_at`: `"2022-08-31 14:12:23"`
   - `updated_at`: `"2022-08-31 14:28:20"`

3. **Data #3**:
   - `id`: `3`
   - `user_id`: `0`
   - `judul`: `"Peminjaman Asset"`
   - `message`: `"Sebuah permintaan peminjaman asset telah diminta."`
   - `item_id`: `2`
   - `type`: `"pinjam"`
   - `read`: `1`
   - `created_at`: `"2022-08-31 14:50:47"`
   - `updated_at`: `"2022-08-31 14:56:42"`

---

## 4. Hasil Pencarian Kolom Terkait FCM / Token / Device / Push

Pencarian otomatis pada `INFORMATION_SCHEMA.COLUMNS` untuk skema `db_layanantik` menemukan 6 kolom pada 4 tabel berikut:

- `users` → `remember_token` (`varchar`)
- `password_resets` → `token` (`varchar`)
- `personal_access_tokens` → `tokenable_type` (`varchar`), `tokenable_id` (`bigint`), `token` (`varchar`)
- `oauth_refresh_tokens` → `access_token_id` (`varchar`)

> **Catatan**: Tidak ditemukan kolom khusus untuk menyimpan token Push Notification / FCM (seperti `fcm_token`, `device_token`, atau sejenisnya) di seluruh 32 tabel database.

---

## 5. Status Package Firebase di `composer.json`

**Status**: **TIDAK ADA** (Belum pernah di-install)

Daftar package terpasang saat ini di bagian `require`:
- `php`: `^8.3`
- `barryvdh/laravel-snappy`: `^1.0`
- `laravel/framework`: `^13.8`
- `laravel/passport`: `^13.7`
- `laravel/tinker`: `^3.0`
- `maatwebsite/excel`: `^3.1`
- `spatie/laravel-activitylog`: `^5.0`
- `spatie/laravel-permission`: `^8.3`
- `yajra/laravel-datatables-oracle`: `^13.1`
