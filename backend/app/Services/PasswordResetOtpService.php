<?php

namespace App\Services;

use App\Models\PasswordResetOtp;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class PasswordResetOtpService
{
    private const EXPIRY_MINUTES = 10;
    private const MAX_ATTEMPTS = 5;

    public function __construct(private NodeServiceClient $nodeServiceClient)
    {
    }

    public function request(string $identifier): array
    {
        $user = User::query()
            ->where('email', $identifier)
            ->orWhere('username', $identifier)
            ->orWhere('nip', $identifier)
            ->first();

        if (! $user || ! $this->phoneNumber($user)) {
            return ['challenge_id' => (string) Str::uuid(), 'expires_in' => self::EXPIRY_MINUTES * 60];
        }

        $recentChallenge = PasswordResetOtp::query()
            ->where('user_id', $user->id)
            ->whereNull('consumed_at')
            ->where('last_sent_at', '>', now()->subMinute())
            ->exists();
        if ($recentChallenge) {
            throw ValidationException::withMessages([
                'identifier' => 'Kode baru dapat diminta kembali setelah 60 detik.',
            ]);
        }

        $gateway = $this->nodeServiceClient->whatsappStatus();
        if (($gateway['status'] ?? null) !== 'connected') {
            throw ValidationException::withMessages([
                'identifier' => 'Kode verifikasi belum dapat dikirim. Silakan coba beberapa saat lagi.',
            ]);
        }

        $otp = (string) random_int(100000, 999999);
        $challenge = DB::transaction(function () use ($user, $otp): PasswordResetOtp {
            PasswordResetOtp::query()
                ->where('user_id', $user->id)
                ->whereNull('consumed_at')
                ->update(['consumed_at' => now()]);

            return PasswordResetOtp::create([
                'user_id' => $user->id,
                'otp_hash' => Hash::make($otp),
                'expires_at' => now()->addMinutes(self::EXPIRY_MINUTES),
                'last_sent_at' => now(),
            ]);
        });

        $result = $this->nodeServiceClient->sendWhatsApp(
            $this->phoneNumber($user),
            "Kode verifikasi Gelatik Anda: {$otp}. Berlaku ".self::EXPIRY_MINUTES.' menit. Jangan berikan kode ini kepada siapa pun.',
            ['event_type' => 'password_reset_otp', 'reference_id' => $challenge->id, 'user_id' => $user->id],
        );

        if (! ($result['success'] ?? false)) {
            $challenge->delete();
            throw ValidationException::withMessages([
                'identifier' => 'Kode verifikasi belum dapat dikirim. Silakan coba beberapa saat lagi.',
            ]);
        }

        return ['challenge_id' => $challenge->id, 'expires_in' => self::EXPIRY_MINUTES * 60];
    }

    public function verify(string $challengeId, string $otp): string
    {
        $challenge = PasswordResetOtp::query()
            ->whereKey($challengeId)
            ->whereNull('consumed_at')
            ->first();

        if (! $challenge || $challenge->expires_at->isPast() || $challenge->attempts >= self::MAX_ATTEMPTS) {
            throw ValidationException::withMessages(['otp' => 'Kode verifikasi tidak valid atau telah kedaluwarsa.']);
        }

        if (! Hash::check($otp, $challenge->otp_hash)) {
            $challenge->increment('attempts');
            throw ValidationException::withMessages(['otp' => 'Kode verifikasi tidak valid atau telah kedaluwarsa.']);
        }

        $token = Str::random(64);
        $challenge->forceFill([
            'verified_at' => now(),
            'reset_token_hash' => hash('sha256', $token),
        ])->save();

        return $token;
    }

    public function reset(string $token, string $password): void
    {
        DB::transaction(function () use ($token, $password): void {
            $challenge = PasswordResetOtp::query()
                ->where('reset_token_hash', hash('sha256', $token))
                ->whereNotNull('verified_at')
                ->whereNull('consumed_at')
                ->where('expires_at', '>', now())
                ->lockForUpdate()
                ->first();

            if (! $challenge) {
                throw ValidationException::withMessages(['reset_token' => 'Sesi reset tidak valid atau telah kedaluwarsa.']);
            }

            $user = User::findOrFail($challenge->user_id);
            $user->forceFill(['password' => Hash::make($password), 'remember_token' => Str::random(60)])->save();
            $user->tokens()->update(['revoked' => true]);
            $challenge->update(['consumed_at' => now(), 'reset_token_hash' => null]);
        });
    }

    private function phoneNumber(User $user): ?string
    {
        // Password recovery must use the explicitly opted-in WhatsApp number,
        // never the general profile phone number.
        $subscription = $user->whatsappSubscription;

        return $subscription?->is_opt_in ? $subscription->nomor_wa : null;
    }
}
