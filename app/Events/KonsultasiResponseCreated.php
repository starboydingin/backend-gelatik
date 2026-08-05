<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

use App\Models\Konsultasi;
use App\Models\KonsultasiResponse;

class KonsultasiResponseCreated
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $konsultasi;
    public $response;

    /**
     * Create a new event instance.
     */
    public function __construct(Konsultasi $konsultasi, KonsultasiResponse $response)
    {
        $this->konsultasi = $konsultasi;
        $this->response = $response;
    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, Channel>
     */
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('channel-name'),
        ];
    }
}
