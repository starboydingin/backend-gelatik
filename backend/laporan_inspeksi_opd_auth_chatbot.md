# Laporan Hasil Inspeksi: Data OPD, Chatbot URLs, Status User, dan Auth Controller

Tanggal Inspeksi: 2026-07-23

---

## 1. Sumber Data Daftar OPD & Perbandingan Konsistensi

### A. Tabel Khusus OPD
- **Status**: **TIDAK ADA**.
- Hasil pencarian tabel via `INFORMATION_SCHEMA.TABLES` untuk kata kunci `%opd%`, `%unit%`, `%instansi%` pada database `db_layanantik` mengembalikan **0 tabel**.

### B. Perbandingan Nilai `nama_opd` di 3 Tabel
1. **Tabel `users` (`users.nama_opd`)**:
   - Memiliki campuran format penulisan Title Case dan UPPERCASE.
   - Contoh data:
     - `"Dinas Komunikasi Informatika dan Statistik"`
     - `"DINAS KOMUNIKASI, INFORMATIKA DAN STATISTIK"` (penulisan UPPERCASE dengan koma)
     - `"INSPEKTORAT PROVINSI"`
     - `"BADAN PERENCANAAN PEMBANGUNAN DAERAH"`
     - `"BIRO PEMERINTAHAN DAN OTONOMI DAERAH"`
2. **Tabel `unker_router` (`unker_router.nama_opd`)**:
   - Contoh data: `"Dinas Komunikasi Informatika dan Statistik"`, `"Dinas Pendidikan"`, `"BADAN PENANGGULANGAN BENCANA DAERAH"`.
3. **Tabel `unker_list_router` (`unker_list_router.nama_opd`)**:
   - Contoh data: `"Dinas Komunikasi Informatika dan Statistik"`, `"Dinas Kesehatan"`, `"DINAS PERPUSTAKAAN DAN KEARSIPAN"`.

### C. Kesimpulan Konsistensi
Nilai `nama_opd` **TIDAK KONSISTEN 100%** antar tabel maupun di dalam tabel `users` sendiri (terdapat variasi huruf kapital, penggunaan koma, dan perbedaan frasa). 
Saat ini endpoint `GET /api/opd` mengambil daftar OPD dari tabel `unker_list_router` (`RouterList::where('status', 1)->get()`).

---

## 2. Struktur Tabel & Data `chatbot_urls`

### A. Struktur Kolom (`DESCRIBE chatbot_urls`)
| Field | Type | Null | Key | Default | Extra |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `id` | `int(11)` | NO | | `NULL` | |
| `account_name` | `varchar(255)` | YES | | `NULL` | |
| `url` | `varchar(255)` | YES | | `NULL` | |
| `status` | `tinyint(4)` | YES | | `1` | |
| `created_at` | `timestamp` | YES | | `NULL` | |
| `updated_at` | `timestamp` | YES | | `NULL` | |

### B. Isi Data Existing (`SELECT * FROM chatbot_urls`)
```json
[
    {
        "id": 1,
        "account_name": "pkl",
        "url": "<iframe src=\"https://www.chatbase.co/chatbot-iframe/9ZpNqIFmVAR8jPsFmMvlo\" width=\"100%\" style=\"height: 100%; min-height: 700px\" frameborder=\"0\"></iframe>",
        "status": 1,
        "created_at": "2025-07-18 15:41:52",
        "updated_at": null
    }
]
```

---

## 3. Hasil Cek Status User (`users.status`)

Query: `SELECT status, COUNT(*) as jumlah FROM users GROUP BY status;`

| `status` | Jumlah User | Keterangan |
| :---: | :---: | :--- |
| **`1`** | **492** | Account Aktif |
| **`0`** | **2** | Account Nonaktif / Blocked |

### Kesimpulan
Secara meyakinkan **TERDAPAT 2 USER DENGAN STATUS `0` (NONAKTIF)** di database saat ini. Penerapan logic validasi login yang memblokir akun dengan `status = 0` / `status = '0'` sangat penting dan sesuai kondisi nyata database.

---

## 4. Isi Code Existing `AuthController.php`

File: [app/Http/Controllers/Api/AuthController.php](file:///e:/Adwika/AdwikaPerkuliahan/KP-BACKEND/backend/app/Http/Controllers/Api/AuthController.php)

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Login user dan dapatkan access token (Passport)
     * POST /api/login
     */
    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Email atau password salah.',
            ], 401);
        }

        $token = $user->createToken('LayanantikToken')->accessToken;

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil.',
            'data'    => [
                'user'         => $user,
                'access_token' => $token,
                'token_type'   => 'Bearer',
            ],
        ]);
    }

    /**
     * Register user baru
     * POST /api/register
     */
    public function register(Request $request)
    {
        $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|string|min:6|confirmed',
        ]);

        $user = User::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
        ]);

        $token = $user->createToken('LayanantikToken')->accessToken;

        return response()->json([
            'success' => true,
            'message' => 'Registrasi berhasil.',
            'data'    => [
                'user'         => $user,
                'access_token' => $token,
                'token_type'   => 'Bearer',
            ],
        ], 201);
    }

    /**
     * Dapatkan data user yang sedang login
     * GET /api/me
     */
    public function me(Request $request)
    {
        return response()->json([
            'success' => true,
            'data'    => $request->user(),
        ]);
    }

    /**
     * Logout (revoke current token)
     * POST /api/logout
     */
    public function logout(Request $request)
    {
        $request->user()->token()->revoke();

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil.',
        ]);
    }
}
```
