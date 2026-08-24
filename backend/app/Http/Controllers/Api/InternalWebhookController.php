<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

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

        // OTP delivery is security telemetry, not a business notification. The
        // legacy table uses an enum for business event types, so keep this
        // callback out of that table and never log the phone number or OTP.
        if ($reference['event_type'] === 'password_reset_otp') {
            Log::info('WhatsApp password reset OTP delivery status received.', [
                'user_id' => $reference['user_id'],
                'challenge_id' => $reference['reference_id'],
                'status' => $status,
            ]);

            return response()->json(['success' => true]);
        }

        try {
            $deliveryKey = (string) ($reference['delivery_key'] ?? hash('sha256', implode('|', [
                $reference['event_type'],
                $reference['reference_id'],
                $reference['user_id'],
            ])));

            $existing = DB::table('whatsapp_delivery_logs')
                ->where('delivery_key', $deliveryKey)
                ->first();

            // updateOrInsert makes repeated callbacks and queue retries idempotent.
            DB::table('whatsapp_delivery_logs')->updateOrInsert(
                ['delivery_key' => $deliveryKey],
                [
                'user_id' => $reference['user_id'],
                'event_type' => Str::limit((string) $reference['event_type'], 100, ''),
                'reference_id' => $reference['reference_id'],
                'status' => $status,
                'attempts' => ((int) ($existing->attempts ?? 0)) + 1,
                'error' => $status === 'failed' ? Str::limit((string) $error, 2000, '') : null,
                'sent_at' => $status === 'delivered' ? now() : null,
                'created_at' => $existing->created_at ?? now(),
                'updated_at' => now(),
                ],
            );

            return response()->json(['success' => true]);
        } catch (\Exception $e) {
            Log::error('Failed to save WA delivery log: ' . $e->getMessage());
            return response()->json(['error' => 'Internal Server Error'], 500);
        }
    }
}
