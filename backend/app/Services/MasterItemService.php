<?php

namespace App\Services;

use App\Models\MasterItem;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;

class MasterItemService
{
    /**
     * Ambil list semua alat TIK (termasuk yang stok 0 dengan flag tersedia = false)
     */
    public function getListAlat(?string $search = null): Collection
    {
        $items = MasterItem::query()
            ->when(filled($search), function ($query) use ($search): void {
                $query->where(function ($nested) use ($search): void {
                    $nested->where('nama', 'like', '%'.$search.'%')
                        ->orWhere('deskripsi', 'like', '%'.$search.'%');
                });
            })
            ->orderBy('nama')
            ->orderBy('id')
            ->get()
            ->unique(fn (MasterItem $item): string => Str::lower(trim($item->nama)))
            ->values();

        return $items->map(function ($item) {
            $item->tersedia = (int) $item->stok > 0;
            return $item;
        });
    }
}
