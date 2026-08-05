<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\LayananInternetService;
use Illuminate\Http\Request;

class RouterController extends Controller
{
    protected LayananInternetService $layananInternetService;

    public function __construct(LayananInternetService $layananInternetService)
    {
        $this->layananInternetService = $layananInternetService;
    }

    /** GET /api/list-router-opd */
    public function listRouterOpd(Request $request)
    {
        $data = $this->layananInternetService->getListRouterOpd($request->user());

        return response()->json([
            'success' => true,
            'data'    => $data,
        ]);
    }
}
