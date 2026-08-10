<?php

namespace App\Services;

use App\Events\UsulanEmailCreated;
use App\Events\UsulanEmailStatusChanged;
use App\Models\PegawaiBelumPunyaEmail;
use App\Models\User;
use App\Models\UsulanEmail;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class UsulanEmailService
{
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

        // Dispatch Event untuk notifikasi ke BKD
        event(new UsulanEmailCreated($usulan));

        return $usulan;
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

        // Dispatch Event untuk notifikasi ke user pemohon (Socket.io, WA, FCM)
        event(new UsulanEmailStatusChanged($usulan, $oldStatus, $statusBaru));

        return $usulan;
    }
}
