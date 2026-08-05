<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PinjamItem extends Model
{
    protected $table = 'pinjam_item';

    public $incrementing = true;

    protected $fillable = [
        'id',
        'pinjam_id',
        'item_id',
        'quantity',
    ];

    public function pinjam()
    {
        return $this->belongsTo(Pinjam::class, 'pinjam_id');
    }

    public function masterItem()
    {
        return $this->belongsTo(MasterItem::class, 'item_id');
    }
}
