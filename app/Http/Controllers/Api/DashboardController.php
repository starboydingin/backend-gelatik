<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\DashboardService;
use Illuminate\Http\Request;

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
        $internal = $this->dashboardService->getStatistikInternal();
        $simki = $this->dashboardService->getSimkiData();

        $data = array_merge($internal, [
            'simki' => $simki,
        ]);

        return response()->json(['success' => true, 'data' => $data]);
    }
}
