<?php

namespace App\Events;

use App\Models\UsulanEmail;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class UsulanEmailCreated
{
    use Dispatchable, SerializesModels;

    public UsulanEmail $usulan;

    /**
     * Create a new event instance.
     */
    public function __construct(UsulanEmail $usulan)
    {
        $this->usulan = $usulan;
    }
}
