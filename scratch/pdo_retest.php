<?php
$pdo = new PDO("mysql:host=127.0.0.1;dbname=db_layanantik;charset=utf8mb4", "root", "", [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
]);

$tablesToTest = [
    'users' => "INSERT INTO `users` (`name`, `nama_opd`, `username`, `email`, `password`, `created_at`, `updated_at`) VALUES ('Test User', 'OPD', 'user_test_".time()."', 'user_test_".time()."@test.com', 'secret', NOW(), NOW())",
    'roles' => "INSERT INTO `roles` (`name`, `guard_name`, `created_at`, `updated_at`) VALUES ('role_test_".time()."', 'web', NOW(), NOW())",
    'tr_permintaan_pinjam' => "INSERT INTO `tr_permintaan_pinjam` (`user_id`, `nama_pic`, `jabatan_pic`, `instansi_pic`, `kontak_pic`, `nomor_identitas`, `alamat_peminjam`, `tanggal_mulai`, `created_at`, `updated_at`) VALUES (1, 'PIC', 'Staff', 'OPD', '08123', '12345', 'Alamat', NOW(), NOW(), NOW())",
    'pinjam_item' => "INSERT INTO `pinjam_item` (`pinjam_id`, `item_id`, `quantity`) VALUES (1, 1, 1)",
    'tr_konsultasi' => "INSERT INTO `tr_konsultasi` (`user_id`, `judul`, `pesan`, `created_at`, `updated_at`) VALUES (1, 'Judul', 'Pesan', NOW(), NOW())",
    'tr_konsultasi_response' => "INSERT INTO `tr_konsultasi_response` (`konsultasi_id`, `user_id`, `pesan`, `created_at`, `updated_at`) VALUES (1, 1, 'Pesan', NOW(), NOW())",
    'usulan_email' => "INSERT INTO `usulan_email` (`id_peg_bkd`, `email_pribadi`, `status`, `created_at`, `updated_at`) VALUES (123, 'test_".time()."@email.com', 'diajukan', NOW(), NOW())",
    'kritik_sarans' => "INSERT INTO `kritik_sarans` (`user_id`, `kritik`, `saran`, `created_at`, `updated_at`) VALUES (1, 'Kritik', 'Saran', NOW(), NOW())",
    'pengumumans' => "INSERT INTO `pengumumans` (`judul`, `konten`, `created_at`, `updated_at`) VALUES ('Judul', 'Konten', NOW(), NOW())",
    'ratings' => "INSERT INTO `ratings` (`user_id`, `rating`, `created_at`, `updated_at`) VALUES (250, 5, NOW(), NOW())",
    'master_item' => "INSERT INTO `master_item` (`nama`, `deskripsi`, `stok`, `created_at`, `updated_at`) VALUES ('Nama Item', 'Deskripsi', 10, NOW(), NOW())",
    'master_topik' => "INSERT INTO `master_topik` (`topik`, `created_at`, `updated_at`) VALUES ('Topik Test', NOW(), NOW())",
    'faq' => "INSERT INTO `faq` (`topik_id`, `judul`, `detail`, `created_at`, `updated_at`) VALUES (1, 'Judul FAQ', 'Detail', NOW(), NOW())",
    'sliders' => "INSERT INTO `sliders` (`judul`, `image`, `created_at`, `updated_at`) VALUES ('Slider', 'img.jpg', NOW(), NOW())"
];

$report = [];
$totalSuccess = 0;

foreach ($tablesToTest as $table => $sql) {
    // 1. Get max before
    $stmtMax = $pdo->query("SELECT MAX(id) as max_id FROM `$table`");
    $maxBefore = (int)($stmtMax->fetch()['max_id'] ?? 0);

    // 2. Execute insert WITHOUT id
    $pdo->exec($sql);
    $createdId = (int)$pdo->lastInsertId();

    // 3. Get max after
    $stmtMaxAfter = $pdo->query("SELECT MAX(id) as max_id FROM `$table`");
    $maxAfter = (int)($stmtMaxAfter->fetch()['max_id'] ?? 0);

    $passed = ($createdId === $maxBefore + 1) && ($maxAfter === $createdId);
    if ($passed) $totalSuccess++;

    $report[$table] = [
        'max_before' => $maxBefore,
        'created_id_from_autoincrement' => $createdId,
        'max_after'  => $maxAfter,
        'status'     => $passed ? 'PASSED 🟢 (Sequential AUTO_INCREMENT)' : 'FAILED 🔴'
    ];
}

echo json_encode([
    'total_tests' => count($tablesToTest),
    'total_success' => $totalSuccess,
    'details' => $report
], JSON_PRETTY_PRINT) . "\n";
