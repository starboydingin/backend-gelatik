<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WhatsappSubscription extends Model
{
    protected $fillable = [
        'user_id',
        'nomor_wa',
        'is_opt_in',
        'verified_at',
        'last_delivery_status',
    ];

    protected $casts = [
        'is_opt_in'   => 'boolean',
        'verified_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
