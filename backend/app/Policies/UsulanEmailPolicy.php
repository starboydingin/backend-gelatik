<?php

namespace App\Policies;

use App\Models\User;
use App\Models\UsulanEmail;

class UsulanEmailPolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, UsulanEmail $usulanEmail): bool
    {
        return (int) $usulanEmail->created_by === (int) $user->id
            || $user->hasAnyRole(['admin', 'superadmin', 'bkd']);
    }

    public function verify(User $user, UsulanEmail $usulanEmail): bool
    {
        return $user->hasAnyRole(['admin', 'superadmin', 'bkd']);
    }

    public function createOfficialEmail(User $user, UsulanEmail $usulanEmail): bool
    {
        return $user->hasAnyRole(['admin', 'superadmin']);
    }

    public function reject(User $user, UsulanEmail $usulanEmail): bool
    {
        return $user->hasAnyRole(['admin', 'superadmin', 'bkd']);
    }
}
