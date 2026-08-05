# Laporan Inspeksi Modul-Modul Lain & Panel Admin

Tanggal Inspeksi: 2026-07-23

---

## 1. Jawaban Khusus Poin-Poin Verifikasi

### A. Pengumuman (`pengumumans`) — Kolom Expired
- **Status**: **ADA**.
- Kolom bernama **`expired_at`** (`timestamp NULL DEFAULT NULL`).
- Fitur pengumuman kedaluwarsa dapat memfilter `whereNull('expired_at')->orWhere('expired_at', '>', now())`.

### B. Rating (`ratings`) — Subjek Rating
- **Status**: **UMUM KE APLIKASI**.
- Kolom hanya terdiri dari `id`, `user_id`, `rating` (int), `created_at`, `updated_at`.
- Tidak ada foreign key ke `pinjam` atau `konsultasi`. Ini adalah rating umum kepuasan pengguna terhadap aplikasi.

### C. Master Item (`master_item`) — Kolom Stok
- **Status**: **ADA & 100% COCOK**.
- Kolom bernama **`stok`** (`bigint(20) NOT NULL default 0`).
- Sesuai persis dengan method `MasterItem::cekKetersediaan()` yang sudah diterapkan pada `PinjamService`.

### D. Permissions (`permissions`) — Pola Penamaan Existing
- **Pola Penamaan**: Menggunakan huruf kecil format `{aksi} {entitas}` (contoh: `list item`, `create pinjam`).
- **Daftar Lengkap 42 Permission Existing**:
  1. `list user`
  2. `edit user`
  3. `delete user`
  4. `create user`
  5. `list item`
  6. `edit item`
  7. `delete item`
  8. `create item`
  9. `list ruangan`
  10. `edit ruangan`
  11. `delete ruangan`
  12. `create ruangan`
  13. `list topik`
  14. `edit topik`
  15. `delete topik`
  16. `create topik`
  17. `list faq`
  18. `edit faq`
  19. `delete faq`
  20. `create faq`
  21. `list pinjam`
  22. `edit pinjam`
  23. `delete pinjam`
  24. `create pinjam`
  25. `list konsultasi`
  26. `edit konsultasi`
  27. `delete konsultasi`
  28. `create konsultasi`
  29. `list role`
  30. `edit role`
  31. `delete role`
  32. `create role`
  33. `list notifikasi`
  34. `list pengajuan`
  35. `list domain`
  36. `edit domain`
  37. `delete domain`
  38. `create domain`
  39. `list slider`
  40. `edit slider`
  41. `delete slider`
  42. `create slider`

---

## 2. Rincian Struktur Tabel

### 1. `kritik_sarans`
- `id` (`bigint(20) unsigned NOT NULL`)
- `user_id` (`bigint(20) NULL`)
- `kritik` (`text NOT NULL`)
- `saran` (`text NOT NULL`)
- `created_at`, `updated_at`

### 2. `ratings`
- `id` (`bigint(20) unsigned NOT NULL`)
- `user_id` (`bigint(20) unsigned NOT NULL`)
- `rating` (`int(11) NOT NULL`)
- `created_at`, `updated_at`

### 3. `pengumumans`
- `id` (`bigint(20) unsigned NOT NULL`)
- `judul` (`varchar(255) NOT NULL`)
- `konten` (`text NOT NULL`)
- `expired_at` (`timestamp NULL`)
- `created_at`, `updated_at`

### 4. `faq`
- `id` (`bigint(20) unsigned NOT NULL`)
- `topik_id` (`bigint(20) unsigned NOT NULL`) — FK ke `master_topik.id`
- `judul` (`varchar(255) NOT NULL`)
- `detail` (`text NOT NULL`)
- `status` (`enum('1','0') NOT NULL default '1'`)
- `created_by`, `updated_by`, `created_at`, `updated_at`, `deleted_at`

### 5. `master_topik`
- `id` (`bigint(20) unsigned NOT NULL`)
- `topik` (`varchar(100) NOT NULL`)
- `status` (`enum('1','0') NOT NULL default '1'`)
- `created_by`, `updated_by`, `created_at`, `updated_at`, `deleted_at`

### 6. `master_item`
- `id` (`bigint(20) unsigned NOT NULL`)
- `nama` (`varchar(255) NOT NULL`)
- `deskripsi` (`text NOT NULL`)
- `foto` (`text NULL`)
- `kondisi` (`enum('Baik','Rusak Sebagian','Rusak Parah','Tidak Berfungsi') NOT NULL default 'Baik'`)
- `stok` (`bigint(20) NOT NULL default 0`)
- `created_by`, `updated_by`, `created_at`, `updated_at`, `deleted_at`

### 7. `sliders`
- `id` (`bigint(20) unsigned NOT NULL`)
- `judul` (`varchar(255) NULL`)
- `image` (`text NULL`)
- `status` (`tinyint(4) NULL default 1`)
- `created_by`, `updated_by`, `created_at`, `updated_at`, `deleted_at`

### 8. `m_settings`
- `id` (`bigint(20) unsigned NOT NULL`)
- `setting_name` (`varchar(255) NOT NULL`)
- `setting_var` (`varchar(50) NOT NULL`)
- `setting_val` (`varchar(255) NULL`)
- `setting_description` (`text NOT NULL`)
- `setting_type` (`enum('text','file','textarea') NOT NULL default 'text'`)
- `created_at`, `updated_at`

---

## 3. Daftar Roles Existing (`roles`)

1. `superadmin` (id: 1)
2. `user` (id: 2)
3. `operator` (id: 3)
4. `bkd` (id: 4)
