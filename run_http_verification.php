<?php

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$baseUrl = 'http://127.0.0.1:8000';
$nodeUrl = 'http://127.0.0.1:4000';
$internalApiKey = '2f9eA7cXvL8qN1mR4zT6wYkP3Hs9Jd5Ub0Gp8Fx2Ce7Lv1QaZmN6Ri4KoBw3TyEh';

function makeRequest($method, $path, $headers = [], $body = null) {
    global $baseUrl;
    $url = (strpos($path, 'http') === 0) ? $path : $baseUrl . $path;

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, strtoupper($method));
    curl_setopt($ch, CURLOPT_TIMEOUT, 15);
    
    $defaultHeaders = [
        'Accept' => 'application/json'
    ];
    if ($body !== null) {
        $defaultHeaders['Content-Type'] = 'application/json';
    }

    $finalHeaders = array_merge($defaultHeaders, $headers);
    
    $reqHeaders = [];
    foreach ($finalHeaders as $k => $v) {
        $reqHeaders[] = "$k: $v";
    }
    curl_setopt($ch, CURLOPT_HTTPHEADER, $reqHeaders);

    if ($body !== null) {
        if (is_array($body)) {
            $jsonBody = json_encode($body);
            curl_setopt($ch, CURLOPT_POSTFIELDS, $jsonBody);
        } else {
            curl_setopt($ch, CURLOPT_POSTFIELDS, $body);
        }
    }

    $start = microtime(true);
    $response = curl_exec($ch);
    $duration = round((microtime(true) - $start) * 1000, 2);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $err = curl_error($ch);
    curl_close($ch);

    return [
        'method' => $method,
        'path' => $path,
        'url' => $url,
        'status_code' => $code,
        'response' => $response,
        'duration_ms' => $duration,
        'error' => $err,
        'request_body' => $body
    ];
}

function maskSensitive($data) {
    if (is_array($data)) {
        foreach ($data as $k => $v) {
            if (in_array(strtolower($k), ['password', 'password_confirmation', 'access_token', 'token'])) {
                $data[$k] = '***MASKED_TOKEN_OR_SECRET***';
            } else {
                $data[$k] = maskSensitive($v);
            }
        }
    }
    return $data;
}

