<?php

namespace App\Listeners;

use App\Events\PinjamStatusChanged;
use App\Models\WhatsappSubscription;
use App\Services\FcmNotificationService;
use App\Services\NodeServiceClient;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Log;

class SendPinjamNotification implements ShouldQueue
{
    /**
     * Create the event listener.
     */
    public function __construct()
    {
        //
    }

    /**
     * Handle the event.
     */
    public function handle(PinjamStatusChanged $event): void
    {
        $nodeService = new NodeServiceClient();
        
        // 1. Broadcast via Socket.io (F-RT)
        $nodeService->broadcastToUser(
            $event->pinjam->user_id,
            'pinjam.status_changed',
            [
                'pinjam_id' => $event->pinjam->id,
                'old_status' => $event->oldStatus,
                'new_status' => $event->newStatus,
                'message' => 'Status peminjaman Anda telah diubah menjadi ' . $event->newStatus
            ]
        );

        // 2. WhatsApp Notification (F-WA)
        try {
            $subscription = WhatsappSubscription::where('user_id', $event->pinjam->user_id)
                ->where('is_opt_in', true)
                ->first();

            if ($subscription) {
                $nama = $event->pinjam->user ? $event->pinjam->user->name : 'Pengguna';
                $id = $event->pinjam->id;
                $statusLower = strtolower($event->newStatus);

                if ($statusLower === 'proses') {
                    $message = "Halo {$nama}, pengajuan peminjaman aset Anda (#{$id}) sedang diproses.";
                } elseif ($statusLower === 'ditolak') {
                    $catatan = $event->pinjam->catatan_petugas ?? 'Tidak ada catatan';
                    $message = "Halo {$nama}, pengajuan peminjaman aset Anda (#{$id}) ditolak. Alasan: {$catatan}";
                } elseif ($statusLower === 'selesai') {
                    $message = "Halo {$nama}, pengajuan peminjaman aset Anda (#{$id}) telah selesai.";
                } else {
                    $message = "Halo {$nama}, pengajuan peminjaman aset Anda (#{$id}) telah diubah menjadi {$event->newStatus}.";
                }
                
                $nodeService->sendWhatsApp(
                    $subscription->nomor_wa,
                    $message,
                    [
                        'event_type' => 'pinjam.status_changed',
                        'reference_id' => $event->pinjam->id,
                        'user_id' => $event->pinjam->user_id
                    ]
                );
            }
        } catch (\Exception $e) {
            Log::error('SendPinjamNotification WA Error: ' . $e->getMessage());
        }

        // 3. FCM Push Notification (topic-based)
        try {
            $fcm = new FcmNotificationService();
            $fcm->sendToUser(
                $event->pinjam->user_id,
                'Peminjaman Asset',
                'Status peminjaman Anda telah diubah menjadi ' . $event->newStatus,
                [
                    'type' => 'pinjam',
                    'reference_id' => (string) $event->pinjam->id,
                ]
            );
        } catch (\Exception $e) {
            Log::error('SendPinjamNotification FCM Error: ' . $e->getMessage());
        }
    }
}
