<?php
$jsonPath = __DIR__ . '/../../layanantik-backend-api.postman_collection.json';
$data = json_decode(file_get_contents($jsonPath), true);

function searchItems($items, $depth = 0) {
    foreach ($items as $idx => $item) {
        $name = $item['name'] ?? '';
        echo str_repeat("  ", $depth) . "[$idx] " . $name . "\n";
        
        if (isset($item['item'])) {
            searchItems($item['item'], $depth + 1);
        } else if (isset($item['request'])) {
            $desc = $item['request']['description'] ?? '';
            $url = $item['request']['url']['raw'] ?? '';
            if (stripos($name, 'laporan') !== false || stripos($url, 'laporan') !== false || stripos($desc, 'bkd') !== false || stripos($name, 'bkd') !== false) {
                echo str_repeat("  ", $depth + 1) . "-> REQUEST URL: " . $url . "\n";
                echo str_repeat("  ", $depth + 1) . "-> DESC: " . substr(str_replace("\n", " ", $desc), 0, 100) . "...\n";
                if (!empty($item['response'])) {
                    echo str_repeat("  ", $depth + 1) . "-> RESPONSES COUNT: " . count($item['response']) . "\n";
                    foreach ($item['response'] as $rIdx => $resp) {
                        echo str_repeat("  ", $depth + 2) . "[$rIdx] " . ($resp['name'] ?? '') . " (Status: " . ($resp['code'] ?? '') . ")\n";
                    }
                }
            }
        }
    }
}

searchItems($data['item']);