function formatResult($res, $notes = '') {
    $out = "### [" . strtoupper($res['method']) . "] " . $res['path'] . "\n";
    $out .= "- Status Code: " . $res['status_code'] . " (" . $res['duration_ms'] . " ms)\n";
    
    if ($res['request_body'] !== null) {
        $out .= "- Contoh Request Body:\n```json\n" . json_encode(maskSensitive($res['request_body']), JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n```\n";
    } else {
        $out .= "- Contoh Request Body: (Tidak ada body)\n";
    }

    $json = json_decode($res['response'], true);
    if ($json !== null) {
        $masked = maskSensitive($json);
        $jsonStr = json_encode($masked, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
        $lines = explode("\n", $jsonStr);
        if (count($lines) > 80) {
            $jsonStr = implode("\n", array_slice($lines, 0, 40)) . "\n  ... [truncated " . (count($lines) - 80) . " lines for brevity] ...\n" . implode("\n", array_slice($lines, -40));
        }
        $out .= "- Contoh Response Body:\n```json\n" . $jsonStr . "\n```\n";
    } else {
        $out .= "- Contoh Response Body: " . (trim($res['response']) ? substr(trim($res['response']), 0, 500) : "(Empty Response)") . "\n";
    }

    $anomaly = [];
    if ($res['status_code'] >= 500) {
        $anomaly[] = "ERROR 500 (Internal Server Error)";
    }
    if ($res['duration_ms'] > 3000) {
        $anomaly[] = "Response Time Lambat (>3s: " . $res['duration_ms'] . "ms)";
    }
    if ($res['error']) {
        $anomaly[] = "cURL Error: " . $res['error'];
    }
    if ($notes) {
        $anomaly[] = $notes;
    }

    $out .= "- Catatan: " . (count($anomaly) > 0 ? implode('; ', $anomaly) : "Normal") . "\n\n";
    return [
        'markdown' => $out,
        'raw' => $res,
        'anomaly' => $anomaly
    ];
}

// 1. Fetch dynamic IDs from DB tables
$samplePeminjamanId = \DB::table('tr_permintaan_pinjam')->value('id') ?? 1;
$sampleKonsultasiId = \DB::table('tr_konsultasi')->value('id') ?? 1;
$sampleItemId = \DB::table('master_item')->value('id') ?? 1;
$sampleUsulanEmailId = \DB::table('usulan_email')->value('id') ?? 1;
$sampleUserId = \DB::table('users')->where('status', '1')->value('id') ?? 2;
$sampleRoleId = \DB::table('roles')->value('id') ?? 1;
$sampleNotifId = \DB::table('notification')->value('id') ?? 1;
$sampleKritikId = \DB::table('kritik_sarans')->value('id') ?? 1;
$samplePeminjamanItemId = \DB::table('pinjam_item')->value('id') ?? 1;

// 2. Perform Auth Login (User OPD)
$loginRes = makeRequest('POST', '/api/login', [], [
    'email' => 'bkd@lampungprov.go.id',
    'password' => 'password123'
]);
$loginData = json_decode($loginRes['response'], true);
$userToken = $loginData['data']['access_token'] ?? '';

// Perform Auth Login (Admin Operator)
$loginAdminRes = makeRequest('POST', '/api/login', [], [
    'email' => 'operator@gmail.com',
    'password' => 'password123'
]);
$loginAdminData = json_decode($loginAdminRes['response'], true);
$adminToken = $loginAdminData['data']['access_token'] ?? $userToken;

$authHeaders = [
    'Authorization' => "Bearer $userToken"
];

$adminAuthHeaders = [
    'Authorization' => "Bearer $adminToken"
];

$results = [];
$bugs = [];

$test = function($method, $path, $headers = [], $body = null, $notes = '') use (&$results, &$bugs) {
    $res = makeRequest($method, $path, $headers, $body);
    $formatted = formatResult($res, $notes);
    $results[] = $formatted;
    echo "Tested [" . strtoupper($method) . "] $path -> HTTP " . $res['status_code'] . " (" . $res['duration_ms'] . " ms)\n";
    if ($res['status_code'] >= 500 || strpos($notes, 'BUG') !== false || $res['error']) {
        $bugs[] = [
            'method' => $method,
            'path' => $path,
            'status' => $res['status_code'],
            'response' => $res['response'],
            'notes' => $notes ?: ($res['error'] ?: 'Server Error 500')
        ];
    }
};

echo "Starting HTTP tests for 70+ endpoints...\n";

// ==========================================
// MODUL 1: AUTH & PUBLIK (6 Endpoints)
// ==========================================
$test('POST', '/api/internal/wa/webhook-delivery-status', ['Authorization' => "Bearer $internalApiKey"], [
    'status' => 'DELIVERED',
    'reference' => 'TEST-REF-123',
    'error' => null
]);
$test('POST', '/api/login', [], ['email' => 'bkd@lampungprov.go.id', 'password' => 'password123']);
$test('POST', '/api/register', [], [
    'name' => 'User Test Auto Verification',
    'email' => 'testverif_' . time() . '@lampungprov.go.id',
    'username' => 'testverif_' . time(),
    'no_hp' => '081234567890',
    'nama_opd' => 'Dinas Komunikasi Informasi dan Statistik',
    'password' => 'password123',
    'password_confirmation' => 'password123'
]);
$test('GET', '/api/opd');
$test('POST', '/api/kritik-saran', [], [
    'nama' => 'Pengunjung Test',
    'email' => 'pengunjung@test.com',
    'subjek' => 'Saran Layanan',
    'pesan' => 'Mohon tingkatkan kecepatan layanan server.'
]);
$test('GET', '/api/kritik-saran/search?keyword=Saran');
$test('GET', '/api/me', $authHeaders);

// ==========================================
// MODUL 2: DASHBOARD & SLIDER (2 Endpoints)
// ==========================================
$test('GET', '/api/slider', $authHeaders);
$test('GET', '/api/dashboard', $authHeaders);

// ==========================================
// MODUL 3: PEMINJAMAN ASET TIK (8 Endpoints)
// ==========================================
$test('GET', '/api/pinjam', $authHeaders);
$test('POST', '/api/pinjam', $authHeaders, [
    'tgl_pinjam' => date('Y-m-d'),
    'tgl_kembali' => date('Y-m-d', strtotime('+3 days')),
    'keterangan' => 'Peminjaman Laptop & Proyektor untuk Rapat Koordinasi',
    'items' => [
        ['item_id' => $sampleItemId, 'jumlah' => 1]
    ]
]);
$test('GET', "/api/pinjam/$samplePeminjamanId", $authHeaders);
$test('PUT', "/api/pinjam/$samplePeminjamanId", $authHeaders, [
    'keterangan' => 'Peminjaman Laptop & Proyektor (Update via HTTP verification test)'
]);
$test('POST', "/api/pinjam/$samplePeminjamanId/status", $adminAuthHeaders, [
    'status' => '1',
    'catatan' => 'Disetujui oleh admin'
]);
$test('POST', "/api/pinjam/$samplePeminjamanId", $authHeaders, [
    'item_id' => $sampleItemId,
    'jumlah' => 1
]);
$test('DELETE', "/api/pinjam/$samplePeminjamanId/item/$samplePeminjamanItemId", $authHeaders);
$test('DELETE', "/api/pinjam/$samplePeminjamanId", $authHeaders);

// ==========================================
// MODUL 4: KONSULTASI TIK (6 Endpoints)
// ==========================================
$test('GET', '/api/konsul', $authHeaders);
$test('POST', '/api/konsul', $authHeaders, [
    'topik_id' => 1,
    'judul' => 'Konsultasi Integrasi Domain OPD',
    'keluhan' => 'Meminta arahan mengenai konfigurasi DNS dan SSL wildcard.'
]);
$test('GET', "/api/konsul/$sampleKonsultasiId", $authHeaders);
$test('POST', "/api/konsul/$sampleKonsultasiId/response", $authHeaders, [
    'pesan' => 'Tanggapan awal dari tim teknis.'
]);
$test('POST', "/api/konsul/$sampleKonsultasiId/status", $adminAuthHeaders, [
    'status' => 'selesai'
]);
$test('DELETE', "/api/konsul/$sampleKonsultasiId", $authHeaders);

// ==========================================
// MODUL 5: ITEM / ASET (4 Endpoints)
// ==========================================
$test('GET', '/api/item', $authHeaders);
$test('GET', '/api/items', $authHeaders);
$test('GET', '/api/items/search/laptop', $authHeaders);
$test('GET', "/api/items/$sampleItemId", $authHeaders);

// ==========================================
// MODUL 6: TOPIK & FAQ (2 Endpoints)
// ==========================================
$test('GET', '/api/topik', $authHeaders);
$test('GET', '/api/faq', $authHeaders);

// ==========================================
// MODUL 7: RATING (3 Endpoints)
// ==========================================
$test('GET', '/api/rating', $authHeaders);
$test('POST', '/api/rating', $authHeaders, [
    'layanan_type' => 'peminjaman',
    'layanan_id' => $samplePeminjamanId,
    'bintang' => 5,
    'ulasan' => 'Sangat memuaskan dan cepat'
]);
$test('POST', '/api/rating/update', $authHeaders, [
    'layanan_type' => 'peminjaman',
    'layanan_id' => $samplePeminjamanId,
    'bintang' => 4,
    'ulasan' => 'Pelayanan bagus, dikembangkan lebih baik'
]);

// ==========================================
// MODUL 8: ROUTER & PEGAWAI (2 Endpoints)
// ==========================================
$test('GET', '/api/list-router-opd', $authHeaders);
$test('GET', '/api/pegawai', $authHeaders);

// ==========================================
// MODUL 9: USULAN EMAIL RESMI (6 Endpoints)
// ==========================================
$test('GET', '/api/pengajuan-email', $authHeaders);
$test('POST', '/api/pengajuan-email', $authHeaders, [
    'nama_pegawai' => 'Ahmad Subardjo',
    'nip' => '198501012010011001',
    'jabatan' => 'Pranata Komputer',
    'email_diusulkan' => 'ahmad.subardjo@lampungprov.go.id',
    'no_hp' => '081298765432'
]);
$test('GET', "/api/pengajuan-email/$sampleUsulanEmailId", $authHeaders);
$test('POST', "/api/pengajuan-email/$sampleUsulanEmailId/verifikasi", $adminAuthHeaders, [
    'catatan' => 'Dokumen pendukung valid'
]);
$test('POST', "/api/pengajuan-email/$sampleUsulanEmailId/buat-email-resmi", $adminAuthHeaders, [
    'email_resmi' => 'ahmad.subardjo@lampungprov.go.id',
    'catatan' => 'Email resmi berhasil dibuat di cPanel/Mail Server'
]);
$test('POST', "/api/pengajuan-email/$sampleUsulanEmailId/tolak-email", $adminAuthHeaders, [
    'alasan_penolakan' => 'NIP tidak sesuai dengan pangkalan data BKD'
]);

// ==========================================
// MODUL 10: PENGUMUMAN, NOTIFIKASI & KRITIK SARAN ADMIN (6 Endpoints)
// ==========================================
$test('GET', '/api/pengumuman', $authHeaders);
$test('POST', '/api/pengumuman', $adminAuthHeaders, [
    'judul' => 'Pemeliharaan Jaringan Utama TIK',
    'isi' => 'Diberitahukan bahwa akan dilakukan maintenance jaringan pada hari Sabtu jam 20:00 WIB.',
    'status' => '1'
]);
$test('GET', '/api/notifications', $authHeaders);
$test('POST', "/api/notifications/$sampleNotifId/read", $authHeaders);
$test('GET', '/api/admin/kritik-saran', $adminAuthHeaders);
$test('POST', '/api/admin/kritik-saran/bulk-delete', $adminAuthHeaders, [
    'ids' => [$sampleKritikId]
]);

// ==========================================
// MODUL 11: CHATBOT OLD & ADMIN USER/ROLE/SETTINGS (16 Endpoints)
// ==========================================
$test('GET', '/api/chatbot', $authHeaders);
$test('GET', '/api/admin/users', $adminAuthHeaders);
$test('POST', '/api/admin/users', $adminAuthHeaders, [
    'name' => 'User Admin Created',
    'email' => 'useradmincreated_' . time() . '@lampungprov.go.id',
    'username' => 'useradmincreated_' . time(),
    'no_hp' => '081234123412',
    'nama_opd' => 'Dinas Komunikasi Informasi dan Statistik',
    'password' => 'password123',
    'role' => 'user'
]);
$test('GET', "/api/admin/users/$sampleUserId", $adminAuthHeaders);
$test('PUT', "/api/admin/users/$sampleUserId", $adminAuthHeaders, [
    'name' => 'Updated Name Test User',
    'no_hp' => '081299998888'
]);
$test('POST', "/api/admin/users/$sampleUserId/deactivate", $adminAuthHeaders);
$test('POST', "/api/admin/users/$sampleUserId/activate", $adminAuthHeaders);
$test('DELETE', "/api/admin/users/$sampleUserId", $adminAuthHeaders);

$test('GET', '/api/admin/roles', $adminAuthHeaders);
$test('POST', '/api/admin/roles', $adminAuthHeaders, [
    'name' => 'test_role_' . time(),
    'permissions' => ['view dashboard']
]);
$test('GET', "/api/admin/roles/$sampleRoleId", $adminAuthHeaders);
$test('PUT', "/api/admin/roles/$sampleRoleId", $adminAuthHeaders, [
    'name' => 'operator_updated',
    'permissions' => ['view dashboard']
]);
$test('DELETE', "/api/admin/roles/$sampleRoleId", $adminAuthHeaders);
$test('GET', '/api/admin/permissions', $adminAuthHeaders);
$test('GET', '/api/admin/settings', $adminAuthHeaders);
$test('PUT', '/api/admin/settings', $adminAuthHeaders, [
    'app_name' => 'Layanan TIK Lampung',
    'running_text' => 'Selamat Datang di Portal TIK Diskominfotik Provinsi Lampung'
]);

// ==========================================
// MODUL 12: FITUR BARU F-WA, F-BOT, F-LAPORAN (7 Endpoints)
// ==========================================
$test('POST', '/api/notifikasi/wa/subscribe', $authHeaders, [
    'nomor_wa' => '081234567890'
]);
$test('GET', '/api/notifikasi/wa/status', $authHeaders);
$test('DELETE', '/api/notifikasi/wa/subscribe', $authHeaders);

$test('POST', '/api/chatbot/message', $authHeaders, [
    'message' => 'Bagaimana cara mengajukan peminjaman aset TIK?'
]);
$test('GET', '/api/chatbot/history', $authHeaders);
$test('DELETE', '/api/chatbot/history', $authHeaders);

$test('GET', '/api/laporan/peminjaman?bulan=07&tahun=2026', $authHeaders);

// ==========================================
// MODUL 13: LOGOUT (1 Endpoint)
// ==========================================
$test('POST', '/api/logout', $authHeaders);

// ==========================================
// MODUL 14: REALTIME SERVICE PORT 4000 (3 Endpoints)
// ==========================================
$test('GET', "$nodeUrl/health");
$test('POST', "$nodeUrl/internal/broadcast", ['x-api-key' => $internalApiKey], [
    'target' => 'all',
    'event' => 'system.test',
    'payload' => ['message' => 'Realtime verification broadcast']
]);
$test('POST', "$nodeUrl/internal/wa/send", ['x-api-key' => $internalApiKey], [
    'nomor_wa' => '081234567890',
    'message' => 'Pesan uji verifikasi WhatsApp gateway',
    'reference' => 'REF-VERIF-001'
]);

echo "Completed testing " . count($results) . " endpoints!\n";

// Write findings report
$reportContent = "# HASIL VERIFIKASI HTTP MENTAH 70+ ENDPOINT API TIK\n\n";
$reportContent .= "Tanggal Verifikasi: " . date('Y-m-d H:i:s') . "\n";
$reportContent .= "Environment: APP_DEBUG=false, Host: 127.0.0.1:8000 & 127.0.0.1:4000\n\n";

foreach ($results as $item) {
    $reportContent .= $item['markdown'];
}

if (count($bugs) > 0) {
    $reportContent .= "\n## DAFTAR TEMUAN BUG / KEJANGGALAN (FAILED ENDPOINTS)\n\n";
    foreach ($bugs as $b) {
        $reportContent .= "- **[" . strtoupper($b['method']) . "] " . $b['path'] . "**\n";
        $reportContent .= "  - Status Code: " . $b['status'] . "\n";
        $reportContent .= "  - Detail: " . $b['notes'] . "\n";
        $reportContent .= "  - Snippet Response: " . substr(trim($b['response']), 0, 300) . "\n\n";
    }
} else {
    $reportContent .= "\n## DAFTAR TEMUAN BUG / KEJANGGALAN\n\n- Tidak ditemukan bug fatal 500 pada seluruh endpoint yang dites.\n";
}

file_put_contents(__DIR__ . '/http_verification_report.md', $reportContent);
echo "Report written to backend/http_verification_report.md\n";

