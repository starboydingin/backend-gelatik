<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Pinjam extends Model
{
    use SoftDeletes;

    // Tabel non-konvensi — wajib eksplisit
    protected $table = 'tr_permintaan_pinjam';

    public $incrementing = false;

    protected $fillable = [
        'id',
        'user_id',
        'nama_pic',
        'jabatan_pic',
        'instansi_pic',
        'kontak_pic',
        'jenis_identitas',
        'nomor_identitas',
        'alamat_peminjam',
        'jenis_durasi',
        'tanggal_mulai',
        'jam_mulai',
        'durasi_peminjaman',
        'tanggal_selesai',
        'keterangan',
        'url_dokumen',
        'status',
        'catatan_petugas',
        'waktu_pengembalian',
        'bukti_pengembalian',
        'rating',
        'created_by',
        'updated_by',
    ];

    protected $casts = [
        'tanggal_mulai'      => 'date',
        'tanggal_selesai'    => 'datetime',
        'waktu_pengembalian' => 'datetime',
        'deleted_at'         => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function items()
    {
        return $this->belongsToMany(MasterItem::class, 'pinjam_item', 'pinjam_id', 'item_id')
                    ->withPivot('quantity')
                    ->withTimestamps();
    }

    public function pinjamItems()
    {
        return $this->hasMany(PinjamItem::class, 'pinjam_id');
    }

    // Scopes
    public function scopeMenunggu($query)
    {
        return $query->where('status', 'Menunggu');
    }

    public function scopeProses($query)
    {
        return $query->where('status', 'Proses');
    }

    public function scopeSelesai($query)
    {
        return $query->where('status', 'Selesai');
    }

    public function scopeDitolak($query)
    {
        return $query->where('status', 'Ditolak');
    }
}
