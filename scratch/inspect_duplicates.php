<?php
$pdo = new PDO("mysql:host=127.0.0.1;dbname=db_layanantik;charset=utf8mb4", "root", "", [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
]);

$tables = [
    'activity_log', 'chatbot_urls', 'faq', 'master_item', 'master_topik', 
    'm_settings', 'notification', 'oauth_access_tokens', 'oauth_clients', 
    'oauth_personal_access_clients', 'permissions', 'pinjam_item', 
    'sliders', 'unker_list_router', 'unker_router', 'users'
];

foreach ($tables as $table) {
    // Check if table has a unique column or duplicate rows
    $stmt = $pdo->query("SELECT * FROM `$table` WHERE id = (SELECT id FROM `$table` GROUP BY id HAVING COUNT(*) > 1 LIMIT 1)");
    $rows = $stmt->fetchAll();
    echo "=== TABLE: $table ===\n";
    echo json_encode($rows, JSON_PRETTY_PRINT) . "\n\n";
}
