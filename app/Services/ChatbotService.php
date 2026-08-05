<?php

namespace App\Services;

use App\Models\ChatbotConversation;
use App\Models\ChatbotMessage;
use App\Models\Pinjam;
use App\Models\Konsultasi;
use App\Models\UsulanEmail;
use App\Models\User;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ChatbotService
{
    protected $systemPrompt = "Anda adalah AI Assistant Layanan TIK. Jawab pertanyaan pengguna dengan ramah, ringkas, dan jelas.";

    public function sendMessage(User $user, string $message, ?string $sessionId)
    {
        if (!$sessionId) {
            $sessionId = Str::uuid()->toString();
            $conversation = ChatbotConversation::create([
                'user_id' => $user->id,
                'session_id' => $sessionId,
            ]);
        } else {
            $conversation = ChatbotConversation::where('user_id', $user->id)
                ->where('session_id', $sessionId)
                ->firstOrFail();
        }

        ChatbotMessage::create([
            'conversation_id' => $conversation->id,
            'role' => 'user',
            'content' => $message,
            'provider_used' => 'gemini',
        ]);

        $context = $this->buildContext($user, $message);
        
        $history = ChatbotMessage::where('conversation_id', $conversation->id)
            ->orderBy('created_at', 'desc')
            ->take(5) // Get last 5 messages for continuity
            ->get()
            ->reverse();

        $prompt = $this->systemPrompt . "\n\n";
        if ($context) {
            $prompt .= "Konteks Data Pengguna saat ini:\n" . $context . "\n\n";
        }
        
        $messages = [
            ['role' => 'system', 'content' => $prompt]
        ];

        foreach ($history as $msg) {
            $messages[] = [
                'role' => $msg->role === 'assistant' ? 'model' : 'user',
                'parts' => [['text' => $msg->content]]
            ];
        }

        $response = $this->callGemini($messages);
        $provider = 'gemini';

        if (!$response['success']) {
            Log::warning('Gemini API failed, falling back to Groq...');
            
            // Re-map messages for Groq format (role: system, user, assistant; content: string)
            $groqMessages = [
                ['role' => 'system', 'content' => $prompt]
            ];
            foreach ($history as $msg) {
                $groqMessages[] = [
                    'role' => $msg->role,
                    'content' => $msg->content
                ];
            }
            
            $response = $this->callGroq($groqMessages);
            $provider = 'groq';
        }

        if (!$response['success']) {
            return [
                'success' => false,
                'error' => 'Maaf, layanan chatbot sedang tidak tersedia saat ini.'
            ];
        }

        ChatbotMessage::create([
            'conversation_id' => $conversation->id,
            'role' => 'assistant',
            'content' => $response['text'],
            'provider_used' => $provider,
        ]);

        return [
            'success' => true,
            'session_id' => $sessionId,
            'reply' => $response['text'],
            'provider' => $provider
        ];
    }

    public function getHistory(User $user, string $sessionId)
    {
        $conversation = ChatbotConversation::where('user_id', $user->id)
            ->where('session_id', $sessionId)
            ->first();

        if (!$conversation) {
            return [];
        }

        return ChatbotMessage::where('conversation_id', $conversation->id)
            ->orderBy('created_at', 'asc')
            ->get();
    }

    public function deleteHistory(User $user, string $sessionId)
    {
        $conversation = ChatbotConversation::where('user_id', $user->id)
            ->where('session_id', $sessionId)
            ->first();

        if ($conversation) {
            ChatbotMessage::where('conversation_id', $conversation->id)->delete();
            $conversation->delete();
            return true;
        }

        return false;
    }

    private function buildContext(User $user, string $message): string
    {
        $messageLower = strtolower($message);
        $context = [];

        if (Str::contains($messageLower, ['status', 'pinjaman saya', 'pinjam'])) {
            $pinjams = Pinjam::where('user_id', $user->id)->latest()->take(3)->get();
            if ($pinjams->isNotEmpty()) {
                $context[] = "Riwayat Peminjaman Terakhir:\n" . $pinjams->map(function ($p) {
                    return "- ID: {$p->id}, Status: {$p->status}, Keperluan: {$p->keperluan}";
                })->implode("\n");
            }
        }

        if (Str::contains($messageLower, ['konsultasi saya', 'konsul'])) {
            $konsuls = Konsultasi::where('user_id', $user->id)->latest()->take(3)->get();
            if ($konsuls->isNotEmpty()) {
                $context[] = "Riwayat Konsultasi Terakhir:\n" . $konsuls->map(function ($k) {
                    return "- ID: {$k->id}, Judul: {$k->judul}, Status: {$k->status}";
                })->implode("\n");
            }
        }

        if (Str::contains($messageLower, ['email saya', 'usulan email'])) {
            $emails = UsulanEmail::where('user_id', $user->id)->latest()->take(3)->get();
            if ($emails->isNotEmpty()) {
                $context[] = "Riwayat Usulan Email Terakhir:\n" . $emails->map(function ($e) {
                    return "- ID: {$e->id}, Email Usulan: {$e->email_usulan}, Status: {$e->status}";
                })->implode("\n");
            }
        }

        return implode("\n\n", $context);
    }

    private function callGemini(array $messages)
    {
        $apiKey = env('GEMINI_API_KEY');
        $model = env('GEMINI_MODEL', 'gemini-1.5-flash');
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$apiKey}";

        // System prompt must be passed via system_instruction in Gemini 1.5
        $systemInstruction = null;
        $contents = [];
        
        foreach ($messages as $msg) {
            if ($msg['role'] === 'system') {
                $systemInstruction = [
                    'parts' => [['text' => $msg['content']]]
                ];
            } else {
                $contents[] = [
                    'role' => $msg['role'], // 'user' or 'model'
                    'parts' => $msg['parts']
                ];
            }
        }

        $payload = [
            'contents' => $contents,
        ];
        
        if ($systemInstruction) {
            $payload['system_instruction'] = $systemInstruction;
        }

        $retries = 2;
        $delay = 1000; // ms

        for ($i = 0; $i <= $retries; $i++) {
            try {
                $response = Http::withoutVerifying()->post($url, $payload);
            } catch (\Exception $e) {
                Log::error('Gemini Http Exception: ' . $e->getMessage());
                break;
            }

            if ($response->successful()) {
                $data = $response->json();
                if (isset($data['candidates'][0]['content']['parts'][0]['text'])) {
                    return [
                        'success' => true,
                        'text' => $data['candidates'][0]['content']['parts'][0]['text']
                    ];
                }
            }

            if ($response->status() === 429 && $i < $retries) {
                usleep($delay * 1000);
                $delay *= 2; // exponential backoff
                continue;
            }

            break; // Break if not 429 or max retries reached
        }

        return ['success' => false];
    }

    private function callGroq(array $messages)
    {
        $apiKey = env('GROQ_API_KEY');
        $model = env('GROQ_MODEL', 'llama3-8b-8192');
        $url = "https://api.groq.com/openai/v1/chat/completions";

        $response = Http::withHeaders([
            'Authorization' => "Bearer {$apiKey}"
        ])->post($url, [
            'model' => $model,
            'messages' => $messages,
        ]);

        if ($response->successful()) {
            $data = $response->json();
            if (isset($data['choices'][0]['message']['content'])) {
                return [
                    'success' => true,
                    'text' => $data['choices'][0]['message']['content']
                ];
            }
        }

        return ['success' => false];
    }
}
