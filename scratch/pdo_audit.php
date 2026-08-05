<?php
$pdo = new PDO("mysql:host=127.0.0.1;dbname=db_layanantik;charset=utf8mb4", "root", "", [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
]);

$tables = [
    'activity_log', 'chatbot_urls', 'failed_jobs', 'faq', 'jobs', 'kritik_sarans', 
    'master_item', 'master_topik', 'm_settings', 'notification', 'oauth_access_tokens', 
    'oauth_auth_codes', 'oauth_clients', 'oauth_personal_access_clients', 
    'oauth_refresh_tokens', 'pengumumans', 'permissions', 'personal_access_tokens', 
    'pinjam_item', 'ratings', 'roles', 'sliders', 'tr_konsultasi', 
    'tr_konsultasi_response', 'tr_permintaan_pinjam', 'unker_list_router', 
    'unker_router', 'users', 'usulan_email'
];

$results = [];

foreach ($tables as $table) {
    // Check column info for id
    $stmt = $pdo->prepare("
        SELECT COLUMN_NAME, COLUMN_TYPE, COLUMN_KEY, EXTRA 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = 'db_layanantik' AND TABLE_NAME = ? AND COLUMN_NAME = 'id'
    ");
    $stmt->execute([$table]);
    $col = $stmt->fetch();

    // Check table auto_increment info
    $stmt = $pdo->prepare("
        SELECT AUTO_INCREMENT 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA = 'db_layanantik' AND TABLE_NAME = ?
    ");
    $stmt->execute([$table]);
    $tbl = $stmt->fetch();

    // Check max id
    $maxId = null;
    try {
        $stmtMax = $pdo->query("SELECT MAX(id) as max_id FROM `$table`");
        $rowMax = $stmtMax->fetch();
        $maxId = $rowMax['max_id'] ?? 0;
    } catch (\Throwable $e) {
        $maxId = 'ERROR: ' . $e->getMessage();
    }

    $results[$table] = [
        'column_type' => $col['COLUMN_TYPE'] ?? 'N/A',
        'column_key' => $col['COLUMN_KEY'] ?? 'NONE',
        'extra' => $col['EXTRA'] ?? 'NONE',
        'auto_increment_info_schema' => $tbl['AUTO_INCREMENT'] ?? null,
        'max_id' => $maxId
    ];
}

echo json_encode($results, JSON_PRETTY_PRINT) . "\n";
