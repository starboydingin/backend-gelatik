<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pengumuman;
use App\Services\PengumumanService;
use Illuminate\Http\Request;

class PengumumanController extends Controller
{
    protected PengumumanService $pengumumanService;

    public function __construct(PengumumanService $pengumumanService)
    {
        $this->pengumumanService = $pengumumanService;
    }

    /** GET /api/pengumuman (publik/terautentikasi) */
    public function index()
    {
        $pengumumans = $this->pengumumanService->getActive();

        return response()->json(['success' => true, 'data' => $pengumumans]);
    }

    public function adminIndex()
    {
        return response()->json([
            'success' => true,
            'data' => Pengumuman::latest()->get(),
        ]);
    }

    /** POST /api/pengumuman (role-gated: superadmin, admin, operator) */
    public function store(Request $request)
    {
        $request->validate([
            'judul'      => 'required|string|max:255',
            'konten'     => 'required|string',
            'expired_at' => 'nullable|date',
        ]);

        $pengumuman = $this->pengumumanService->buatPengumuman(
            $request->user(),
            $request->judul,
            $request->konten,
            $request->expired_at
        );

        return response()->json([
            'success' => true,
            'message' => 'Pengumuman berhasil dibuat.',
            'data'    => $pengumuman,
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $validated = $request->validate([
            'judul' => 'sometimes|required|string|max:255',
            'konten' => 'sometimes|required|string',
            'expired_at' => 'nullable|date',
        ]);

        $pengumuman = Pengumuman::findOrFail($id);
        $pengumuman->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Pengumuman berhasil diperbarui.',
            'data' => $pengumuman,
        ]);
    }

    public function destroy($id)
    {
        Pengumuman::findOrFail($id)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Pengumuman berhasil dihapus.',
        ]);
    }
}
