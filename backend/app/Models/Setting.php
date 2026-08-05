<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Setting extends Model
{
    // Tabel non-konvensi — wajib eksplisit
    protected $table = 'm_settings';

    protected $fillable = [
        'key',
        'value',
        'keterangan',
    ];
}
