<?php

namespace App\Services;

use App\Events\PengumumanCreated;
use App\Models\Pengumuman;
use App\Models\User;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

class PengumumanService
{
    /**
     * Buat pengumuman baru oleh admin
     */
    public function buatPengumuman(User $admin, string $judul, string $konten, ?string $expiredAt = null): Pengumuman
    {
        $pengumuman = Pengumuman::create([
            'judul'      => $judul,
            'konten'     => $konten,
            'expired_at' => $expiredAt,
        ]);

        // Dispatch Event (memicu FCM push ke topic 'pengumuman' & Socket.io)
        event(new PengumumanCreated($pengumuman));

        return $pengumuman;
    }

    /**
     * Ambil pengumuman aktif yang belum kedaluwarsa
     */
    public function getActive(): Collection
    {
        return Pengumuman::aktif()->latest()->get();
    }
}
