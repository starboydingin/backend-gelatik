<?php

namespace App\Listeners;

use App\Events\PinjamCreated;
use App\Services\FcmNotificationService;
use App\Services\NodeServiceClient;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Log;

class SendPinjamCreatedNotification implements ShouldQueue
{
    public function __construct() {}

    public function handle(PinjamCreated $event): void
    {
        $nodeService = new NodeServiceClient();

        // 1. Broadcast Socket.io ke admin/all
        $nodeService->broadcastToAll(
            'pinjam.created',
            [
                'pinjam_id' => $event->pinjam->id,
                'user_id' => $event->pinjam->user_id,
                'message' => 'Sebuah permintaan peminjaman asset telah diminta.'
            ]
        );

        // 2. FCM Push Notification ke Topic Admin
        try {
            $fcm = new FcmNotificationService();
            $fcm->sendToAdmins(
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
