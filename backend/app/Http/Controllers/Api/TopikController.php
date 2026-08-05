<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MasterTopik;
use App\Services\FaqService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TopikController extends Controller
{
    protected FaqService $faqService;

    public function __construct(FaqService $faqService)
    {
        $this->faqService = $faqService;
    }

    /** GET /api/topik (publik/terautentikasi) */
    public function index()
    {
        $topiks = $this->faqService->getAllTopik();

        return response()->json(['success' => true, 'data' => $topiks]);
    }

    /** POST /api/topik */
    public function store(Request $request)
    {
        $request->validate([
            'topik'  => 'required|string|max:100',
            'status' => 'nullable|in:1,0',
        ]);

        $topik = MasterTopik::create([
            'topik'      => $request->topik,
            'status'     => $request->status ?? '1',
            'created_by' => $request->user()->id ?? null,
        ]);

        return response()->json(['success' => true, 'message' => 'Topik berhasil dibuat.', 'data' => $topik], 201);
    }

    /** GET /api/topik/{id} */
    public function show($id)
    {
        $topik = MasterTopik::with('faqs')->findOrFail($id);
        return response()->json(['success' => true, 'data' => $topik]);
    }

    /** PUT /api/topik/{id} */
    public function update(Request $request, $id)
    {
        $topik = MasterTopik::findOrFail($id);

        $topik->update($request->only(['topik', 'status']) + [
            'updated_by' => $request->user()->id ?? null,
        ]);

        return response()->json(['success' => true, 'message' => 'Topik berhasil diupdate.', 'data' => $topik]);
    }

    /** DELETE /api/topik/{id} */
    public function destroy($id)
    {
        $topik = MasterTopik::findOrFail($id);
        $topik->delete();

        return response()->json(['success' => true, 'message' => 'Topik berhasil dihapus.']);
    }
}
