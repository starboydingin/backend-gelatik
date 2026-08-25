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
        $content = strtolower(trim($this->judul.' '.$this->message));

        return match (true) {
            str_contains($type, 'konsultasi'), str_contains($type, 'konsul'),
            str_contains($content, 'konsultasi') => 'konsultasi',
            str_contains($type, 'pinjam'), str_contains($type, 'peminjaman'),
            str_contains($content, 'peminjaman') => 'peminjaman',
            str_contains($type, 'usulan_email'), str_contains($type, 'email'),
            str_contains($content, 'usulan email'), str_contains($content, 'email resmi') => 'usulan_email',
            str_contains($type, 'kritik_saran'), str_contains($type, 'feedback'),
            str_contains($content, 'kritik'), str_contains($content, 'saran') => 'kritik_saran',
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
