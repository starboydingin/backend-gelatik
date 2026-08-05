<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class TambahResponKonsultasiRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'isi_respon' => 'required_without:jawaban|string',
            'jawaban'    => 'nullable|string',
            'file'       => 'nullable|file|mimes:jpg,jpeg,png,pdf|max:2048',
        ];
    }
}
