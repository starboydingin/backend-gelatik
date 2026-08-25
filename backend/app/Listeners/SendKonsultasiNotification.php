<?php

namespace App\Listeners;

use App\Events\KonsultasiResponseCreated;
use App\Services\FcmNotificationService;
use App\Services\NodeServiceClient;
use App\Services\RealtimeEventPayload;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Log;

class SendKonsultasiNotification implements ShouldQueue
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
    public function handle(KonsultasiResponseCreated $event): void
    {
        $nodeService = new NodeServiceClient;
        $deliveryFailure = null;

        // 1. Broadcast via Socket.io (F-RT)
        $targetIsAdmin = (int) $event->response->user_id === (int) $event->konsultasi->user_id;
        $payload = RealtimeEventPayload::make('konsultasi.responded', (int) $event->konsultasi->id, [
            'status' => $event->konsultasi->status,
            'response_id' => (int) $event->response->id,
            'message' => 'Anda mendapat balasan baru pada konsultasi: '.$event->konsultasi->judul,
        ]);

        if ($targetIsAdmin) {
            $nodeService->broadcastToRole(
                'admin',
                'konsultasi.responded',
                $payload
            );
        }

        // 2. FCM Push Notification (topic-based). WhatsApp is scheduled
        // directly by KonsultasiService so it cannot be stranded in this
        // listener when no queue worker is running.
        try {
            $fcm = new FcmNotificationService;

            if (! $targetIsAdmin) {
                // Admin membalas → kirim FCM ke user pemilik konsultasi
                $fcm->sendToUser(
                    $event->konsultasi->user_id,
                    'Balasan Konsultasi',
                    "Ada balasan baru untuk konsultasi '{$event->konsultasi->judul}'.",
                    [
                        'type' => 'konsultasi',
                        'reference_id' => (string) $event->konsultasi->id,
                    ]
                );
            } else {
                // User membalas → kirim FCM ke admin
                $fcm->sendToAdmins(
                    'Balasan Konsultasi',
                    "User memberikan balasan pada konsultasi '{$event->konsultasi->judul}'.",
                    [
                        'type' => 'konsultasi',
                        'reference_id' => (string) $event->konsultasi->id,
                    ]
                );
            }
        } catch (\Exception $e) {
            Log::error('SendKonsultasiNotification FCM Error: '.$e->getMessage());
            $deliveryFailure ??= $e;
        }

        if ($deliveryFailure) {
            throw $deliveryFailure;
        }
    }
}
