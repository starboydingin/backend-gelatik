<?php
/**
 * Investigate & Verify 7 endpoints with APP_DEBUG=true
 */

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\UsulanEmail;
use Illuminate\Support\Facades\DB;

$baseUrl = 'http://127.0.0.1:8000';

function httpRequest($url, $method = 'GET', $data = null, $token = null) {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    
    $headers = ['Accept: application/json', 'Content-Type: application/json'];
    if ($token) {
        $headers[] = "Authorization: Bearer {$token}";
    }
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    
    if ($method === 'POST') {
        curl_setopt($ch, CURLOPT_POST, true);
        if ($data) curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    } elseif ($method === 'PUT') {
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
        if ($data) curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    }
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    return ['code' => $httpCode, 'body' => $response, 'error' => $error];
}

echo "=== VERIFIKASI 7 ENDPOINT FAILED (APP_DEBUG=true) ===\n\n";

// Login first
echo "--- LOGIN ---\n";
$loginResp = httpRequest("{$baseUrl}/api/login", 'POST', [
    'email' => 'wahyu.ramadhan59@gmail.com',
    'password' => 'password123'
]);
echo "Login HTTP {$loginResp['code']}\n";
$loginData = json_decode($loginResp['body'], true);
$token = $loginData['data']['access_token'] ?? null;

if (!$token) {
    echo "GAGAL LOGIN! Body: {$loginResp['body']}\n";
    exit(1);
}
echo "Token: " . substr($token, 0, 30) . "...\n\n";

function createFreshDiajukanUsulan() {
    $maxId = DB::table('usulan_email')->max('id') + 1;
    return UsulanEmail::create([
        'id' => $maxId,
        'id_peg_bkd' => 51512,
        'email_pribadi' => 'test.investigasi_' . microtime(true) . '@gmail.com',
        'status' => 'diajukan',
        'created_by' => 1,
    ]);
}

// 1. POST /api/pengajuan-email/{id}/verifikasi
$u1 = createFreshDiajukanUsulan();
$ep1 = [
    'name' => "1. POST /api/pengajuan-email/{$u1->id}/verifikasi",
    'url' => "{$baseUrl}/api/pengajuan-email/{$u1->id}/verifikasi",
    'method' => 'POST',
    'data' => [
        'disetujui' => true,
        'catatan' => 'Disetujui untuk testing',
        'email_resmi' => 'test.pegawai@bkd.go.id'
    ]
];

// 2. POST /api/pengajuan-email/{id}/buat-email-resmi
$u2 = createFreshDiajukanUsulan();
$ep2 = [
    'name' => "2. POST /api/pengajuan-email/{$u2->id}/buat-email-resmi",
    'url' => "{$baseUrl}/api/pengajuan-email/{$u2->id}/buat-email-resmi",
    'method' => 'POST',
    'data' => [
        'email_resmi' => 'pegawai.baru@bkd.go.id',
        'catatan' => 'Email resmi dibuat'
    ]
];

// 3. POST /api/pengajuan-email/{id}/tolak-email
$u3 = createFreshDiajukanUsulan();
$ep3 = [
    'name' => "3. POST /api/pengajuan-email/{$u3->id}/tolak-email",
    'url' => "{$baseUrl}/api/pengajuan-email/{$u3->id}/tolak-email",
    'method' => 'POST',
    'data' => [
        'catatan' => 'Data tidak lengkap',
        'keterangan' => 'Mohon lengkapi dokumen pendukung'
    ]
];

// 4. POST /api/admin/users
$ep4 = [
    'name' => '4. POST /api/admin/users',
    'url' => "{$baseUrl}/api/admin/users",
    'method' => 'POST',
    'data' => [
        'name' => 'Test User Baru',
        'email' => 'testuserbaru_' . time() . '@example.com',
        'username' => 'testuser_' . time(),
        'password' => 'password123',
        'role' => 'admin',
        'nama_opd' => 'Dinas Pendidikan'
    ]
];

// 5. POST /api/admin/roles
$ep5 = [
    'name' => '5. POST /api/admin/roles',
    'url' => "{$baseUrl}/api/admin/roles",
    'method' => 'POST',
    'data' => [
        'name' => 'test_role_' . time(),
        'permissions' => []
    ]
];

// 6. PUT /api/admin/roles/3 (Role id=3 exists in DB: operator)
$ep6 = [
    'name' => '6. PUT /api/admin/roles/3',
    'url' => "{$baseUrl}/api/admin/roles/3",
    'method' => 'PUT',
    'data' => [
        'name' => 'operator',
        'permissions' => []
    ]
];

// 7. GET /api/laporan/peminjaman?filter=bulanan&tanggal=2026-07
$ep7 = [
    'name' => '7. GET /api/laporan/peminjaman?filter=bulanan&tanggal=2026-07',
    'url' => "{$baseUrl}/api/laporan/peminjaman?filter=bulanan&tanggal=2026-07",
    'method' => 'GET',
    'data' => null
];

$endpoints = [$ep1, $ep2, $ep3, $ep4, $ep5, $ep6, $ep7];

foreach ($endpoints as $ep) {
    echo str_repeat('=', 80) . "\n";
    echo "ENDPOINT: {$ep['name']}\n";
    echo str_repeat('-', 80) . "\n";
    
    $resp = httpRequest($ep['url'], $ep['method'], $ep['data'], $token);
    echo "HTTP Status: {$resp['code']}\n";
    
    $json = json_decode($resp['body'], true);
    if ($resp['code'] >= 500) {
        echo "!!! INTERNAL SERVER ERROR (500) DETECTED !!!\n";
        if ($json) {
            echo "Message: " . ($json['message'] ?? 'N/A') . "\n";
            echo "Exception: " . ($json['exception'] ?? 'N/A') . "\n";
            echo "File: " . ($json['file'] ?? 'N/A') . ":" . ($json['line'] ?? 'N/A') . "\n";
        } else {
            echo substr($resp['body'], 0, 1000) . "\n";
        }
    } else {
        echo "RESULT: " . ($resp['code'] < 400 ? 'SUCCESS' : 'EXPECTED CLIENT ERROR') . "\n";
        if ($json) {
            echo "Response Body: " . json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n";
        }
    }
    echo "\n";
}

echo "=== VERIFIKASI SELESAI ===\n";
