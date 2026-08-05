<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AjukanPinjamRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'nama_pic'          => 'required|string|max:150',
            'jabatan_pic'       => 'required|string|max:255',
            'instansi_pic'      => 'required|string|max:255',
            'kontak_pic'        => 'required|string|max:16',
            'jenis_identitas'   => 'required|in:KTP,SIM,Passport,NIP',
            'nomor_identitas'   => 'required|string|max:255',
            'alamat_peminjam'   => 'required|string|max:255',
            'jenis_durasi'      => 'required|in:harian,jam,menit',
            'tanggal_mulai'     => 'required|date',
            'jam_mulai'         => 'nullable|date_format:H:i:s,H:i',
            'durasi_peminjaman' => 'required|integer|min:1',
            'keterangan'        => 'nullable|string',
            'url_dokumen'       => 'nullable|string',
            'items'             => 'required|array|min:1',
            'items.*.item_id'   => 'required|exists:master_item,id',
            'items.*.quantity'  => 'required_without:items.*.jumlah|integer|min:1',
            'items.*.jumlah'    => 'nullable|integer|min:1',
        ];
    }
}
