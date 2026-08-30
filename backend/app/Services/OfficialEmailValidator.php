<?php

namespace App\Services;

use Illuminate\Validation\ValidationException;

class OfficialEmailValidator
{
    /**
     * Validate only newly registered accounts. Existing accounts and login
     * deliberately do not pass through this rule.
     */
    public function validateForRegistration(string $email): void
    {
        $domain = mb_strtolower((string) str($email)->afterLast('@')->trim());
        $allowedDomains = collect(config('official_email.allowed_domains', []))
            ->map(fn ($item) => mb_strtolower(trim((string) $item)))
            ->filter()
            ->values();

        if ($allowedDomains->isEmpty()) {
            throw ValidationException::withMessages([
                'email' => 'Validasi email dinas belum dikonfigurasi. Hubungi administrator Gelatik.',
            ]);
        }

        if (! $allowedDomains->contains($domain)) {
            throw ValidationException::withMessages([
                'email' => 'Gunakan email resmi dinas yang terdaftar.',
            ]);
        }
    }
}
