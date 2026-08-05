<?php

namespace App\Listeners;

use App\Events\KonsultasiResponseCreated;
use App\Models\WhatsappSubscription;
use App\Services\FcmNotificationService;
use App\Services\NodeServiceClient;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class SendKonsultasiNotification implements ShouldQueue
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
    public function handle(KonsultasiResponseCreated $event): void
    {
        $nodeService = new NodeServiceClient();
        
        // 1. Broadcast via Socket.io (F-RT)
        $nodeService->broadcastToUser(
            $event->konsultasi->user_id,
            'konsultasi.responded',
            [
                'konsultasi_id' => $event->konsultasi->id,
                'response_id' => $event->response->id,
                'message' => 'Anda mendapat balasan baru pada konsultasi: ' . $event->konsultasi->judul
            ]
        );

        // 2. WhatsApp Notification (F-WA)
        try {
            $subscription = WhatsappSubscription::where('user_id', $event->konsultasi->user_id)
                ->where('is_opt_in', true)
                ->first();

            if ($subscription) {
                $nama = $event->konsultasi->user ? $event->konsultasi->user->name : 'Pengguna';
                $pesanRespon = $event->response ? ($event->response->pesan ?? '') : '';
                $snippet = Str::limit(trim(strip_tags($pesanRespon)), 100);
                $message = "Halo {$nama}, ada balasan baru untuk konsultasi Anda dengan judul '{$event->konsultasi->judul}'";
                if (!empty($snippet)) {
                    $message .= ": \"{$snippet}\"";
                } else {
                    $message .= ".";
                }
                
                $nodeService->sendWhatsApp(
                    $subscription->nomor_wa,
                    $message,
                    [
                        'event_type' => 'konsultasi.responded',
                        'reference_id' => $event->konsultasi->id,
                        'user_id' => $event->konsultasi->user_id
                    ]
                );
            }
        } catch (\Exception $e) {
            Log::error('SendKonsultasiNotification WA Error: ' . $e->getMessage());
        }

        // 3. FCM Push Notification (topic-based)
        try {
            $fcm = new FcmNotificationService();

            if ($event->response->is_admin) {
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
            Log::error('SendKonsultasiNotification FCM Error: ' . $e->getMessage());
        }
    }
}
