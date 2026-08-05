<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class MasterTopik extends Model
{
    use SoftDeletes;

    protected $table = 'master_topik';

    public $incrementing = false;

    protected $fillable = [
        'id',
        'topik',
        'status',
        'created_by',
        'updated_by',
    ];

    public function faqs()
    {
        return $this->hasMany(Faq::class, 'topik_id');
    }

    /**
     * Scope untuk topik aktif (status = '1' string enum)
     */
    public function scopeAktif($query)
    {
        return $query->where('status', '1');
    }
}
