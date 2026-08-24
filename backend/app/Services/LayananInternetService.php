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
    public function getListRouterOpd(User $user): array
    {
        if (empty($user->nama_opd)) {
            return [
                'list_router' => [],
                'router'      => [],
                'bandwidth' => [
                    'available' => false,
                    'opd' => null,
                    'connections' => [],
                ],
            ];
        }

        $listRouter = RouterList::aktif()
            ->where('nama_opd', $user->nama_opd)
            ->get();

        $router = Router::aktif()
            ->where('nama_opd', $user->nama_opd)
            ->get();

        return [
            'list_router' => $listRouter,
            'router'      => $router,
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
            ],
        ];
    }
}
