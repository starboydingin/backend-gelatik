<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\BuatKonsultasiRequest;
use App\Http\Requests\TambahResponKonsultasiRequest;
use App\Models\Konsultasi;
use App\Services\KonsultasiService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use InvalidArgumentException;

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
        // Notifications are historical records. A user or administrator must
        // still be able to open the submitted consultation after it has been
        // soft-deleted, but it remains read-only in the client.
        $konsultasi = Konsultasi::withTrashed()
            ->with(['user', 'topik', 'responses.user'])
            ->findOrFail($id);
        Gate::authorize('view', $konsultasi);

        return response()->json(['success' => true, 'data' => $konsultasi]);
    }

    /** PUT /api/konsul/{id} */
    public function update(Request $request, $id)
    {
        $konsultasi = Konsultasi::findOrFail($id);
        Gate::authorize('update', $konsultasi);

        $validated = $request->validate([
            'topik_id' => 'sometimes|required|exists:master_topik,id',
            'judul' => 'sometimes|required|string|max:255',
            'deskripsi' => 'sometimes|required|string',
        ]);

        $update = [];
        if (array_key_exists('topik_id', $validated)) {
            $update['faq_id'] = $validated['topik_id'];
        }
        if (array_key_exists('judul', $validated)) {
            $update['judul'] = $validated['judul'];
        }
        if (array_key_exists('deskripsi', $validated)) {
            $update['pesan'] = $validated['deskripsi'];
        }
        $update['updated_by'] = $request->user()->id;

        $konsultasi->update($update);

        return response()->json([
            'success' => true,
            'message' => 'Konsultasi berhasil diperbarui.',
            'data' => $konsultasi->fresh(['user', 'topik', 'responses.user']),
        ]);
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
        try {
            $updatedKonsultasi = $this->konsultasiService->ubahStatus($konsultasi, $request->status, $request->user());
        } catch (InvalidArgumentException $exception) {
            return response()->json([
                'success' => false,
                'message' => $exception->getMessage(),
            ], 400);
        }

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

        if ($konsultasi->status !== 'Menunggu') {
            return response()->json([
                'success' => false,
                'message' => 'Konsultasi yang sudah diproses tidak dapat dihapus.',
            ], 409);
        }

        $konsultasi->delete();

        return response()->json(['success' => true, 'message' => 'Konsultasi berhasil dihapus.']);
    }
}
