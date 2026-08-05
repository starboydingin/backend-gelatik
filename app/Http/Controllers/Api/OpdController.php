<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RouterList;

class OpdController extends Controller
{
    /** GET /api/opd (publik) */
    public function index()
    {
        $opd = RouterList::where('status', 1)->get();
        return response()->json(['success' => true, 'data' => $opd]);
    }
}
