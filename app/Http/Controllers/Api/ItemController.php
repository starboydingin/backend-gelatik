<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MasterItem;
use App\Services\MasterItemService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ItemController extends Controller
{
    protected MasterItemService $itemService;

    public function __construct(MasterItemService $itemService)
    {
        $this->itemService = $itemService;
    }

    /** GET /api/item — semua item TIK */
    public function item()
    {
        $items = $this->itemService->getListAlat();
        return response()->json(['success' => true, 'data' => $items]);
    }

    /** GET /api/items — list item TIK */
    public function index()
    {
        $items = $this->itemService->getListAlat();
        return response()->json(['success' => true, 'data' => $items]);
    }

    /** GET /api/items/{id} */
    public function show($id)
    {
        $item = MasterItem::findOrFail($id);
        $item->tersedia = (int) $item->stok > 0;
        return response()->json(['success' => true, 'data' => $item]);
    }

    /** GET /api/items/search/{keyword} */
    public function search($keyword)
    {
        $items = MasterItem::where('nama', 'like', "%{$keyword}%")
            ->orWhere('deskripsi', 'like', "%{$keyword}%")
            ->get()
            ->map(function ($i) {
                $i->tersedia = (int) $i->stok > 0;
                return $i;
            });

        return response()->json(['success' => true, 'data' => $items]);
    }

    /** POST /api/items */
    public function store(Request $request)
    {
        $request->validate([
            'nama'      => 'required|string|max:255',
            'deskripsi' => 'required|string',
            'foto'      => 'nullable|string',
            'kondisi'   => 'nullable|in:Baik,Rusak Sebagian,Rusak Parah,Tidak Berfungsi',
            'stok'      => 'required|integer|min:0',
        ]);

        $item = MasterItem::create([
            'nama'      => $request->nama,
            'deskripsi' => $request->deskripsi,
            'foto'      => $request->foto,
            'kondisi'   => $request->kondisi ?? 'Baik',
            'stok'      => $request->stok,
            'created_by'=> $request->user()->id ?? null,
        ]);

        return response()->json(['success' => true, 'message' => 'Item berhasil ditambahkan.', 'data' => $item], 201);
    }

    /** PUT /api/items/{id} */
    public function update(Request $request, $id)
    {
        $item = MasterItem::findOrFail($id);

        $item->update($request->only(['nama', 'deskripsi', 'foto', 'kondisi', 'stok']) + [
            'updated_by' => $request->user()->id ?? null,
        ]);

        return response()->json(['success' => true, 'message' => 'Item berhasil diupdate.', 'data' => $item]);
    }

    /** DELETE /api/items/{id} */
    public function destroy($id)
    {
        $item = MasterItem::findOrFail($id);
        $item->delete();

        return response()->json(['success' => true, 'message' => 'Item berhasil dihapus.']);
    }
}
