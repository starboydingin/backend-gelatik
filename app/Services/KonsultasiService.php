<?php

namespace App\Services;

use App\Events\KonsultasiCreated;
use App\Events\KonsultasiResponseCreated;
use App\Models\Konsultasi;
use App\Models\KonsultasiResponse;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class KonsultasiService
{
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

        // Dispatch Event untuk memicu notifikasi ke admin
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

        return $konsultasi;
    }
}
