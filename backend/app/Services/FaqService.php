<?php

namespace App\Services;

use App\Models\Faq;
use App\Models\MasterTopik;
use Illuminate\Database\Eloquent\Collection;

class FaqService
{
    /**
     * Ambil list FAQ aktif (opsional filter by topik_id)
     */
    public function getFaqByTopik(?int $topikId = null): Collection
    {
        return Faq::aktif()
            ->with('topik')
            ->when($topikId, fn($q) => $q->where('topik_id', $topikId))
            ->latest()
            ->get();
    }

    /**
     * Ambil semua topik aktif
     */
    public function getAllTopik(): Collection
    {
        return MasterTopik::aktif()->get();
    }
}
