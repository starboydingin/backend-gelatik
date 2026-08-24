<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    // Tabel non-konvensi: singular — wajib eksplisit (bukan bawaan Laravel)
    protected $table = 'notification';

    protected $fillable = [
        'user_id',
        'judul',
        'message',
        'item_id',
        'type',
        'read',
    ];

    protected $casts = [
        'read' => 'boolean',
    ];

    protected $appends = [
        'resource_type',
        'resource_id',
    ];

    public function getResourceTypeAttribute(): ?string
    {
        $type = strtolower((string) $this->type);

        return match (true) {
            str_contains($type, 'konsultasi') => 'konsultasi',
            str_contains($type, 'pinjam') => 'peminjaman',
            str_contains($type, 'usulan_email'), str_contains($type, 'email') => 'usulan_email',
            default => null,
        };
    }

    public function getResourceIdAttribute(): ?int
    {
        return $this->resource_type && (int) $this->item_id > 0
            ? (int) $this->item_id
            : null;
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
