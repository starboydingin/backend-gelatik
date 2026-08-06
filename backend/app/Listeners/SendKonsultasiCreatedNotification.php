<?php

namespace App\Listeners;

use App\Events\KonsultasiCreated;
use App\Services\FcmNotificationService;
use App\Services\NodeServiceClient;
use App\Services\RealtimeEventPayload;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Log;

class SendKonsultasiCreatedNotification implements ShouldQueue
{
    public function __construct() {}

    public function handle(KonsultasiCreated $event): void
    {
        $nodeService = new NodeServiceClient();

        // 1. Broadcast Socket.io ke admin/all
        $nodeService->broadcastToRole(
            'admin',
            'konsultasi.created',
            RealtimeEventPayload::make('konsultasi.created', (int) $event->konsultasi->id, [
                'status' => $event->konsultasi->status,
                'message' => 'Sebuah permintaan konsultasi telah diminta.'
            ])
        );

        // 2. FCM Push Notification ke Topic Admin
        try {
            $fcm = new FcmNotificationService();
            $fcm->sendToAdmins(
                'Permintaan Konsultasi',
                'Sebuah permintaan konsultasi telah diminta.',
                [
                    'type' => 'konsultasi',
                    'reference_id' => (string) $event->konsultasi->id,
                ]
            );
        } catch (\Exception $e) {
            Log::error('SendKonsultasiCreatedNotification FCM Error: ' . $e->getMessage());
        }
    }
}
