<?php
/**
 * Refined Audit Script for ALL 39 database tables.
 */

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

$sqlFile = __DIR__ . '/db_layanantik.sql';
$sqlContent = file_get_contents($sqlFile);

echo "=== AUDIT SCHEMA PRESISI: DUMP ASLI (db_layanantik.sql) VS DATABASE AKTUAL ===\n\n";

// 1. Find all PRIMARY KEYs in dump (in ALTER TABLE statements)
preg_match_all('/ALTER TABLE `([^`]+)`\s+ADD PRIMARY KEY \(([^)]+)\)/i', $sqlContent, $pkMatches, PREG_SET_ORDER);

$dumpPrimaryKeys = [];
foreach ($pkMatches as $m) {
    $table = $m[1];
    $cols = str_replace('`', '', $m[2]);
    $dumpPrimaryKeys[$table] = $cols;
}

// 2. Find all AUTO_INCREMENTs in dump (in ALTER TABLE statements)
preg_match_all('/ALTER TABLE `([^`]+)`\s+MODIFY `([^`]+)` [^;\n]*AUTO_INCREMENT/i', $sqlContent, $aiMatches, PREG_SET_ORDER);

$dumpAutoIncrements = [];
foreach ($aiMatches as $m) {
    $table = $m[1];
    $col = $m[2];
    $dumpAutoIncrements[$table] = $col;
}

// 3. Query actual database structure
$actualColumns = DB::select("
    SELECT TABLE_NAME, COLUMN_NAME, COLUMN_KEY, EXTRA 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'db_layanantik' 
    AND COLUMN_NAME = 'id'
    ORDER BY TABLE_NAME
");

$actualMap = [];
foreach ($actualColumns as $row) {
    $actualMap[$row->TABLE_NAME] = [
        'column' => $row->COLUMN_NAME,
        'key' => $row->COLUMN_KEY,
        'extra' => $row->EXTRA
    ];
}

$allTables = DB::select("
    SELECT TABLE_NAME 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'db_layanantik'
    ORDER BY TABLE_NAME
");

echo sprintf("%-30s | %-25s | %-25s | %s\n", "NAMA TABEL", "DUMP ASLI (PK/AI)", "DB AKTUAL (KEY/EXTRA)", "STATUS");
echo str_repeat("-", 95) . "\n";

$issuesCount = 0;

foreach ($allTables as $tRow) {
    $table = $tRow->TABLE_NAME;
    
    $shouldHavePk = isset($dumpPrimaryKeys[$table]) && strpos($dumpPrimaryKeys[$table], 'id') !== false;
    $shouldHaveAi = isset($dumpAutoIncrements[$table]) && $dumpAutoIncrements[$table] === 'id';
    
    $dumpExpectation = ($shouldHavePk ? "PK" : "NO PK") . " + " . ($shouldHaveAi ? "AI" : "NO AI");
    
    if (isset($actualMap[$table])) {
        $actKey = $actualMap[$table]['key'] ?: 'NONE';
        $actExtra = $actualMap[$table]['extra'] ?: 'NONE';
        $actualState = "KEY: {$actKey} / EXTRA: {$actExtra}";
        
        $hasPkInDb = ($actKey === 'PRI');
        $hasAiInDb = (strpos(strtolower($actExtra), 'auto_increment') !== false);
        
        $isOk = true;
        if ($shouldHavePk && !$hasPkInDb) {
            $isOk = false;
        }
        if ($shouldHaveAi && !$hasAiInDb) {
            $isOk = false;
        }
        
        $status = $isOk ? "OK" : "⚠️ BERMASALAH";
        if (!$isOk) $issuesCount++;
    } else {
        $actualState = "NO 'id' COLUMN";
        $status = "PIVOT / NON-ID";
    }
    
    echo sprintf("%-30s | %-25s | %-25s | %s\n", $table, $dumpExpectation, $actualState, $status);
}

echo str_repeat("-", 95) . "\n";
echo "Total Tabel: " . count($allTables) . " | Total Tabel Bermasalah: {$issuesCount}\n";
