<?php

namespace App\Listeners;

use App\Events\UsulanEmailStatusChanged;
use App\Models\WhatsappSubscription;
use App\Services\FcmNotificationService;
use App\Services\NodeServiceClient;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Log;

class SendUsulanEmailNotification implements ShouldQueue
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
    public function handle(UsulanEmailStatusChanged $event): void
    {
        $nodeService = new NodeServiceClient();
        
        // 1. Broadcast via Socket.io (F-RT)
        $nodeService->broadcastToUser(
            $event->usulan->user_id,
            'usulan_email.status_changed',
            [
                'usulan_id' => $event->usulan->id,
                'new_status' => $event->newStatus,
                'message' => 'Status usulan email Anda telah diubah menjadi ' . $event->newStatus
            ]
        );

        // 2. WhatsApp Notification (F-WA)
        try {
            $subscription = WhatsappSubscription::where('user_id', $event->usulan->user_id)
                ->where('is_opt_in', true)
                ->first();

            if ($subscription) {
                $nama = $event->usulan->user ? $event->usulan->user->name : 'Pengguna';
                $statusLower = strtolower($event->newStatus);

                if ($statusLower === 'ditolak') {
                    $catatan = $event->usulan->catatan ?? 'Tidak ada catatan';
                    $message = "Halo {$nama}, pengajuan usulan email Anda ditolak. Alasan: {$catatan}";
                } else {
                    $message = "Halo {$nama}, pengajuan email Anda (ID: {$event->usulan->id}) telah diubah statusnya menjadi {$event->newStatus}.";
                }
                
                $nodeService->sendWhatsApp(
                    $subscription->nomor_wa,
                    $message,
                    [
                        'event_type' => 'usulan_email.status_changed',
                        'reference_id' => $event->usulan->id,
                        'user_id' => $event->usulan->user_id
                    ]
                );
            }
        } catch (\Exception $e) {
            Log::error('SendUsulanEmailNotification WA Error: ' . $e->getMessage());
        }

        // 3. FCM Push Notification (topic-based)
        try {
            $fcm = new FcmNotificationService();
            $fcm->sendToUser(
                $event->usulan->user_id,
                'Usulan Email',
                'Status usulan email Anda telah diubah menjadi ' . $event->newStatus,
                [
                    'type' => 'usulan_email',
                    'reference_id' => (string) $event->usulan->id,
                ]
            );
        } catch (\Exception $e) {
            Log::error('SendUsulanEmailNotification FCM Error: ' . $e->getMessage());
        }
    }
}
