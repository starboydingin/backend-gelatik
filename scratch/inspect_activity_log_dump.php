<?php

$json = json_decode(file_get_contents(__DIR__ . '/dump_dup_analysis.json'), true);
if (isset($json['activity_log']['dup_groups'][1])) {
    echo "=== ACTIVITY_LOG ID 1 IN DUMP ===\n";
    foreach ($json['activity_log']['dup_groups'][1]['rows'] as $idx => $r) {
        echo "Row #" . ($idx + 1) . ": " . json_encode($r) . "\n";
    }
}
