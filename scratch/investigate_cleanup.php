<?php

$sqlFilePath = __DIR__ . '/../db_layanantik.sql';
$pdo = new PDO("mysql:host=127.0.0.1;dbname=db_layanantik;charset=utf8mb4", "root", "", [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
]);

echo "=== MEMBACA DB_LAYANANTIK.SQL ===\n";

$sqlContent = file_get_contents($sqlFilePath);

// Function to parse INSERT statements for a table
function getDumpRowsForTable($sqlContent, $table) {
    // Match INSERT INTO `table` ... VALUES (...);
    $pattern = '/INSERT INTO `' . preg_quote($table, '/') . '` \([^)]+\) VALUES\s*(.*?);/s';
    if (!preg_match_all($pattern, $sqlContent, $matches)) {
        return [];
    }
    
    // Also get column names
    $colPattern = '/INSERT INTO `' . preg_quote($table, '/') . '` \(([^)]+)\) VALUES/';
    preg_match($colPattern, $sqlContent, $colMatch);
    $cols = [];
    if (!empty($colMatch[1])) {
        $cols = array_map(function($c) { return trim($c, "` "); }, explode(',', $colMatch[1]));
    }

    $rows = [];
    foreach ($matches[1] as $valuesBlock) {
        // Split by tuple: (...), (...)
        // Simple regex parser for values tuple
        preg_match_all('/\((?>[^()]+|\([^()]*\))*\)/s', $valuesBlock, $tupleMatches);
        foreach ($tupleMatches[0] as $tuple) {
            $tupleStr = trim($tuple, "()");
            // Parse CSV-like values
            $values = str_getcsv($tupleStr, ',', "'", "\\");
            if (count($cols) === count($values)) {
                $rows[] = array_combine($cols, $values);
            } else {
                $rows[] = ['raw' => $tupleStr, 'parsed_values' => $values];
            }
        }
    }
    return ['cols' => $cols, 'rows' => $rows];
}

// Get list of all tables in current DB
$tablesStmt = $pdo->query("SHOW TABLES");
$allTables = $tablesStmt->fetchAll(PDO::FETCH_COLUMN);

$report = [];

foreach ($allTables as $table) {
    // Get row count in current DB
    $currentCount = (int)$pdo->query("SELECT COUNT(*) FROM `$table`")->fetchColumn();
    
    // Parse dump
    $dumpData = getDumpRowsForTable($sqlContent, $table);
    $dumpRows = $dumpData['rows'] ?? [];
    $dumpCount = count($dumpRows);
    
    // Check duplicate IDs in dump
    $idGroups = [];
    foreach ($dumpRows as $idx => $r) {
        $id = $r['id'] ?? null;
        if ($id !== null) {
            $idGroups[$id][] = $r;
        }
    }
    
    $duplicateIds = [];
    $duplicateRowsCount = 0;
    $diffColumnsFound = [];
    
    foreach ($idGroups as $id => $group) {
        if (count($group) > 1) {
            $duplicateIds[$id] = count($group);
            $duplicateRowsCount += (count($group) - 1);
            
            // Check if all rows in group are identical
            $first = $group[0];
            for ($i = 1; $i < count($group); $i++) {
                $diff = array_diff_assoc($first, $group[$i]);
                if (!empty($diff)) {
                    $diffColumnsFound[$id] = array_keys($diff);
                }
            }
        }
    }
    
    $report[$table] = [
        'dump_count' => $dumpCount,
        'current_count' => $currentCount,
        'duplicate_id_groups' => count($duplicateIds),
        'deleted_rows_calculated' => $duplicateRowsCount,
        'diff_rows_with_other_columns' => count($diffColumnsFound),
        'diff_column_details' => $diffColumnsFound,
        'duplicate_ids' => $duplicateIds,
        'sample_duplicates' => []
    ];

    // Collect sample duplicates
    if (!empty($duplicateIds)) {
        $sampleCount = 0;
        foreach ($duplicateIds as $id => $cnt) {
            $report[$table]['sample_duplicates'][$id] = $idGroups[$id];
            $sampleCount++;
            if ($sampleCount >= 2) break; // max 2 sample IDs per table
        }
    }
}

file_put_contents(__DIR__ . '/investigation_report.json', json_encode($report, JSON_PRETTY_PRINT));
echo "Investigasi selesai. Output disimpan di scratch/investigation_report.json\n";
