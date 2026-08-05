# Laporan Inspeksi Database Batch 2 & Verifikasi Relasi

Tanggal Inspeksi: 2026-07-23

---

## 1. Verifikasi Relasi Konsultasi-Topik (`tr_konsultasi`)

- **Nama Kolom Foreign Key**: **`faq_id`** (`bigint(20) unsigned NOT NULL`).
- **Struktur Lengkap Tabel `tr_konsultasi`**:

| Nama Kolom | Tipe Data | Nullable | Default | Keterangan |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint(20) unsigned` | NO | *NULL* | Primary Key |
| `user_id` | `bigint(20) unsigned` | NO | *NULL* | Foreign Key ke `users.id` |
| `judul` | `varchar(255)` | NO | *NULL* | Judul konsultasi |
| `pesan` | `text` | NO | *NULL* | Isi pesan / deskripsi |
| `file` | `text` | YES | *NULL* | Path lampiran file |
| `status` | `enum('Menunggu','Diproses','Ditolak','Selesai')` | NO | `'Menunggu'` | Status konsultasi |
| `created_by` | `bigint(20) unsigned` | NO | *NULL* | Creator |
| `updated_by` | `bigint(20) unsigned` | YES | *NULL* | Updater |
| `created_at` | `timestamp` | YES | *NULL* | |
| `updated_at` | `timestamp` | YES | *NULL* | |
| `deleted_at` | `timestamp` | YES | *NULL* | Soft deletes |
| `faq_id` | `bigint(20) unsigned` | NO | *NULL* | Foreign Key ke `master_topik` |

---

## 2. Struktur Tabel Batch 2

### A. Tabel `usulan_email`

**Struktur Lengkap Kolom**:

| Nama Kolom | Tipe Data | Nullable | Default | Keterangan |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint(20) unsigned` | NO | *NULL* | Primary Key |
| `id_peg_bkd` | `bigint(20) unsigned` | NO | *NULL* | Foreign Key ke ID Pegawai (SIMKI/BKD) |
| `email_pribadi` | `varchar(100)` | NO | *NULL* | Email pribadi pemohon |
| `email_resmi` | `varchar(100)` | YES | *NULL* | Email resmi yang disetujui |
| `status` | `enum('draft','diajukan','disetujui','ditolak')` | NO | `'draft'` | Status pengajuan usulan email |
| `tanggal_verifikasi` | `datetime` | YES | *NULL* | Tanggal verifikasi/approval |
| `diverifikasi_oleh` | `varchar(100)` | YES | *NULL* | Nama/identitas verifikator (BKD/Admin) |
| `catatan` | `text` | YES | *NULL* | Catatan atau alasan penolakan |
| `created_at` | `timestamp` | YES | *NULL* | |
| `updated_at` | `timestamp` | YES | *NULL* | |
| `created_by` | `int(11)` | YES | *NULL* | |
| `updated_by` | `int(11)` | YES | *NULL* | |

- **Contoh Data**: Tabel saat ini masih **kosong** (0 baris).

**Jawaban Spesifik Temuan `usulan_email`**:
1. **Nilai Enum Status**: **`'draft'`, `'diajukan'`, `'disetujui'`, `'ditolak'`** (huruf kecil).
2. **Kolom Referensi `ID_Peg`**: Named **`id_peg_bkd`** (`bigint(20) unsigned NOT NULL`).
3. **Pencatatan Verifikasi/Approval**: Menggunakan 1 pasang kolom pencatatan umum yaitu `diverifikasi_oleh` (`varchar(100)`), `tanggal_verifikasi` (`datetime`), `catatan` (`text`), dan `status` (`enum`).

---

### B. Tabel `unker_list_router`

| Nama Kolom | Tipe Data | Nullable | Default | Keterangan |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `bigint(20)` | NO | *NULL* | Primary Key |
| `nama_opd` | `varchar(500)` | NO | *NULL* | Nama OPD |
| `identity_router` | `varchar(2000)` | NO | *NULL* | Identity/Host Router |
| `interface` | `varchar(255)` | YES | *NULL* | Interface router |
| `lokasi` | `varchar(1000)` | YES | *NULL* | Lokasi fisik/geografis |
| `status` | `int(11)` | YES | `1` | Status router (1=aktif, 0=nonaktif) |
| `created_by` | `int(11)` | YES | *NULL* | |
| `created_at` | `timestamp` | YES | *NULL* | |
| `updated_by` | `int(11)` | YES | *NULL* | |
| `updated_at` | `timestamp` | YES | *NULL* | |

---

### C. Tabel `unker_router`

| Nama Kolom | Tipe Data | Nullable | Default | Keterangan |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `int(11)` | NO | *NULL* | Primary Key |
| `nama_opd` | `varchar(500)` | NO | *NULL* | Nama OPD |
| `nama_router` | `varchar(500)` | YES | *NULL* | Nama Router |
| `is_active` | `int(11)` | NO | `1` | Flag aktif (1/0) |
| `created_by` | `int(11)` | YES | *NULL* | |
| `created_at` | `timestamp` | YES | *NULL* | |
| `updated_by` | `int(11)` | YES | *NULL* | |
| `updated_at` | `timestamp` | YES | *NULL* | |
