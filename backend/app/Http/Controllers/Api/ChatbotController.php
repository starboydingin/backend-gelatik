<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ChatbotService;
use Illuminate\Http\Request;

class ChatbotController extends Controller
{
    protected $chatbotService;

    public function __construct(ChatbotService $chatbotService)
    {
        $this->chatbotService = $chatbotService;
    }

    /**
     * POST /api/chatbot/message
     * Kirim pesan ke Chatbot AI Native (F-BOT)
     */
    public function message(Request $request)
    {
        $request->validate([
            'message' => 'required|string|max:1200',
            'session_id' => 'nullable|string',
        ]);

        $response = $this->chatbotService->sendMessage(
            $request->user(),
            $request->message,
            $request->session_id
        );

        if (! $response['success']) {
            $status = ($response['error_code'] ?? null) === 'upstream_timeout'
                ? 504
                : 503;

            return response()->json([
                'success' => false,
                'message' => $response['error'],
            ], $status);
        }

        return response()->json([
            'success' => true,
            'data' => $response,
        ]);
    }

    /**
     * GET /api/chatbot/history
     * Ambil riwayat percakapan chatbot (F-BOT)
     */
    public function history(Request $request)
    {
        $request->validate(['session_id' => 'required|string']);

        $history = $this->chatbotService->getHistory($request->user(), $request->session_id);

        return response()->json([
            'success' => true,
            'data' => $history,
        ]);
    }

    public function latestConversation(Request $request)
    {
        return response()->json([
            'success' => true,
            'data' => $this->chatbotService->latestConversation($request->user()),
        ]);
    }

    /**
     * DELETE /api/chatbot/history
     * Hapus riwayat percakapan chatbot (F-BOT)
     */
    public function deleteHistory(Request $request)
    {
        $request->validate(['session_id' => 'required|string']);

        $this->chatbotService->deleteHistory($request->user(), $request->session_id);

        return response()->json(['success' => true, 'message' => 'Berhasil menghapus riwayat percakapan.']);
    }
}
