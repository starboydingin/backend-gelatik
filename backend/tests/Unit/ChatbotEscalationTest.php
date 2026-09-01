<?php

namespace Tests\Unit;

use App\Services\ChatbotService;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;
use ReflectionClass;

class ChatbotEscalationTest extends TestCase
{
    private ChatbotService $service;

    protected function setUp(): void
    {
        $this->service = (new ReflectionClass(ChatbotService::class))->newInstanceWithoutConstructor();
    }

    public static function confirmationAnswers(): array
    {
        return [
            ['iya', true, false],
            ['ya', true, false],
            ['iya boleh', true, false],
            ['tidak', false, true],
            ['gak', false, true],
            ['tolong jelaskan', false, false],
        ];
    }

    #[DataProvider('confirmationAnswers')]
    public function test_it_recognizes_explicit_yes_and_no_answers(
        string $answer,
        bool $affirmative,
        bool $negative,
    ): void {
        $normalized = $this->invoke('normalizeSentence', [$answer]);

        $this->assertSame($affirmative, $this->invoke('isAffirmativeConsultationResponse', [$normalized]));
        $this->assertSame($negative, $this->invoke('isNegativeConsultationResponse', [$normalized]));
    }

    public function test_confirmation_prompt_explains_exactly_how_to_answer(): void
    {
        $prompt = $this->invoke('consultationConfirmationPrompt', ['internet']);

        $this->assertStringContainsString('(iya/tidak)', $prompt);
        $this->assertStringContainsString('Anda hanya perlu menjawab "iya" atau "tidak".', $prompt);
    }

    public function test_it_selects_only_the_latest_actual_complaint(): void
    {
        $complaint = $this->invoke('latestComplaintFromMessages', [[
            'Tolong jelaskan maksudnya',
            'Tetap tidak bisa setelah restart router',
            'Internet kantor tidak bisa digunakan',
        ], 'internet']);

        $this->assertSame(
            'Koneksi internet tetap tidak dapat digunakan setelah router dimulai ulang.',
            $complaint,
        );
    }

    public function test_it_combines_the_current_topic_with_the_latest_short_follow_up(): void
    {
        $complaint = $this->invoke('latestComplaintFromMessages', [[
            'Tetap tidak bisa',
            'Masih tidak bisa',
            'Internet kantor tidak bisa digunakan',
        ], 'internet']);

        $this->assertSame(
            'Internet kantor tidak bisa digunakan. Langkah penanganan yang disarankan telah dicoba, namun kendala masih terjadi.',
            $complaint,
        );
    }

    public function test_it_does_not_mix_an_older_topic_into_the_current_consultation(): void
    {
        $complaint = $this->invoke('latestComplaintFromMessages', [[
            'Masih gagal',
            'Email dinas tidak dapat menerima pesan baru',
            'Internet kantor sering terputus',
        ], 'email']);

        $this->assertSame(
            'Email dinas tidak dapat menerima pesan baru. Langkah penanganan yang disarankan telah dicoba, namun kendala masih terjadi.',
            $complaint,
        );
        $this->assertStringNotContainsString('Internet kantor', $complaint);
    }

    public function test_it_turns_a_quick_faq_question_into_an_incident_statement(): void
    {
        $complaint = $this->invoke('latestComplaintFromMessages', [[
            'Masih tidak bisa',
            'WiFi terhubung tetapi tidak ada internet. Apa yang harus dilakukan?',
        ], 'internet']);

        $this->assertSame(
            'WiFi terhubung, tetapi perangkat tidak dapat mengakses internet. Langkah penanganan yang disarankan telah dicoba, namun kendala masih terjadi.',
            $complaint,
        );
        $this->assertStringNotContainsString('Apa yang harus dilakukan?', $complaint);
    }

    private function invoke(string $method, array $arguments = []): mixed
    {
        return (new ReflectionClass($this->service))->getMethod($method)->invokeArgs(
            $this->service,
            $arguments,
        );
    }
}
