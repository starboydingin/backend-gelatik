<?php

namespace App\Services;

use App\Models\Faq;
use App\Models\MasterTopik;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class FaqService
{
    /**
     * Ambil list FAQ aktif (opsional filter by topik_id)
     */
    public function getFaqByTopik(?int $topikId = null, ?string $search = null): Collection
    {
        if (! filled($search)) {
            return Cache::remember(
                $this->versionedCacheKey('reference:faq:active:'.($topikId ?? 'all')),
                now()->addMinutes(10),
                fn (): Collection => $this->queryFaq($topikId),
            );
        }

        return $this->queryFaq($topikId, $search);
    }

    public function getChatbotKnowledge(): Collection
    {
        return Cache::remember(
            $this->versionedCacheKey('chatbot:faq:active'),
            now()->addMinutes(10),
            fn (): Collection => $this->queryFaq(),
        );
    }

    private function queryFaq(?int $topikId = null, ?string $search = null): Collection
    {
        return Faq::aktif()
            ->with('topik')
            ->when($topikId, fn ($q) => $q->where('topik_id', $topikId))
            ->when(filled($search), fn ($q) => $q->where(function ($nested) use ($search): void {
                $nested->where('judul', 'like', '%'.$search.'%')
                    ->orWhere('detail', 'like', '%'.$search.'%');
            }))
            ->orderBy('judul')
            ->orderBy('id')
            ->get()
            ->unique(fn (Faq $faq): string => Str::lower(trim($faq->judul)))
            ->values();
    }

    /**
     * Ambil semua topik aktif
     */
    public function getAllTopik(?string $search = null): Collection
    {
        if (! filled($search)) {
            return Cache::remember(
                $this->versionedCacheKey('reference:topik:active'),
                now()->addMinutes(10),
                fn (): Collection => $this->queryTopik(),
            );
        }

        return $this->queryTopik($search);
    }

    private function queryTopik(?string $search = null): Collection
    {
        return MasterTopik::aktif()
            ->when(filled($search), fn ($q) => $q->where('topik', 'like', '%'.$search.'%'))
            ->orderBy('topik')
            ->orderBy('id')
            ->get()
            ->unique(fn (MasterTopik $topik): string => Str::lower(trim($topik->topik)))
            ->values();
    }

    public function flushReferenceCache(): void
    {
        Cache::add('reference:knowledge:version', 1);
        Cache::increment('reference:knowledge:version');
    }

    private function versionedCacheKey(string $key): string
    {
        $version = (int) Cache::get('reference:knowledge:version', 1);

        return $key.':v'.$version;
    }
}
