<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\AjukanUsulanEmailRequest;
use App\Http\Requests\UpdateUsulanEmailRequest;
use App\Models\UsulanEmail;
use App\Services\UsulanEmailService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class UsulanEmailController extends Controller
{
    protected UsulanEmailService $usulanEmailService;

    public function __construct(UsulanEmailService $usulanEmailService)
    {
        $this->usulanEmailService = $usulanEmailService;
    }

    /** POST /api/pengajuan-email */
    public function store(AjukanUsulanEmailRequest $request)
    {
        $idPeg = $request->id_peg ?? $request->id_peg_bkd;

        $usulan = $this->usulanEmailService->ajukanUsulan(
            $request->user(),
            $idPeg === null ? null : (string) $idPeg,
            $request->email_pribadi,
            $request->nip
        );

        return response()->json([
            'success' => true,
            'message' => 'Usulan email resmi berhasil diajukan.',
            'data' => $usulan,
        ], 201);
    }

    /** GET /api/pengajuan-email */
    public function index(Request $request)
    {
        Gate::authorize('viewAny', UsulanEmail::class);

        $query = UsulanEmail::query();

        // Admin/superadmin/BKD bisa melihat semua, user biasa hanya melihat ciptaannya sendiri.
        if (! $request->user()->hasAnyRole(['admin', 'superadmin', 'bkd'])) {
            $query->where('created_by', $request->user()->id);
        }

        $usulan = $query->latest()->paginate(10);

        return response()->json(['success' => true, 'data' => $usulan]);
    }

    /** GET /api/pengajuan-email/{id} */
    public function show(Request $request, $id)
    {
        $usulan = UsulanEmail::findOrFail($id);
        Gate::authorize('view', $usulan);

        return response()->json(['success' => true, 'data' => $usulan]);
    }

    /** PUT /api/pengajuan-email/{id} */
    public function update(UpdateUsulanEmailRequest $request, $id)
    {
        $usulan = UsulanEmail::findOrFail($id);
        Gate::authorize('update', $usulan);

        $updatedUsulan = $this->usulanEmailService->updateUsulan($usulan, $request->validated());

        return response()->json([
            'success' => true,
            'message' => 'Usulan email berhasil diperbarui.',
            'data' => $updatedUsulan,
        ]);
    }

    /** POST /api/pengajuan-email/{id}/verifikasi */
    public function verifikasi(Request $request, $id)
    {
        $usulan = UsulanEmail::findOrFail($id);
        Gate::authorize('verify', $usulan);

        $validated = $request->validate([
            'catatan' => 'nullable|string|max:1000',
        ]);

        try {
            $updatedUsulan = $this->usulanEmailService->verifikasiDokumen(
                $usulan,
                $request->user(),
                $validated['catatan'] ?? null
            );
        } catch (\InvalidArgumentException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Dokumen usulan email berhasil diverifikasi.',
            'data' => $updatedUsulan,
        ]);
    }

    /** POST /api/pengajuan-email/{id}/buat-email-resmi */
    public function buatEmailResmi(Request $request, $id)
    {
        $usulan = UsulanEmail::findOrFail($id);
        Gate::authorize('createOfficialEmail', $usulan);

        $request->validate(['email_resmi' => 'required|email']);

        try {
            $updatedUsulan = $this->usulanEmailService->verifikasiUsulan(
                $usulan,
                $request->user(),
                true,
                $request->catatan ?? $request->keterangan,
                $request->email_resmi
            );
        } catch (\InvalidArgumentException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Email resmi berhasil disetujui & dibuat.',
            'data' => $updatedUsulan,
        ]);
    }

    /** POST /api/pengajuan-email/{id}/tolak-email */
    public function tolakEmail(Request $request, $id)
    {
        $usulan = UsulanEmail::findOrFail($id);
        Gate::authorize('reject', $usulan);

        try {
            $updatedUsulan = $this->usulanEmailService->verifikasiUsulan(
                $usulan,
                $request->user(),
                false,
                $request->catatan ?? $request->keterangan
            );
        } catch (\InvalidArgumentException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Usulan email berhasil ditolak.',
            'data' => $updatedUsulan,
        ]);
    }
}
