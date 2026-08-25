<?php

namespace App\Listeners;

use App\Events\UsulanEmailStatusChanged;
use App\Services\FcmNotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;
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
        $ownerId = (int) ($event->usulan->created_by ?? 0);
        if ($ownerId <= 0) {
            Log::warning('Usulan email status notification skipped because the owner is missing.', [
                'usulan_id' => $event->usulan->id,
            ]);

            return;
        }

        // Socket.IO, browser inbox, and WhatsApp are handled directly by the
        // business service. This queued listener only handles FCM push.
        try {
            $fcm = new FcmNotificationService;
            $fcm->sendToUser(
                $ownerId,
                'Usulan Email',
                'Status usulan email Anda telah diubah menjadi '.$event->newStatus,
                [
                    'type' => 'usulan_email',
                    'reference_id' => (string) $event->usulan->id,
                ],
            );
        } catch (\Exception $e) {
            Log::error('SendUsulanEmailNotification FCM Error: '.$e->getMessage());
            throw $e;
        }
    }
}
