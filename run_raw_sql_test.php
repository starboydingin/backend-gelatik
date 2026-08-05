<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

function runQuery($label, $sql) {
    echo "=== {$label} ===\n";
    echo "SQL: {$sql}\n";
    try {
        $result = DB::select($sql);
        echo json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) . "\n\n";
    } catch (\Exception $e) {
        echo "ERROR: " . $e->getMessage() . "\n\n";
    }
}

// LANGKAH 1
runQuery("SHOW CREATE TABLE tr_permintaan_pinjam", "SHOW CREATE TABLE tr_permintaan_pinjam");
runQuery("SHOW CREATE TABLE users", "SHOW CREATE TABLE users");
runQuery("SHOW CREATE TABLE usulan_email", "SHOW CREATE TABLE usulan_email");
runQuery("SHOW CREATE TABLE kritik_sarans", "SHOW CREATE TABLE kritik_sarans");

// LANGKAH 2
runQuery("SELECT id FROM tr_permintaan_pinjam ORDER BY id DESC LIMIT 5", "SELECT id FROM tr_permintaan_pinjam ORDER BY id DESC LIMIT 5");
runQuery("SELECT id FROM usulan_email ORDER BY id DESC LIMIT 5", "SELECT id FROM usulan_email ORDER BY id DESC LIMIT 5");

// LANGKAH 3
echo "=== TRANSACTION INSERT TEST (kritik_sarans) ===\n";
try {
    DB::beginTransaction();
    DB::insert("INSERT INTO kritik_sarans (user_id, kritik, saran, created_at, updated_at) VALUES (NULL, 'test verifikasi', 'test verifikasi', NOW(), NOW())");
    $lastId = DB::getPdo()->lastInsertId();
    echo "RESULT: SUCCESS\n";
    echo "LAST_INSERT_ID: " . $lastId . "\n";
    DB::rollBack();
    echo "TRANSACTION ROLLED BACK CLEANLY.\n";
} catch (\Exception $e) {
    DB::rollBack();
    echo "RESULT: FAILED\n";
    echo "ERROR MESSAGE: " . $e->getMessage() . "\n";
}
