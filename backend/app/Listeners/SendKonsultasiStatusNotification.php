<?php

namespace App\Listeners;

use App\Events\KonsultasiStatusChanged;
use App\Services\NodeServiceClient;
use App\Services\RealtimeEventPayload;
use Illuminate\Contracts\Queue\ShouldQueue;

class SendKonsultasiStatusNotification implements ShouldQueue
{
    public function handle(KonsultasiStatusChanged $event): void
    {
        $payload = RealtimeEventPayload::make(
            'konsultasi.status_changed',
            (int) $event->konsultasi->id,
            [
                'status' => $event->newStatus,
                'old_status' => $event->oldStatus,
                'message' => 'Status konsultasi Anda telah diubah menjadi ' . $event->newStatus,
            ],
        );

        $nodeService = new NodeServiceClient();
        $nodeService->broadcastToUser($event->konsultasi->user_id, 'konsultasi.status_changed', $payload);
        $nodeService->broadcastToRole('admin', 'konsultasi.status_changed', $payload);
    }
}
