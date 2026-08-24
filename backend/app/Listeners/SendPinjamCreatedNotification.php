<?php

namespace App\Listeners;

use App\Events\PinjamCreated;
use App\Services\FcmNotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Log;

class SendPinjamCreatedNotification implements ShouldQueue
{
    public function __construct() {}

    public function handle(PinjamCreated $event): void
    {
        // Realtime and inbox persistence occur synchronously in the service.
        // This queued listener only sends the optional mobile push.
        try {
            $fcm = new FcmNotificationService();
            $fcm->sendToTopic(
                'admin',
                'Peminjaman Asset',
                'Sebuah permintaan peminjaman asset telah diminta.',
                [
                    'type' => 'pinjam',
                    'reference_id' => (string) $event->pinjam->id,
                ]
            );
        } catch (\Exception $e) {
            Log::error('SendPinjamCreatedNotification FCM Error: ' . $e->getMessage());
        }
    }
}
