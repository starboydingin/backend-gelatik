<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Konsultasi extends Model
{
    use SoftDeletes;

    protected $table = 'tr_konsultasi';

    public $incrementing = true;

    protected $fillable = [
        'id',
        'user_id',
        'faq_id',
        'judul',
        'pesan',
        'file',
        'status',
        'created_by',
        'updated_by',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function updatedBy()
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function topik()
    {
        return $this->belongsTo(MasterTopik::class, 'faq_id');
    }

    public function responses()
    {
        return $this->hasMany(KonsultasiResponse::class, 'konsultasi_id')->orderBy('created_at', 'asc');
    }

    // Accessor & Mutator untuk kemudahan kompatibilitas topik_id & deskripsi
    public function getTopikIdAttribute()
    {
        return $this->attributes['faq_id'] ?? null;
    }

    public function setTopikIdAttribute($value)
    {
        $this->attributes['faq_id'] = $value;
    }

    public function getDeskripsiAttribute()
    {
        return $this->attributes['pesan'] ?? null;
    }

    public function setDeskripsiAttribute($value)
    {
        $this->attributes['pesan'] = $value;
    }

    public function getPertanyaanAttribute()
    {
        return $this->attributes['pesan'] ?? null;
    }

    public function setPertanyaanAttribute($value)
    {
        $this->attributes['pesan'] = $value;
    }
}
