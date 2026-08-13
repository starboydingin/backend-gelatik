<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Slider extends Model
{
    use SoftDeletes;

    protected $table = 'sliders';

    public $incrementing = true;

    protected $fillable = [
        'id',
        'judul',
        'image',
        'status',
        'created_by',
        'updated_by',
    ];
}
