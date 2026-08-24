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
    public function handle(UsulanEmailStatusChanged $event): void
    {
        $nodeService = new NodeServiceClient();
        $deliveryFailure = null;
        $ownerId = (int) ($event->usulan->created_by ?? 0);
        if ($ownerId <= 0) {
            Log::warning('Usulan email status notification skipped because the owner is missing.', [
                'usulan_id' => $event->usulan->id,
            ]);

            return;
        }

        // Socket.IO and the browser inbox are written synchronously by
        // UsulanEmailService. This queued listener only handles external push.
        // 1. WhatsApp Notification (F-WA)
        try {
            $subscription = WhatsappSubscription::where('user_id', $ownerId)
                ->where('is_opt_in', true)
                ->first();

            if ($subscription) {
                $nama = $event->usulan->user?->name ?? 'Pengguna';
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
                        'user_id' => $ownerId
                    ]
                );
            }
        } catch (\Exception $e) {
            Log::error('SendUsulanEmailNotification WA Error: ' . $e->getMessage());
            $deliveryFailure = $e;
        }

        // 2. FCM Push Notification (topic-based)
        try {
            $fcm = new FcmNotificationService();
            $fcm->sendToUser(
                $ownerId,
                'Usulan Email',
                'Status usulan email Anda telah diubah menjadi ' . $event->newStatus,
                [
                    'type' => 'usulan_email',
                    'reference_id' => (string) $event->usulan->id,
                ]
            );
        } catch (\Exception $e) {
            Log::error('SendUsulanEmailNotification FCM Error: ' . $e->getMessage());
            $deliveryFailure ??= $e;
        }

        if ($deliveryFailure) {
            throw $deliveryFailure;
        }
    }
}
