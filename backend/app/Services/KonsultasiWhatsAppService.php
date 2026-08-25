<?php

namespace App\Services;

use App\Models\Konsultasi;
use App\Models\KonsultasiResponse;
use App\Models\WhatsappSubscription;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

use function Illuminate\Support\defer;

class KonsultasiWhatsAppService
{
    public function __construct(private NodeServiceClient $nodeService) {}

    /**
     * Deliver after the HTTP response without depending on a queue worker.
     * The response ID is the idempotency reference for one admin reply.
     */
    public function afterAdminResponse(Konsultasi $konsultasi, KonsultasiResponse $response): void
    {
        $konsultasi->loadMissing('user');
        $payload = [
            'consultation_id' => (int) $konsultasi->id,
            'response_id' => (int) $response->id,
            'user_id' => (int) $konsultasi->user_id,
            'user_name' => $konsultasi->user?->name ?: 'Pengguna',
            'title' => (string) $konsultasi->judul,
            'response' => (string) $response->pesan,
        ];

        defer(
            fn () => $this->deliver($payload),
            'gelatik-wa-konsultasi-response-'.$payload['response_id'],
            always: true,
        );
    }

    /** @param array<string, int|string> $payload */
    private function deliver(array $payload): void
    {
        $subscription = null;
        try {
            $subscription = WhatsappSubscription::query()
                ->where('user_id', $payload['user_id'])
                ->where('is_opt_in', true)
                ->first();
            if (! $subscription) {
                return;
            }

            $snippet = Str::limit(trim(strip_tags((string) $payload['response'])), 100);
            $message = "Halo {$payload['user_name']}, ada balasan baru untuk konsultasi Anda dengan judul '{$payload['title']}'";
            $message .= $snippet !== '' ? ": \"{$snippet}\"" : '.';

            $this->nodeService->sendWhatsApp($subscription->nomor_wa, $message, [
                'event_type' => 'konsultasi.responded',
                'reference_id' => $payload['response_id'],
                'user_id' => $payload['user_id'],
            ]);
            $subscription->update(['last_delivery_status' => 'delivered']);
        } catch (\Throwable $exception) {
            $subscription?->update(['last_delivery_status' => 'failed']);
            Log::error('Notifikasi WhatsApp balasan konsultasi gagal.', [
                'consultation_id' => $payload['consultation_id'],
                'response_id' => $payload['response_id'],
                'exception' => $exception::class,
            ]);
        }
    }
}
