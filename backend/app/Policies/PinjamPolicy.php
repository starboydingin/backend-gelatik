<?php

namespace App\Policies;

use App\Models\Pinjam;
use App\Models\User;

class PinjamPolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, Pinjam $pinjam): bool
    {
        return $this->isOwner($user, $pinjam) || $this->isAdmin($user);
    }

    public function update(User $user, Pinjam $pinjam): bool
    {
        return $this->isOwner($user, $pinjam);
    }

    public function delete(User $user, Pinjam $pinjam): bool
    {
        return $this->isOwner($user, $pinjam) || $this->isAdmin($user);
    }

    public function modifyItems(User $user, Pinjam $pinjam): bool
    {
        return $this->isOwner($user, $pinjam);
    }

    public function updateStatus(User $user, Pinjam $pinjam): bool
    {
        return $this->isAdmin($user);
    }

    private function isOwner(User $user, Pinjam $pinjam): bool
    {
        return (int) $pinjam->user_id === (int) $user->id;
    }

    private function isAdmin(User $user): bool
    {
        return $user->hasAnyRole(['admin', 'superadmin']);
    }
}
