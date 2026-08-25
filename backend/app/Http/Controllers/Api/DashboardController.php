<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\DashboardService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class DashboardController extends Controller
{
    protected DashboardService $dashboardService;

    public function __construct(DashboardService $dashboardService)
    {
        $this->dashboardService = $dashboardService;
    }

    /** GET /api/dashboard */
    public function index(Request $request)
    {
        $user = $request->user();
        $data = Cache::remember(
            "dashboard:user:{$user->id}",
            now()->addSeconds(90),
            fn (): array => $this->dashboardService->getUserDashboard($user),
        );

        return response()->json(['success' => true, 'data' => $data]);
    }
}
