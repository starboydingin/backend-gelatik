<?php
$jsonPath = __DIR__ . '/../../layanantik-backend-api.postman_collection.json';
$data = json_decode(file_get_contents($jsonPath), true);

echo "=== 00 - PANDUAN PENGGUNAAN ===\n";
$panduanDesc = $data['item'][0]['item'][0]['request']['description'];
echo "Description:\n" . $panduanDesc . "\n\n";

echo "=== 15 - Fitur Baru - Laporan (F-LAPORAN) ===\n";
$laporanItem = $data['item'][16]['item'][0];
echo "Name: " . $laporanItem['name'] . "\n";
echo "Description:\n" . $laporanItem['request']['description'] . "\n\n";

echo "Responses count: " . count($laporanItem['response']) . "\n";
foreach ($laporanItem['response'] as $idx => $resp) {
    echo "--- Response [$idx] ---\n";
    echo "Name: " . $resp['name'] . "\n";
    echo "Status code: " . $resp['code'] . "\n";
    echo "Status text: " . $resp['status'] . "\n";
    echo "Body:\n" . $resp['body'] . "\n";
}
