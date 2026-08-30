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

        $query = UsulanEmail::query()->with('pegawaiBkd');

        // Admin/superadmin/BKD bisa melihat semua, user biasa hanya melihat ciptaannya sendiri.
        if (! $request->user()->hasAnyRole(['admin', 'superadmin', 'bkd'])) {
            $query->where('created_by', $request->user()->id);
        }

        $request->validate([
            'search' => 'nullable|string|max:100',
            'status' => 'nullable|in:diajukan,disetujui,ditolak',
            'verification' => 'nullable|in:waiting,verified',
            'per_page' => 'nullable|integer|min:5|max:50',
        ]);

        $query
            ->when($request->filled('status'), fn ($builder) => $builder->where('status', $request->string('status')))
            ->when($request->string('verification')->toString() === 'waiting', fn ($builder) => $builder
                ->where('status', 'diajukan')
                ->whereNull('tanggal_verifikasi'))
            ->when($request->string('verification')->toString() === 'verified', fn ($builder) => $builder
                ->where('status', 'diajukan')
                ->whereNotNull('tanggal_verifikasi'))
            ->when($request->filled('search'), function ($builder) use ($request): void {
                $search = trim($request->string('search')->toString());
                $builder->where(function ($scoped) use ($search): void {
                    $scoped->where('email_pribadi', 'like', "%{$search}%")
                        ->orWhere('email_resmi', 'like', "%{$search}%")
                        ->orWhereHas('pegawaiBkd', function ($pegawai) use ($search): void {
                            $pegawai->where('Nama', 'like', "%{$search}%")
                                ->orWhere('NIP_Baru', 'like', "%{$search}%")
                                ->orWhere('Unit_Kerja', 'like', "%{$search}%");
                        });
                });
            });

        $usulan = $query->latest()->paginate((int) $request->integer('per_page', 10));
        $usulan->getCollection()->transform(fn (UsulanEmail $item) => $this->present($item));

        return response()->json(['success' => true, 'data' => $usulan]);
    }

    /** GET /api/pengajuan-email/{id} */
    public function show(Request $request, $id)
    {
        $usulan = UsulanEmail::with('pegawaiBkd')->findOrFail($id);
        Gate::authorize('view', $usulan);

        return response()->json(['success' => true, 'data' => $this->present($usulan)]);
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

    /** Flatten the BKD employee data needed by the presentation history table. */
    private function present(UsulanEmail $usulan): array
    {
        $pegawai = $usulan->pegawaiBkd;

        return array_merge($usulan->toArray(), [
            'nama' => $pegawai?->Nama,
            'nama_pegawai' => $pegawai?->Nama,
            'nip' => $pegawai?->NIP_Baru,
            'unit_kerja' => $pegawai?->Unit_Kerja,
            'jabatan' => $pegawai?->NJab,
            'verification_state' => $usulan->status !== 'diajukan'
                ? 'completed'
                : ($usulan->tanggal_verifikasi ? 'verified' : 'waiting'),
            'can_be_verified' => $usulan->status === 'diajukan' && $usulan->tanggal_verifikasi === null,
            'can_be_published' => $usulan->status === 'diajukan' && $usulan->tanggal_verifikasi !== null,
        ]);
    }
}
