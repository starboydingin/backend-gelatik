<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class MasterItem extends Model
{
    use SoftDeletes;

    protected $table = 'master_item';

    protected $fillable = [
        'nama',
        'deskripsi',
        'foto',
        'kondisi',
        'stok',
        'created_by',
        'updated_by',
    ];

    public function pinjamItems()
    {
        return $this->hasMany(PinjamItem::class, 'item_id');
    }

    /**
     * Hitung sisa stok aset yang tersedia pada rentang tanggal tertentu.
     * Mengurangkan total stok terhadap jumlah peminjaman (status Menunggu & Proses)
     * yang tanggal peminjamannya bersinggungan (overlap).
     */
    public function cekKetersediaan(string $tanggalMulai, string $tanggalSelesai): int
    {
        $totalStok = (int) $this->stok;

        // Query total quantity item yang sedang dipinjam atau menunggu persetujuan pada rentang tanggal yang overlap
        $dipinjam = PinjamItem::where('item_id', $this->id)
            ->whereHas('pinjam', function ($query) use ($tanggalMulai, $tanggalSelesai) {
                $query->whereIn('status', ['Menunggu', 'Proses'])
                    ->where(function ($q) use ($tanggalMulai, $tanggalSelesai) {
                        $q->where('tanggal_mulai', '<=', $tanggalSelesai)
                          ->where('tanggal_selesai', '>=', $tanggalMulai);
                    });
            })
            ->sum('quantity');

        $sisaStok = $totalStok - (int) $dipinjam;

        return max(0, $sisaStok);
    }

    /**
     * Scope untuk filter item yang stoknya > 0
     */
    public function scopeTersedia($query)
    {
        return $query->where('stok', '>', 0);
    }
}
