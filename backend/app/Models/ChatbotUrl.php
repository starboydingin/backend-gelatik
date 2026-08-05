<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChatbotUrl extends Model
{
    protected $table = 'chatbot_urls';

    public $incrementing = false;

    protected $fillable = [
        'id',
        'account_name',
        'url',
        'status',
    ];

    /**
     * Scope untuk config chatbot aktif (status = 1)
     */
    public function scopeAktif($query)
    {
        return $query->where('status', 1);
    }
}
