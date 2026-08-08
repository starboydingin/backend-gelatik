<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RouterList;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
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
            'identifier' => 'required|string',
            'password'   => 'required|string',
        ]);

        $user = User::where('email', $request->identifier)
            ->orWhere('username', $request->identifier)
            ->orWhere('nip', $request->identifier)
            ->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Email, NIP/Username, atau password salah.',
            ], 401);
        }

        // Cek status keaktifan akun user (BAGIAN 1)
        if ((string) $user->status !== '1') {
            return response()->json([
                'success' => false,
                'message' => 'Akun Anda belum aktif atau telah dinonaktifkan.',
            ], 403);
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
     * Register user baru dan terbitkan access token agar dapat langsung masuk.
     * POST /api/register
     */
    public function register(Request $request)
    {
        $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'nip'      => 'required|digits:18|unique:users,nip',
            'no_hp'    => 'required|string',
            'nama_opd' => 'required|string',
            'password' => 'required|string|min:6|confirmed',
        ]);

        // Validasi OPD harus ada di tabel unker_list_router
        $validOpd = RouterList::where('nama_opd', $request->nama_opd)->exists();
        if (! $validOpd) {
            throw ValidationException::withMessages([
                'nama_opd' => 'Nama OPD tidak valid atau tidak terdaftar dalam sistem.',
            ]);
        }

        $authData = DB::transaction(function () use ($request): array {
            $user = User::create([
                'name'     => $request->name,
                'email'    => $request->email,
                'username' => $request->nip,
                'nip'      => $request->nip,
                'no_hp'    => $request->no_hp,
                'nama_opd' => $request->nama_opd,
                'password' => Hash::make($request->password),
                'status'   => '1',
            ]);

            $user->assignRole('user');

            return [
                'user'         => $user,
                'access_token' => $user->createToken('LayanantikToken')->accessToken,
                'token_type'   => 'Bearer',
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Registrasi berhasil. Akun Anda sudah aktif.',
            'data'    => $authData,
        ], 201);
    }

    /**
     * Dapatkan data user yang sedang login
     * GET /api/me
     */
    public function me(Request $request)
    {
        $user = $request->user()->loadMissing('roles:id,name');

        return response()->json([
            'success' => true,
            'data'    => $user,
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
