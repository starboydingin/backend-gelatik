<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;

use function Illuminate\Support\defer;

/**
 * Publishes metadata-only invalidation events. Clients never trust these
 * events as data; they re-read the REST API with their current credentials.
 */
class RealtimeDataSyncService
{
    /** @var array<string, \Closure> */
    private array $pending = [];

    private bool $flushRegistered = false;

    public function eventToUser(int $userId, string $event, array $payload): void
    {
        if ($userId < 1) {
            return;
        }
        $entityId = (int) ($payload['entity_id'] ?? 0);
        $this->afterResponse("event:user:{$userId}:{$event}:{$entityId}", fn () => app(NodeServiceClient::class)
            ->broadcastToUser($userId, $event, $payload));
    }

    public function eventToAdmins(string $event, array $payload): void
    {
        $entityId = (int) ($payload['entity_id'] ?? 0);
        $this->afterResponse("event:admins:{$event}:{$entityId}", fn () => app(NodeServiceClient::class)
            ->broadcastToRole('admin', $event, $payload));
    }

    public function eventToEveryone(string $event, array $payload): void
    {
        $entityId = (int) ($payload['entity_id'] ?? 0);
        $this->afterResponse("event:everyone:{$event}:{$entityId}", fn () => app(NodeServiceClient::class)
            ->broadcastToAll($event, $payload));
    }

    public function user(int $userId, string $resource, int $entityId): void
    {
        if ($userId < 1 || $entityId < 1) {
            return;
        }

        Cache::forget("dashboard:user:{$userId}");
        $this->afterResponse("user:{$userId}:{$resource}", fn () => app(NodeServiceClient::class)->broadcastToUser(
            $userId,
            'data.sync',
            $this->payload($entityId, $resource),
        ));
    }

    public function admins(string $resource, int $entityId): void
    {
        if ($entityId < 1) {
            return;
        }

        Cache::forget('dashboard:admin:admin');
        Cache::forget('dashboard:admin:superadmin');
        $this->afterResponse("admins:{$resource}", fn () => app(NodeServiceClient::class)->broadcastToRole(
            'admin',
            'data.sync',
            $this->payload($entityId, $resource),
        ));
    }

    public function userAndAdmins(int $userId, string $resource, int $entityId): void
    {
        $this->user($userId, $resource, $entityId);
        $this->admins($resource, $entityId);
    }

    /** Broadcast only anonymous aggregate refreshes to every authenticated client. */
    public function insights(string $resource = 'service_insights'): void
    {
        Cache::forget('dashboard:service-insights');
        Cache::forget('dashboard:admin:admin');
        Cache::forget('dashboard:admin:superadmin');

        $this->afterResponse('insights', fn () => app(NodeServiceClient::class)->broadcastToAll(
            'insights.sync',
            RealtimeEventPayload::make('insights.sync', 1, [
                'status' => 'updated',
                'resource' => $resource,
            ]),
        ));
    }

    /** Public reference data can be safely invalidated for all signed-in clients. */
    public function everyone(string $resource, int $entityId): void
    {
        if ($entityId < 1) {
            return;
        }

        Cache::forget('dashboard:service-insights');
        Cache::forget('dashboard:admin:admin');
        Cache::forget('dashboard:admin:superadmin');
        $this->afterResponse("everyone:{$resource}", fn () => app(NodeServiceClient::class)->broadcastToAll(
            'data.sync',
            $this->payload($entityId, $resource),
        ));
    }

    private function payload(int $entityId, string $resource): array
    {
        return RealtimeEventPayload::make('data.sync', $entityId, [
            'status' => 'updated',
            'resource' => $resource,
        ]);
    }

    private function afterResponse(string $key, \Closure $publish): void
    {
        $this->pending[$key] = $publish;
        if ($this->flushRegistered) {
            return;
        }

        $this->flushRegistered = true;
        defer(function (): void {
            foreach ($this->pending as $publish) {
                $publish();
            }
            $this->pending = [];
            $this->flushRegistered = false;
        }, 'gelatik-realtime-sync', always: true);
    }
}
