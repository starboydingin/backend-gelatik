<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use RuntimeException;

class NodeServiceClient
{
    private const BROADCAST_CIRCUIT_KEY = 'realtime:node:broadcast-unavailable';

    protected $baseUrl;

    protected $apiKey;

    public function __construct()
    {
        $this->baseUrl = env('NODE_SERVICE_URL', 'http://127.0.0.1:4000');
        $this->apiKey = env('INTERNAL_SERVICE_API_KEY');
    }

    /**
     * Mengirim broadcast event Socket.io ke user tertentu melalui Node.js service.
     */
    public function broadcastToUser($userId, $event, $payload)
    {
        return $this->broadcast([
            'target' => 'user',
            'user_id' => $userId,
            'event' => $event,
            'payload' => $payload,
        ]);
    }

    /**
     * Mengirim broadcast event Socket.io ke semua user melalui Node.js service.
     */
    public function broadcastToAll($event, $payload)
    {
        return $this->broadcast([
            'target' => 'all',
            'event' => $event,
            'payload' => $payload,
        ]);
    }

    /**
     * Mengirim event ke room role yang dibentuk dari identity tervalidasi.
     */
    public function broadcastToRole(string $role, string $event, array $payload)
    {
        return $this->broadcast([
            'target' => 'role',
            'role' => $role,
            'event' => $event,
            'payload' => $payload,
        ]);
    }

    private function broadcast(array $payload): array
    {
        if (Cache::has(self::BROADCAST_CIRCUIT_KEY)) {
            return ['success' => false, 'error' => 'Realtime service temporarily unavailable.'];
        }

        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer '.$this->apiKey,
                'Accept' => 'application/json',
            ])->connectTimeout(1)->timeout(2)->post($this->baseUrl.'/internal/broadcast', $payload);

            if (! $response->successful()) {
                Cache::put(self::BROADCAST_CIRCUIT_KEY, true, now()->addSeconds(5));
            }

            return $response->json() ?? ['success' => $response->successful()];
        } catch (\Throwable $e) {
            Cache::put(self::BROADCAST_CIRCUIT_KEY, true, now()->addSeconds(5));
            Log::warning('Realtime broadcast tidak tersedia.', ['exception' => $e::class]);

            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Mengirim pesan WhatsApp melalui Node.js service.
     */
    public function sendWhatsApp($nomorWa, $message, $reference = [])
    {
        $deliveryKey = (string) ($reference['delivery_key'] ?? hash('sha256', implode('|', [
            $reference['event_type'] ?? 'unknown',
            $reference['reference_id'] ?? '0',
            $reference['user_id'] ?? '0',
            Str::limit((string) $message, 160, ''),
        ])));

        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer '.$this->apiKey,
                'Accept' => 'application/json',
            ])->timeout(20)->post($this->baseUrl.'/internal/wa/send', [
                'nomor_wa' => $nomorWa,
                'message' => $message,
                'reference' => $reference + ['delivery_key' => $deliveryKey],
                'delivery_key' => $deliveryKey,
            ]);

            if (! $response->successful() || $response->json('success') !== true) {
                throw new RuntimeException('WhatsApp gateway menolak pengiriman.');
            }

            return $response->json() + ['delivery_key' => $deliveryKey];
        } catch (\Throwable $e) {
            Log::error('Gagal mengirim WhatsApp ke Node.js: '.$e->getMessage());
            throw $e;
        }
    }

    public function whatsappStatus(): array
    {
        try {
            $response = Http::acceptJson()->timeout(3)->get($this->baseUrl.'/health');

            return [
                'success' => $response->successful(),
                'status' => $response->json('whatsappStatus'),
            ];
        } catch (\Throwable $e) {
            Log::warning('Status WhatsApp gateway tidak tersedia.', ['exception' => $e::class]);

            return ['success' => false, 'status' => 'unavailable'];
        }
    }
}
