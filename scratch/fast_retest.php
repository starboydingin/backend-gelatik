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

$tablesToTest = [
    'users'                 => fn() => User::create(['name' => 'AutoTest User', 'email' => 'auto_'.time().'@test.com', 'username' => 'auto_'.time(), 'password' => bcrypt('pass'), 'status' => '1']),
    'roles'                 => fn() => Role::create(['name' => 'auto_role_'.time(), 'guard_name' => 'web']),
    'tr_permintaan_pinjam'  => fn() => Pinjam::create([
        'user_id' => 1, 'nama_pic' => 'PIC Test', 'jabatan_pic' => 'Staff', 'instansi_pic' => 'Diskominfo',
        'kontak_pic' => '0812345678', 'jenis_identitas' => 'KTP', 'nomor_identitas' => '1234567890',
        'alamat_peminjam' => 'Jl. Test', 'jenis_durasi' => 'harian', 'tanggal_mulai' => now(), 'durasi_peminjaman' => 1,
        'status' => 'Menunggu'
    ]),
    'pinjam_item'           => fn($pinjamId) => PinjamItem::create(['pinjam_id' => $pinjamId, 'item_id' => 1, 'quantity' => 1]),
    'tr_konsultasi'         => fn() => Konsultasi::create(['user_id' => 1, 'faq_id' => 1, 'judul' => 'Konsultasi AutoTest', 'pesan' => 'Tes pesan', 'status' => 'Menunggu']),
    'tr_konsultasi_response'=> fn($konsultasiId) => KonsultasiResponse::create(['konsultasi_id' => $konsultasiId, 'user_id' => 1, 'pesan' => 'Tes balasan']),
    'usulan_email'          => fn() => UsulanEmail::create(['id_peg_bkd' => 999, 'email_pribadi' => 'test_'.time().'@email.com', 'status' => 'diajukan']),
    'kritik_sarans'         => fn() => KritikSaran::create(['user_id' => 1, 'kritik' => 'Kritik tes', 'saran' => 'Saran tes']),
    'pengumumans'           => fn() => Pengumuman::create(['judul' => 'Pengumuman AutoTest', 'konten' => 'Isi pengumuman']),
    'ratings'               => fn() => Rating::create(['user_id' => 2, 'rating' => 5]),
    'master_item'           => fn() => MasterItem::create(['nama' => 'Item AutoTest', 'deskripsi' => 'Deskripsi', 'stok' => 10, 'kondisi' => 'Baik']),
    'master_topik'          => fn() => MasterTopik::create(['topik' => 'Topik AutoTest', 'status' => '1']),
    'faq'                   => fn() => Faq::create(['topik_id' => 1, 'judul' => 'FAQ AutoTest', 'detail' => 'Detail', 'status' => '1']),
    'sliders'               => fn() => Slider::create(['judul' => 'Slider AutoTest', 'image' => 'slider.jpg', 'status' => 1]),
];

$report = [];
$totalSuccess = 0;

foreach ($tablesToTest as $table => $callback) {
    $maxBefore = (int) (DB::table($table)->max('id') ?? 0);
    
    try {
        $createdObj = null;
        if ($table === 'pinjam_item') {
            $createdObj = $callback($report['tr_permintaan_pinjam']['created_id'] ?? 1);
        } else if ($table === 'tr_konsultasi_response') {
            $createdObj = $callback($report['tr_konsultasi']['created_id'] ?? 1);
        } else {
            $createdObj = $callback();
        }

        $createdId = (int) $createdObj->id;
        $maxAfter = (int) (DB::table($table)->max('id') ?? 0);

        $passed = ($createdId === $maxBefore + 1) && ($maxAfter === $createdId);
        if ($passed) $totalSuccess++;

        $report[$table] = [
            'max_before' => $maxBefore,
            'created_id' => $createdId,
            'max_after'  => $maxAfter,
            'status'     => $passed ? 'PASSED 🟢 (Pure AUTO_INCREMENT)' : 'FAILED 🔴'
        ];
    } catch (\Throwable $e) {
        $report[$table] = [
            'max_before' => $maxBefore,
            'error'      => $e->getMessage(),
            'status'     => 'ERROR 🔴'
        ];
    }
}

echo json_encode([
    'total_tests' => count($tablesToTest),
    'total_success' => $totalSuccess,
    'details' => $report
], JSON_PRETTY_PRINT) . "\n";
