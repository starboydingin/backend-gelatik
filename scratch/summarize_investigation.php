<?php

$json = json_decode(file_get_contents(__DIR__ . '/investigation_report.json'), true);

echo "======================================================================\n";
echo "SUMMARY CLEAN-UP DUPLIKASI BARIS (INVESTIGASI RAW SQL DUMP VS DB)\n";
echo "======================================================================\n\n";

printf("%-30s | %-10s | %-15s | %-12s | %-12s | %-15s\n", 
    "Nama Tabel", "Dump Rows", "Current Rows", "Group Dupl", "Rows Dihapus", "Beda Kolom?");
echo str_repeat("-", 108) . "\n";

$totalDeleted = 0;
$tablesWithDups = [];

foreach ($json as $table => $data) {
    if ($data['duplicate_id_groups'] > 0 || $data['dump_count'] != $data['current_count']) {
        $tablesWithDups[$table] = $data;
        $totalDeleted += $data['deleted_rows_calculated'];
        printf("%-30s | %-10d | %-15d | %-12d | %-12d | %-15s\n",
            $table,
            $data['dump_count'],
            $data['current_count'],
            $data['duplicate_id_groups'],
            $data['deleted_rows_calculated'],
            ($data['diff_rows_with_other_columns'] > 0 ? "YA (BEDA!)" : "TIDAK (IDENTIK)")
        );
    }
}

echo str_repeat("-", 108) . "\n";
echo "Total Tabel Terkena Deduplikasi: " . count($tablesWithDups) . "\n";
echo "Total Baris Dihapus: $totalDeleted\n\n";

echo "======================================================================\n";
echo "CONTOH KONKRET SAMPLE DUPLIKAT DARI 3 TABEL DIFFERENT\n";
echo "======================================================================\n\n";

$count = 0;
foreach ($tablesWithDups as $table => $data) {
    if ($count >= 5) break;
    echo "--- TABEL: $table ---\n";
    foreach ($data['sample_duplicates'] as $id => $rows) {
        echo "Group ID: $id (Total " . count($rows) . " baris dalam dump):\n";
        foreach ($rows as $idx => $r) {
            echo "  Row #" . ($idx+1) . ": " . json_encode($r) . "\n";
        }
        echo "\n";
    }
    $count++;
}
