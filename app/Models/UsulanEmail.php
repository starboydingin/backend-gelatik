<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class UsulanEmail extends Model
{
    // Tabel: usulan_email (singular, non-konvensi)
    protected $table = 'usulan_email';

    public $incrementing = false;

    protected $fillable = [
        'id',
        'id_peg_bkd',
        'email_pribadi',
        'email_resmi',
        'status',
        'tanggal_verifikasi',
        'diverifikasi_oleh',
        'catatan',
        'created_by',
        'updated_by',
    ];

    protected $casts = [
        'tanggal_verifikasi' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    // Accessor manual ke PegawaiBelumPunyaEmail karena tipe data kolom beda (bigint vs varchar)
    public function getPegawaiAttribute()
    {
        if (empty($this->id_peg_bkd)) {
            return null;
        }

        return PegawaiBelumPunyaEmail::where('ID_Peg', (string) $this->id_peg_bkd)->first();
    }

    // Property tambahan user_id untuk kompatibilitas jika dipanggil listener
    public function getUserIdAttribute()
    {
        return $this->attributes['created_by'] ?? null;
    }

    // Scopes (menggunakan nilai enum huruf kecil asli)
    public function scopeDraft($query)
    {
        return $query->where('status', 'draft');
    }

    public function scopeDiajukan($query)
    {
        return $query->where('status', 'diajukan');
    }

    public function scopeDisetujui($query)
    {
        return $query->where('status', 'disetujui');
    }

    public function scopeDitolak($query)
    {
        return $query->where('status', 'ditolak');
    }
}
