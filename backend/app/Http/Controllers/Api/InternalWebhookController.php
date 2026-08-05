<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class InternalWebhookController extends Controller
{
    /**
     * Menerima callback dari Node.js mengenai status pengiriman WhatsApp
     */
    public function waDeliveryStatus(Request $request)
    {
        // Validasi internal API key (harus sama dengan NODE_SERVICE_URL API KEY)
        $authHeader = $request->header('Authorization');
        $expectedKey = 'Bearer ' . env('INTERNAL_SERVICE_API_KEY');

        if (!$authHeader || $authHeader !== $expectedKey) {
            return response()->json(['error' => 'Unauthorized. Invalid API Key.'], 401);
        }

        $status = $request->input('status');
        $error = $request->input('error');
        $reference = $request->input('reference', []);

        if (empty($reference['user_id']) || empty($reference['event_type']) || empty($reference['reference_id'])) {
            return response()->json(['error' => 'Missing reference data'], 400);
        }

        try {
            // Simpan status pengiriman ke database (Tabel whatsapp_delivery_logs)
            DB::table('whatsapp_delivery_logs')->insert([
                'user_id' => $reference['user_id'],
                'event_type' => $reference['event_type'],
                'reference_id' => $reference['reference_id'],
                'status' => $status,
                'sent_at' => $status === 'delivered' ? now() : null,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            return response()->json(['success' => true]);
        } catch (\Exception $e) {
            Log::error('Failed to save WA delivery log: ' . $e->getMessage());
            return response()->json(['error' => 'Internal Server Error'], 500);
        }
    }
}
