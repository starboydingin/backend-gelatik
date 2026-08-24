<?php

namespace App\Services;

use App\Events\KonsultasiCreated;
use App\Events\KonsultasiResponseCreated;
use App\Events\KonsultasiStatusChanged;
use App\Models\Konsultasi;
use App\Models\KonsultasiResponse;
use App\Models\Notification;
use App\Models\User;
use App\Services\NodeServiceClient;
use App\Services\RealtimeEventPayload;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class KonsultasiService
{
    public function __construct(
        private AdminAuditService $audit,
        private AdminNotificationService $adminNotifications,
    )
    {
    }

    /**
     * Buat pengajuan konsultasi TIK baru.
     */
    public function buatKonsultasi(User $user, array $data, ?UploadedFile $fileAttachment = null): Konsultasi
    {
        $filePath = null;
        if ($fileAttachment) {
            $filePath = $fileAttachment->store('lampiran_konsultasi', 'public');
        }

        $konsultasi = Konsultasi::create([
            'user_id'    => $user->id,
            'faq_id'     => $data['topik_id'] ?? $data['faq_id'],
            'judul'      => $data['judul'],
            'pesan'      => $data['deskripsi'] ?? $data['pertanyaan'] ?? $data['pesan'],
            'file'       => $filePath,
            'status'     => 'Menunggu',
            'created_by' => $user->id,
        ]);

        // The browser inbox and Socket.IO signal are persisted/delivered now;
        // queued listeners remain responsible only for optional push delivery.
        $this->adminNotifications->announce(
            'konsultasi.created',
            (int) $konsultasi->id,
            'Permintaan Konsultasi',
            'Pengajuan konsultasi baru telah masuk.',
            'konsultasi',
            ['status' => $konsultasi->status],
        );
        event(new KonsultasiCreated($konsultasi));

        return $konsultasi->load(['user', 'topik']);
    }

    /**
     * Tambahkan balasan/respon pada konsultasi TIK.
     */
    public function tambahRespon(Konsultasi $konsultasi, User $pembalas, string $isiRespon, ?UploadedFile $fileAttachment = null): KonsultasiResponse
    {
        $filePath = null;
        if ($fileAttachment) {
            $filePath = $fileAttachment->store('lampiran_konsultasi_response', 'public');
        }

        $response = KonsultasiResponse::create([
            'konsultasi_id' => $konsultasi->id,
            'user_id'       => $pembalas->id,
            'pesan'         => $isiRespon,
            'file'          => $filePath,
        ]);

        // Jika pembalas adalah admin (atau user lain), update status Konsultasi otomatis menjadi 'Diproses'
        $isAdmin = (int) $pembalas->id !== (int) $konsultasi->user_id;
        if ($isAdmin && in_array($konsultasi->status, ['Menunggu'])) {
            $konsultasi->update(['status' => 'Diproses', 'updated_by' => $pembalas->id]);
        }

        // This durable, user-scoped record powers the notification inbox. It is
        // written in the business action, not a queued listener, so retries do
        // not create duplicate "admin replied" notifications.
        if ($pembalas->hasAnyRole(['admin', 'superadmin'])) {
            $this->audit->record(
                $pembalas,
                'konsultasi.response_created',
                "Membalas konsultasi “{$konsultasi->judul}”.",
                $konsultasi,
            );
            $notification = Notification::create([
                'user_id' => $konsultasi->user_id,
                'judul' => 'Balasan baru dari admin',
                'message' => 'Admin membalas konsultasi: ' . $konsultasi->judul,
                'type' => 'konsultasi_response',
                'item_id' => $konsultasi->id,
                'read' => false,
            ]);
            app(NotificationRealtimeService::class)->toUser($notification);

            // Keep the user's open web/mobile session in sync immediately.
            // WhatsApp and FCM are still handled asynchronously by the event
            // listener below, so a gateway outage never blocks this reply.
            app(NodeServiceClient::class)->broadcastToUser(
                $konsultasi->user_id,
                'konsultasi.responded',
                RealtimeEventPayload::make('konsultasi.responded', (int) $konsultasi->id, [
                    'status' => $konsultasi->status,
                    'response_id' => (int) $response->id,
                    'message' => 'Anda mendapat balasan baru pada konsultasi: '.$konsultasi->judul,
                ]),
            );
        }

        // Dispatch Event untuk notifikasi
        event(new KonsultasiResponseCreated($konsultasi, $response));

        return $response->load('user');
    }

    /**
     * Ubah status konsultasi.
     */
    public function ubahStatus(Konsultasi $konsultasi, string $statusBaru, ?User $admin = null): Konsultasi
    {
        $oldStatus = $konsultasi->status;

        $allowedTransitions = [
            'Menunggu' => ['Diproses', 'Ditolak', 'Selesai'],
            'Diproses' => ['Selesai', 'Ditolak'],
            'Ditolak'  => [],
            'Selesai'  => [],
        ];

        if (!isset($allowedTransitions[$oldStatus]) || !in_array($statusBaru, $allowedTransitions[$oldStatus])) {
            throw new \InvalidArgumentException("Transisi status konsultasi dari '{$oldStatus}' ke '{$statusBaru}' tidak diperbolehkan.");
        }

        $konsultasi->update([
            'status'     => $statusBaru,
            'updated_by' => $admin ? $admin->id : null,
        ]);

        if ($admin) {
            $this->audit->record(
                $admin,
                'konsultasi.status_changed',
                "Mengubah status konsultasi “{$konsultasi->judul}” dari {$oldStatus} menjadi {$statusBaru}.",
                $konsultasi,
                ['status_lama' => $oldStatus, 'status_baru' => $statusBaru],
            );

            $notification = Notification::create([
                'user_id' => $konsultasi->user_id,
                'judul' => 'Status konsultasi diperbarui',
                'message' => "Status konsultasi \"{$konsultasi->judul}\" berubah menjadi {$statusBaru}.",
                'type' => 'konsultasi_status',
                'item_id' => $konsultasi->id,
                'read' => false,
            ]);
            app(NotificationRealtimeService::class)->toUser($notification);

            app(NodeServiceClient::class)->broadcastToUser(
                $konsultasi->user_id,
                'konsultasi.status_changed',
                RealtimeEventPayload::make('konsultasi.status_changed', (int) $konsultasi->id, [
                    'status' => $statusBaru,
                    'old_status' => $oldStatus,
                    'message' => 'Status konsultasi Anda telah diubah menjadi '.$statusBaru,
                ]),
            );
        }

        event(new KonsultasiStatusChanged($konsultasi, $oldStatus, $statusBaru));

        return $konsultasi;
    }
}
