<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChatbotUrl;
use Illuminate\Http\Request;

class ChatbotUrlController extends Controller
{
    /** GET /api/chatbot */
    public function index()
    {
        $config = ChatbotUrl::aktif()->first();

        if (! $config) {
            return response()->json([
                'success' => true,
                'message' => 'Konfigurasi Chatbot belum tersedia.',
                'data'    => null,
            ]);
        }

        return response()->json([
            'success' => true,
            'data'    => $config,
        ]);
    }
}
