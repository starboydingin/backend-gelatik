<?php

namespace Tests\Unit;

use App\Services\RealtimeEventPayload;
use Tests\TestCase;

class RealtimeEventPayloadTest extends TestCase
{
    public function test_payload_contains_only_contract_identity_fields_and_attributes(): void
    {
        $payload = RealtimeEventPayload::make('pinjam.status_changed', 12, [
            'status' => 'Proses',
            'old_status' => 'Menunggu',
        ]);

        $this->assertSame('pinjam.status_changed', $payload['type']);
        $this->assertSame(12, $payload['entity_id']);
        $this->assertSame('Proses', $payload['status']);
        $this->assertSame('Menunggu', $payload['old_status']);
        $this->assertNotEmpty($payload['event_id']);
        $this->assertNotEmpty($payload['created_at']);
        $this->assertArrayNotHasKey('token', $payload);
        $this->assertArrayNotHasKey('user', $payload);
    }
}
