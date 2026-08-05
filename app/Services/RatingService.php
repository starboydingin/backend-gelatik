<?php

namespace App\Services;

use App\Models\Rating;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class RatingService
{
    /**
     * Beri rating pertama kali oleh user
     */
    public function beriRating(User $user, int $nilai): Rating
    {
        if ($nilai < 1 || $nilai > 5) {
            throw ValidationException::withMessages(['rating' => 'Nilai rating harus antara 1 sampai 5.']);
        }

        $existing = Rating::where('user_id', $user->id)->first();
        if ($existing) {
            throw ValidationException::withMessages([
                'rating' => 'Anda sudah pernah memberikan rating. Gunakan endpoint update rating terlebih dahulu.'
            ]);
        }

        return Rating::create([
            'user_id' => $user->id,
            'rating'  => $nilai,
        ]);
    }

    /**
     * Update rating existing milik user
     */
    public function updateRating(User $user, int $nilaiBaru): Rating
    {
        if ($nilaiBaru < 1 || $nilaiBaru > 5) {
            throw ValidationException::withMessages(['rating' => 'Nilai rating harus antara 1 sampai 5.']);
        }

        $rating = Rating::where('user_id', $user->id)->first();
        if (!$rating) {
            throw ValidationException::withMessages([
                'rating' => 'Anda belum pernah memberi rating, gunakan endpoint beri rating terlebih dahulu.'
            ]);
        }

        $rating->update(['rating' => $nilaiBaru]);

        return $rating;
    }

    /**
     * Dapatkan statistik rating untuk Dashboard
     */
    public function getStatistik(): array
    {
        $avg = Rating::avg('rating');
        $total = Rating::count();

        $distribusi = [
            1 => Rating::where('rating', 1)->count(),
            2 => Rating::where('rating', 2)->count(),
            3 => Rating::where('rating', 3)->count(),
            4 => Rating::where('rating', 4)->count(),
            5 => Rating::where('rating', 5)->count(),
        ];

        return [
            'rata_rata'  => round((float) $avg, 2),
            'total_user' => $total,
            'distribusi' => $distribusi,
        ];
    }
}
