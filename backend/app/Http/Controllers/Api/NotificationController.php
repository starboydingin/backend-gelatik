<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Models\NotificationRead;
use App\Models\User;
use App\Services\NotificationRealtimeService;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /** GET /api/notifications */
    public function index(Request $request)
    {
        $userId = $request->user()->id;

        // Regular users only see notifications created for their own account.
        // Admins may additionally see the admin broadcast stream (user_id=0).
        $isAdmin = $request->user()->hasAnyRole(['admin', 'superadmin']);
        $isBkd = $request->user()->hasRole('bkd');
        $notifications = Notification::query()
            ->where(function ($q) use ($userId, $isAdmin, $isBkd) {
                $q->where('user_id', $userId);
                if ($isAdmin) {
                    $q->orWhere('user_id', 0);
                } elseif ($isBkd) {
                    $q->orWhere(function ($broadcast): void {
                        $broadcast->where('user_id', 0)->where('type', 'usulan_email');
                    });
                }
            })
            ->orderBy('id', 'desc')
            ->paginate((int) min($request->integer('per_page', 15), 50));

        $readIds = NotificationRead::where('user_id', $userId)
            ->whereIn('notification_id', $notifications->pluck('id'))
            ->pluck('notification_id')
            ->all();
        $notifications->getCollection()->transform(function (Notification $notification) use ($readIds): Notification {
            if ((int) $notification->user_id === 0) {
                $notification->setAttribute('read', in_array($notification->id, $readIds, true));
            }

            return $notification;
        });

        $unreadCount = Notification::query()
            ->where(function ($query) use ($userId, $isAdmin, $isBkd): void {
                $query->where(function ($personal) use ($userId): void {
                    $personal->where('user_id', $userId)->where('read', false);
                });
                if ($isAdmin) {
                    $query->orWhere(function ($broadcast) use ($userId): void {
                        $broadcast->where('user_id', 0)
                            ->whereNotExists(function ($reads) use ($userId): void {
                                $reads->selectRaw('1')
                                    ->from('notification_reads')
                                    ->whereColumn('notification_reads.notification_id', 'notification.id')
                                    ->where('notification_reads.user_id', $userId);
                            });
                    });
                } elseif ($isBkd) {
                    $query->orWhere(function ($broadcast) use ($userId): void {
                        $broadcast->where('user_id', 0)
                            ->where('type', 'usulan_email')
                            ->whereNotExists(function ($reads) use ($userId): void {
                                $reads->selectRaw('1')
                                    ->from('notification_reads')
                                    ->whereColumn('notification_reads.notification_id', 'notification.id')
                                    ->where('notification_reads.user_id', $userId);
                            });
                    });
                }
            })
            ->count();

        $data = $notifications->toArray();
        $data['unread_count'] = $unreadCount;

        return response()->json(['success' => true, 'data' => $data]);
    }

    /** POST /api/notifications/{id}/read */
    public function markAsRead(Request $request, $id)
    {
        $notification = Notification::findOrFail($id);
        $userId = $request->user()->id;
        $isAdmin = $request->user()->hasAnyRole(['admin', 'superadmin']);
        $isBkdBroadcast = $request->user()->hasRole('bkd')
            && (int) $notification->user_id === 0
            && $notification->type === 'usulan_email';
        abort_unless((int) $notification->user_id === $userId || ($isAdmin && (int) $notification->user_id === 0) || $isBkdBroadcast, 403);

        if (($isAdmin || $isBkdBroadcast) && (int) $notification->user_id === 0) {
            NotificationRead::updateOrCreate(
                ['notification_id' => $notification->id, 'user_id' => $userId],
                ['read_at' => now()]
            );
        } else {
            $notification->update(['read' => true]);
        }

        app(NotificationRealtimeService::class)->inboxState(
            (int) $userId,
            (int) $notification->id,
            'read',
        );

        return response()->json(['success' => true, 'message' => 'Notifikasi berhasil ditandai telah dibaca.']);
    }

    /** POST /api/notifications/read-all */
    public function markAllAsRead(Request $request)
    {
        $userId = $request->user()->id;
        $isAdmin = $request->user()->hasAnyRole(['admin', 'superadmin']);
        $isBkd = $request->user()->hasRole('bkd');
        Notification::where('user_id', $userId)->where('read', false)->update(['read' => true]);
        if ($isAdmin || $isBkd) {
            $broadcastIds = Notification::where('user_id', 0)
                ->when($isBkd && ! $isAdmin, fn ($query) => $query->where('type', 'usulan_email'))
                ->pluck('id');
            $alreadyRead = NotificationRead::where('user_id', $userId)
                ->whereIn('notification_id', $broadcastIds)
                ->pluck('notification_id');
            $readAt = now();
            $rows = $broadcastIds->diff($alreadyRead)->map(fn ($notificationId) => [
                'notification_id' => $notificationId,
                'user_id' => $userId,
                'read_at' => $readAt,
            ])->values()->all();
            if ($rows !== []) {
                NotificationRead::upsert($rows, ['notification_id', 'user_id'], ['read_at']);
            }
        }

        // Any positive event entity is sufficient for clients to refresh their
        // own inbox count; it is not interpreted as a resource deep link.
        app(NotificationRealtimeService::class)->inboxState(
            (int) $userId,
            1,
            'read_all',
        );

        return response()->json(['success' => true, 'message' => 'Semua notifikasi ditandai telah dibaca.']);
    }

    /** GET /api/admin/notifications */
    public function adminIndex(Request $request)
    {
        $query = Notification::with('user:id,name,email')->latest();
        if ($request->filled('type')) {
            $query->where('type', $request->input('type'));
        }
        if ($request->has('read')) {
            $query->where('read', $request->boolean('read'));
        }
        if ($request->has('user_id')) {
            $query->where('user_id', $request->integer('user_id'));
        }

        return response()->json(['success' => true, 'data' => $query->paginate(20)]);
    }

    /** POST /api/admin/notifications */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'user_id' => 'nullable|integer|min:0',
            'judul' => 'required|string|max:255',
            'message' => 'required|string|max:255',
            'type' => 'nullable|string|max:20',
            'item_id' => 'nullable|integer|min:0',
        ]);
        $targetUser = $validated['user_id'] ?? 0;
        if ($targetUser !== 0 && ! User::whereKey($targetUser)->exists()) {
            return response()->json(['success' => false, 'message' => 'Pengguna tujuan tidak ditemukan.'], 422);
        }

        $notification = Notification::create([
            'user_id' => $targetUser,
            'judul' => $validated['judul'],
            'message' => $validated['message'],
            'type' => $validated['type'] ?? 'informasi',
            'item_id' => $validated['item_id'] ?? 0,
            'read' => false,
        ]);

        $realtime = app(NotificationRealtimeService::class);
        $targetUser === 0
            ? $realtime->toAdmins($notification)
            : $realtime->toUser($notification);

        return response()->json(['success' => true, 'message' => 'Notifikasi berhasil dibuat.', 'data' => $notification], 201);
    }

    /** PUT /api/admin/notifications/{id} */
    public function update(Request $request, int $id)
    {
        $notification = Notification::findOrFail($id);
        $validated = $request->validate([
            'judul' => 'sometimes|required|string|max:255',
            'message' => 'sometimes|required|string|max:255',
            'type' => 'sometimes|required|string|max:20',
        ]);
        $notification->update($validated);
        $this->publishRealtime($notification, 'updated');

        return response()->json(['success' => true, 'message' => 'Notifikasi berhasil diperbarui.', 'data' => $notification]);
    }

    /** DELETE /api/admin/notifications/{id} */
    public function destroy(int $id)
    {
        $notification = Notification::findOrFail($id);
        NotificationRead::where('notification_id', $notification->id)->delete();
        $notification->delete();
        $this->publishRealtime($notification, 'deleted');

        return response()->json(['success' => true, 'message' => 'Notifikasi berhasil dihapus.']);
    }

    private function publishRealtime(Notification $notification, string $status): void
    {
        $realtime = app(NotificationRealtimeService::class);
        (int) $notification->user_id === 0
            ? $realtime->toAdmins($notification, $status)
            : $realtime->toUser($notification, $status);
    }
}
