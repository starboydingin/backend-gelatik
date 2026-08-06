<?php

namespace App\Services;

use Illuminate\Support\Str;

class RealtimeEventPayload
{
    public static function make(string $type, int $entityId, array $attributes = []): array
    {
        return array_merge([
            'event_id' => (string) Str::uuid(),
            'type' => $type,
            'entity_id' => $entityId,
            'created_at' => now()->toIso8601String(),
        ], $attributes);
    }
}
