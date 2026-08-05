<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Faq extends Model
{
    use SoftDeletes;

    protected $table = 'faq';

    public $incrementing = false;

    protected $fillable = [
        'id',
        'topik_id',
        'judul',
        'detail',
        'status',
        'created_by',
        'updated_by',
    ];

    public function topik()
    {
        return $this->belongsTo(MasterTopik::class, 'topik_id');
    }

    /**
     * Scope untuk FAQ aktif (status = '1' string enum)
     */
    public function scopeAktif($query)
    {
        return $query->where('status', '1');
    }
}
