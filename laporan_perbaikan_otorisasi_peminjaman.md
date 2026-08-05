# Laporan Verifikasi & Perbaikan Otorisasi Endpoint GET /api/laporan/peminjaman

## 1. Ringkasan Eksekutif

Telah dilakukan verifikasi dan perbaikan otorisasi akses pada endpoint `GET /api/laporan/peminjaman` (Laporan Peminjaman Aset TIK). Berdasarkan aturan hak akses terkini, **hanya role `admin` dan `superadmin`** (serta pengguna yang memiliki permission `list laporan`) yang diperbolehkan mengakses laporan peminjaman aset. Role `bkd` yang sebelumnya sempat mendapatkan akses telah **dikeluarkan dari daftar otorisasi**.

---

## 2. Kode Sebelum Perubahan (Before)

File: [`App\Http\Controllers\Api\LaporanController.php`](backend/app/Http/Controllers/Api/LaporanController.php#L22-L38)

```php
    /**
     * GET /api/laporan/peminjaman
     * Ambil data laporan peminjaman (F-LAPORAN)
     */
    public function peminjaman(Request $request)
    {
        $user = $request->user();
        $isAuthorized = false;
        if ($user->hasRole('admin') || $user->hasRole('superadmin') || $user->hasRole('bkd')) {
            $isAuthorized = true;
        } else {
            try {
                $isAuthorized = $user->hasPermissionTo('list laporan', 'web');
            } catch (\Exception $e) {
                $isAuthorized = false;
            }
        }

        if (!$isAuthorized) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }
```

---

## 3. Hasil Pengecekan Permission `'list laporan'`

1. **Eksistensi Permission**: Permission `'list laporan'` dengan guard `web` telah terdaftar di database (`permissions` table).
2. **Assignment Role `admin`**: Role `admin` **sudah memiliki** permission `'list laporan'` di database.
3. **Pembaruan Seeder**: File [`NewPermissionsSeeder.php`](backend/database/seeders/NewPermissionsSeeder.php#L37-L46) diperbarui agar secara otomatis meng-assign permission `'list laporan'`, `'export laporan'`, dan `'manage notifikasi-wa'` ke role `admin` (selain `superadmin`) apabila seeder dieksekusi ulang.

---

## 4. Kode Setelah Perubahan (After)

File: [`App\Http\Controllers\Api\LaporanController.php`](backend/app/Http/Controllers/Api/LaporanController.php#L22-L38)

```php
    /**
     * GET /api/laporan/peminjaman
     * Ambil data laporan peminjaman (F-LAPORAN)
     */
    public function peminjaman(Request $request)
    {
        $user = $request->user();
        $isAuthorized = false;
        if ($user->hasRole('admin') || $user->hasRole('superadmin')) {
            $isAuthorized = true;
        } else {
            try {
                $isAuthorized = $user->hasPermissionTo('list laporan', 'web');
            } catch (\Exception $e) {
                $isAuthorized = false;
            }
        }

        if (!$isAuthorized) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }
```

---

## 5. Hasil Pengujian (Matrix Sebelum & Sesudah Perubahan)

Pengujian dilakukan dengan mensimulasikan HTTP Request ke endpoint `GET /api/laporan/peminjaman` menggunakan user dengan masing-masing role:

| Scenario / Role User | Status Sebelum (Before) | Status Sesudah (After) | Status Pengujian | Keterangan |
| :--- | :---: | :---: | :---: | :--- |
| **User Biasa (`role: user`)** | **403 Forbidden** | **403 Forbidden** | **PASSED** | Akses ditolak |
| **User BKD (`role: bkd`)** | **200 OK** | **403 Forbidden** | **PASSED** | Akses berhasil dicabut |
| **Admin (`role: admin`)** | **200 OK** | **200 OK** | **PASSED** | Akses tetap diberikan |
| **Superadmin (`role: superadmin`)** | **200 OK** | **200 OK** | **PASSED** | Akses tetap diberikan |

---

## 6. Pembaruan Dokumen Postman Collection

File: [`layanantik-backend-api.postman_collection.json`](layanantik-backend-api.postman_collection.json)

1. **Deskripsi Request Updated**:
   Folder `15 - Fitur Baru - Laporan (F-LAPORAN)` -> `GET Laporan Rekapitulasi Peminjaman Aset`:
   > **Permission/Role**: Hanya dapat diakses oleh role admin dan superadmin. Role user dan bkd akan menerima 403 Forbidden.

2. **Contoh Response Disediakan**:
   - `200 OK - Admin / Superadmin`: Menampilkan contoh response sukses rekapitulasi laporan.
   - `403 Forbidden - Role BKD / User`: Menampilkan contoh response error `{"error": "Unauthorized"}` ketika diakses oleh role BKD atau User biasa.

3. **Validasi Sintaks JSON**: Validasi dengan `json_last_error()` mengonfirmasi file `layanantik-backend-api.postman_collection.json` 100% **VALID**.

---

## 7. Kesimpulan

- Otorisasi endpoint `GET /api/laporan/peminjaman` telah berhasil diperbaiki.
- Role `bkd` sekarang mendapat respons **403 Forbidden** ketika mencoba mengakses laporan peminjaman.
- Access control list kini konsisten: hanya **admin** dan **superadmin** yang berhak mengakses laporan peminjaman.
- Dokumentasi Postman Collection telah disesuaikan dan tervalidasi.
