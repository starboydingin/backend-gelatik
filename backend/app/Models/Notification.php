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

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
