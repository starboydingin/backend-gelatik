<?php

namespace App\Listeners;

use App\Events\UsulanEmailCreated;
use App\Services\FcmNotificationService;
use App\Services\NodeServiceClient;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Log;

class SendUsulanEmailCreatedNotification implements ShouldQueue
{
    public function __construct() {}

    public function handle(UsulanEmailCreated $event): void
    {
        $nodeService = new NodeServiceClient();

        // 1. Broadcast Socket.io ke BKD / Admin
        $nodeService->broadcastToAll(
            'usulan_email.created',
            [
                'usulan_id' => $event->usulan->id,
                'user_id' => $event->usulan->user_id ?? 0,
                'message' => 'Permintaan pengajuan email resmi baru telah masuk.'
            ]
        );

        // 2. FCM Push Notification ke BKD / Admin
        try {
            $fcm = new FcmNotificationService();
            $fcm->sendToAdmins(
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
