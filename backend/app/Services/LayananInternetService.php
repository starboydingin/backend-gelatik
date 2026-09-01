<?php

namespace App\Services;

use App\Models\Router;
use App\Models\RouterList;
use App\Models\User;

class LayananInternetService
{
    /**
     * Ambil data router OPD milik user yang sedang login
     */
    public function getListRouterOpd(User $user, ?string $search = null): array
    {
        if (empty($user->nama_opd)) {
            return [
                'list_router' => [],
                'router' => [],
                'bandwidth' => [
                    'available' => false,
                    'opd' => null,
                    'connections' => [],
                    'user' => $this->userBandwidth($user),
                ],
            ];
        }

        $listRouter = RouterList::aktif()
            ->where('nama_opd', $user->nama_opd)
            ->when(filled($search), fn ($q) => $q->where(function ($nested) use ($search): void {
                $nested->where('identity_router', 'like', '%'.$search.'%')
                    ->orWhere('interface', 'like', '%'.$search.'%')
                    ->orWhere('lokasi', 'like', '%'.$search.'%');
            }))
            ->orderBy('identity_router')
            ->orderBy('id')
            ->get()
            ->unique(fn (RouterList $item): string => strtolower(trim(implode('|', [
                $item->identity_router,
                $item->interface,
                $item->lokasi,
            ]))))
            ->values();

        $router = Router::aktif()
            ->where('nama_opd', $user->nama_opd)
            ->orderBy('id')
            ->get()
            ->unique(fn (Router $item): string => strtolower(trim((string) ($item->identity_router ?? $item->getKey()))))
            ->values();
        $primaryBandwidth = $listRouter->first(
            fn (RouterList $item): bool => $item->bandwidth_download_mbps !== null
                || $item->bandwidth_upload_mbps !== null,
        );

        return [
            'list_router' => $listRouter,
            'router' => $router,
            'bandwidth' => [
                'available' => $listRouter->contains(
                    fn (RouterList $item): bool => $item->bandwidth_download_mbps !== null
                        || $item->bandwidth_upload_mbps !== null,
                ),
                'opd' => $user->nama_opd,
                'connections' => $listRouter->map(fn (RouterList $item): array => [
                    'router_id' => $item->id,
                    'identity_router' => $item->identity_router,
                    'interface' => $item->interface,
                    'lokasi' => $item->lokasi,
                    'status' => (bool) $item->status,
                    'download_mbps' => $item->bandwidth_download_mbps,
                    'upload_mbps' => $item->bandwidth_upload_mbps,
                ])->values(),
                'user' => $this->userBandwidth($user, $primaryBandwidth),
            ],
        ];
    }

    private function userBandwidth(User $user, ?RouterList $router = null): array
    {
        $hasAllocation = $user->bandwidth_download_mbps !== null
            || $user->bandwidth_upload_mbps !== null;
        $detectedFromRouter = ! $hasAllocation && $router !== null;

        return [
            'available' => $hasAllocation || $detectedFromRouter,
            'detected' => $hasAllocation || $detectedFromRouter,
            'user_id' => $user->getKey(),
            'name' => $user->name,
            'download_mbps' => $hasAllocation
                ? $user->bandwidth_download_mbps
                : $router?->bandwidth_download_mbps,
            'upload_mbps' => $hasAllocation
                ? $user->bandwidth_upload_mbps
                : $router?->bandwidth_upload_mbps,
            'source' => $hasAllocation
                ? 'user_allocation'
                : ($detectedFromRouter ? 'opd_router' : 'unavailable'),
            'source_label' => $hasAllocation
                ? 'Alokasi khusus akun'
                : ($detectedFromRouter
                    ? 'Terdeteksi dari '.($router->identity_router ?: 'router OPD')
                    : 'Belum ada sumber bandwidth'),
            'inherited_from_opd' => $detectedFromRouter,
        ];
    }
}
