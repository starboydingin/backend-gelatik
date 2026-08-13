<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Konsultasi;
use App\Models\Notification;
use App\Models\Pinjam;
use App\Models\UsulanEmail;
use App\Models\User;
use App\Services\DashboardService;

class AdminDashboardController extends Controller
{
    public function __construct(private DashboardService $dashboardService)
    {
    }

    /** GET /api/admin/dashboard */
    public function index()
    {
        return response()->json([
            'success' => true,
            'data' => [
                'summary' => [
                    'users_total' => User::count(),
                    'users_active' => User::where('status', '1')->count(),
                    'konsultasi_open' => Konsultasi::whereIn('status', ['Menunggu', 'Diproses'])->count(),
                    'peminjaman_open' => Pinjam::whereIn('status', ['Menunggu', 'Proses'])->count(),
                    'usulan_email_pending' => UsulanEmail::where('status', 'diajukan')->count(),
                    'notifications_unread' => Notification::where('read', false)->count(),
                ],
                'dashboard' => $this->dashboardService->getStatistikInternal(),
                'recent' => [
                    'konsultasi' => Konsultasi::with('user:id,name')->latest()->take(5)->get(),
                    'peminjaman' => Pinjam::with('user:id,name')->latest()->take(5)->get(),
                    'usulan_email' => UsulanEmail::latest()->take(5)->get(),
                ],
            ],
        ]);
    }
}
