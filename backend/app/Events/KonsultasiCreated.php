<?php

namespace App\Events;

use App\Models\Konsultasi;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class KonsultasiCreated
{
    use Dispatchable, SerializesModels;

    public Konsultasi $konsultasi;

    /**
     * Create a new event instance.
     */
    public function __construct(Konsultasi $konsultasi)
    {
        $this->konsultasi = $konsultasi;
    }
}
