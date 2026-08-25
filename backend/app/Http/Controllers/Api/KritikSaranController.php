<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\KritikSaran;
use App\Services\KritikSaranService;
use Illuminate\Http\Request;

class KritikSaranController extends Controller
{
    protected KritikSaranService $kritikSaranService;

    public function __construct(KritikSaranService $kritikSaranService)
    {
        $this->kritikSaranService = $kritikSaranService;
    }

    /** POST /api/kritik-saran (publik / optional auth) */
    public function store(Request $request)
    {
        $request->validate([
            'kritik' => 'required|string',
            'saran' => 'required|string',
        ]);

        $user = auth('api')->user();

        $kritikSaran = $this->kritikSaranService->kirimKritikSaran(
            $user,
            $request->kritik,
            $request->saran
        );

        return response()->json([
            'success' => true,
            'message' => 'Kritik & saran berhasil dikirim.',
            'data' => $kritikSaran,
        ], 201);
    }

    /** GET /api/kritik-saran/search (publik) */
    public function search(Request $request)
    {
        $keyword = $request->q ?? $request->keyword ?? '';
        $kritiks = KritikSaran::query()
            ->select(['id', 'kritik', 'saran', 'created_at'])
            ->where('kritik', 'like', "%{$keyword}%")
            ->orWhere('saran', 'like', "%{$keyword}%")
            ->latest()
            ->paginate(10);

        return response()->json(['success' => true, 'data' => $kritiks]);
    }

    /** GET /api/admin/kritik-saran (role-gated: superadmin, admin, operator) */
    public function index(Request $request)
    {
        $data = $this->kritikSaranService->getAllForAdmin(
            $request->string('q')->trim()->value() ?: null,
            $request->string('status')->trim()->lower()->value() ?: null,
            $request->integer('per_page', 15),
        );

        return response()->json(['success' => true, 'data' => $data]);
    }

    /** GET /api/kritik-saran/mine */
    public function mine(Request $request)
    {
        return response()->json([
            'success' => true,
            'data' => $this->kritikSaranService->getForUser(
                $request->user(),
                $request->string('q')->trim()->value() ?: null,
                $request->string('status')->trim()->lower()->value() ?: null,
            ),
        ]);
    }

    /** GET /api/kritik-saran/mine/{id} */
    public function showMine(Request $request, int $id)
    {
        return response()->json([
            'success' => true,
            'data' => $this->kritikSaranService->findForUser($request->user(), $id),
        ]);
    }

    /** POST /api/admin/kritik-saran/{kritikSaran}/reply */
    public function reply(Request $request, KritikSaran $kritikSaran)
    {
        $validated = $request->validate([
            'balasan' => 'required|string|max:5000',
        ]);

        $result = $this->kritikSaranService->balas(
            $kritikSaran,
            $request->user(),
            $validated['balasan'],
        );

        return response()->json([
            'success' => true,
            'message' => 'Balasan kritik dan saran berhasil dikirim.',
            'data' => $result,
        ]);
    }

    /** POST /api/admin/kritik-saran/bulk-delete */
    public function bulkDelete(Request $request)
    {
        $request->validate([
            'ids' => 'required|array|min:1',
            'ids.*' => 'required|integer',
        ]);

        $deletedCount = $this->kritikSaranService->bulkDelete($request->ids);

        return response()->json([
            'success' => true,
            'message' => "Berhasil menghapus {$deletedCount} data kritik & saran.",
        ]);
    }
}
