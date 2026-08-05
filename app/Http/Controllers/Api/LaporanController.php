<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\LaporanPeminjamanService;
use Illuminate\Http\Request;

class LaporanController extends Controller
{
    protected $laporanService;

    public function __construct(LaporanPeminjamanService $laporanService)
    {
        $this->laporanService = $laporanService;
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
