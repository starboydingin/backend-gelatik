<?php

$json = json_decode(file_get_contents(__DIR__ . '/dump_dup_analysis.json'), true);
foreach ($json as $table => $data) {
    if ($data['duplicate_id_count'] > 0) {
        echo "Table: $table, Dup Groups: " . json_encode($data['dup_groups']) . "\n";
    }
}
