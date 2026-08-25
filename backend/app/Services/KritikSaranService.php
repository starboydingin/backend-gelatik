<?php

namespace App\Services;

use App\Models\KritikSaran;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Support\Str;

class KritikSaranService
{
    /**
     * Kirim kritik dan saran (user_id null jika anonim / belum login)
     */
    public function kirimKritikSaran(?User $user, string $kritik, string $saran): KritikSaran
    {
        $kritikSaran = KritikSaran::create([
            'user_id' => $user ? $user->id : null,
            'kritik'  => $kritik,
            'saran'   => $saran,
        ]);

        $sender = $user?->name ?: 'Pengguna anonim';
        app(AdminNotificationService::class)->announce(
            'kritik_saran.created',
            (int) $kritikSaran->id,
            'Kritik & saran baru',
            "{$sender} mengirimkan kritik dan saran layanan.",
            'kritik_saran',
        );

        return $kritikSaran;
    }

    /**
     * Ambil list semua kritik saran untuk admin
     */
    public function getAllForAdmin()
    {
        return KritikSaran::with(['user', 'responder:id,name,role'])->latest()->paginate(15);
    }

    public function getForUser(User $user, ?string $keyword = null, ?string $status = null)
    {
        return KritikSaran::with('responder:id,name,role')
            ->where('user_id', $user->id)
            ->when($keyword, function ($query, string $value) {
                $query->where(function ($nested) use ($value): void {
                    $nested->where('kritik', 'like', "%{$value}%")
                        ->orWhere('saran', 'like', "%{$value}%")
                        ->orWhere('balasan', 'like', "%{$value}%");
                });
            })
            ->when($status === 'answered', fn ($query) => $query->whereNotNull('balasan'))
            ->when($status === 'waiting', fn ($query) => $query->whereNull('balasan'))
            ->latest()
            ->paginate(15);
    }

    public function findForUser(User $user, int $id): KritikSaran
    {
        return KritikSaran::with('responder:id,name,role')
            ->where('user_id', $user->id)
            ->findOrFail($id);
    }

    public function balas(KritikSaran $kritikSaran, User $responder, string $balasan): KritikSaran
    {
        $kritikSaran->update([
            'balasan' => $balasan,
            'dibalas_oleh' => $responder->id,
            'dibalas_pada' => now(),
        ]);

        if ((int) $kritikSaran->user_id > 0) {
            $notification = Notification::create([
                'user_id' => $kritikSaran->user_id,
                'judul' => 'Balasan kritik & saran',
                'message' => "{$responder->name}: ".Str::limit($balasan, 210, ''),
                'type' => 'kritik_saran',
                'item_id' => $kritikSaran->id,
                'read' => false,
            ]);

            // Tidak memanggil WhatsApp: balasan kritik & saran hanya tersedia
            // melalui notifikasi realtime aplikasi dan website.
            app(NotificationRealtimeService::class)->toUser($notification);
        }

        return $kritikSaran->fresh(['user', 'responder:id,name,role']);
    }

    /**
     * Hapus banyak kritik saran sekaligus (bulk delete)
     */
    public function bulkDelete(array $ids): int
    {
        $items = KritikSaran::whereIn('id', $ids)->get(['id', 'user_id']);
        $deleted = KritikSaran::whereIn('id', $ids)->delete();
        foreach ($items as $item) {
            app(RealtimeDataSyncService::class)->userAndAdmins(
                (int) $item->user_id,
                'kritik_saran',
                (int) $item->id,
            );
        }

        return $deleted;
    }
}
