<?php

namespace App\Services;

use App\Models\Pinjam;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Carbon\Carbon;

class LaporanPeminjamanService
{
    public function getSummary(string $filter, string $tanggal)
    {
        $query = Pinjam::query();

        // 1. Filter by period
        if ($filter === 'harian') {
            // tanggal = YYYY-MM-DD
            $parsedDate = Carbon::parse($tanggal);
            $query->whereDate('tanggal_mulai', $parsedDate->toDateString());
            $periodeLabel = "Harian: " . $parsedDate->translatedFormat('d F Y');
            $groupByFormat = '%H:00'; // Breakdown by hour
            $groupByColumn = DB::raw("DATE_FORMAT(tanggal_mulai, '%Y-%m-%d %H:00:00')");
        } elseif ($filter === 'bulanan') {
            // tanggal = YYYY-MM
            $parsedDate = Carbon::parse($tanggal . '-01');
            $query->whereYear('tanggal_mulai', $parsedDate->year)
                  ->whereMonth('tanggal_mulai', $parsedDate->month);
            $periodeLabel = "Bulanan: " . $parsedDate->translatedFormat('F Y');
            $groupByFormat = '%Y-%m-%d'; // Breakdown by day
            $groupByColumn = DB::raw("DATE(tanggal_mulai)");
        } elseif ($filter === 'tahunan') {
            // tanggal = YYYY
            $query->whereYear('tanggal_mulai', $tanggal);
            $periodeLabel = "Tahunan: " . $tanggal;
            $groupByFormat = '%Y-%m'; // Breakdown by month
            $groupByColumn = DB::raw("DATE_FORMAT(tanggal_mulai, '%Y-%m-01')");
        } else {
            throw new \InvalidArgumentException('Filter tidak valid');
        }

        // 2. Aggregate status
        $statusCounts = (clone $query)->select('status', DB::raw('count(*) as total'))
            ->groupBy('status')
            ->get()
            ->mapWithKeys(fn ($row) => [Str::lower($row->status) => (int) $row->total]);

        $totalPerStatus = [
            'menunggu' => $statusCounts->get('menunggu', 0),
            'proses' => $statusCounts->get('proses', 0),
            'selesai' => $statusCounts->get('selesai', 0),
            'ditolak' => $statusCounts->get('ditolak', 0),
        ];

        // 3. Breakdown
        $breakdownData = (clone $query)
            ->select($groupByColumn, 'status', DB::raw('count(*) as total'))
            ->groupBy($groupByColumn, 'status')
            ->orderBy($groupByColumn, 'asc')
            ->get();

        // Extract the alias string from groupByColumn (since we know it's a raw expression)
        // Alternatively, since we didn't alias it, the property name might be the exact raw expression string, which is messy.
        // It's better to alias it in the select query. Let's modify the select.
        $breakdownData = (clone $query)
            ->select(DB::raw("{$groupByColumn->getValue(DB::connection()->getQueryGrammar())} as group_date"), 'status', DB::raw('count(*) as total'))
            ->groupBy(DB::raw("group_date"), 'status')
            ->orderBy(DB::raw("group_date"), 'asc')
            ->get();

        $breakdown = [];
        foreach ($breakdownData as $data) {
            $dateKey = $data->group_date;
            if (!isset($breakdown[$dateKey])) {
                $breakdown[$dateKey] = [
                    'waktu' => $dateKey,
                    'menunggu' => 0,
                    'proses' => 0,
                    'selesai' => 0,
                    'ditolak' => 0,
                ];
            }
            $status = Str::lower($data->status);
            if (array_key_exists($status, $breakdown[$dateKey])) {
                $breakdown[$dateKey][$status] = (int) $data->total;
            }
        }

        // 4. Most Popular Items
        $popularItems = DB::table('pinjam_item')
            ->join('tr_permintaan_pinjam', 'pinjam_item.pinjam_id', '=', 'tr_permintaan_pinjam.id')
            ->join('master_item', 'pinjam_item.item_id', '=', 'master_item.id')
            ->select('master_item.nama', DB::raw('SUM(pinjam_item.quantity) as total_dipinjam'));
            
        if ($filter === 'harian') {
            $popularItems->whereDate('tr_permintaan_pinjam.tanggal_mulai', $parsedDate->toDateString());
        } elseif ($filter === 'bulanan') {
            $popularItems->whereYear('tr_permintaan_pinjam.tanggal_mulai', $parsedDate->year)
                         ->whereMonth('tr_permintaan_pinjam.tanggal_mulai', $parsedDate->month);
        } else {
            $popularItems->whereYear('tr_permintaan_pinjam.tanggal_mulai', $tanggal);
        }

        $popularItems = $popularItems->groupBy('master_item.nama')
            ->orderBy('total_dipinjam', 'desc')
            ->take(5)
            ->get();

        // 5. Average Duration
        // Menghitung rata-rata (tanggal_selesai - tanggal_mulai) dalam hari
        $avgDuration = (clone $query)
            ->whereNotNull('tanggal_selesai')
            ->whereNotNull('tanggal_mulai')
            ->select(DB::raw('AVG(DATEDIFF(tanggal_selesai, tanggal_mulai)) as avg_days'))
            ->first();

        $rataRataDurasi = round((float) $avgDuration->avg_days, 1);

        return [
            'periode' => $periodeLabel,
            'total_per_status' => $totalPerStatus,
            'aset_terpopuler' => $popularItems,
            'rata_rata_durasi_hari' => $rataRataDurasi,
            'breakdown' => array_values($breakdown),
        ];
    }
}
