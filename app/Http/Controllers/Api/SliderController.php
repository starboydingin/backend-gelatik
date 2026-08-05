<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Slider;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SliderController extends Controller
{
    /** GET /api/slider */
    public function index()
    {
        $sliders = Slider::where('status', 1)->latest()->get();
        return response()->json(['success' => true, 'data' => $sliders]);
    }

    /** POST /api/slider */
    public function store(Request $request)
    {
        $request->validate([
            'judul'  => 'required|string|max:255',
            'image'  => 'required|string',
            'status' => 'nullable|integer|in:0,1',
        ]);

        $slider = Slider::create([
            'judul'     => $request->judul,
            'image'     => $request->image,
            'status'    => $request->status ?? 1,
            'created_by'=> $request->user()->id ?? null,
        ]);

        return response()->json(['success' => true, 'message' => 'Slider berhasil ditambahkan.', 'data' => $slider], 201);
    }

    /** GET /api/slider/{id} */
    public function show($id)
    {
        $slider = Slider::findOrFail($id);
        return response()->json(['success' => true, 'data' => $slider]);
    }

    /** PUT /api/slider/{id} */
    public function update(Request $request, $id)
    {
        $slider = Slider::findOrFail($id);

        $slider->update($request->only(['judul', 'image', 'status']) + [
            'updated_by' => $request->user()->id ?? null,
        ]);

        return response()->json(['success' => true, 'message' => 'Slider berhasil diupdate.', 'data' => $slider]);
    }

    /** DELETE /api/slider/{id} */
    public function destroy($id)
    {
        $slider = Slider::findOrFail($id);
        $slider->delete();

        return response()->json(['success' => true, 'message' => 'Slider berhasil dihapus.']);
    }
}
