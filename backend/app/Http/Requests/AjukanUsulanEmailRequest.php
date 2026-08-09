<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AjukanUsulanEmailRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'id_peg'        => 'required_without_all:id_peg_bkd,nip|string',
            'id_peg_bkd'    => 'nullable|string',
            'nip'           => 'required_without_all:id_peg,id_peg_bkd|string',
            'email_pribadi' => 'required|email',
        ];
    }
}
