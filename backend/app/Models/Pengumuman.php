<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Pengumuman extends Model
{
    protected $table = 'pengumumans';

    public $incrementing = true;

    protected $fillable = [
        'id',
        'judul',
        'konten',
        'expired_at',
    ];

    protected $casts = [
        'expired_at' => 'datetime',
    ];

    /**
     * Scope untuk pengumuman yang belum kedaluwarsa
     */
    public function scopeAktif($query)
    {
        return $query->where(function ($q) {
            $q->whereNull('expired_at')
              // The admin form captures a calendar date, not a time. Keep an
              // announcement active through the end of that WIB date instead
              // of expiring it at 00:00 at the start of the day.
                ->orWhereDate('expired_at', '>=', today());
        });
    }
}
