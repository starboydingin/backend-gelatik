<?php

namespace App\Http\Requests;

use Carbon\Carbon;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class UpdatePinjamRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'nama_pic' => 'sometimes|required|string|max:150',
            'jabatan_pic' => 'nullable|string|max:255',
            'instansi_pic' => 'sometimes|required|string|max:255',
            'kontak_pic' => 'sometimes|required|string|max:16',
            'jenis_identitas' => 'sometimes|required|in:KTP,SIM,Passport,NIP',
            'nomor_identitas' => 'sometimes|required|string|max:255',
            'alamat_peminjam' => 'sometimes|required|string|max:255',
            'jenis_durasi' => 'sometimes|required|in:harian,jam,menit',
            'tanggal_mulai' => 'sometimes|required|date',
            'jam_mulai' => 'nullable|date_format:H:i:s,H:i',
            'durasi_peminjaman' => 'sometimes|required|integer|min:1',
            'keterangan' => 'nullable|string|max:5000',
        ];
    }

    public function after(): array
    {
        return [function (Validator $validator): void {
            if (! $this->filled('tanggal_mulai')) {
                return;
            }

            $timezone = config('app.timezone', 'Asia/Jakarta');
            $today = Carbon::now($timezone)->startOfDay();

            try {
                $startDate = Carbon::parse($this->string('tanggal_mulai'), $timezone)->startOfDay();
            } catch (\Throwable) {
                return;
            }
            if ($startDate->lt($today) || $startDate->gt($today->copy()->addDay())) {
                $validator->errors()->add('tanggal_mulai', 'Tanggal mulai hanya dapat dipilih untuk hari ini atau besok.');
            }

            if ($startDate->isSameDay($today) && $this->filled('jam_mulai')) {
                try {
                    $startTime = Carbon::parse($startDate->toDateString().' '.$this->string('jam_mulai'), $timezone);
                    if ($startTime->lte(Carbon::now($timezone))) {
                        $validator->errors()->add('jam_mulai', 'Jam mulai untuk hari ini harus berada setelah waktu sekarang.');
                    }
                } catch (\Throwable) {
                    // The date_format rule owns malformed time messages.
                }
            }
        }];
    }
}
