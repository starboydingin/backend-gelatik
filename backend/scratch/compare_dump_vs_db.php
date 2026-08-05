<?php

$sqlFilePath = __DIR__ . '/../db_layanantik.sql';
$sqlContent = file_get_contents($sqlFilePath);

$pdo = new PDO("mysql:host=127.0.0.1;dbname=db_layanantik;charset=utf8mb4", "root", "", [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
]);

// Count INSERT rows in db_layanantik.sql for each table
$dumpCounts = [];

$tablesStmt = $pdo->query("SHOW TABLES");
$tables = $tablesStmt->fetchAll(PDO::FETCH_COLUMN);

foreach ($tables as $table) {
    // Match INSERT INTO `table` ...
    $pattern = '/INSERT INTO `' . preg_quote($table, '/') . '` \([^)]+\) VALUES\s*(.*?);/s';
    if (preg_match_all($pattern, $sqlContent, $matches)) {
        $count = 0;
        foreach ($matches[1] as $valuesBlock) {
            // Count tuples by commas outside quotes or parenthesis matching
            preg_match_all('/\((?>[^()]+|\([^()]*\))*\)/s', $valuesBlock, $tupleMatches);
            $count += count($tupleMatches[0]);
        }
        $dumpCounts[$table] = $count;
    } else {
        $dumpCounts[$table] = 0; // No INSERT in dump
    }
}

echo "=========================================================================================\n";
echo "PERBANDINGAN JUMLAH BARIS: ORIGINAL SQL DUMP (db_layanantik.sql) VS DATABASE SAAT INI (MySQL)\n";
echo "=========================================================================================\n\n";

printf("%-32s | %-18s | %-18s | %-12s\n", "Nama Tabel", "Original Dump (.sql)", "DB Saat Ini (MySQL)", "Selisih (+/-)");
echo str_repeat("-", 88) . "\n";

$totalDump = 0;
$totalCurrent = 0;

foreach ($tables as $table) {
    $dCount = $dumpCounts[$table] ?? 0;
    $cCount = (int)$pdo->query("SELECT COUNT(*) FROM `$table`")->fetchColumn();
    $diff = $cCount - $dCount;
    
    $totalDump += $dCount;
    $totalCurrent += $cCount;
    
    $diffStr = ($diff > 0) ? "+$diff" : "$diff";
    printf("%-32s | %-18d | %-18d | %-12s\n", $table, $dCount, $cCount, $diffStr);
}

echo str_repeat("-", 88) . "\n";
printf("%-32s | %-18d | %-18d | %-12s\n", "TOTAL SELURUH TABEL", $totalDump, $totalCurrent, (($totalCurrent - $totalDump) > 0 ? "+".($totalCurrent - $totalDump) : ($totalCurrent - $totalDump)));
