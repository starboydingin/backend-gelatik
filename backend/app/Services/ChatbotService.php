<?php

namespace App\Services;

use App\Models\ChatbotConversation;
use App\Models\ChatbotMessage;
use App\Models\Konsultasi;
use App\Models\Pinjam;
use App\Models\User;
use App\Models\UsulanEmail;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class ChatbotService
{
    protected $systemPrompt = 'Anda adalah AI Assistant Layanan TIK. Jawab pertanyaan pengguna dengan ramah, ringkas, dan jelas.';

    public function sendMessage(User $user, string $message, ?string $sessionId)
    {
        if (! $sessionId) {
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

        $prompt = $this->systemPrompt."\n\n";
        if ($context) {
            $prompt .= "Konteks Data Pengguna saat ini:\n".$context."\n\n";
        }

        $messages = [
            ['role' => 'system', 'content' => $prompt],
        ];

        foreach ($history as $msg) {
            $messages[] = [
                'role' => $msg->role === 'assistant' ? 'model' : 'user',
                'parts' => [['text' => $msg->content]],
            ];
        }

        $response = $this->callGemini($messages);
        $provider = 'gemini';
        $geminiFailureReason = $response['reason'] ?? null;

        if (! $response['success']) {
            Log::warning('Gemini API failed, falling back to Groq...');

            // Re-map messages for Groq format (role: system, user, assistant; content: string)
            $groqMessages = [
                ['role' => 'system', 'content' => $prompt],
            ];
            foreach ($history as $msg) {
                $groqMessages[] = [
                    'role' => $msg->role,
                    'content' => $msg->content,
                ];
            }

            $response = $this->callGroq($groqMessages);
            $provider = 'groq';
        }

        if (! $response['success']) {
            $timedOut = $geminiFailureReason === 'timeout'
                || ($response['reason'] ?? null) === 'timeout';

            return [
                'success' => false,
                'error' => 'Maaf, layanan chatbot sedang tidak tersedia saat ini.',
                'error_code' => $timedOut
                    ? 'upstream_timeout'
                    : 'upstream_unavailable',
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
            'provider' => $provider,
        ];
    }

    public function getHistory(User $user, string $sessionId)
    {
        $conversation = ChatbotConversation::where('user_id', $user->id)
            ->where('session_id', $sessionId)
            ->first();

        if (! $conversation) {
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
                $context[] = "Riwayat Peminjaman Terakhir:\n".$pinjams->map(function ($p) {
                    return "- ID: {$p->id}, Status: {$p->status}, Keperluan: {$p->keterangan}";
                })->implode("\n");
            }
        }

        if (Str::contains($messageLower, ['konsultasi saya', 'konsul'])) {
            $konsuls = Konsultasi::where('user_id', $user->id)->latest()->take(3)->get();
            if ($konsuls->isNotEmpty()) {
                $context[] = "Riwayat Konsultasi Terakhir:\n".$konsuls->map(function ($k) {
                    return "- ID: {$k->id}, Judul: {$k->judul}, Status: {$k->status}";
                })->implode("\n");
            }
        }

        if (Str::contains($messageLower, ['email saya', 'usulan email'])) {
            $emails = UsulanEmail::where('created_by', $user->id)->latest()->take(3)->get();
            if ($emails->isNotEmpty()) {
                $context[] = "Riwayat Usulan Email Terakhir:\n".$emails->map(function ($e) {
                    $email = $e->email_resmi ?: $e->email_pribadi;

                    return "- ID: {$e->id}, Email: {$email}, Status: {$e->status}";
                })->implode("\n");
            }
        }

        return implode("\n\n", $context);
    }

    private function callGemini(array $messages)
    {
        $apiKey = config('services.chatbot.gemini.key');
        if (empty($apiKey)) {
            Log::warning('Gemini provider is not configured.');

            return ['success' => false, 'reason' => 'not_configured'];
        }

        $model = config('services.chatbot.gemini.model', 'gemini-flash-latest');
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$apiKey}";

        // System prompt must be passed via system_instruction in Gemini 1.5
        $systemInstruction = null;
        $contents = [];

        foreach ($messages as $msg) {
            if ($msg['role'] === 'system') {
                $systemInstruction = [
                    'parts' => [['text' => $msg['content']]],
                ];
            } else {
                $contents[] = [
                    'role' => $msg['role'], // 'user' or 'model'
                    'parts' => $msg['parts'],
                ];
            }
        }

        $payload = [
            'contents' => $contents,
        ];

        if ($systemInstruction) {
            $payload['system_instruction'] = $systemInstruction;
        }

        $attempts = max(1, min(2, (int) config('services.chatbot.gemini_attempts', 2)));
        $delay = 1000; // ms

        for ($i = 0; $i < $attempts; $i++) {
            try {
                $response = $this->aiHttpClient()->post($url, $payload);
            } catch (ConnectionException) {
                Log::warning('Gemini provider request timed out or could not connect.');

                return ['success' => false, 'reason' => 'timeout'];
            } catch (\Throwable) {
                Log::warning('Gemini provider request failed unexpectedly.');

                return ['success' => false, 'reason' => 'unavailable'];
            }

            if ($response->successful()) {
                $data = $response->json();
                if (isset($data['candidates'][0]['content']['parts'][0]['text'])) {
                    return [
                        'success' => true,
                        'text' => $data['candidates'][0]['content']['parts'][0]['text'],
                    ];
                }
            }

            if ($response->status() === 429 && $i + 1 < $attempts) {
                usleep($delay * 1000);
                $delay *= 2; // exponential backoff

                continue;
            }

            break; // Break if not 429 or max retries reached
        }

        return ['success' => false, 'reason' => 'unavailable'];
    }

    private function callGroq(array $messages)
    {
        $apiKey = config('services.chatbot.groq.key');
        if (empty($apiKey)) {
            Log::warning('Groq provider is not configured.');

            return ['success' => false, 'reason' => 'not_configured'];
        }

        $model = config('services.chatbot.groq.model', 'llama-3.3-70b-versatile');
        $url = 'https://api.groq.com/openai/v1/chat/completions';

        try {
            $response = $this->aiHttpClient()->withToken($apiKey)->post($url, [
                'model' => $model,
                'messages' => $messages,
            ]);
        } catch (ConnectionException) {
            Log::warning('Groq provider request timed out or could not connect.');

            return ['success' => false, 'reason' => 'timeout'];
        } catch (\Throwable) {
            Log::warning('Groq provider request failed unexpectedly.');

            return ['success' => false, 'reason' => 'unavailable'];
        }

        if ($response->successful()) {
            $data = $response->json();
            if (isset($data['choices'][0]['message']['content'])) {
                return [
                    'success' => true,
                    'text' => $data['choices'][0]['message']['content'],
                ];
            }
        }

        return ['success' => false, 'reason' => 'unavailable'];
    }

    private function aiHttpClient()
    {
        $connectTimeout = max(1, min(10, (int) config('services.chatbot.connect_timeout', 3)));
        $requestTimeout = max($connectTimeout, min(15, (int) config('services.chatbot.request_timeout', 8)));

        $client = Http::acceptJson()
            ->connectTimeout($connectTimeout)
            ->timeout($requestTimeout);

        $caBundle = config('services.chatbot.ca_bundle');
        if (is_string($caBundle) && is_file($caBundle)) {
            $client = $client->withOptions(['verify' => $caBundle]);
        }

        return $client;
    }
}
