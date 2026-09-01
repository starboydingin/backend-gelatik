<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\Konsultasi;
use App\Models\Notification;
use App\Models\Pinjam;
use App\Models\RouterList;
use App\Models\User;
use App\Models\UsulanEmail;
use App\Services\AdminAuditService;
use App\Services\OfficialEmailValidator;
use App\Services\PasswordResetOtpService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function __construct(
        private PasswordResetOtpService $passwordResetOtpService,
        private AdminAuditService $adminAudit,
        private OfficialEmailValidator $officialEmailValidator,
    ) {}

    /**
     * Login user dan dapatkan access token (Passport)
     * POST /api/login
     */
    public function login(Request $request)
    {
        $request->validate([
            'identifier' => 'required|string',
            'password' => 'required|string',
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
            'data' => [
                'user' => $user,
                'access_token' => $token,
                'token_type' => 'Bearer',
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
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'nip' => 'required|digits:18|unique:users,nip',
            'no_hp' => 'required|string',
            'nama_opd' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $this->officialEmailValidator->validateForRegistration((string) $request->email);

        // Validasi OPD harus ada di tabel unker_list_router
        $validOpd = RouterList::where('nama_opd', $request->nama_opd)->exists();
        if (! $validOpd) {
            throw ValidationException::withMessages([
                'nama_opd' => 'Nama OPD tidak valid atau tidak terdaftar dalam sistem.',
            ]);
        }

        $authData = DB::transaction(function () use ($request): array {
            $user = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'username' => $request->nip,
                'nip' => $request->nip,
                'no_hp' => $request->no_hp,
                'nama_opd' => $request->nama_opd,
                'password' => Hash::make($request->password),
                'status' => '1',
            ]);

            $user->assignRole('user');

            return [
                'user' => $user,
                'access_token' => $user->createToken('LayanantikToken')->accessToken,
                'token_type' => 'Bearer',
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Registrasi berhasil. Akun Anda sudah aktif.',
            'data' => $authData,
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
            'data' => $user,
        ]);
    }

    /** PATCH /api/me */
    public function updateProfile(Request $request)
    {
        $user = $request->user();
        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'email' => 'sometimes|required|email|max:255|unique:users,email,'.$user->id,
            'no_hp' => 'sometimes|nullable|string|max:20',
            'nama_opd' => 'sometimes|nullable|string|max:255',
        ]);

        $user->update($validated);

        if ($user->hasAnyRole(['admin', 'superadmin'])) {
            $this->adminAudit->record(
                $user,
                'profile.updated',
                'Memperbarui profil administrator.',
                $user,
            );
        }

        return response()->json([
            'success' => true,
            'message' => 'Profil berhasil diperbarui.',
            'data' => $user->fresh()->load('roles:id,name'),
        ]);
    }

    /** POST /api/me/change-password */
    public function changePassword(Request $request)
    {
        $validated = $request->validate([
            'current_password' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
        ]);
        $user = $request->user();

        if (! Hash::check($validated['current_password'], $user->password)) {
            throw ValidationException::withMessages([
                'current_password' => 'Kata sandi saat ini tidak sesuai.',
            ]);
        }

        $user->update(['password' => Hash::make($validated['password'])]);
        if ($user->hasAnyRole(['admin', 'superadmin'])) {
            $this->adminAudit->record(
                $user,
                'password.changed',
                'Mengubah kata sandi administrator.',
                $user,
            );
        }

        return response()->json([
            'success' => true,
            'message' => 'Kata sandi berhasil diperbarui.',
        ]);
    }

    /** GET /api/me/activity-log — aktivitas akun sendiri, bukan log global. */
    public function activityLog(Request $request)
    {
        $user = $request->user();

        if ($user->hasAnyRole(['admin', 'superadmin'])) {
            if (! Schema::hasTable('admin_audit_logs')) {
                return response()->json(['success' => true, 'data' => []]);
            }

            $entries = AdminAuditLog::query()
                ->where('actor_id', $user->id)
                ->latest()
                ->take(30)
                ->get(['id', 'action', 'description', 'created_at']);

            return response()->json(['success' => true, 'data' => $entries]);
        }

        $entries = collect()
            ->concat(Konsultasi::query()->where('user_id', $user->id)->latest()->take(30)->get(['id', 'judul', 'created_at'])->map(fn (Konsultasi $konsultasi) => [
                'id' => 'konsultasi-'.$konsultasi->id,
                'action' => 'konsultasi.created',
                'description' => 'Mengajukan konsultasi'.($konsultasi->judul ? ': '.$konsultasi->judul : '.'),
                'created_at' => $konsultasi->created_at,
            ]))
            ->concat(Pinjam::query()->where('user_id', $user->id)->latest()->take(30)->get(['id', 'keterangan', 'created_at'])->map(fn (Pinjam $pinjam) => [
                'id' => 'pinjam-'.$pinjam->id,
                'action' => 'pinjam.created',
                'description' => 'Mengajukan peminjaman aset'.($pinjam->keterangan ? ': '.$pinjam->keterangan : '.'),
                'created_at' => $pinjam->created_at,
            ]))
            ->concat(UsulanEmail::query()->where('created_by', $user->id)->latest()->take(30)->get(['id', 'email_pribadi', 'created_at'])->map(fn (UsulanEmail $usulan) => [
                'id' => 'usulan-email-'.$usulan->id,
                'action' => 'usulan_email.created',
                'description' => 'Mengajukan usulan email ASN'.($usulan->email_pribadi ? ' untuk '.$usulan->email_pribadi.'.' : '.'),
                'created_at' => $usulan->created_at,
            ]))
            ->concat(Notification::query()->where('user_id', $user->id)->latest()->take(30)->get(['id', 'judul', 'created_at'])->map(fn (Notification $notification) => [
                'id' => 'notification-'.$notification->id,
                'action' => 'notification.received',
                'description' => 'Menerima pembaruan: '.($notification->judul ?: 'Notifikasi layanan').'.',
                'created_at' => $notification->created_at,
            ]))
            ->sortByDesc('created_at')
            ->take(30)
            ->values();

        return response()->json(['success' => true, 'data' => $entries]);
    }

    /** POST /api/forgot-password */
    public function forgotPassword(Request $request)
    {
        $validated = $request->validate(['identifier' => 'required|string|max:255']);
        $challenge = $this->passwordResetOtpService->request($validated['identifier']);

        return response()->json([
            'success' => true,
            'message' => 'Jika akun dan nomor WhatsApp terdaftar, kode verifikasi telah dikirim.',
            'data' => $challenge,
        ]);
    }

    /** POST /api/forgot-password/verify */
    public function verifyPasswordResetOtp(Request $request)
    {
        $validated = $request->validate([
            'challenge_id' => 'required|uuid',
            'otp' => 'required|digits:6',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Kode verifikasi berhasil diverifikasi.',
            'data' => [
                'reset_token' => $this->passwordResetOtpService->verify(
                    $validated['challenge_id'],
                    $validated['otp'],
                ),
            ],
        ]);
    }

    /** POST /api/reset-password */
    public function resetPassword(Request $request)
    {
        $validated = $request->validate([
            'reset_token' => 'required|string|size:64',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $this->passwordResetOtpService->reset($validated['reset_token'], $validated['password']);

        return response()->json([
            'success' => true,
            'message' => 'Kata sandi berhasil diperbarui. Silakan masuk kembali.',
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
