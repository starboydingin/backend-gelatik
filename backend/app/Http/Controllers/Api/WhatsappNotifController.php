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
            'nomor_wa' => ['required', 'string', 'regex:/^(?:08[0-9]{8,13}|628[0-9]{7,12})$/'],
            'is_opt_in' => ['sometimes', 'boolean'],
        ]);

        $isOptIn = $request->has('is_opt_in')
            ? $request->boolean('is_opt_in')
            : true;

        $subscription = WhatsappSubscription::updateOrCreate(
            ['user_id' => $request->user()->id],
            [
                'nomor_wa' => $request->nomor_wa,
                'is_opt_in' => $isOptIn,
                'verified_at' => $isOptIn ? now() : null,
            ]
        );

        return response()->json([
            'success' => true, 
            'message' => 'Pengaturan notifikasi WhatsApp berhasil disimpan.',
            'data' => $this->subscriptionData($subscription),
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
                    ...$this->subscriptionData($subscription),
                ]
            ]);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'nomor_wa' => null,
                'is_subscribed' => false,
                'subscribed_at' => null,
            ]
        ]);
    }

    private function subscriptionData(WhatsappSubscription $subscription): array
    {
        return [
            'user_id' => $subscription->user_id,
            'wa_number' => $subscription->nomor_wa,
            'is_subscribed' => (bool) $subscription->is_opt_in,
            'subscribed_at' => $subscription->verified_at?->toISOString(),
        ];
    }
}
