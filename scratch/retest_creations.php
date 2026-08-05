<?php
require __DIR__ . '/../vendor/autoload.php';

$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;
use App\Models\User;
use App\Models\Pinjam;
use App\Models\PinjamItem;
use App\Models\Konsultasi;
use App\Models\KonsultasiResponse;
use App\Models\UsulanEmail;
use App\Models\KritikSaran;
use App\Models\MasterItem;
use App\Models\MasterTopik;
use App\Models\Faq;
use App\Models\Slider;
use App\Models\Pengumuman;
use App\Models\Rating;
use Spatie\Permission\Models\Role;

use App\Services\PinjamService;
use App\Services\KonsultasiService;
use App\Services\UsulanEmailService;
use App\Services\KritikSaranService;
use App\Services\PengumumanService;
use App\Services\RatingService;

$results = [];

// Fetch initial Max IDs before test
$tables = [
    'tr_permintaan_pinjam', 'pinjam_item', 'tr_konsultasi', 'tr_konsultasi_response',
    'usulan_email', 'kritik_sarans', 'users', 'roles', 'pengumumans', 'ratings'
];

$maxBefore = [];
foreach ($tables as $tbl) {
    $maxBefore[$tbl] = DB::table($tbl)->max('id') ?? 0;
}

// 1. User Creation Test
try {
    $user = User::create([
        'name'     => 'Test User AutoIncrement ' . time(),
        'email'    => 'test_auto_' . time() . '@example.com',
        'username' => 'test_auto_' . time(),
        'password' => bcrypt('password123'),
        'status'   => '1'
    ]);
    $results['User Creation'] = [
        'id' => $user->id,
        'max_before' => $maxBefore['users'],
        'passed' => $user->id > $maxBefore['users']
    ];
} catch (\Throwable $e) {
    $results['User Creation'] = ['error' => $e->getMessage()];
}

// 2. Role Creation Test
try {
    $role = Role::create([
        'name' => 'test_role_' . time(),
        'guard_name' => 'web'
    ]);
    $results['Role Creation'] = [
        'id' => $role->id,
        'max_before' => $maxBefore['roles'],
        'passed' => $role->id > $maxBefore['roles']
    ];
} catch (\Throwable $e) {
    $results['Role Creation'] = ['error' => $e->getMessage()];
}

// 3. Pinjam Service Test
try {
    $pinjamService = app(PinjamService::class);
    $masterItem = MasterItem::first();
    $pinjam = $pinjamService->ajukanPinjam($user, [
        'nama_pic'        => 'Test PIC',
        'jabatan_pic'     => 'Staff',
        'instansi_pic'    => 'Diskominfotik',
        'kontak_pic'      => '081234567890',
        'jenis_identitas' => 'KTP',
        'nomor_identitas' => '1234567890123456',
        'alamat_peminjam' => 'Jl. Test',
        'jenis_durasi'    => 'harian',
        'tanggal_mulai'   => date('Y-m-d'),
        'durasi'          => 2,
        'items'           => [
            ['item_id' => $masterItem->id ?? 1, 'quantity' => 1]
        ]
    ]);
    
    $pinjamItem = PinjamItem::where('pinjam_id', $pinjam->id)->first();

    $results['Pinjam Creation'] = [
        'tr_permintaan_pinjam_id' => $pinjam->id,
        'tr_permintaan_pinjam_max_before' => $maxBefore['tr_permintaan_pinjam'],
        'pinjam_item_id' => $pinjamItem->id ?? null,
        'pinjam_item_max_before' => $maxBefore['pinjam_item'],
        'passed' => ($pinjam->id > $maxBefore['tr_permintaan_pinjam']) && ($pinjamItem->id > $maxBefore['pinjam_item'])
    ];
} catch (\Throwable $e) {
    $results['Pinjam Creation'] = ['error' => $e->getMessage()];
}

// 4. Konsultasi Service Test
try {
    $konsultasiService = app(KonsultasiService::class);
    $topik = MasterTopik::first();
    $konsultasi = $konsultasiService->buatKonsultasi($user, [
        'topik_id' => $topik->id ?? 1,
        'judul'    => 'Test Konsultasi Auto',
        'pesan'    => 'Pesan tes konsultasi auto increment'
    ]);

    $respon = $konsultasiService->tambahRespon($konsultasi, $user, 'Respon tes auto increment');

    $results['Konsultasi & Respon Creation'] = [
        'konsultasi_id' => $konsultasi->id,
        'konsultasi_max_before' => $maxBefore['tr_konsultasi'],
        'respon_id' => $respon->id,
        'respon_max_before' => $maxBefore['tr_konsultasi_response'],
        'passed' => ($konsultasi->id > $maxBefore['tr_konsultasi']) && ($respon->id > $maxBefore['tr_konsultasi_response'])
    ];
} catch (\Throwable $e) {
    $results['Konsultasi & Respon Creation'] = ['error' => $e->getMessage()];
}

// 5. Usulan Email Service Test
try {
    $usulanService = app(UsulanEmailService::class);
    $usulan = $usulanService->ajukanUsulan($user, 12345, 'pribadi_test_' . time() . '@gmail.com');
    $results['Usulan Email Creation'] = [
        'id' => $usulan->id,
        'max_before' => $maxBefore['usulan_email'],
        'passed' => $usulan->id > $maxBefore['usulan_email']
    ];
} catch (\Throwable $e) {
    $results['Usulan Email Creation'] = ['error' => $e->getMessage()];
}

// 6. Kritik Saran Service Test
try {
    $kritikService = app(KritikSaranService::class);
    $ks = $kritikService->kirimKritikSaran($user, 'Kritik tes auto', 'Saran tes auto');
    $results['Kritik Saran Creation'] = [
        'id' => $ks->id,
        'max_before' => $maxBefore['kritik_sarans'],
        'passed' => $ks->id > $maxBefore['kritik_sarans']
    ];
} catch (\Throwable $e) {
    $results['Kritik Saran Creation'] = ['error' => $e->getMessage()];
}

// 7. Pengumuman Service Test
try {
    $pengumumanService = app(PengumumanService::class);
    $pengumuman = $pengumumanService->buatPengumuman($user, 'Pengumuman Tes Auto', 'Konten tes auto increment');
    $results['Pengumuman Creation'] = [
        'id' => $pengumuman->id,
        'max_before' => $maxBefore['pengumumans'],
        'passed' => $pengumuman->id > $maxBefore['pengumumans']
    ];
} catch (\Throwable $e) {
    $results['Pengumuman Creation'] = ['error' => $e->getMessage()];
}

// 8. Rating Service Test
try {
    $ratingService = app(RatingService::class);
    $rating = $ratingService->beriRating($user, 5);
    $results['Rating Creation'] = [
        'id' => $rating->id,
        'max_before' => $maxBefore['ratings'],
        'passed' => $rating->id > $maxBefore['ratings']
    ];
} catch (\Throwable $e) {
    $results['Rating Creation'] = ['error' => $e->getMessage()];
}

echo json_encode($results, JSON_PRETTY_PRINT) . "\n";
