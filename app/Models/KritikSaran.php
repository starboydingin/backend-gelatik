<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class KritikSaran extends Model
{
    protected $table = 'kritik_sarans';

    public $incrementing = false;

    protected $fillable = [
        'id',
        'user_id',
        'kritik',
        'saran',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
