<?php

namespace App\Services;

use App\Models\Konsultasi;
use App\Models\Notification;
use App\Models\Pinjam;
use App\Models\PinjamItem;
use App\Models\Rating;
use App\Models\User;
use App\Models\UsulanEmail;
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
        $pinjamCounts = Pinjam::query()
            ->selectRaw("COUNT(*) as total")
            ->selectRaw("SUM(CASE WHEN status = 'Menunggu' THEN 1 ELSE 0 END) as menunggu")
            ->selectRaw("SUM(CASE WHEN status = 'Proses' THEN 1 ELSE 0 END) as proses")
            ->selectRaw("SUM(CASE WHEN status = 'Selesai' THEN 1 ELSE 0 END) as selesai")
            ->selectRaw("SUM(CASE WHEN status = 'Ditolak' THEN 1 ELSE 0 END) as ditolak")
            ->first();
        $peminjaman = collect(['total', 'menunggu', 'proses', 'selesai', 'ditolak'])
            ->mapWithKeys(fn (string $key): array => [$key => (int) ($pinjamCounts->{$key} ?? 0)])
            ->all();

        // 3. Top 5 aset paling sering dipinjam
        $top5ItemsRaw = DB::table('pinjam_item as pi')
            ->join('master_item as mi', 'mi.id', '=', 'pi.item_id')
            ->selectRaw('mi.id as item_id, mi.nama as nama_item, SUM(pi.quantity) as total_peminjaman')
            ->groupBy('mi.id', 'mi.nama')
            ->orderByDesc('total_peminjaman')
            ->limit(5)
            ->get();

        $top5Aset = $top5ItemsRaw->map(fn ($row): array => [
            'item_id' => $row->item_id,
            'nama_item' => $row->nama_item,
            'total_peminjaman' => (int) $row->total_peminjaman,
        ])->all();

        $activity = collect(range(29, 0))->mapWithKeys(
            fn (int $days): array => [now()->subDays($days)->toDateString() => [
                'tanggal' => now()->subDays($days)->toDateString(),
                'peminjaman' => 0,
                'konsultasi' => 0,
                'usulan_email' => 0,
            ]],
        );
        $this->fillActivitySeries($activity, Pinjam::query(), 'peminjaman');
        $this->fillActivitySeries($activity, Konsultasi::query(), 'konsultasi');
        $this->fillActivitySeries($activity, UsulanEmail::query(), 'usulan_email');
        $grafikKonsultasi = $activity->values()->take(-7)->map(fn (array $item): array => [
            'tanggal' => $item['tanggal'],
            'total' => $item['konsultasi'],
        ])->values()->all();

        $topicStats = Konsultasi::query()
            ->leftJoin('master_topik as t', 't.id', '=', 'tr_konsultasi.faq_id')
            ->selectRaw("COALESCE(t.topik, 'Tanpa topik') as label, COUNT(*) as total")
            ->groupBy('t.topik')
            ->orderByDesc('total')
            ->limit(8)
            ->get();

        $emailStats = UsulanEmail::query()
            ->selectRaw('status, COUNT(*) as total')
            ->groupBy('status')
            ->get()
            ->mapWithKeys(fn ($row): array => [$row->status => (int) $row->total]);

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
            'activity_series'     => $activity->values(),
            'consultation_topics' => $topicStats,
            'email_statistics'    => $emailStats,
        ];
    }

    public function getUserDashboard(User $user): array
    {
        $userId = $user->id;
        $activity = collect(range(29, 0))->mapWithKeys(
            fn (int $days): array => [now()->subDays($days)->toDateString() => [
                'tanggal' => now()->subDays($days)->toDateString(),
                'peminjaman' => 0,
                'konsultasi' => 0,
                'usulan_email' => 0,
            ]],
        );

        $this->fillActivitySeries($activity, Pinjam::where('user_id', $userId), 'peminjaman');
        $this->fillActivitySeries($activity, Konsultasi::where('user_id', $userId), 'konsultasi');
        $this->fillActivitySeries($activity, UsulanEmail::where('created_by', $userId), 'usulan_email');

        // Statistik pada dua panel insight bersifat agregat agar pengguna dapat
        // melihat tren layanan, tanpa menerima detail atau identitas pengguna lain.
        $serviceActivity = collect(range(29, 0))->mapWithKeys(
            fn (int $days): array => [now()->subDays($days)->toDateString() => [
                'tanggal' => now()->subDays($days)->toDateString(),
                'peminjaman' => 0,
                'konsultasi' => 0,
                'usulan_email' => 0,
            ]],
        );
        $this->fillActivitySeries($serviceActivity, Pinjam::query(), 'peminjaman');
        $this->fillActivitySeries($serviceActivity, Konsultasi::query(), 'konsultasi');
        $this->fillActivitySeries($serviceActivity, UsulanEmail::query(), 'usulan_email');

        $topicStats = Konsultasi::query()
            ->leftJoin('master_topik as t', 't.id', '=', 'tr_konsultasi.faq_id')
            ->where('tr_konsultasi.user_id', $userId)
            ->selectRaw("COALESCE(t.topik, 'Tanpa topik') as label, COUNT(*) as total")
            ->groupBy('t.topik')
            ->orderByDesc('total')
            ->limit(8)
            ->get();

        $assetStats = PinjamItem::query()
            ->join('tr_permintaan_pinjam as p', 'p.id', '=', 'pinjam_item.pinjam_id')
            ->join('master_item as i', 'i.id', '=', 'pinjam_item.item_id')
            ->where('p.user_id', $userId)
            ->selectRaw('i.nama as label, SUM(pinjam_item.quantity) as total')
            ->groupBy('i.nama')
            ->orderByDesc('total')
            ->limit(8)
            ->get();

        return [
            'summary' => [
                'peminjaman_aktif' => Pinjam::where('user_id', $userId)->whereIn('status', ['Menunggu', 'Proses'])->count(),
                'konsultasi_aktif' => Konsultasi::where('user_id', $userId)->whereIn('status', ['Menunggu', 'Diproses'])->count(),
                'usulan_email' => UsulanEmail::where('created_by', $userId)->count(),
                'notifikasi_belum_dibaca' => Notification::where('user_id', $userId)->where('read', false)->count(),
            ],
            'activity_series' => $activity->values(),
            'service_activity_series' => $serviceActivity->values(),
            'service_rating_statistics' => $this->ratingService->getStatistik(),
            'consultation_topics' => $topicStats,
            'asset_usage' => $assetStats,
            'rating' => Rating::where('user_id', $userId)->latest()->first(),
            'recent' => [
                'peminjaman' => Pinjam::query()
                    ->with(['items:id,nama'])
                    ->where('user_id', $userId)
                    ->latest()
                    ->take(5)
                    ->get(),
                'konsultasi' => Konsultasi::query()
                    ->with('topik:id,topik')
                    ->where('user_id', $userId)
                    ->latest()
                    ->take(5)
                    ->get(),
                'usulan_email' => UsulanEmail::query()
                    ->with('pegawaiBkd')
                    ->where('created_by', $userId)
                    ->latest()
                    ->take(5)
                    ->get(),
            ],
        ];
    }

    private function fillActivitySeries($activity, $query, string $key): void
    {
        $query->where('created_at', '>=', now()->subDays(29)->startOfDay())
            ->selectRaw('DATE(created_at) as activity_date, COUNT(*) as total')
            ->groupByRaw('DATE(created_at)')
            ->get()
            ->each(function ($row) use ($activity, $key): void {
                if ($activity->has($row->activity_date)) {
                    $value = $activity->get($row->activity_date);
                    $value[$key] = (int) $row->total;
                    $activity->put($row->activity_date, $value);
                }
            });
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
