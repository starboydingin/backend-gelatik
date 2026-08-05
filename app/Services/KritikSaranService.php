<?php

namespace App\Services;

use App\Models\KritikSaran;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class KritikSaranService
{
    /**
     * Kirim kritik dan saran (user_id null jika anonim / belum login)
     */
    public function kirimKritikSaran(?User $user, string $kritik, string $saran): KritikSaran
    {
        return KritikSaran::create([
            'user_id' => $user ? $user->id : null,
            'kritik'  => $kritik,
            'saran'   => $saran,
        ]);
    }

    /**
     * Ambil list semua kritik saran untuk admin
     */
    public function getAllForAdmin()
    {
        return KritikSaran::with('user')->latest()->paginate(15);
    }

    /**
     * Hapus banyak kritik saran sekaligus (bulk delete)
     */
    public function bulkDelete(array $ids): int
    {
        return KritikSaran::whereIn('id', $ids)->delete();
    }
}
