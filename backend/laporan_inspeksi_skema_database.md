# 📄 LAPORAN INSPEKSI RAW SKEMA DATABASE & KONTRADIKSI AUTO_INCREMENT

**Tanggal Inspeksi:** 27 Juli 2026  
**Database Name:** `db_layanantik`  
**Objek Inspeksi:** Hasil Eksekusi Query Mentah (`SHOW CREATE TABLE`, `SELECT id`, `TRANSACTION INSERT`)  

---

## 📌 1. HASIL MENTAH EXPLICIT QUERY (`SHOW CREATE TABLE`)

### A. `SHOW CREATE TABLE tr_permintaan_pinjam;`
```sql
CREATE TABLE `tr_permintaan_pinjam` (
  `id` bigint(20) unsigned NOT NULL,
  `user_id` bigint(20) unsigned NOT NULL,
  `nama_pic` varchar(150) NOT NULL,
  `jabatan_pic` varchar(255) NOT NULL,
  `instansi_pic` varchar(255) NOT NULL,
  `kontak_pic` char(16) NOT NULL,
  `jenis_identitas` enum('KTP','SIM','Passport','NIP') NOT NULL DEFAULT 'KTP',
  `nomor_identitas` varchar(255) NOT NULL,
  `alamat_peminjam` varchar(255) NOT NULL,
  `jenis_durasi` enum('harian','jam','menit') NOT NULL DEFAULT 'harian',
  `tanggal_mulai` date NOT NULL,
  `jam_mulai` time DEFAULT NULL,
  `durasi_peminjaman` bigint(20) NOT NULL DEFAULT 0,
  `keterangan` text DEFAULT NULL,
  `url_dokumen` text DEFAULT NULL,
  `status` enum('Menunggu','Proses','Ditolak','Selesai') NOT NULL DEFAULT 'Menunggu',
  `catatan_petugas` text DEFAULT NULL,
  `rating` double DEFAULT NULL,
  `created_by` smallint(6) DEFAULT NULL,
  `updated_by` smallint(6) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `tanggal_selesai` datetime DEFAULT NULL,
  `waktu_pengembalian` datetime DEFAULT NULL,
  `bukti_pengembalian` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
```

### B. `SHOW CREATE TABLE users;`
```sql
CREATE TABLE `users` (
  `id` bigint(20) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `nama_opd` varchar(255) DEFAULT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(255) NOT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `no_hp` varchar(20) DEFAULT NULL,
  `status` enum('1','0') NOT NULL DEFAULT '0',
  `picture` varchar(255) DEFAULT NULL,
  `created_by` smallint(6) DEFAULT NULL,
  `updated_by` smallint(6) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `avatar` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
```

### C. `SHOW CREATE TABLE usulan_email;`
```sql
CREATE TABLE `usulan_email` (
  `id` bigint(20) unsigned NOT NULL,
  `id_peg_bkd` bigint(20) unsigned NOT NULL,
  `email_pribadi` varchar(100) NOT NULL,
  `email_resmi` varchar(100) DEFAULT NULL,
  `status` enum('draft','diajukan','disetujui','ditolak') NOT NULL DEFAULT 'draft',
  `tanggal_verifikasi` datetime DEFAULT NULL,
  `diverifikasi_oleh` varchar(100) DEFAULT NULL,
  `catatan` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
```

### D. `SHOW CREATE TABLE kritik_sarans;`
```sql
CREATE TABLE `kritik_sarans` (
  `id` bigint(20) unsigned NOT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `kritik` text NOT NULL,
  `saran` text NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
```

---

## 📌 2. HASIL MENTAH CEK DATA AKTUAL (`SELECT id`)

### A. `SELECT id FROM tr_permintaan_pinjam ORDER BY id DESC LIMIT 5;`
```json
[
    { "id": 921117 },
    { "id": 921116 },
    { "id": 921115 },
    { "id": 921114 },
    { "id": 921113 }
]
```

### B. `SELECT id FROM usulan_email ORDER BY id DESC LIMIT 5;`
```json
[
    { "id": 10 },
    { "id": 9 },
    { "id": 8 },
    { "id": 7 },
    { "id": 6 }
]
```

---

## 📌 3. HASIL MENTAH UJI INSERT TANPA KOLOM `id`

```text
QUERY EXECUTED:
START TRANSACTION;
INSERT INTO kritik_sarans (user_id, kritik, saran, created_at, updated_at) 
VALUES (NULL, 'test verifikasi', 'test verifikasi', NOW(), NOW());
SELECT LAST_INSERT_ID();
ROLLBACK;

STATUS RESULT: FAILED
ERROR MESSAGE: 
SQLSTATE[HY000]: General error: 1364 Field 'id' doesn't have a default value 
(Connection: mysql, Host: 127.0.0.1, Port: 3306, Database: db_layanantik, 
SQL: INSERT INTO kritik_sarans (user_id, kritik, saran, created_at, updated_at) VALUES (NULL, 'test verifikasi', 'test verifikasi', NOW(), NOW()))
```

---

## 📌 4. PENJELASAN TEKNIS KONTRADIKSI

1. **Mengapa INSERT melalui API/Service Berhasil Menyimpan Data Ber-ID Baru?**
   Pada kode aplikasi (`PinjamService.php`, `UsulanEmailService.php`, `UserController.php`, dll.), pembuatan data baru dilakukan secara eksplisit dengan melakukan kueri ID maksimum terlebih dahulu:
   ```php
   $id = DB::table('tr_permintaan_pinjam')->max('id') + 1;
   ```
   Nilai `$id` tersebut kemudian dimasukkan secara manual ke dalam array data sebelum pemicuan `insert()` / `create()`.

2. **Mengapa INSERT Murni Tanpa `id` Gagal?**
   Karena pada skema database MySQL aktual saat ini, kolom `id` pada tabel-tabel di atas terdaftar sebagai `bigint(20) unsigned NOT NULL` tanpa atribut `AUTO_INCREMENT` dan tanpa nilai `DEFAULT`. Sehingga, setiap pernyataan SQL `INSERT` murni yang tidak menyertakan kolom `id` akan ditolak oleh engine MySQL dengan error `Field 'id' doesn't have a default value`.
