<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\AjukanPinjamRequest;
use App\Http\Requests\UbahStatusPinjamRequest;
use App\Http\Requests\UpdatePinjamRequest;
use App\Models\Pinjam;
use App\Services\PinjamService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class PinjamController extends Controller
{
    protected PinjamService $pinjamService;

    public function __construct(PinjamService $pinjamService)
    {
        $this->pinjamService = $pinjamService;
    }

    /** GET /api/pinjam */
    public function index(Request $request)
    {
        Gate::authorize('viewAny', Pinjam::class);

        $query = Pinjam::with(['pinjamItems.masterItem', 'user']);
        if (! $request->user()->hasAnyRole(['admin', 'superadmin'])) {
            $query->where('user_id', $request->user()->id);
        }

        $pinjams = $query->latest()->paginate(10);

        return response()->json(['success' => true, 'data' => $pinjams]);
    }

    /** POST /api/pinjam */
    public function store(AjukanPinjamRequest $request)
    {
        $data = $request->validated();
        $user = $request->user();

        // Profile-owned identity fields are authoritative. Read-only fields in
        // the mobile form must not be forgeable through a crafted request.
        $data['nama_pic'] = $user->name ?: $data['nama_pic'];
        $data['kontak_pic'] = $user->no_hp ?: $data['kontak_pic'];
        $data['instansi_pic'] = $user->nama_opd ?: $data['instansi_pic'];
        if (($data['jenis_identitas'] ?? null) === 'NIP' && filled($user->nip)) {
            $data['nomor_identitas'] = $user->nip;
        }

        $pinjam = $this->pinjamService->ajukanPeminjaman(
            $user,
            $data
        );

        return response()->json([
            'success' => true,
            'message' => 'Permintaan peminjaman berhasil dibuat.',
            'data' => $pinjam,
        ], 201);
    }

    /** GET /api/pinjam/{id} */
    public function show(Request $request, $id)
    {
        $pinjam = Pinjam::with(['pinjamItems.masterItem', 'user'])->findOrFail($id);
        Gate::authorize('view', $pinjam);

        return response()->json(['success' => true, 'data' => $pinjam]);
    }

    /** PUT /api/pinjam/{id} */
    public function update(UpdatePinjamRequest $request, $id)
    {
        $pinjam = Pinjam::findOrFail($id);
        Gate::authorize('update', $pinjam);

        try {
            $updatedPinjam = $this->pinjamService->updatePengajuan($pinjam, $request->validated());

            return response()->json([
                'success' => true,
                'message' => 'Pengajuan peminjaman berhasil diperbarui.',
                'data' => $updatedPinjam,
            ]);
        } catch (\InvalidArgumentException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 400);
        }
    }

    /** DELETE /api/pinjam/{id} */
    public function destroy(Request $request, $id)
    {
        $pinjam = Pinjam::findOrFail($id);
        Gate::authorize('delete', $pinjam);

        try {
            $this->pinjamService->hapusPengajuan($pinjam);

            return response()->json([
                'success' => true,
                'message' => 'Pengajuan peminjaman berhasil dihapus.',
            ]);
        } catch (\InvalidArgumentException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 400);
        }
    }

    /** POST /api/pinjam/{id}/status */
    public function updateStatus(UbahStatusPinjamRequest $request, $id)
    {
        $pinjam = Pinjam::findOrFail($id);
        Gate::authorize('updateStatus', $pinjam);

        $updatedPinjam = $this->pinjamService->ubahStatus(
            $pinjam,
            $request->status,
            $request->catatan,
            $request->user(),
            $request->file('bukti_pengembalian')
        );

        return response()->json([
            'success' => true,
            'message' => 'Status peminjaman berhasil diupdate.',
            'data' => $updatedPinjam,
        ]);
    }

    /** POST /api/pinjam/{id} (Tambahkan aset ke pengajuan) */
    public function tambahItem(Request $request, $id)
    {
        $pinjam = Pinjam::findOrFail($id);
        Gate::authorize('modifyItems', $pinjam);

        $request->validate([
            'items' => 'required|array|min:1',
            'items.*.item_id' => 'required|exists:master_item,id',
            'items.*.quantity' => 'required_without:items.*.jumlah|integer|min:1',
        ]);

        $updatedPinjam = $this->pinjamService->tambahAsetKePengajuan($pinjam, $request->items);

        return response()->json([
            'success' => true,
            'message' => 'Aset berhasil ditambahkan ke pengajuan.',
            'data' => $updatedPinjam,
        ]);
    }

    /** DELETE /api/pinjam/{p}/item/{id} (Hapus aset dari pengajuan) */
    public function hapusItem(Request $request, $p, $id)
    {
        $pinjam = Pinjam::findOrFail($p);
        Gate::authorize('modifyItems', $pinjam);
        $updatedPinjam = $this->pinjamService->hapusAsetDariPengajuan($pinjam, (int) $id);

        return response()->json([
            'success' => true,
            'message' => 'Aset berhasil dihapus dari pengajuan.',
            'data' => $updatedPinjam,
        ]);
    }
}
