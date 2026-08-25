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
        // Serve the previous aggregate briefly while Laravel refreshes it in
        // the background. This keeps dashboard navigation responsive after a
        // short cache expiry without weakening mutation invalidation.
        $data = Cache::flexible(
            "dashboard:user:{$user->id}",
            [30, 120],
            fn (): array => $this->dashboardService->getUserDashboard($user),
        );

        return response()->json(['success' => true, 'data' => $data]);
    }
}
