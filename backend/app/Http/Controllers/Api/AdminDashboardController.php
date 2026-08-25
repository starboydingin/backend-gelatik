<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\Konsultasi;
use App\Models\Notification;
use App\Models\Pinjam;
use App\Models\UsulanEmail;
use App\Models\User;
use App\Services\DashboardService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AdminDashboardController extends Controller
{
    public function __construct(private DashboardService $dashboardService)
    {
    }

    /** GET /api/admin/dashboard */
    public function index(Request $request)
    {
        $superadmin = $request->user()->hasRole('superadmin');
        $scope = $superadmin ? 'superadmin' : 'admin';
        $data = Cache::remember("dashboard:admin:{$scope}", now()->addSeconds(90), function () use ($superadmin, $scope): array {
            $adminActivity = collect();
            if ($superadmin) {
                if (Schema::hasTable('admin_audit_logs')) {
                    $adminActivity = AdminAuditLog::query()
                        ->with('actor:id,name,username')
                        ->latest()
                        ->take(10)
                        ->get()
                        ->map(fn (AdminAuditLog $entry): array => [
                            'id' => 'audit-'.$entry->id,
                            'actor' => $entry->actor?->name ?? $entry->actor?->username ?? 'Administrator',
                            'actor_role' => $entry->actor_role,
                            'description' => $entry->description,
                            'created_at' => $entry->created_at,
                        ]);
                }

                // Compatibility for activity_log entries produced before the
                // dedicated audit stream was added.
                if (Schema::hasTable('activity_log')) {
                $privilegedUserIds = DB::table('model_has_roles as model_roles')
                    ->join('roles', 'roles.id', '=', 'model_roles.role_id')
                    ->where('model_roles.model_type', User::class)
                    ->whereIn('roles.name', ['admin', 'superadmin'])
                    ->pluck('model_roles.model_id');
                    $legacyActivity = DB::table('activity_log as a')
                    ->leftJoin('users as u', 'u.id', '=', 'a.causer_id')
                    ->where('a.causer_type', User::class)
                    ->whereIn('a.causer_id', $privilegedUserIds)
                    ->latest('a.id')
                    ->limit(10)
                    ->get(['a.id', 'a.description', 'a.created_at', 'u.name as actor'])
                    ->map(fn ($entry): array => [
                        'id' => 'legacy-'.$entry->id,
                        'actor' => $entry->actor ?? 'Administrator',
                        'actor_role' => 'administrator',
                        'description' => $entry->description,
                        'created_at' => $entry->created_at,
                    ]);
                    $adminActivity = $adminActivity->concat($legacyActivity);
                }

                // Status mutations made before the audit stream existed are
                // still visible to superadmin from their persisted actor and
                // updated timestamp. New actions are stored in audit logs.
                $recordedConsultationIds = Schema::hasTable('admin_audit_logs')
                    ? AdminAuditLog::query()
                        ->where('action', 'konsultasi.status_changed')
                        ->where('subject_type', Konsultasi::class)
                        ->pluck('subject_id')
                        ->all()
                    : [];
                $inferredActivity = Konsultasi::query()
                    ->with('updatedBy:id,name,username')
                    ->where('status', 'Ditolak')
                    ->whereNotNull('updated_by')
                    ->whereNotIn('id', $recordedConsultationIds)
                    ->latest('updated_at')
                    ->take(10)
                    ->get()
                    ->filter(fn (Konsultasi $item): bool => $item->updatedBy?->hasAnyRole(['admin', 'superadmin']) ?? false)
                    ->map(function (Konsultasi $item): array {
                        $role = $item->updatedBy?->hasRole('superadmin') ? 'superadmin' : 'admin';

                        return [
                            'id' => 'inferred-konsultasi-'.$item->id,
                            'actor' => $item->updatedBy?->name ?? $item->updatedBy?->username ?? 'Administrator',
                            'actor_role' => $role,
                            'description' => "Menolak konsultasi “{$item->judul}”.",
                            'created_at' => $item->updated_at,
                        ];
                    });
                $adminActivity = $adminActivity
                    ->concat($inferredActivity)
                    ->sortByDesc('created_at')
                    ->take(10)
                    ->values()
                    ->all();
            }
            $userCounts = User::query()
                ->selectRaw('COUNT(*) as total')
                ->selectRaw("SUM(CASE WHEN status = '1' THEN 1 ELSE 0 END) as active")
                ->first();
            $dashboard = $this->dashboardService->getStatistikInternal();

            return [
                'scope' => $scope,
                'summary' => [
                    'users_total' => (int) ($userCounts->total ?? 0),
                    'users_active' => (int) ($userCounts->active ?? 0),
                    'konsultasi_open' => Konsultasi::whereIn('status', ['Menunggu', 'Diproses'])->count(),
                    'peminjaman_open' => ($dashboard['peminjaman']['menunggu'] ?? 0)
                        + ($dashboard['peminjaman']['proses'] ?? 0),
                    'usulan_email_pending' => UsulanEmail::where('status', 'diajukan')->count(),
                    'notifications_unread' => Notification::where('read', false)->count(),
                ],
                'dashboard' => $dashboard,
                'admin_activity' => $adminActivity,
                'recent' => [
                    'users' => User::query()
                        ->latest()
                        ->take(5)
                        ->get(['id', 'name', 'username', 'email', 'nama_opd', 'status', 'created_at']),
                    'konsultasi' => Konsultasi::with(['user:id,name', 'topik:id,topik'])
                        ->latest()
                        ->take(5)
                        ->get(),
                    'peminjaman' => Pinjam::with(['user:id,name', 'items:id,nama'])
                        ->latest()
                        ->take(5)
                        ->get(),
                    'usulan_email' => UsulanEmail::with(['user:id,name', 'pegawaiBkd'])
                        ->latest()
                        ->take(5)
                        ->get(),
                ],
            ];
        });

        return response()->json(['success' => true, 'data' => $data]);
    }
}
