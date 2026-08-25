<?php

namespace App\Services;

use App\Models\Notification;
use Illuminate\Support\Facades\Cache;

/** Publishes a durable inbox update after its database row has been written. */
class NotificationRealtimeService
{
    public function toUser(Notification $notification): void
    {
        if ((int) $notification->user_id < 1) {
            return;
        }

        Cache::forget('dashboard:user:' . (int) $notification->user_id);
        Cache::forget('dashboard:admin:admin');
        Cache::forget('dashboard:admin:superadmin');

        app(NodeServiceClient::class)->broadcastToUser(
            (int) $notification->user_id,
            'notification',
            RealtimeEventPayload::make('notification', (int) $notification->id, [
                'status' => 'new',
                'message' => $notification->message ?: $notification->judul,
            ]),
        );
    }

    public function toAdmins(Notification $notification): void
    {
        app(NodeServiceClient::class)->broadcastToRole(
            'admin',
            'notification',
            RealtimeEventPayload::make('notification', (int) $notification->id, [
                'status' => 'new',
                'message' => $notification->message ?: $notification->judul,
            ]),
        );
    }

    /**
     * Synchronise a read-state change to every active client of one account.
     * This uses the authenticated user room, not the shared admin room, so one
     * administrator reading a broadcast cannot mark it read for another.
     */
    public function inboxState(int $userId, int $notificationId, string $status): void
    {
        if ($userId < 1 || $notificationId < 1) {
            return;
        }

        Cache::forget("dashboard:user:{$userId}");
        Cache::forget('dashboard:admin:admin');
        Cache::forget('dashboard:admin:superadmin');

        app(NodeServiceClient::class)->broadcastToUser(
            $userId,
            'notification',
            RealtimeEventPayload::make('notification', $notificationId, [
                'status' => $status,
                'message' => $status === 'read_all'
                    ? 'Semua notifikasi telah dibaca.'
                    : 'Status notifikasi diperbarui.',
            ]),
        );
    }
}
