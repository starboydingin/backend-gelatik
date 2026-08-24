<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WhatsappDeliveryLog extends Model
{
    protected $fillable = [
        'delivery_key',
        'user_id',
        'event_type',
        'reference_id',
        'status',
        'attempts',
        'error',
        'sent_at',
    ];

    protected $casts = [
        'sent_at' => 'datetime',
        'attempts' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
