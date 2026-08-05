<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\WhatsappSubscription;
use Illuminate\Http\Request;

class WhatsappNotifController extends Controller
{
    /**
     * POST /api/notifikasi/wa/subscribe
     * Subscribe user ke notifikasi WhatsApp (F-WA)
     */
    public function subscribe(Request $request)
    {
        $request->validate([
            'nomor_wa' => ['required', 'string', 'regex:/^(08|62)[0-9]{8,13}$/']
        ]);

        $subscription = WhatsappSubscription::updateOrCreate(
            ['user_id' => $request->user()->id],
            [
                'nomor_wa' => $request->nomor_wa,
                'is_opt_in' => true,
                'verified_at' => now(), // Assuming verified upon subscribe for this scope
            ]
        );

        return response()->json([
            'success' => true, 
            'message' => 'Berhasil subscribe notifikasi WhatsApp.',
            'data' => $subscription
        ]);
    }

    /**
     * DELETE /api/notifikasi/wa/subscribe
     * Unsubscribe user dari notifikasi WhatsApp (F-WA)
     */
    public function unsubscribe(Request $request)
    {
        $subscription = WhatsappSubscription::where('user_id', $request->user()->id)->first();
        
        if ($subscription) {
            $subscription->update(['is_opt_in' => false]);
            return response()->json(['success' => true, 'message' => 'Berhasil unsubscribe notifikasi WhatsApp.']);
        }

        return response()->json(['success' => false, 'message' => 'Belum berlangganan WhatsApp.'], 404);
    }

    /**
     * GET /api/notifikasi/wa/status
     * Cek status langganan WA user (F-WA)
     */
    public function status(Request $request)
    {
        $subscription = WhatsappSubscription::where('user_id', $request->user()->id)->first();
        
        if ($subscription) {
            return response()->json([
                'success' => true,
                'data' => [
                    'nomor_wa' => $subscription->nomor_wa,
                    'is_opt_in' => (bool)$subscription->is_opt_in,
                ]
            ]);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'nomor_wa' => null,
                'is_opt_in' => false,
            ]
        ]);
    }
}
