<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WhatsappDeliveryLog extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'user_id',
        'event_type',
        'reference_id',
        'status',
        'sent_at',
    ];

    protected $casts = [
        'sent_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
