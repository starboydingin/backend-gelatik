<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Konsultasi;
use App\Models\KonsultasiResponse;
use App\Models\Pinjam;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class AttachmentController extends Controller
{
    public function pinjam(Request $request, int $id, string $kind = 'document'): BinaryFileResponse
    {
        $pinjam = Pinjam::findOrFail($id);
        Gate::authorize('view', $pinjam);

        $path = $kind === 'return-proof'
            ? $pinjam->bukti_pengembalian
            : $pinjam->url_dokumen;

        abort_unless(in_array($kind, ['document', 'return-proof'], true), 404);

        return $this->serve($path);
    }

    public function konsultasi(Request $request, int $id): BinaryFileResponse
    {
        $konsultasi = Konsultasi::findOrFail($id);
        Gate::authorize('view', $konsultasi);

        return $this->serve($konsultasi->file);
    }

    public function konsultasiResponse(Request $request, int $id, int $responseId): BinaryFileResponse
    {
        $konsultasi = Konsultasi::findOrFail($id);
        Gate::authorize('view', $konsultasi);
        $response = KonsultasiResponse::query()
            ->where('konsultasi_id', $konsultasi->id)
            ->findOrFail($responseId);

        return $this->serve($response->file);
    }

    private function serve(?string $path): BinaryFileResponse
    {
        $path = ltrim(str_replace('\\', '/', (string) $path), '/');
        abort_if($path === '' || str_contains($path, '..'), 404);

        $disk = Storage::disk('public');
        abort_unless($disk->exists($path), 404);

        $mime = $disk->mimeType($path) ?: 'application/octet-stream';
        $previewable = in_array($mime, [
            'application/pdf',
            'image/png',
            'image/jpeg',
            'image/webp',
        ], true);
        $disposition = $previewable ? 'inline' : 'attachment';
        $filename = basename($path);

        return response()->file($disk->path($path), [
            'Content-Type' => $mime,
            'Content-Disposition' => $disposition.'; filename="'.addslashes($filename).'"',
            'X-Content-Type-Options' => 'nosniff',
            'Cache-Control' => 'private, no-store',
        ]);
    }
}
