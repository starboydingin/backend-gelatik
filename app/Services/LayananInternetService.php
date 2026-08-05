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
        ];
    }
}
