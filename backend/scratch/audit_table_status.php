<?php
require __DIR__ . '/../vendor/autoload.php';

$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

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
    if (!Schema::hasTable($table)) {
        $results[$table] = ['status' => 'TABLE NOT FOUND'];
        continue;
    }

    $colInfo = DB::select("
        SELECT COLUMN_NAME, COLUMN_TYPE, COLUMN_KEY, EXTRA 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = 'id'
    ", [$table]);

    $tblInfo = DB::select("
        SELECT AUTO_INCREMENT 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?
    ", [$table]);

    $maxId = null;
    try {
        $maxId = DB::table($table)->max('id');
    } catch (\Throwable $e) {
        $maxId = 'ERROR: ' . $e->getMessage();
    }

    $results[$table] = [
        'column_type' => $colInfo[0]->COLUMN_TYPE ?? 'N/A',
        'column_key' => $colInfo[0]->COLUMN_KEY ?? 'NONE',
        'extra' => $colInfo[0]->EXTRA ?? 'NONE',
        'auto_increment' => $tblInfo[0]->AUTO_INCREMENT ?? null,
        'max_id' => $maxId
    ];
}

echo json_encode($results, JSON_PRETTY_PRINT) . "\n";
