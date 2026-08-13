<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Konsultasi;
use App\Models\Pinjam;
use Carbon\Carbon;
use Illuminate\Http\Request;

class CalendarController extends Controller
{
    /** GET /api/dashboard/calendar?start=YYYY-MM-DD&end=YYYY-MM-DD */
    public function index(Request $request)
    {
        $validated = $request->validate([
            'start' => 'nullable|date',
            'end' => 'nullable|date|after_or_equal:start',
        ]);

        $start = isset($validated['start'])
            ? Carbon::parse($validated['start'])->startOfDay()
            : now()->startOfMonth();
        $end = isset($validated['end'])
            ? Carbon::parse($validated['end'])->endOfDay()
            : now()->endOfMonth();

        if ($start->diffInDays($end) > 93) {
            return response()->json([
                'success' => false,
                'message' => 'Rentang kalender maksimal 93 hari.',
            ], 422);
        }

        $user = $request->user();
        $allRecords = $user->hasAnyRole(['admin', 'superadmin']);
        $pinjam = Pinjam::query()
            ->when(! $allRecords, fn ($query) => $query->where('user_id', $user->id))
            ->whereBetween('tanggal_mulai', [$start->toDateString(), $end->toDateString()])
            ->get(['id', 'tanggal_mulai', 'tanggal_selesai', 'status', 'keterangan']);
        $konsultasi = Konsultasi::query()
            ->when(! $allRecords, fn ($query) => $query->where('user_id', $user->id))
            ->whereBetween('created_at', [$start, $end])
            ->get(['id', 'judul', 'status', 'created_at']);

        $events = $pinjam->map(fn (Pinjam $item) => [
            'id' => 'pinjam-'.$item->id,
            'type' => 'peminjaman',
            'title' => 'Peminjaman: '.($item->keterangan ?: 'Tanpa keterangan'),
            'start' => optional($item->tanggal_mulai)->toDateString(),
            'end' => optional($item->tanggal_selesai)->toDateString(),
            'status' => $item->status,
            'reference_id' => $item->id,
        ])->concat($konsultasi->map(fn (Konsultasi $item) => [
            'id' => 'konsultasi-'.$item->id,
            'type' => 'konsultasi',
            'title' => 'Konsultasi: '.$item->judul,
            'start' => optional($item->created_at)->toDateString(),
            'end' => null,
            'status' => $item->status,
            'reference_id' => $item->id,
        ]))->values();

        return response()->json(['success' => true, 'data' => $events]);
    }
}
