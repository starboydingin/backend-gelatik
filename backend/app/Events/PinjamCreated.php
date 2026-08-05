<?php

namespace App\Events;

use App\Models\Pinjam;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class PinjamCreated
{
    use Dispatchable, SerializesModels;

    public Pinjam $pinjam;

    /**
     * Create a new event instance.
     */
    public function __construct(Pinjam $pinjam)
    {
        $this->pinjam = $pinjam;
    }
}
