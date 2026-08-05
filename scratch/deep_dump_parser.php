<?php

$sqlFilePath = __DIR__ . '/../db_layanantik.sql';
$sqlContent = file_get_contents($sqlFilePath);

// Find all CREATE TABLE and INSERT INTO blocks
$lines = explode("\n", $sqlContent);

$currentTable = null;
$tableInserts = [];
$tableSchemas = [];

foreach ($lines as $lineNum => $line) {
    $trimmed = trim($line);
    if (str_starts_with($trimmed, "CREATE TABLE")) {
        if (preg_match('/CREATE TABLE `([^`]+)`/', $trimmed, $m)) {
            $currentTable = $m[1];
            $tableSchemas[$currentTable] = [];
        }
    }
    
    if (str_starts_with($trimmed, "INSERT INTO")) {
        if (preg_match('/INSERT INTO `([^`]+)` \(([^)]+)\) VALUES/', $trimmed, $m)) {
            $tableName = $m[1];
            $cols = array_map(function($c) { return trim($c, "` "); }, explode(',', $m[2]));
            $tableInserts[$tableName]['cols'] = $cols;
            if (!isset($tableInserts[$tableName]['values_lines'])) {
                $tableInserts[$tableName]['values_lines'] = [];
            }
            $tableInserts[$tableName]['values_lines'][] = $trimmed;
        }
    }
}

// Now let's parse values for each table
$report = [];

foreach ($tableInserts as $table => $data) {
    $cols = $data['cols'];
    $idIdx = array_search('id', $cols);
    
    $rows = [];
    $idCounts = [];
    $idRows = [];
    
    // Combine all insert lines for this table
    $fullInsert = implode(" ", $data['values_lines']);
    // Extract everything after VALUES
    $valuesStr = preg_replace('/^.*?VALUES\s*/s', '', $fullInsert);
    // Remove trailing semicolon
    $valuesStr = rtrim($valuesStr, ';');
    
    // Parse tuples safely
    // Match tuples like (...)
    // Note: handle nested quotes and commas
    $tuples = [];
    $len = strlen($valuesStr);
    $inTuple = false;
    $inQuote = false;
    $quoteChar = null;
    $escaped = false;
    $currentTuple = '';

    for ($i = 0; $i < $len; $i++) {
        $char = $valuesStr[$i];
        
        if ($inQuote) {
            $currentTuple .= $char;
            if ($escaped) {
                $escaped = false;
            } elseif ($char === '\\') {
                $escaped = true;
            } elseif ($char === $quoteChar) {
                $inQuote = false;
            }
        } else {
            if ($char === "'" || $char === '"') {
                $inQuote = true;
                $quoteChar = $char;
                $currentTuple .= $char;
            } elseif ($char === '(') {
                $inTuple = true;
                $currentTuple = '';
            } elseif ($char === ')') {
                if ($inTuple) {
                    $tuples[] = $currentTuple;
                    $inTuple = false;
                }
            } else {
                if ($inTuple) {
                    $currentTuple .= $char;
                }
            }
        }
    }

    foreach ($tuples as $tupleStr) {
        $values = str_getcsv($tupleStr, ',', "'", "\\");
        if (count($values) === count($cols)) {
            $rowObj = array_combine($cols, $values);
            $rows[] = $rowObj;
            $idVal = $rowObj['id'] ?? null;
            if ($idVal !== null) {
                if (!isset($idCounts[$idVal])) {
                    $idCounts[$idVal] = 0;
                    $idRows[$idVal] = [];
                }
                $idCounts[$idVal]++;
                $idRows[$idVal][] = $rowObj;
            }
        }
    }

    $dupGroups = array_filter($idCounts, fn($c) => $c > 1);
    
    $report[$table] = [
        'total_rows_in_dump' => count($rows),
        'unique_ids' => count($idCounts),
        'duplicate_id_count' => count($dupGroups),
        'dup_groups' => []
    ];

    foreach ($dupGroups as $dupId => $cnt) {
        // Check if all rows for this dupId are identical or different
        $firstRow = $idRows[$dupId][0];
        $isIdentical = true;
        $diffCols = [];

        for ($k = 1; $k < count($idRows[$dupId]); $k++) {
            $otherRow = $idRows[$dupId][$k];
            $diff = array_diff_assoc($firstRow, $otherRow);
            if (!empty($diff)) {
                $isIdentical = false;
                $diffCols = array_unique(array_merge($diffCols, array_keys($diff)));
            }
        }

        $report[$table]['dup_groups'][$dupId] = [
            'count' => $cnt,
            'is_identical' => $isIdentical,
            'diff_cols' => $diffCols,
            'rows' => $idRows[$dupId]
        ];
    }
}

file_put_contents(__DIR__ . '/dump_dup_analysis.json', json_encode($report, JSON_PRETTY_PRINT));
echo "ANALISIS DUMP SELESAI!\n";

$dupTablesCount = 0;
foreach ($report as $table => $data) {
    if ($data['duplicate_id_count'] > 0) {
        $dupTablesCount++;
        echo "TABEL: $table | Total Rows: {$data['total_rows_in_dump']} | Unique IDs: {$data['unique_ids']} | Dup ID Groups: {$data['duplicate_id_count']}\n";
    }
}
echo "Total Tabel Terkena Duplikasi di dump: $dupTablesCount\n";
