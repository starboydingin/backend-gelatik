<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Faq;
use App\Services\FaqService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FaqController extends Controller
{
    protected FaqService $faqService;

    public function __construct(FaqService $faqService)
    {
        $this->faqService = $faqService;
    }

    /** GET /api/faq (publik/terautentikasi) */
    public function index(Request $request)
    {
        $topikId = $request->topik_id ? (int) $request->topik_id : null;
        $faqs = $this->faqService->getFaqByTopik(
            $topikId,
            $request->string('search')->trim()->value() ?: null,
        );

        return response()->json(['success' => true, 'data' => $faqs]);
    }

    public function adminIndex()
    {
        return response()->json([
            'success' => true,
            'data' => Faq::with('topik')->orderBy('judul')->get(),
        ]);
    }

    /** POST /api/faq */
    public function store(Request $request)
    {
        $request->validate([
            'topik_id' => 'required|exists:master_topik,id',
            'judul'    => 'required|string|max:255',
            'detail'   => 'required|string',
            'status'   => 'nullable|in:1,0',
        ]);

        $faq = Faq::create([
            'topik_id'   => $request->topik_id,
            'judul'      => $request->judul,
            'detail'     => $request->detail,
            'status'     => $request->status ?? '1',
            'created_by' => $request->user()->id ?? null,
        ]);

        return response()->json(['success' => true, 'message' => 'FAQ berhasil ditambahkan.', 'data' => $faq->load('topik')], 201);
    }

    /** GET /api/faq/{id} */
    public function show($id)
    {
        $faq = Faq::with('topik')->findOrFail($id);
        return response()->json(['success' => true, 'data' => $faq]);
    }

    /** PUT /api/faq/{id} */
    public function update(Request $request, $id)
    {
        $faq = Faq::findOrFail($id);

        $validated = $request->validate([
            'topik_id' => 'sometimes|required|exists:master_topik,id',
            'judul' => 'sometimes|required|string|max:255',
            'detail' => 'sometimes|required|string',
            'status' => 'nullable|in:1,0',
        ]);

        $faq->update($validated + [
            'updated_by' => $request->user()->id ?? null,
        ]);

        return response()->json(['success' => true, 'message' => 'FAQ berhasil diupdate.', 'data' => $faq->load('topik')]);
    }

    /** DELETE /api/faq/{id} */
    public function destroy($id)
    {
        $faq = Faq::findOrFail($id);
        $faq->delete();

        return response()->json(['success' => true, 'message' => 'FAQ berhasil dihapus.']);
    }
}
