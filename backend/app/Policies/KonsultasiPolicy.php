<?php

namespace App\Policies;

use App\Models\Konsultasi;
use App\Models\User;

class KonsultasiPolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, Konsultasi $konsultasi): bool
    {
        return $this->isOwner($user, $konsultasi) || $this->isAdmin($user);
    }

    public function respond(User $user, Konsultasi $konsultasi): bool
    {
        return $this->isAdmin($user);
    }

    public function updateStatus(User $user, Konsultasi $konsultasi): bool
    {
        return $this->isAdmin($user);
    }

    public function delete(User $user, Konsultasi $konsultasi): bool
    {
        return $this->isOwner($user, $konsultasi) || $this->isAdmin($user);
    }

    private function isOwner(User $user, Konsultasi $konsultasi): bool
    {
        return (int) $konsultasi->user_id === (int) $user->id;
    }

    private function isAdmin(User $user): bool
    {
        return $user->hasAnyRole(['admin', 'superadmin']);
    }
}
