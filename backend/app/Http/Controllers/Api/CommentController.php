<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Konsultasi;
use App\Models\KonsultasiResponse;
use App\Models\Notification;
use App\Models\Pinjam;
use App\Models\RequestComment;
use App\Models\UsulanEmail;
use App\Services\AdminNotificationService;
use App\Services\FcmNotificationService;
use App\Services\KonsultasiService;
use App\Services\NotificationRealtimeService;
use App\Services\RealtimeDataSyncService;
use App\Services\RealtimeEventPayload;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CommentController extends Controller
{
    public function __construct(
        private KonsultasiService $konsultasiService,
        private AdminNotificationService $adminNotifications,
        private NotificationRealtimeService $userNotifications,
    ) {}

    /**
     * Normalisasi tipe service.
     */
    private function normalizeType(string $type): string
    {
        $clean = strtolower(trim($type));
        return match ($clean) {
            'pinjam', 'peminjaman' => 'pinjam',
            'email', 'usulan-email', 'usulan_email', 'pengajuan-email' => 'usulan_email',
            'konsul', 'konsultasi' => 'konsultasi',
            default => $clean,
        };
    }

    /**
     * Ambil entity pengajuan dan validasi hak akses kepemilikan.
     */
    private function resolveEntity(string $type, int|string $id, $user): array
    {
        $type = $this->normalizeType($type);

        switch ($type) {
            case 'pinjam':
                $record = Pinjam::with('user')->findOrFail($id);
                $isOwner = (int) $record->user_id === (int) $user->id;
                $isAdmin = $user->hasAnyRole(['admin', 'superadmin']);
                if (! $isOwner && ! $isAdmin) {
                    abort(403, 'Anda tidak memiliki akses ke diskusi peminjaman ini.');
                }
                $status = (string) $record->status;
                $canComment = in_array(strtolower($status), ['proses', 'diproses', 'ditolak']);
                $ownerId = (int) $record->user_id;
                $title = "Peminjaman #{$record->id}";
                break;

            case 'usulan_email':
                $record = UsulanEmail::with(['user', 'pegawaiBkd'])->findOrFail($id);
                $isOwner = (int) $record->created_by === (int) $user->id;
                $isAdmin = $user->hasAnyRole(['admin', 'superadmin', 'bkd']);
                if (! $isOwner && ! $isAdmin) {
                    abort(403, 'Anda tidak memiliki akses ke diskusi usulan email ini.');
                }
                $status = (string) $record->status;
                $isVerified = $record->tanggal_verifikasi !== null;
                $canComment = in_array(strtolower($status), ['ditolak', 'diproses']) || (strtolower($status) === 'diajukan' && $isVerified);
                $ownerId = (int) $record->created_by;
                $title = "Usulan Email #{$record->id}";
                break;

            case 'konsultasi':
                $record = Konsultasi::with(['user', 'responses.user'])->findOrFail($id);
                $isOwner = (int) $record->user_id === (int) $user->id;
                $isAdmin = $user->hasAnyRole(['admin', 'superadmin']);
                if (! $isOwner && ! $isAdmin) {
                    abort(403, 'Anda tidak memiliki akses ke diskusi konsultasi ini.');
                }
                $status = (string) $record->status;
                $canComment = in_array(strtolower($status), ['diproses', 'ditolak']);
                $ownerId = (int) $record->user_id;
                $title = "Konsultasi: {$record->judul}";
                break;

            default:
                abort(404, 'Tipe layanan tidak dikenali.');
        }

        return [$type, $record, $isOwner, $isAdmin, $canComment, $ownerId, $title];
    }

    /**
     * GET /api/{type}/{id}/comments
     */
    public function index(Request $request, string $type, $id): JsonResponse
    {
        $user = $request->user();
        [$normalizedType, $record, $isOwner, $isAdmin, $canComment, $ownerId] = $this->resolveEntity($type, $id, $user);

        if ($normalizedType === 'konsultasi') {
            $comments = $record->responses->map(function (KonsultasiResponse $resp) use ($ownerId, $record) {
                $isAdminResponse = (int) $resp->user_id !== $ownerId;
                return [
                    'id' => $resp->id,
                    'request_type' => 'konsultasi',
                    'request_id' => $record->id,
                    'user_id' => $resp->user_id,
                    'pesan' => $resp->pesan ?: ($resp->jawaban ?? ''),
                    'file' => $resp->file,
                    'is_admin' => $isAdminResponse,
                    'author_name' => $resp->user?->name ?? ($isAdminResponse ? 'Petugas' : 'Pemohon'),
                    'author_role' => $isAdminResponse ? 'Admin' : 'Pemohon',
                    'created_at' => $resp->created_at?->toISOString() ?? (string) now()->toISOString(),
                ];
            });
        } else {
            $comments = RequestComment::with('user')
                ->where('request_type', $normalizedType)
                ->where('request_id', (int) $record->id)
                ->orderBy('created_at', 'asc')
                ->get()
                ->map(function (RequestComment $c) use ($ownerId) {
                    $isAdminResponse = (int) $c->user_id !== $ownerId;
                    return [
                        'id' => $c->id,
                        'request_type' => $c->request_type,
                        'request_id' => $c->request_id,
                        'user_id' => $c->user_id,
                        'pesan' => $c->pesan,
                        'is_admin' => $isAdminResponse,
                        'author_name' => $c->user?->name ?? ($isAdminResponse ? 'Petugas' : 'Pemohon'),
                        'author_role' => $isAdminResponse ? 'Admin' : 'Pemohon',
                        'created_at' => $c->created_at?->toISOString() ?? (string) now()->toISOString(),
                    ];
                });
        }

        return response()->json([
            'success' => true,
            'data' => $comments,
            'can_comment' => $canComment,
            'status' => $record->status,
        ]);
    }

    /**
     * POST /api/{type}/{id}/comments
     */
    public function store(Request $request, string $type, $id): JsonResponse
    {
        $user = $request->user();
        [$normalizedType, $record, $isOwner, $isAdmin, $canComment, $ownerId, $title] = $this->resolveEntity($type, $id, $user);

        // Validasi aturan status
        if (! $canComment) {
            return response()->json([
                'success' => false,
                'message' => 'Diskusi hanya dapat dilakukan saat pengajuan berstatus Diproses atau Ditolak.',
            ], 422);
        }

        $request->validate([
            'pesan' => 'required|string|min:1|max:2000',
            'isi_respon' => 'nullable|string|max:2000',
        ]);

        $pesan = trim($request->string('pesan')->toString() ?: $request->string('isi_respon')->toString());
        if (empty($pesan)) {
            return response()->json([
                'success' => false,
                'message' => 'Komentar tidak boleh kosong.',
            ], 422);
        }

        $isAdminSender = (int) $user->id !== $ownerId;

        if ($normalizedType === 'konsultasi') {
            $resp = $this->konsultasiService->tambahRespon(
                $record,
                $user,
                $pesan,
                $request->file('file')
            );
            $newComment = [
                'id' => $resp->id,
                'request_type' => 'konsultasi',
                'request_id' => $record->id,
                'user_id' => $user->id,
                'pesan' => $pesan,
                'file' => $resp->file,
                'is_admin' => $isAdminSender,
                'author_name' => $user->name,
                'author_role' => $isAdminSender ? 'Admin' : 'Pemohon',
                'created_at' => now()->toISOString(),
            ];
        } else {
            $comment = RequestComment::create([
                'request_type' => $normalizedType,
                'request_id' => (int) $record->id,
                'user_id' => $user->id,
                'pesan' => $pesan,
            ]);

            // Kirim notifikasi realtime & inbox
            if ($isAdminSender && $ownerId > 0) {
                $notification = Notification::create([
                    'user_id' => $ownerId,
                    'judul' => 'Tanggapan baru dari Petugas',
                    'message' => "Petugas menambahkan tanggapan pada {$title}.",
                    'type' => "{$normalizedType}_comment",
                    'item_id' => $record->id,
                    'read' => false,
                ]);
                $this->userNotifications->toUser($notification);

                app(RealtimeDataSyncService::class)->eventToUser(
                    $ownerId,
                    "{$normalizedType}.comment",
                    RealtimeEventPayload::make("{$normalizedType}.comment", (int) $record->id, [
                        'status' => $record->status,
                        'message' => "Petugas menambahkan tanggapan pada {$title}.",
                    ]),
                );

                try {
                    app(FcmNotificationService::class)->sendToUser(
                        $ownerId,
                        'Tanggapan baru dari Petugas',
                        "Petugas menambahkan tanggapan pada {$title}.",
                        [
                            'type' => $normalizedType,
                            'reference_id' => (string) $record->id,
                        ],
                        false
                    );
                } catch (\Throwable $e) {
                    // Skips on FCM issue without breaking comment
                }
            } elseif (! $isAdminSender) {
                $this->adminNotifications->announce(
                    "{$normalizedType}.comment",
                    (int) $record->id,
                    'Tanggapan baru dari Pemohon',
                    "Pemohon ({$user->name}) menanggapi {$title}.",
                    $normalizedType,
                    ['status' => $record->status],
                );

                try {
                    app(FcmNotificationService::class)->sendToAdmins(
                        'Tanggapan baru dari Pemohon',
                        "Pemohon ({$user->name}) menanggapi {$title}.",
                        [
                            'type' => $normalizedType,
                            'reference_id' => (string) $record->id,
                        ],
                        false
                    );
                } catch (\Throwable $e) {
                    // Skips on FCM issue without breaking comment
                }
            }

            $newComment = [
                'id' => $comment->id,
                'request_type' => $normalizedType,
                'request_id' => $record->id,
                'user_id' => $user->id,
                'pesan' => $pesan,
                'is_admin' => $isAdminSender,
                'author_name' => $user->name,
                'author_role' => $isAdminSender ? 'Admin' : 'Pemohon',
                'created_at' => now()->toISOString(),
            ];
        }

        return response()->json([
            'success' => true,
            'message' => 'Komentar berhasil dikirim.',
            'data' => $newComment,
        ], 201);
    }
}
