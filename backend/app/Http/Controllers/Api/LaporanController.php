<?php

namespace App\Http\Controllers\Api;

use App\Exports\ServiceReportExport;
use App\Http\Controllers\Controller;
use App\Services\LaporanPeminjamanService;
use App\Services\ServiceReportQuery;
use Illuminate\Http\Request;
use Maatwebsite\Excel\Excel as ExcelWriter;
use Maatwebsite\Excel\Facades\Excel;

class LaporanController extends Controller
{
    protected $laporanService;

    public function __construct(
        LaporanPeminjamanService $laporanService,
        private ServiceReportQuery $serviceReportQuery,
    )
    {
        $this->laporanService = $laporanService;
    }

    public function index(Request $request, string $type)
    {
        $this->authorizeReport($request);
        $filters = $this->validatedFilters($request, $type);

        return response()->json([
            'success' => true,
            'data' => $this->serviceReportQuery->build($type, $filters)->paginate(20),
        ]);
    }

    public function export(Request $request, string $type)
    {
        $this->authorizeReport($request);
        $filters = $this->validatedFilters($request, $type);
        $format = $request->validate(['format' => 'required|in:csv,xlsx'])['format'];
        $writer = $format === 'csv' ? ExcelWriter::CSV : ExcelWriter::XLSX;

        return Excel::download(
            new ServiceReportExport($type, $filters, $this->serviceReportQuery),
            $type.'-'.now()->format('Ymd-His').'.'.$format,
            $writer,
        );
    }

    private function validatedFilters(Request $request, string $type): array
    {
        if (! in_array($type, ['peminjaman', 'konsultasi', 'usulan-email'], true)) {
            abort(404);
        }

        return $request->validate([
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
            'status' => 'nullable|string|max:50',
            'user_id' => 'nullable|integer|exists:users,id',
            'opd' => 'nullable|string|max:500',
            'topik_id' => 'nullable|integer|exists:master_topik,id',
            'asset_id' => 'nullable|integer|exists:master_item,id',
        ]);
    }

    private function authorizeReport(Request $request): void
    {
        abort_unless($request->user()->hasAnyRole(['admin', 'superadmin']), 403, 'Unauthorized');
    }

    /**
     * GET /api/laporan/peminjaman
     * Ambil data laporan peminjaman (F-LAPORAN)
     */
    public function peminjaman(Request $request)
    {
        $user = $request->user();
        $isAuthorized = false;
        if ($user->hasRole('admin') || $user->hasRole('superadmin')) {
            $isAuthorized = true;
        } else {
            try {
                $isAuthorized = $user->hasPermissionTo('list laporan', 'web');
            } catch (\Exception $e) {
                $isAuthorized = false;
            }
        }

        if (!$isAuthorized) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $filter = $request->filter;
        $tanggal = $request->tanggal;

        if (!$filter && $request->has('bulan') && $request->has('tahun')) {
            $filter = 'bulanan';
            $tanggal = sprintf('%04d-%02d', (int) $request->tahun, (int) $request->bulan);
        }

        if (!$filter || !$tanggal) {
            return response()->json([
                'success' => false,
                'message' => 'Parameter filter (harian, bulanan, tahunan) dan tanggal wajib diisi, atau bulan dan tahun.'
            ], 422);
        }

        try {
            $summary = $this->laporanService->getSummary($filter, $tanggal);
            
            return response()->json([
                'success' => true,
                'data' => $summary
            ]);
        } catch (\InvalidArgumentException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 400);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Internal Server Error'], 500);
        }
    }
}
