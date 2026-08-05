<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class BuatKonsultasiRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'topik_id'   => 'required|exists:master_topik,id',
            'judul'      => 'required|string|max:255',
            'deskripsi'  => 'required_without:pertanyaan|string',
            'pertanyaan' => 'nullable|string',
            'file'       => 'nullable|file|mimes:jpg,jpeg,png,pdf|max:2048',
        ];
    }
}
