<?php

namespace App\Listeners;

use App\Events\UsulanEmailCreated;
use App\Services\FcmNotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Log;

class SendUsulanEmailCreatedNotification implements ShouldQueue
{
    public function __construct() {}

    public function handle(UsulanEmailCreated $event): void
    {
        // Realtime and inbox persistence occur synchronously in the service.
        // This queued listener only sends the optional mobile push.
        try {
            $fcm = new FcmNotificationService();
            $fcm->sendToTopic(
                'admin',
                'Usulan Email Resmi Baru',
                'Permintaan pengajuan email resmi baru telah diajukan.',
                [
                    'type' => 'usulan_email',
                    'reference_id' => (string) $event->usulan->id,
                ]
            );
        } catch (\Exception $e) {
            Log::error('SendUsulanEmailCreatedNotification FCM Error: ' . $e->getMessage());
        }
    }
}
