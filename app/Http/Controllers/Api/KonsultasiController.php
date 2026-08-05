<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\BuatKonsultasiRequest;
use App\Http\Requests\TambahResponKonsultasiRequest;
use App\Models\Konsultasi;
use App\Services\KonsultasiService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class KonsultasiController extends Controller
{
    protected KonsultasiService $konsultasiService;

    public function __construct(KonsultasiService $konsultasiService)
    {
        $this->konsultasiService = $konsultasiService;
    }

    /** GET /api/konsul */
    public function index(Request $request)
    {
        Gate::authorize('viewAny', Konsultasi::class);

        $query = Konsultasi::with(['user', 'topik', 'responses.user']);
        if (! $request->user()->hasAnyRole(['admin', 'superadmin'])) {
            $query->where('user_id', $request->user()->id);
        }

        $konsultasis = $query->latest()->paginate(10);

        return response()->json(['success' => true, 'data' => $konsultasis]);
    }

    /** POST /api/konsul */
    public function store(BuatKonsultasiRequest $request)
    {
        $konsultasi = $this->konsultasiService->buatKonsultasi(
            $request->user(),
            $request->validated(),
            $request->file('file')
        );

        return response()->json([
            'success' => true,
            'message' => 'Konsultasi berhasil diajukan.',
            'data' => $konsultasi,
        ], 201);
    }

    /** GET /api/konsul/{id} */
    public function show(Request $request, $id)
    {
        $konsultasi = Konsultasi::with(['user', 'topik', 'responses.user'])->findOrFail($id);
        Gate::authorize('view', $konsultasi);

        return response()->json(['success' => true, 'data' => $konsultasi]);
    }

    /** POST /api/konsul/{id}/response */
    public function respond(TambahResponKonsultasiRequest $request, $id)
    {
        $konsultasi = Konsultasi::findOrFail($id);
        Gate::authorize('respond', $konsultasi);

        $isiRespon = $request->isi_respon ?? $request->jawaban;

        $response = $this->konsultasiService->tambahRespon(
            $konsultasi,
            $request->user(),
            $isiRespon,
            $request->file('file')
        );

        return response()->json([
            'success' => true,
            'message' => 'Respon berhasil dikirim.',
            'data' => $response,
        ], 201);
    }

    /** POST /api/konsul/{id}/status */
    public function updateStatus(Request $request, $id)
    {
        $konsultasi = Konsultasi::findOrFail($id);
        Gate::authorize('updateStatus', $konsultasi);

        $request->validate(['status' => 'required|in:Diproses,Ditolak,Selesai']);
        $updatedKonsultasi = $this->konsultasiService->ubahStatus($konsultasi, $request->status, $request->user());

        return response()->json([
            'success' => true,
            'message' => 'Status konsultasi berhasil diupdate.',
            'data' => $updatedKonsultasi,
        ]);
    }

    /** DELETE /api/konsul/{id} */
    public function destroy(Request $request, $id)
    {
        $konsultasi = Konsultasi::findOrFail($id);
        Gate::authorize('delete', $konsultasi);
        $konsultasi->delete();

        return response()->json(['success' => true, 'message' => 'Konsultasi berhasil dihapus.']);
    }
}
