<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class NodeServiceClient
{
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
        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $this->apiKey,
                'Accept' => 'application/json'
            ])->timeout(5)->post($this->baseUrl . '/internal/broadcast', [
                'target' => 'user',
                'user_id' => $userId,
                'event' => $event,
                'payload' => $payload
            ]);

            return $response->json();
        } catch (\Throwable $e) {
            Log::error('Gagal mengirim broadcast ke Node.js: ' . $e->getMessage());
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Mengirim broadcast event Socket.io ke semua user melalui Node.js service.
     */
    public function broadcastToAll($event, $payload)
    {
        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $this->apiKey,
                'Accept' => 'application/json'
            ])->timeout(5)->post($this->baseUrl . '/internal/broadcast', [
                'target' => 'all',
                'event' => $event,
                'payload' => $payload
            ]);

            return $response->json();
        } catch (\Throwable $e) {
            Log::error('Gagal mengirim broadcast ke Node.js: ' . $e->getMessage());
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Mengirim event ke room role yang dibentuk dari identity tervalidasi.
     */
    public function broadcastToRole(string $role, string $event, array $payload)
    {
        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $this->apiKey,
                'Accept' => 'application/json',
            ])->timeout(5)->post($this->baseUrl . '/internal/broadcast', [
                'target' => 'role',
                'role' => $role,
                'event' => $event,
                'payload' => $payload,
            ]);

            return $response->json();
        } catch (\Throwable $e) {
            Log::error('Gagal mengirim role broadcast ke Node.js: ' . $e->getMessage());
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Mengirim pesan WhatsApp melalui Node.js service.
     */
    public function sendWhatsApp($nomorWa, $message, $reference = [])
    {
        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $this->apiKey,
                'Accept' => 'application/json'
            ])->timeout(5)->post($this->baseUrl . '/internal/wa/send', [
                'nomor_wa' => $nomorWa,
                'message' => $message,
                'reference' => $reference // array berisi event_type, reference_id, user_id
            ]);

            return $response->json();
        } catch (\Throwable $e) {
            Log::error('Gagal mengirim WhatsApp ke Node.js: ' . $e->getMessage());
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }
}
