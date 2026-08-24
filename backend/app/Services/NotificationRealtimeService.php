<?php

namespace App\Services;

use App\Models\Notification;

/** Publishes a durable inbox update after its database row has been written. */
class NotificationRealtimeService
{
    public function toUser(Notification $notification): void
    {
        if ((int) $notification->user_id < 1) {
            return;
        }

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
}
