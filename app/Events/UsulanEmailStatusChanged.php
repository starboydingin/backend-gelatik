<?php

namespace App\Events;

use App\Models\UsulanEmail;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class UsulanEmailStatusChanged
{
    use Dispatchable, SerializesModels;

    public UsulanEmail $usulan;
    public string $oldStatus;
    public string $newStatus;

    /**
     * Create a new event instance.
     */
    public function __construct(UsulanEmail $usulan, string $oldStatus, string $newStatus = '')
    {
        $this->usulan = $usulan;
        // Tangani jika hanya 1 status passed (backward compatibility)
        if (empty($newStatus)) {
            $this->oldStatus = 'diajukan';
            $this->newStatus = $oldStatus;
        } else {
            $this->oldStatus = $oldStatus;
            $this->newStatus = $newStatus;
        }
    }
}
