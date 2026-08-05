<?php

namespace App\Services;

use App\Models\Notification;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification as FcmNotification;

class FcmNotificationService
{
    protected ?Messaging $messaging = null;

    public function __construct()
    {
        try {
            $this->messaging = app('firebase.messaging');
        } catch (\Throwable $e) {
            Log::warning('FcmNotificationService: Firebase Messaging tidak tersedia — ' . $e->getMessage());
        }
    }

    /**
     * Kirim FCM message ke topic tertentu (core method).
     * Semua method lain memanggil ini.
     */
    public function sendToTopic(string $topic, string $judul, string $pesan, array $data = []): bool
    {
        if (!$this->messaging) {
            Log::warning("FCM sendToTopic('{$topic}'): Messaging tidak tersedia, skip.");
            return false;
        }

        try {
            $message = CloudMessage::withTarget('topic', $topic)
                ->withNotification(FcmNotification::create($judul, $pesan))
                ->withData($data);

            $this->messaging->send($message);

            Log::info("FCM terkirim ke topic '{$topic}': {$judul}");
            return true;
        } catch (\Throwable $e) {
            Log::error("FCM sendToTopic('{$topic}') Error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Kirim notifikasi personal ke user via topic user_{userId}.
     * Otomatis insert ke tabel notification.
     */
    public function sendToUser(int $userId, string $judul, string $pesan, array $data = []): bool
    {
        $topic = "user_{$userId}";
        $result = $this->sendToTopic($topic, $judul, $pesan, $data);

        // Log ke tabel notification (personal → user_id diisi)
        $this->logNotification(
            $userId,
            $judul,
            $pesan,
            $data['reference_id'] ?? 0,
            $data['type'] ?? 'general'
        );

        return $result;
    }

    /**
     * Kirim notifikasi ke semua admin via topic "admin".
     * Otomatis insert ke tabel notification (user_id = 0, konsisten dengan pola existing).
     */
    public function sendToAdmins(string $judul, string $pesan, array $data = []): bool
    {
        $result = $this->sendToTopic('admin', $judul, $pesan, $data);

        // Log ke tabel notification (broadcast → user_id = 0)
        $this->logNotification(
            0,
            $judul,
            $pesan,
            $data['reference_id'] ?? 0,
            $data['type'] ?? 'general'
        );

        return $result;
    }

    /**
     * Broadcast pengumuman ke semua user via topic "pengumuman".
     * Otomatis insert ke tabel notification (user_id = 0).
     */
    public function broadcastPengumuman(string $judul, string $pesan, array $data = []): bool
    {
        $result = $this->sendToTopic('pengumuman', $judul, $pesan, $data);

        // Log ke tabel notification (broadcast → user_id = 0)
        $this->logNotification(
            0,
            $judul,
            $pesan,
            $data['reference_id'] ?? 0,
            $data['type'] ?? 'pengumuman'
        );

        return $result;
    }

    /**
     * Insert baris ke tabel notification.
     * Dipanggil otomatis oleh sendToUser/sendToAdmins/broadcastPengumuman.
     */
    protected function logNotification(int $userId, string $judul, string $pesan, int $itemId, string $type): void
    {
        try {
            \Illuminate\Support\Facades\DB::table('notification')->insert([
                'user_id'    => $userId,
                'judul'      => $judul,
                'message'    => $pesan,
                'item_id'    => $itemId,
                'type'       => $type,
                'read'       => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        } catch (\Throwable $e) {
            Log::error('FcmNotificationService logNotification Error: ' . $e->getMessage());
        }
    }
}
