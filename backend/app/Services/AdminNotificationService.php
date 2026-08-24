<?php

namespace App\Services;

use App\Models\Notification;
use Illuminate\Support\Facades\Cache;

/**
 * Persists the admin inbox entry before attempting delivery to Socket.IO.
 * A temporary Node outage therefore never prevents a user submission.
 */
class AdminNotificationService
{
    public function announce(
        string $event,
        int $entityId,
        string $title,
        string $message,
        string $type,
        array $attributes = [],
    ): Notification {
        $notification = Notification::create([
            'user_id' => 0,
            'judul' => $title,
            'message' => $message,
            'type' => $type,
            'item_id' => $entityId,
            'read' => false,
        ]);

        Cache::forget('dashboard:admin:admin');
        Cache::forget('dashboard:admin:superadmin');

        app(NotificationRealtimeService::class)->toAdmins($notification);

        app(NodeServiceClient::class)->broadcastToRole(
            'admin',
            $event,
            RealtimeEventPayload::make($event, $entityId, array_merge([
                'message' => $message,
            ], $attributes)),
        );

        return $notification;
    }
}
