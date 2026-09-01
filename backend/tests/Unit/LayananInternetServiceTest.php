<?php

namespace Tests\Unit;

use App\Models\RouterList;
use App\Models\User;
use App\Services\LayananInternetService;
use PHPUnit\Framework\TestCase;
use ReflectionClass;

class LayananInternetServiceTest extends TestCase
{
    public function test_it_returns_bandwidth_allocated_to_the_current_user_separately_from_opd_data(): void
    {
        $user = new User([
            'id' => 17,
            'name' => 'Pengguna Bandwidth',
            'nama_opd' => null,
            'bandwidth_download_mbps' => 50,
            'bandwidth_upload_mbps' => 20,
        ]);

        $data = (new LayananInternetService)->getListRouterOpd($user);

        $this->assertFalse($data['bandwidth']['available']);
        $this->assertSame([
            'available' => true,
            'detected' => true,
            'user_id' => 17,
            'name' => 'Pengguna Bandwidth',
            'download_mbps' => 50,
            'upload_mbps' => 20,
            'source' => 'user_allocation',
            'source_label' => 'Alokasi khusus akun',
            'inherited_from_opd' => false,
        ], $data['bandwidth']['user']);
    }

    public function test_it_detects_user_bandwidth_from_the_opd_router_when_no_personal_allocation_exists(): void
    {
        $user = new User([
            'id' => 18,
            'name' => 'Pengguna Terdeteksi',
            'nama_opd' => 'OPD Test',
        ]);
        $router = new RouterList([
            'identity_router' => 'Router Utama OPD',
            'bandwidth_download_mbps' => 250,
            'bandwidth_upload_mbps' => 100,
        ]);
        $method = (new ReflectionClass(LayananInternetService::class))
            ->getMethod('userBandwidth');

        $bandwidth = $method->invoke(new LayananInternetService, $user, $router);

        $this->assertTrue($bandwidth['detected']);
        $this->assertTrue($bandwidth['inherited_from_opd']);
        $this->assertSame('opd_router', $bandwidth['source']);
        $this->assertSame(250, $bandwidth['download_mbps']);
        $this->assertSame(100, $bandwidth['upload_mbps']);
        $this->assertSame('Terdeteksi dari Router Utama OPD', $bandwidth['source_label']);
    }
}
