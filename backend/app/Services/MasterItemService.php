<?php

namespace App\Services;

use App\Models\MasterItem;
use Illuminate\Support\Collection;

class MasterItemService
{
    /**
     * Ambil list semua alat TIK (termasuk yang stok 0 dengan flag tersedia = false)
     */
    public function getListAlat(): Collection
    {
        $items = MasterItem::latest()->get();

        return $items->map(function ($item) {
            $item->tersedia = (int) $item->stok > 0;
            return $item;
        });
    }
}
