<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class KritikSaran extends Model
{
    protected $table = 'kritik_sarans';

    public $incrementing = true;

    protected $fillable = [
        'id',
        'user_id',
        'kritik',
        'saran',
        'balasan',
        'dibalas_oleh',
        'dibalas_pada',
    ];

    protected $casts = [
        'dibalas_pada' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function responder()
    {
        return $this->belongsTo(User::class, 'dibalas_oleh');
    }
}
