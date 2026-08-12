<?php

namespace App\Services;

use App\Events\PinjamCreated;
use App\Events\PinjamStatusChanged;
use App\Models\MasterItem;
use App\Models\Pinjam;
use App\Models\PinjamItem;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class PinjamService
{
    /**
     * Ajukan peminjaman aset TIK baru.
     */
    public function ajukanPeminjaman(User $user, array $data): Pinjam
    {
        $tanggalMulai = $data['tanggal_mulai'];
        $jenisDurasi = $data['jenis_durasi']; // harian, jam, menit
        $jumlahDurasi = (int) ($data['durasi_peminjaman'] ?? $data['jumlah_durasi']);

        // Hitung tanggal_selesai secara otomatis berdasarkan jenis_durasi
        $carbonMulai = Carbon::parse($tanggalMulai);
        if ($jenisDurasi === 'harian') {
            $tanggalSelesai = $carbonMulai->copy()->addDays($jumlahDurasi);
        } elseif ($jenisDurasi === 'jam') {
            $tanggalSelesai = $carbonMulai->copy()->addHours($jumlahDurasi);
        } elseif ($jenisDurasi === 'menit') {
            $tanggalSelesai = $carbonMulai->copy()->addMinutes($jumlahDurasi);
        } else {
            throw ValidationException::withMessages(['jenis_durasi' => 'Jenis durasi tidak valid. Harus harian, jam, atau menit.']);
        }

        // Cek ketersediaan stok untuk setiap item
        $itemsToInsert = [];
        foreach ($data['items'] as $itemData) {
            $itemId = $itemData['item_id'];
            $qty = (int) ($itemData['quantity'] ?? $itemData['jumlah']);

            $masterItem = MasterItem::findOrFail($itemId);
            $sisaStok = $masterItem->cekKetersediaan($tanggalMulai, $tanggalSelesai->toDateTimeString());

            if ($qty > $sisaStok) {
                throw ValidationException::withMessages([
                    'items' => "Stok aset '{$masterItem->nama}' tidak mencukupi untuk rentang waktu yang dipilih. Stok tersedia: {$sisaStok}, diminta: {$qty}.",
                ]);
            }

            $itemsToInsert[] = [
                'item_id' => $itemId,
                'quantity' => $qty,
            ];
        }

        if (isset($data['dokumen_pendukung'])) {
            $data['url_dokumen'] = $data['dokumen_pendukung']->store(
                'dokumen_peminjaman',
                'public'
            );
        }

        // Simpan Pinjam dan PinjamItem dalam 1 DB Transaction
        $pinjam = DB::transaction(function () use ($user, $data, $tanggalMulai, $jenisDurasi, $jumlahDurasi, $tanggalSelesai, $itemsToInsert) {
            $pinjam = Pinjam::create([
                'user_id' => $user->id,
                'nama_pic' => $data['nama_pic'],
                'jabatan_pic' => filled($data['jabatan_pic'] ?? null)
                    ? $data['jabatan_pic']
                    : ($user->jabatan ?: '-'),
                'instansi_pic' => $data['instansi_pic'],
                'kontak_pic' => $data['kontak_pic'],
                'jenis_identitas' => $data['jenis_identitas'] ?? 'KTP',
                'nomor_identitas' => $data['nomor_identitas'],
                'alamat_peminjam' => $data['alamat_peminjam'],
                'jenis_durasi' => $jenisDurasi,
                'tanggal_mulai' => $tanggalMulai,
                'jam_mulai' => $data['jam_mulai'] ?? null,
                'durasi_peminjaman' => $jumlahDurasi,
                'tanggal_selesai' => $tanggalSelesai,
                'keterangan' => $data['keterangan'] ?? null,
                'url_dokumen' => $data['url_dokumen'] ?? null,
                'status' => 'Menunggu',
                'created_by' => $user->id,
            ]);

            foreach ($itemsToInsert as $item) {
                PinjamItem::create([
                    'pinjam_id' => $pinjam->id,
                    'item_id' => $item['item_id'],
                    'quantity' => $item['quantity'],
                ]);
            }

            return $pinjam;
        });

        // Dispatch Event setelah transaksi berhasil disubmit
        event(new PinjamCreated($pinjam));

        return $pinjam->load('pinjamItems.masterItem');
    }

    /**
     * Ubah status peminjaman dengan aturan transisi yang presisi.
     */
    public function ubahStatus(Pinjam $pinjam, string $statusBaru, ?string $catatan = null, ?User $admin = null, ?UploadedFile $buktiPengembalian = null): Pinjam
    {
        $oldStatus = $pinjam->status;

        // Validasi transisi status
        $allowedTransitions = [
            'Menunggu' => ['Proses', 'Ditolak'],
            'Proses' => ['Selesai'],
        ];

        if (! isset($allowedTransitions[$oldStatus]) || ! in_array($statusBaru, $allowedTransitions[$oldStatus])) {
            throw new \InvalidArgumentException("Transisi status dari '{$oldStatus}' ke '{$statusBaru}' tidak diperbolehkan.");
        }

        $updateData = [
            'status' => $statusBaru,
            'updated_by' => $admin ? $admin->id : null,
        ];

        if ($statusBaru === 'Selesai') {
            if ($buktiPengembalian) {
                $path = $buktiPengembalian->store('bukti_pengembalian', 'public');
                $updateData['bukti_pengembalian'] = $path;
            }
            $updateData['waktu_pengembalian'] = now();
        }

        if ($statusBaru === 'Ditolak') {
            if (empty($catatan)) {
                throw ValidationException::withMessages(['catatan' => 'Catatan alasan penolakan wajib diisi.']);
            }
            $updateData['catatan_petugas'] = $catatan;
        }

        $pinjam->update($updateData);

        // Dispatch Event untuk notifikasi (Socket.io, WA, FCM)
        event(new PinjamStatusChanged($pinjam, $oldStatus, $statusBaru));

        return $pinjam;
    }

    /**
     * Tambah aset ke pengajuan yang sudah ada (hanya jika status 'Menunggu').
     */
    public function tambahAsetKePengajuan(Pinjam $pinjam, array $items): Pinjam
    {
        if ($pinjam->status !== 'Menunggu') {
            throw new \InvalidArgumentException("Item hanya dapat ditambahkan saat pengajuan masih berstatus 'Menunggu'.");
        }

        foreach ($items as $itemData) {
            $itemId = $itemData['item_id'];
            $qty = (int) ($itemData['quantity'] ?? $itemData['jumlah']);

            $masterItem = MasterItem::findOrFail($itemId);
            $sisaStok = $masterItem->cekKetersediaan($pinjam->tanggal_mulai->toDateString(), $pinjam->tanggal_selesai->toDateTimeString());

            if ($qty > $sisaStok) {
                throw ValidationException::withMessages([
                    'items' => "Stok aset '{$masterItem->nama}' tidak mencukupi. Stok tersedia: {$sisaStok}, diminta: {$qty}.",
                ]);
            }

            $existingItem = PinjamItem::where('pinjam_id', $pinjam->id)->where('item_id', $itemId)->first();
            if ($existingItem) {
                $existingItem->update(['quantity' => $existingItem->quantity + $qty]);
            } else {
                PinjamItem::create([
                    'pinjam_id' => $pinjam->id,
                    'item_id' => $itemId,
                    'quantity' => $qty,
                ]);
            }
        }

        return $pinjam->fresh(['pinjamItems.masterItem']);
    }

    /**
     * Hapus 1 aset dari pengajuan (hanya jika status 'Menunggu' dan tersisa minimal 1 item).
     */
    public function hapusAsetDariPengajuan(Pinjam $pinjam, int $itemId): Pinjam
    {
        if ($pinjam->status !== 'Menunggu') {
            throw new \InvalidArgumentException("Item hanya dapat dihapus saat pengajuan masih berstatus 'Menunggu'.");
        }

        $countCurrent = $pinjam->pinjamItems()->count();
        if ($countCurrent <= 1) {
            throw new \InvalidArgumentException('Minimal harus tersisa 1 item dalam pengajuan peminjaman.');
        }

        PinjamItem::where('pinjam_id', $pinjam->id)->where('item_id', $itemId)->delete();

        return $pinjam->fresh(['pinjamItems.masterItem']);
    }

    /**
     * Update data pengajuan peminjaman (hanya jika status 'Menunggu').
     */
    public function updatePengajuan(Pinjam $pinjam, array $data): Pinjam
    {
        if ($pinjam->status !== 'Menunggu') {
            throw new \InvalidArgumentException('Pengajuan yang sudah diproses tidak dapat diubah.');
        }

        $updateData = [];

        // Field PIC & informasi dasar
        $allowedFields = ['nama_pic', 'jabatan_pic', 'instansi_pic', 'kontak_pic', 'jenis_identitas', 'nomor_identitas', 'alamat_peminjam', 'keterangan', 'url_dokumen'];
        foreach ($allowedFields as $field) {
            if (isset($data[$field])) {
                $updateData[$field] = $data[$field];
            }
        }

        // Cek jika ada perubahan jadwal/durasi
        if (isset($data['tanggal_mulai']) || isset($data['durasi_peminjaman']) || isset($data['jumlah_durasi']) || isset($data['jenis_durasi'])) {
            $tanggalMulai = $data['tanggal_mulai'] ?? $pinjam->tanggal_mulai->toDateTimeString();
            $jenisDurasi = $data['jenis_durasi'] ?? $pinjam->jenis_durasi;
            $jumlahDurasi = (int) ($data['durasi_peminjaman'] ?? $data['jumlah_durasi'] ?? $pinjam->durasi_peminjaman);

            $carbonMulai = Carbon::parse($tanggalMulai);
            if ($jenisDurasi === 'harian') {
                $tanggalSelesai = $carbonMulai->copy()->addDays($jumlahDurasi);
            } elseif ($jenisDurasi === 'jam') {
                $tanggalSelesai = $carbonMulai->copy()->addHours($jumlahDurasi);
            } elseif ($jenisDurasi === 'menit') {
                $tanggalSelesai = $carbonMulai->copy()->addMinutes($jumlahDurasi);
            } else {
                throw ValidationException::withMessages(['jenis_durasi' => 'Jenis durasi tidak valid. Harus harian, jam, atau menit.']);
            }

            // Hitung ketersediaan stok untuk semua item di pengajuan ini
            foreach ($pinjam->pinjamItems as $pItem) {
                $masterItem = MasterItem::findOrFail($pItem->item_id);
                $totalStok = (int) $masterItem->stok;

                $dipinjamLain = PinjamItem::where('item_id', $masterItem->id)
                    ->where('pinjam_id', '!=', $pinjam->id)
                    ->whereHas('pinjam', function ($query) use ($tanggalMulai, $tanggalSelesai) {
                        $query->whereIn('status', ['Menunggu', 'Proses'])
                            ->where('tanggal_mulai', '<=', $tanggalSelesai->toDateTimeString())
                            ->where('tanggal_selesai', '>=', $tanggalMulai);
                    })
                    ->sum('quantity');

                $sisaStok = max(0, $totalStok - (int) $dipinjamLain);
                if ($pItem->quantity > $sisaStok) {
                    throw ValidationException::withMessages([
                        'items' => "Stok aset '{$masterItem->nama}' tidak mencukupi untuk rentang waktu baru yang dipilih. Stok tersedia: {$sisaStok}, diminta: {$pItem->quantity}.",
                    ]);
                }
            }

            $updateData['tanggal_mulai'] = $tanggalMulai;
            $updateData['jenis_durasi'] = $jenisDurasi;
            $updateData['durasi_peminjaman'] = $jumlahDurasi;
            $updateData['tanggal_selesai'] = $tanggalSelesai;
        }

        $pinjam->update($updateData);

        return $pinjam->fresh(['pinjamItems.masterItem']);
    }

    /**
     * Soft delete pengajuan peminjaman (hanya jika status 'Menunggu').
     */
    public function hapusPengajuan(Pinjam $pinjam): bool
    {
        if ($pinjam->status !== 'Menunggu') {
            throw new \InvalidArgumentException('Pengajuan yang sudah diproses tidak dapat dihapus.');
        }

        return (bool) $pinjam->delete();
    }
}
