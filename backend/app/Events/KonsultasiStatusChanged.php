<?php

namespace App\Events;

use App\Models\Konsultasi;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class KonsultasiStatusChanged
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public Konsultasi $konsultasi,
        public string $oldStatus,
        public string $newStatus,
    ) {
    }
}
