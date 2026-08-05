<?php
$jsonPath = __DIR__ . '/../../layanantik-backend-api.postman_collection.json';
$data = json_decode(file_get_contents($jsonPath), true);

function searchBkdAndLaporan($items, $path = '') {
    foreach ($items as $idx => $item) {
        $currentPath = $path . ' -> ' . ($item['name'] ?? '');
        if (isset($item['item'])) {
            searchBkdAndLaporan($item['item'], $currentPath);
        } else {
            $desc = $item['request']['description'] ?? '';
            $name = $item['name'] ?? '';
            if (stripos($desc, 'laporan') !== false && stripos($desc, 'bkd') !== false) {
                echo "MATCH IN DESC: " . $currentPath . "\n";
                echo "Desc snippet: " . $desc . "\n\n";
            }
            if (stripos($name, 'laporan') !== false && stripos($name, 'bkd') !== false) {
                echo "MATCH IN NAME: " . $currentPath . "\n\n";
            }
        }
    }
}

searchBkdAndLaporan($data['item']);
