<?php

namespace App\Listeners;

use App\Events\KonsultasiStatusChanged;
use App\Models\WhatsappSubscription;
use App\Services\NodeServiceClient;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Log;

class SendKonsultasiStatusNotification implements ShouldQueue
{
    public int $tries = 3;

    public function backoff(): array
    {
        return [10, 30, 90];
    }

    public function handle(KonsultasiStatusChanged $event): void
    {
        $nodeService = new NodeServiceClient();

        // WhatsApp is opt-in per account. A status update must only reach the
        // owner of this consultation, never an admin room or another user.
        try {
            $subscription = WhatsappSubscription::query()
                ->where('user_id', $event->konsultasi->user_id)
                ->where('is_opt_in', true)
                ->first();

            if ($subscription) {
                $nama = $event->konsultasi->user?->name ?: 'Pengguna';
                $judul = $event->konsultasi->judul ?: 'konsultasi Anda';
                $message = match (strtolower($event->newStatus)) {
                    'diproses' => "Halo {$nama}, konsultasi \"{$judul}\" sedang diproses oleh petugas TIK.",
                    'selesai' => "Halo {$nama}, konsultasi \"{$judul}\" telah selesai ditangani. Silakan cek detail konsultasi untuk informasi terbaru.",
                    'ditolak' => "Halo {$nama}, konsultasi \"{$judul}\" tidak dapat diproses. Silakan cek detail konsultasi atau hubungi helpdesk TIK.",
                    default => "Halo {$nama}, status konsultasi \"{$judul}\" telah berubah menjadi {$event->newStatus}.",
                };

                $nodeService->sendWhatsApp($subscription->nomor_wa, $message, [
                    'event_type' => 'konsultasi.status_changed',
                    'reference_id' => $event->konsultasi->id,
                    'user_id' => $event->konsultasi->user_id,
                ]);
            }
        } catch (\Throwable $exception) {
            // Queue failures are logged and retried; changing consultation
            // status must never fail merely because WhatsApp is unavailable.
            Log::error('SendKonsultasiStatusNotification WA Error: '.$exception->getMessage());
            throw $exception;
        }
    }
}
