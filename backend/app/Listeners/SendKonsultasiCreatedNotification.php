<?php

namespace App\Listeners;

use App\Events\KonsultasiCreated;
use App\Services\FcmNotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Log;

class SendKonsultasiCreatedNotification implements ShouldQueue
{
    public int $tries = 3;

    public function backoff(): array
    {
        return [10, 30, 90];
    }

    public function __construct() {}

    public function handle(KonsultasiCreated $event): void
    {
        // Realtime and inbox persistence occur synchronously in the service.
        // This queued listener only sends the optional mobile push.
        try {
            $fcm = new FcmNotificationService();
            $fcm->sendToTopic(
                'admin',
                'Permintaan Konsultasi',
                'Sebuah permintaan konsultasi telah diminta.',
                [
                    'type' => 'konsultasi',
                    'reference_id' => (string) $event->konsultasi->id,
                ]
            );
        } catch (\Exception $e) {
            Log::error('SendKonsultasiCreatedNotification FCM Error: ' . $e->getMessage());
            throw $e;
        }
    }
}
