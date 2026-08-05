<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PegawaiBelumPunyaEmail;
use Illuminate\Http\Request;

class PegawaiController extends Controller
{
    /**
     * GET /api/pegawai
     * Menampilkan list pegawai belum punya email.
     * FR-B07: ID_Peg disembunyikan dari response (sudah di $hidden model).
     */
    public function index(Request $request)
    {
        $query = PegawaiBelumPunyaEmail::query();

        // Support pencarian opsional
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('Nama', 'like', "%{$search}%")
                  ->orWhere('NIP_Baru', 'like', "%{$search}%")
                  ->orWhere('Unit_Kerja', 'like', "%{$search}%");
            });
        }

        $pegawai = $query->paginate(20);

        return response()->json(['success' => true, 'data' => $pegawai]);
    }
}
