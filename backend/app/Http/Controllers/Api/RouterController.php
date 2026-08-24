<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RouterList;
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
        $data = $this->layananInternetService->getListRouterOpd(
            $request->user(),
            $request->string('search')->trim()->value() ?: null,
        );

        return response()->json([
            'success' => true,
            'data'    => $data,
        ]);
    }

    public function adminIndex()
    {
        return response()->json([
            'success' => true,
            'data' => RouterList::orderBy('nama_opd')->orderBy('identity_router')->get(),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'nama_opd' => 'required|string|max:500',
            'identity_router' => 'required|string|max:2000',
            'interface' => 'nullable|string|max:255',
            'lokasi' => 'nullable|string|max:1000',
            'bandwidth_download_mbps' => 'nullable|integer|min:0|max:1000000',
            'bandwidth_upload_mbps' => 'nullable|integer|min:0|max:1000000',
            'status' => 'nullable|integer|in:0,1',
        ]);

        $router = RouterList::create($validated + [
            'status' => $validated['status'] ?? 1,
            'created_by' => $request->user()->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Router OPD berhasil ditambahkan.',
            'data' => $router,
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $validated = $request->validate([
            'nama_opd' => 'sometimes|required|string|max:500',
            'identity_router' => 'sometimes|required|string|max:2000',
            'interface' => 'nullable|string|max:255',
            'lokasi' => 'nullable|string|max:1000',
            'bandwidth_download_mbps' => 'nullable|integer|min:0|max:1000000',
            'bandwidth_upload_mbps' => 'nullable|integer|min:0|max:1000000',
            'status' => 'nullable|integer|in:0,1',
        ]);

        $router = RouterList::findOrFail($id);
        $router->update($validated + ['updated_by' => $request->user()->id]);

        return response()->json([
            'success' => true,
            'message' => 'Router OPD berhasil diperbarui.',
            'data' => $router,
        ]);
    }

    public function destroy($id)
    {
        RouterList::findOrFail($id)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Router OPD berhasil dihapus.',
        ]);
    }
}
