<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Router extends Model
{
    // Tabel non-konvensi — wajib eksplisit
    protected $table = 'unker_router';

    public $incrementing = false;

    protected $fillable = [
        'id',
        'nama_opd',
        'nama_router',
        'is_active',
        'created_by',
        'updated_by',
    ];

    /**
     * Scope untuk filter status aktif (is_active = 1)
     */
    public function scopeAktif($query)
    {
        return $query->where('is_active', 1);
    }
}
