<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class RequestComment extends Model
{
    use SoftDeletes;

    protected $table = 'request_comments';

    protected $fillable = [
        'id',
        'request_type',
        'request_id',
        'user_id',
        'pesan',
    ];

    protected $appends = [
        'is_admin',
        'author_name',
        'author_role',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function getIsAdminAttribute(): bool
    {
        if (! $this->relationLoaded('user') && $this->user === null) {
            return false;
        }

        return (bool) ($this->user?->hasAnyRole(['admin', 'superadmin']) ?? false);
    }

    public function getAuthorNameAttribute(): string
    {
        return $this->user?->name ?? 'Pengguna';
    }

    public function getAuthorRoleAttribute(): string
    {
        return $this->isAdmin ? 'Admin' : 'Pemohon';
    }
}
