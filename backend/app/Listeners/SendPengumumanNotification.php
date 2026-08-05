<?php

namespace App\Listeners;

use App\Events\PengumumanCreated;
use App\Services\FcmNotificationService;
use App\Services\NodeServiceClient;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Log;

class SendPengumumanNotification implements ShouldQueue
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
    public function handle(PengumumanCreated $event): void
    {
        $nodeService = new NodeServiceClient();
        
        // 1. Broadcast via Socket.io (F-RT)
        $nodeService->broadcastToAll(
            'pengumuman.created',
            [
                'pengumuman_id' => $event->pengumuman->id,
                'judul' => $event->pengumuman->judul,
                'message' => 'Pengumuman baru: ' . $event->pengumuman->judul
            ]
        );

        // 2. FCM Push Notification (topic-based)
        try {
            $fcm = new FcmNotificationService();
            $fcm->broadcastPengumuman(
                'Pengumuman Baru',
                $event->pengumuman->judul,
                [
                    'type' => 'pengumuman',
                    'reference_id' => (string) $event->pengumuman->id,
                ]
            );
        } catch (\Exception $e) {
            Log::error('SendPengumumanNotification FCM Error: ' . $e->getMessage());
        }
    }
}
