<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class KonsultasiResponse extends Model
{
    use SoftDeletes;

    protected $table = 'tr_konsultasi_response';

    public $incrementing = true;

    protected $fillable = [
        'id',
        'konsultasi_id',
        'user_id',
        'pesan',
        'file',
    ];

    public function konsultasi()
    {
        return $this->belongsTo(Konsultasi::class, 'konsultasi_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    // Accessor untuk jawaban (kompatibilitas pesan)
    public function getJawabanAttribute()
    {
        return $this->attributes['pesan'] ?? null;
    }

    public function setJawabanAttribute($value)
    {
        $this->attributes['pesan'] = $value;
    }

    // Accessor untuk is_admin: balasan bukan berasal dari user pemilik konsultasi asli
    public function getIsAdminAttribute(): bool
    {
        $konsultasi = $this->konsultasi;
        if ($konsultasi) {
            return (int) $this->user_id !== (int) $konsultasi->user_id;
        }

        return false;
    }
}
