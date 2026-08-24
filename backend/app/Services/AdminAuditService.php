<?php

namespace App\Services;

use App\Models\AdminAuditLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Schema;

class AdminAuditService
{
    /** Record privileged operational actions without blocking the business mutation. */
    public function record(User $actor, string $action, string $description, ?Model $subject = null, array $metadata = []): void
    {
        if (! $actor->hasAnyRole(['admin', 'superadmin']) || ! Schema::hasTable('admin_audit_logs')) {
            return;
        }

        AdminAuditLog::create([
            'actor_id' => $actor->id,
            'actor_role' => $actor->hasRole('superadmin') ? 'superadmin' : 'admin',
            'action' => $action,
            'subject_type' => $subject ? $subject::class : null,
            'subject_id' => $subject?->getKey(),
            'description' => $description,
            'metadata' => $metadata ?: null,
        ]);

        Cache::forget('dashboard:admin:admin');
        Cache::forget('dashboard:admin:superadmin');
    }
}
