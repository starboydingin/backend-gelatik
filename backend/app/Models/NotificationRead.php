<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NotificationRead extends Model
{
    protected $table = 'notification_reads';

    public $timestamps = false;

    protected $fillable = ['notification_id', 'user_id', 'read_at'];

    protected $casts = ['read_at' => 'datetime'];
}
