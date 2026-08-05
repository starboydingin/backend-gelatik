<?php

namespace App\Services;

use App\Models\Konsultasi;
use App\Models\Pinjam;
use App\Models\PinjamItem;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class DashboardService
{
    protected RatingService $ratingService;
    protected PengumumanService $pengumumanService;

    public function __construct(RatingService $ratingService, PengumumanService $pengumumanService)
    {
        $this->ratingService = $ratingService;
        $this->pengumumanService = $pengumumanService;
    }

    /**
     * Dapatkan statistik internal aplikasi
     */
    public function getStatistikInternal(): array
    {
        // 1. Total peminjaman per status
        $peminjaman = [
            'total'    => Pinjam::count(),
            'menunggu' => Pinjam::menunggu()->count(),
            'proses'   => Pinjam::proses()->count(),
            'selesai'  => Pinjam::selesai()->count(),
            'ditolak'  => Pinjam::ditolak()->count(),
        ];

        // 2. Grafik konsultasi 7 hari terakhir
        $grafikKonsultasi = [];
        for ($i = 6; $i >= 0; $i--) {
            $date = Carbon::now()->subDays($i)->format('Y-m-d');
            $count = Konsultasi::whereDate('created_at', $date)->count();
            $grafikKonsultasi[] = [
                'tanggal' => $date,
                'total'   => $count,
            ];
        }

        // 3. Top 5 aset paling sering dipinjam
        $top5ItemsRaw = DB::table('pinjam_item')
            ->select('item_id', DB::raw('COUNT(*) as total_peminjaman'))
            ->groupBy('item_id')
            ->orderByDesc('total_peminjaman')
            ->limit(5)
            ->get();

        $top5Aset = [];
        foreach ($top5ItemsRaw as $row) {
            $masterItem = DB::table('master_item')->where('id', $row->item_id)->first();
            if ($masterItem) {
                $top5Aset[] = [
                    'item_id'          => $masterItem->id,
                    'nama_item'        => $masterItem->nama,
                    'total_peminjaman' => $row->total_peminjaman,
                ];
            }
        }

        // 4. Statistik rating
        $ratingStatistik = $this->ratingService->getStatistik();

        // 5. Pengumuman aktif terbaru (limit 3)
        $pengumumanTerbaru = $this->pengumumanService->getActive()->take(3);

        return [
            'peminjaman'          => $peminjaman,
            'grafik_konsultasi'   => $grafikKonsultasi,
            'top_5_aset'          => $top5Aset,
            'rating_statistik'    => $ratingStatistik,
            'pengumuman_terbaru'  => $pengumumanTerbaru,
        ];
    }

    /**
     * Dapatkan data SIMKI API eksternal secara aman (try-catch)
     */
    public function getSimkiData(): ?array
    {
        $baseUrl = env('URL_API_SIMKI') ?: env('SIMKI_API_BASE_URL');
        $apiKey = env('TOKEN_SIMKI') ?: env('SIMKI_API_KEY');

        if (empty($baseUrl) || empty($apiKey)) {
            Log::warning('DashboardService: Kredensial SIMKI API (URL_API_SIMKI / TOKEN_SIMKI) belum diisi.');
            return null;
        }

        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $apiKey,
                'X-API-KEY' => $apiKey,
            ])->timeout(5)->get(rtrim($baseUrl, '/') . '/dashboard-stats');

            if ($response->successful()) {
                return $response->json('data') ?? $response->json();
            }
        } catch (\Throwable $e) {
            Log::error('DashboardService: Gagal memanggil SIMKI API: ' . $e->getMessage());
        }

        return null;
    }
}
