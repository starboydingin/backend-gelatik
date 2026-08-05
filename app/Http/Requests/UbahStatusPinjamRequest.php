<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UbahStatusPinjamRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'status'             => 'required|in:Proses,Ditolak,Selesai',
            'catatan'            => 'nullable|string',
            'bukti_pengembalian' => 'nullable|file|mimes:jpg,jpeg,png,pdf|max:2048',
        ];
    }
}
