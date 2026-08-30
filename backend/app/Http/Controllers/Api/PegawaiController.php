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

        // Data pegawai bersifat lintas-OPD bagi petugas operasional. Pengguna
        // biasa hanya boleh memilih pegawai dari OPD akun mereka; pembatasan
        // ini wajib di backend karena filter UI dapat dilewati.
        if (! $request->user()->hasAnyRole(['admin', 'superadmin', 'bkd'])) {
            $opd = trim((string) $request->user()->nama_opd);
            if ($opd === '') {
                $query->whereRaw('1 = 0');
            } else {
                $query->where(function ($scoped) use ($opd): void {
                    $scoped->where('Unit_Kerja', $opd)
                        ->orWhere('NUnKer', $opd);
                });
            }
        }

        // Support pencarian opsional
        if ($request->filled('search')) {
            $search = trim((string) $request->search);
            $query->where(function ($q) use ($search) {
                $q->where('Nama', 'like', "%{$search}%")
                    ->orWhere('NIP_Baru', 'like', "%{$search}%")
                    ->orWhere('Unit_Kerja', 'like', "%{$search}%");
            });
        }

        $perPage = min(max((int) $request->integer('per_page', 20), 5), 50);
        $pegawai = $query->orderBy('Nama')->paginate($perPage);

        return response()->json(['success' => true, 'data' => $pegawai]);
    }
}
