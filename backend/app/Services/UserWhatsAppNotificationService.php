<?php

namespace App\Services;

use App\Models\Konsultasi;
use App\Models\KonsultasiResponse;
use App\Models\KritikSaran;
use App\Models\Pinjam;
use App\Models\User;
use App\Models\UsulanEmail;
use App\Models\WhatsappSubscription;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

use function Illuminate\Support\defer;

/** Delivers every user-facing admin response without requiring a queue worker. */
class UserWhatsAppNotificationService
{
    public function __construct(private NodeServiceClient $nodeService) {}

    public function afterConsultationResponse(Konsultasi $konsultasi, KonsultasiResponse $response): void
    {
        $konsultasi->loadMissing('user');
        $snippet = $this->snippet($response->pesan);
        $message = "Halo {$this->userName($konsultasi->user)}, ada balasan baru untuk konsultasi Anda dengan judul '{$konsultasi->judul}'";
        $message .= $snippet !== '' ? ": \"{$snippet}\"" : '.';

        $this->schedule(
            (int) $konsultasi->user_id,
            'konsultasi.responded',
            (int) $response->id,
            $message,
            ['consultation_id' => (int) $konsultasi->id],
        );
    }

    public function afterLoanStatusChanged(Pinjam $pinjam, string $status): void
    {
        $pinjam->loadMissing('user');
        $message = "Halo {$this->userName($pinjam->user)}, status peminjaman aset Anda (#{$pinjam->id}) telah diubah menjadi {$status}.";
        $note = $this->snippet($pinjam->catatan_petugas);
        if ($note !== '') {
            $message .= " Catatan petugas: {$note}";
        }

        $this->schedule(
            (int) $pinjam->user_id,
            'pinjam.status_changed',
            (int) $pinjam->id,
            $message,
            ['status' => $status],
        );
    }

    public function afterEmailStatusChanged(UsulanEmail $usulan, string $status): void
    {
        $usulan->loadMissing('user');
        $message = "Halo {$this->userName($usulan->user)}, status pengajuan email Anda (#{$usulan->id}) telah diubah menjadi {$status}.";
        if ($status === 'disetujui' && filled($usulan->email_resmi)) {
            $message .= " Email resmi: {$usulan->email_resmi}.";
        }
        $note = $this->snippet($usulan->catatan);
        if ($note !== '') {
            $message .= " Catatan petugas: {$note}";
        }

        $this->schedule(
            (int) $usulan->created_by,
            'usulan_email.status_changed',
            (int) $usulan->id,
            $message,
            ['status' => $status],
        );
    }

    public function afterFeedbackReply(KritikSaran $feedback, User $responder): void
    {
        $feedback->loadMissing('user');
        $reply = $this->snippet($feedback->balasan);
        $message = "Halo {$this->userName($feedback->user)}, {$responder->name} memberikan tanggapan untuk kritik dan saran Anda";
        $message .= $reply !== '' ? ": \"{$reply}\"" : '.';

        $this->schedule(
            (int) $feedback->user_id,
            'kritik_saran.responded',
            (int) $feedback->id,
            $message,
        );
    }

    /** @param array<string, int|string> $context */
    private function schedule(int $userId, string $eventType, int $referenceId, string $message, array $context = []): void
    {
        if ($userId < 1 || $referenceId < 1) {
            return;
        }

        $payload = compact('userId', 'eventType', 'referenceId', 'message', 'context');
        defer(
            fn () => $this->deliver($payload),
            "gelatik-wa-{$eventType}-{$referenceId}",
            always: true,
        );
    }

    /** @param array{userId: int, eventType: string, referenceId: int, message: string, context: array<string, int|string>} $payload */
    private function deliver(array $payload): void
    {
        $subscription = null;
        try {
            $subscription = WhatsappSubscription::query()
                ->where('user_id', $payload['userId'])
                ->where('is_opt_in', true)
                ->first();
            if (! $subscription) {
                return;
            }

            $this->nodeService->sendWhatsApp($subscription->nomor_wa, $payload['message'], [
                'event_type' => $payload['eventType'],
                'reference_id' => $payload['referenceId'],
                'user_id' => $payload['userId'],
            ] + $payload['context']);
            $subscription->update(['last_delivery_status' => 'delivered']);
        } catch (\Throwable $exception) {
            $subscription?->update(['last_delivery_status' => 'failed']);
            Log::error('Notifikasi WhatsApp tanggapan admin gagal.', [
                'event_type' => $payload['eventType'],
                'reference_id' => $payload['referenceId'],
                'user_id' => $payload['userId'],
                'exception' => $exception::class,
            ]);
        }
    }

    private function snippet(mixed $value): string
    {
        return Str::limit(trim(strip_tags((string) $value)), 180);
    }

    private function userName(?User $user): string
    {
        return $user?->name ?: 'Pengguna';
    }
}
