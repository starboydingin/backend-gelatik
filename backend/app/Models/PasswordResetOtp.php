<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class PasswordResetOtp extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'otp_hash',
        'reset_token_hash',
        'attempts',
        'expires_at',
        'verified_at',
        'consumed_at',
        'last_sent_at',
    ];

    protected $hidden = ['otp_hash', 'reset_token_hash'];

    protected function casts(): array
    {
        return [
            'expires_at' => 'datetime',
            'verified_at' => 'datetime',
            'consumed_at' => 'datetime',
            'last_sent_at' => 'datetime',
        ];
    }
}
