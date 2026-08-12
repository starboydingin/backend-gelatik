<?php

namespace Tests\Unit;

use App\Http\Requests\AjukanPinjamRequest;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Validator;
use Tests\TestCase;

class AjukanPinjamRequestRulesTest extends TestCase
{
    public function test_supporting_document_accepts_one_megabyte_and_job_title_is_optional(): void
    {
        $payload = [
            'dokumen_pendukung' => UploadedFile::fake()->create('surat.pdf', 1024, 'application/pdf'),
        ];

        $validator = Validator::make($payload, $this->relevantRules());

        $this->assertTrue($validator->passes(), json_encode($validator->errors()->toArray()));
    }

    public function test_supporting_document_rejects_files_larger_than_one_megabyte(): void
    {
        $payload = [
            'dokumen_pendukung' => UploadedFile::fake()->create('surat.pdf', 1025, 'application/pdf'),
        ];

        $validator = Validator::make($payload, $this->relevantRules());

        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('dokumen_pendukung', $validator->errors()->toArray());
    }

    private function relevantRules(): array
    {
        $rules = (new AjukanPinjamRequest)->rules();

        return [
            'jabatan_pic' => $rules['jabatan_pic'],
            'dokumen_pendukung' => $rules['dokumen_pendukung'],
        ];
    }
}
