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
            'id_peg'        => 'required_without:id_peg_bkd|string',
            'id_peg_bkd'    => 'nullable|string',
            'email_pribadi' => 'required|email',
        ];
    }
}
