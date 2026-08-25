<?php

namespace App\Listeners;

use App\Events\PinjamStatusChanged;
use App\Services\FcmNotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Log;

class SendPinjamNotification implements ShouldQueue
{
    public int $tries = 3;

    public function backoff(): array
    {
        return [10, 30, 90];
    }

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
        // Socket.IO, browser inbox, and WhatsApp are handled directly by the
        // business service. This queued listener only handles FCM push.
        try {
            $fcm = new FcmNotificationService;
            $fcm->sendToUser(
                $event->pinjam->user_id,
                'Peminjaman Asset',
                'Status peminjaman Anda telah diubah menjadi '.$event->newStatus,
                [
                    'type' => 'pinjam',
                    'reference_id' => (string) $event->pinjam->id,
                ],
            );
        } catch (\Exception $e) {
            Log::error('SendPinjamNotification FCM Error: '.$e->getMessage());
            throw $e;
        }
    }
}
