<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotificationController extends Controller
{
    /** GET /api/notifications */
    public function index(Request $request)
    {
        $userId = $request->user()->id;

        // Ambil notifikasi personal user atau notifikasi publik/admin (user_id = 0)
        $notifications = DB::table('notification')
            ->where(function ($q) use ($userId) {
                $q->where('user_id', $userId)
                  ->orWhere('user_id', 0);
            })
            ->orderBy('id', 'desc')
            ->paginate(15);

        return response()->json(['success' => true, 'data' => $notifications]);
    }

    /** POST /api/notifications/{id}/read */
    public function markAsRead(Request $request, $id)
    {
        DB::table('notification')
            ->where('id', $id)
            ->update(['read' => 1, 'updated_at' => now()]);

        return response()->json(['success' => true, 'message' => 'Notifikasi berhasil ditandai telah dibaca.']);
    }
}
