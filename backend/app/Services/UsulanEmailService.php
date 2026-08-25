<?php

namespace App\Services;

use App\Events\UsulanEmailCreated;
use App\Events\UsulanEmailStatusChanged;
use App\Models\Notification;
use App\Models\PegawaiBelumPunyaEmail;
use App\Models\User;
use App\Models\UsulanEmail;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class UsulanEmailService
{
    public function __construct(
        private AdminAuditService $audit,
        private AdminNotificationService $adminNotifications,
    ) {}

    /**
     * Catat verifikasi dokumen BKD tanpa mengambil keputusan final.
     * Status tetap diajukan agar Admin Operator masih dapat membuat email resmi.
     */
    public function verifikasiDokumen(UsulanEmail $usulan, User $verifikator, ?string $catatan = null): UsulanEmail
    {
        if ($usulan->status !== 'diajukan') {
            throw new \InvalidArgumentException("Hanya usulan berstatus 'diajukan' yang dapat diverifikasi.");
        }

        $usulan->update([
            'diverifikasi_oleh' => $verifikator->name ?? $verifikator->username,
            'tanggal_verifikasi' => now(),
            'catatan' => $catatan,
            'updated_by' => $verifikator->id,
        ]);

        $this->audit->record(
            $verifikator,
            'usulan_email.document_verified',
            "Memverifikasi dokumen usulan email #{$usulan->id}.",
            $usulan,
        );

        return $usulan->fresh();
    }

    /**
     * Ajukan usulan email resmi baru.
     */
    public function ajukanUsulan(User $user, ?string $idPeg, string $emailPribadi, ?string $nip = null): UsulanEmail
    {
        // ID_Peg is intentionally hidden by FR-B07. A listed NIP is a safe
        // client selection key; legacy id_peg clients remain supported.
        $pegawai = null;
        if ($idPeg === null && ! empty($nip)) {
            $pegawai = PegawaiBelumPunyaEmail::where('NIP_Baru', $nip)->first();
            if (! $pegawai) {
                throw ValidationException::withMessages([
                    'nip' => 'Data pegawai tidak ditemukan.',
                ]);
            }
            $idPeg = (string) $pegawai->getKey();
        }

        // Aturan defensif: cek apakah ID yang dipakai untuk persistence murni angka.
        if ($idPeg === null || ! is_numeric($idPeg)) {
            Log::warning("UsulanEmailService: idPeg '{$idPeg}' bukan angka murni. User ID: {$user->id}");
            throw ValidationException::withMessages([
                'id_peg' => 'Data pegawai tidak valid untuk diajukan usulan email.',
            ]);
        }

        // 2. Cek keberadaan data pegawai di PegawaiBelumPunyaEmail
        $pegawai = $pegawai ?? PegawaiBelumPunyaEmail::where('ID_Peg', (string) $idPeg)->first();
        if (! $pegawai) {
            throw ValidationException::withMessages([
                'id_peg' => 'Data pegawai tidak ditemukan.',
            ]);
        }

        // 3. Simpan usulan email dengan status awal 'diajukan'
        $usulan = UsulanEmail::create([
            'id_peg_bkd' => (int) $idPeg,
            'email_pribadi' => $emailPribadi,
            'status' => 'diajukan',
            'created_by' => $user->id,
        ]);

        $this->adminNotifications->announce(
            'usulan_email.created',
            (int) $usulan->id,
            'Usulan Email Resmi Baru',
            'Pengajuan email resmi baru telah masuk.',
            'usulan_email',
        );
        $this->forgetDashboardCache((int) $user->id);
        event(new UsulanEmailCreated($usulan));

        return $usulan;
    }

    /** Update an unverified submission without changing its approval state. */
    public function updateUsulan(UsulanEmail $usulan, array $data): UsulanEmail
    {
        $idPeg = $data['id_peg'] ?? $data['id_peg_bkd'] ?? null;
        if ($idPeg !== null || isset($data['nip'])) {
            $pegawai = $idPeg === null
                ? PegawaiBelumPunyaEmail::where('NIP_Baru', $data['nip'])->first()
                : PegawaiBelumPunyaEmail::where('ID_Peg', (string) $idPeg)->first();
            if (! $pegawai) {
                throw ValidationException::withMessages(['nip' => 'Data pegawai tidak ditemukan.']);
            }
            $usulan->id_peg_bkd = (int) $pegawai->getKey();
        }
        if (array_key_exists('email_pribadi', $data)) {
            $usulan->email_pribadi = $data['email_pribadi'];
        }
        $usulan->save();
        $this->forgetDashboardCache((int) $usulan->created_by);

        return $usulan->fresh();
    }

    /**
     * Verifikasi usulan email (Approval / Rejection tunggal).
     */
    public function verifikasiUsulan(UsulanEmail $usulan, User $verifikator, bool $disetujui, ?string $catatan = null, ?string $emailResmi = null): UsulanEmail
    {
        if ($usulan->status !== 'diajukan') {
            throw new \InvalidArgumentException("Hanya usulan berstatus 'diajukan' yang dapat diverifikasi.");
        }

        $oldStatus = $usulan->status;
        $statusBaru = $disetujui ? 'disetujui' : 'ditolak';

        $updateData = [
            'diverifikasi_oleh' => $verifikator->name ?? $verifikator->username,
            'tanggal_verifikasi' => now(),
            'catatan' => $catatan,
            'status' => $statusBaru,
            'updated_by' => $verifikator->id,
        ];

        if ($disetujui && ! empty($emailResmi)) {
            $updateData['email_resmi'] = $emailResmi;
        }

        $usulan->update($updateData);

        $action = $disetujui ? 'usulan_email.approved' : 'usulan_email.rejected';
        $description = $disetujui
            ? "Menyetujui usulan email #{$usulan->id}."
            : "Menolak usulan email #{$usulan->id}.";
        $this->audit->record(
            $verifikator,
            $action,
            $description,
            $usulan,
            ['status_lama' => $oldStatus, 'status_baru' => $statusBaru],
        );

        $ownerId = (int) ($usulan->created_by ?? 0);
        $this->forgetDashboardCache($ownerId);
        if ($ownerId > 0) {
            $notification = Notification::create([
                'user_id' => $ownerId,
                'judul' => 'Status usulan email diperbarui',
                'message' => "Status usulan email #{$usulan->id} berubah menjadi {$statusBaru}.",
                'type' => 'usulan_email_status',
                'item_id' => $usulan->id,
                'read' => false,
            ]);
            app(NotificationRealtimeService::class)->toUser($notification);

            app(RealtimeDataSyncService::class)->eventToUser(
                $ownerId,
                'usulan_email.status_changed',
                RealtimeEventPayload::make('usulan_email.status_changed', (int) $usulan->id, [
                    'status' => $statusBaru,
                    'old_status' => $oldStatus,
                    'message' => 'Status usulan email Anda telah diubah menjadi '.$statusBaru,
                ]),
            );
            if ($verifikator->hasAnyRole(['admin', 'superadmin'])) {
                app(UserWhatsAppNotificationService::class)->afterEmailStatusChanged(
                    $usulan,
                    $statusBaru,
                );
            }
        }

        // Dispatch event for the queued FCM notification.
        event(new UsulanEmailStatusChanged($usulan, $oldStatus, $statusBaru));

        return $usulan;
    }

    private function forgetDashboardCache(int $userId): void
    {
        if ($userId > 0) {
            Cache::forget("dashboard:user:{$userId}");
        }
        Cache::forget('dashboard:service-insights');
        Cache::forget('dashboard:admin:admin');
        Cache::forget('dashboard:admin:superadmin');
    }
}
