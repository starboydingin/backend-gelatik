<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RouterList extends Model
{
    // Tabel non-konvensi — wajib eksplisit
    protected $table = 'unker_list_router';

    public $incrementing = true;

    protected $fillable = [
        'id',
        'nama_opd',
        'identity_router',
        'interface',
        'lokasi',
        'status',
        'created_by',
        'updated_by',
    ];

    /**
     * Scope untuk filter status aktif (status = 1)
     */
    public function scopeAktif($query)
    {
        return $query->where('status', 1);
    }
}
