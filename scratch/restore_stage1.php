<?php
$pdo = new PDO("mysql:host=127.0.0.1;dbname=db_layanantik;charset=utf8mb4", "root", "", [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
]);

$tables = [
    'activity_log'                 => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'chatbot_urls'                 => ['type' => 'INT NOT NULL',             'auto' => true],
    'failed_jobs'                  => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'faq'                          => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'jobs'                         => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'kritik_sarans'                => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'master_item'                  => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'master_topik'                 => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'm_settings'                   => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'notification'                 => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'oauth_access_tokens'          => ['type' => 'VARCHAR(100) NOT NULL',    'auto' => false],
    'oauth_auth_codes'             => ['type' => 'VARCHAR(100) NOT NULL',    'auto' => false],
    'oauth_clients'                => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'oauth_personal_access_clients' => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'oauth_refresh_tokens'         => ['type' => 'VARCHAR(100) NOT NULL',    'auto' => false],
    'pengumumans'                  => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'permissions'                  => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'personal_access_tokens'       => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'pinjam_item'                  => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'ratings'                      => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'roles'                        => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'sliders'                      => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'tr_konsultasi'                => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'tr_konsultasi_response'       => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'tr_permintaan_pinjam'         => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'unker_list_router'            => ['type' => 'BIGINT NOT NULL',          'auto' => true],
    'unker_router'                 => ['type' => 'INT NOT NULL',             'auto' => true],
    'users'                        => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
    'usulan_email'                 => ['type' => 'BIGINT UNSIGNED NOT NULL', 'auto' => true],
];

$logs = [];

foreach ($tables as $table => $config) {
    $logs[$table] = ['step' => 'START'];

    // 1. Get max id
    if ($config['auto']) {
        $stmtMax = $pdo->query("SELECT MAX(id) as max_id FROM `$table`");
        $maxId = (int)($stmtMax->fetch()['max_id'] ?? 0);
        $nextId = max(1, $maxId + 1);
        $logs[$table]['max_id'] = $maxId;
        $logs[$table]['next_auto_increment'] = $nextId;
    }

    // 2. Check if PRIMARY KEY exists
    $stmtKey = $pdo->prepare("
        SELECT CONSTRAINT_NAME 
        FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
        WHERE TABLE_SCHEMA = 'db_layanantik' AND TABLE_NAME = ? AND CONSTRAINT_TYPE = 'PRIMARY KEY'
    ");
    $stmtKey->execute([$table]);
    $hasPk = $stmtKey->fetch();

    if (!$hasPk) {
        try {
            $pdo->exec("ALTER TABLE `$table` ADD PRIMARY KEY (`id`)");
            $logs[$table]['add_pk'] = 'SUCCESS';
        } catch (\Throwable $e) {
            $logs[$table]['add_pk'] = 'ERROR: ' . $e->getMessage();
        }
    } else {
        $logs[$table]['add_pk'] = 'ALREADY_EXISTS';
    }

    // 3. Modify AUTO_INCREMENT if auto is true
    if ($config['auto']) {
        try {
            $sqlModify = "ALTER TABLE `$table` MODIFY `id` {$config['type']} AUTO_INCREMENT, AUTO_INCREMENT = $nextId";
            $pdo->exec($sqlModify);
            $logs[$table]['modify_auto_increment'] = "SUCCESS (Next AUTO_INCREMENT=$nextId)";
        } catch (\Throwable $e) {
            $logs[$table]['modify_auto_increment'] = 'ERROR: ' . $e->getMessage();
        }
    } else {
        $logs[$table]['modify_auto_increment'] = 'SKIPPED (VARCHAR PK)';
    }
}

// Verification Phase
$verification = [];
foreach ($tables as $table => $config) {
    $stmtCol = $pdo->prepare("
        SELECT COLUMN_NAME, COLUMN_TYPE, COLUMN_KEY, EXTRA 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = 'db_layanantik' AND TABLE_NAME = ? AND COLUMN_NAME = 'id'
    ");
    $stmtCol->execute([$table]);
    $colInfo = $stmtCol->fetch();

    $stmtTbl = $pdo->prepare("
        SELECT AUTO_INCREMENT 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA = 'db_layanantik' AND TABLE_NAME = ?
    ");
    $stmtTbl->execute([$table]);
    $tblInfo = $stmtTbl->fetch();

    $verification[$table] = [
        'column_key' => $colInfo['COLUMN_KEY'] ?? 'NONE',
        'extra' => $colInfo['EXTRA'] ?? 'NONE',
        'auto_increment' => $tblInfo['AUTO_INCREMENT'] ?? 'N/A',
        'status' => ($colInfo['COLUMN_KEY'] === 'PRI' && (!$config['auto'] || str_contains(strtolower($colInfo['EXTRA']), 'auto_increment'))) ? 'PASSED 🟢' : 'FAILED 🔴'
    ];
}

echo json_encode([
    'execution_logs' => $logs,
    'verification_results' => $verification
], JSON_PRETTY_PRINT) . "\n";
