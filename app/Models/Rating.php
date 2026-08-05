<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Rating extends Model
{
    protected $table = 'ratings';

    public $incrementing = false;

    protected $fillable = [
        'id',
        'user_id',
        'rating',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
