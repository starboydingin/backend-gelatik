# Laporan Inspeksi Historis & Struktur Tabel Terkait

Tanggal Inspeksi: 2026-07-23

---

## 1. Hasil Pencarian Historis `usulan_email` di `activity_log`

Query yang dijalankan:
```sql
SELECT * 
FROM activity_log 
WHERE subject_type LIKE '%UsulanEmail%' 
   OR subject_type LIKE '%usulan_email%' 
   OR log_name LIKE '%email%' 
LIMIT 10;
```

- **Hasil**: **Tidak Ditemukan** (`0` baris data).
- **Catatan**: Meskipun tabel `activity_log` memiliki total 3.536 baris data historis secara keseluruhan, tidak ada entri log yang mencatat aktivitas terkait `UsulanEmail` atau `email`.

---

## 2. Hasil Pencarian Tabel Terkait (`bkd`, `simki`, `pegawai`)

Query yang dijalankan:
```sql
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'db_layanantik' 
  AND (TABLE_NAME LIKE '%bkd%' OR TABLE_NAME LIKE '%simki%' OR TABLE_NAME LIKE '%pegawai%');
```

- **Hasil**:
  - `pegawaibelumpunyaemail`

- **Catatan**: Dari seluruh 32 tabel di database `db_layanantik`, hanya ditemukan **1 tabel** yang sesuai dengan kata kunci pencarian tersebut, yaitu `pegawaibelumpunyaemail`. Tidak ditemukan tabel jembatan/perantara lainnya.
