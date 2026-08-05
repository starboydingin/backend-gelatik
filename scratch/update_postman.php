<?php
$jsonPath = __DIR__ . '/../../layanantik-backend-api.postman_collection.json';
$rawContent = file_get_contents($jsonPath);
$data = json_decode($rawContent, true);

if (!$data) {
    die("Failed to decode JSON!\n");
}

// Find item 15: "15 - Fitur Baru - Laporan (F-LAPORAN)" -> "GET Laporan Rekapitulasi Peminjaman Aset"
$updated = false;
foreach ($data['item'] as &$folder) {
    if (isset($folder['name']) && strpos($folder['name'], '15 - Fitur Baru - Laporan') !== false) {
        foreach ($folder['item'] as &$reqItem) {
            if (isset($reqItem['name']) && strpos($reqItem['name'], 'GET Laporan Rekapitulasi Peminjaman Aset') !== false) {
                // Update description
                $newDesc = "Fungsi: Fitur Baru F-LAPORAN: Mengambil laporan rekapitulasi data peminjaman aset TIK.\nPermission/Role: Hanya dapat diakses oleh role admin dan superadmin. Role user dan bkd akan menerima 403 Forbidden.\nCatatan: Mendukung filter query string 'bulan' dan 'tahun' atau 'filter' dan 'tanggal'.";
                $reqItem['request']['description'] = $newDesc;

                // Set response examples
                $reqItem['response'] = [
                    [
                        "name" => "200 OK - Admin / Superadmin",
                        "originalRequest" => [
                            "method" => "GET",
                            "header" => [
                                [
                                    "key" => "Accept",
                                    "value" => "application/json",
                                    "type" => "text"
                                ]
                            ],
                            "url" => [
                                "raw" => "{{base_url}}/laporan/peminjaman?filter=bulanan&tanggal=2026-07",
                                "host" => ["{{base_url}}"],
                                "path" => ["laporan", "peminjaman"],
                                "query" => [
                                    ["key" => "filter", "value" => "bulanan"],
                                    ["key" => "tanggal", "value" => "2026-07"]
                                ]
                            ]
                        ],
                        "status" => "OK",
                        "code" => 200,
                        "_postman_previewlanguage" => "json",
                        "header" => [
                            ["key" => "Content-Type", "value" => "application/json"]
                        ],
                        "cookie" => [],
                        "body" => json_encode([
                            "success" => true,
                            "data" => [
                                "periode" => "2026-07",
                                "filter" => "bulanan",
                                "total_peminjaman" => 15,
                                "status_summary" => [
                                    "Menunggu" => 3,
                                    "Disetujui" => 8,
                                    "Ditolak" => 2,
                                    "Selesai" => 2
                                ],
                                "item_terbanyak_dipinjam" => []
                            ]
                        ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES)
                    ],
                    [
                        "name" => "403 Forbidden - Role BKD / User",
                        "originalRequest" => [
                            "method" => "GET",
                            "header" => [
                                [
                                    "key" => "Accept",
                                    "value" => "application/json",
                                    "type" => "text"
                                ]
                            ],
                            "url" => [
                                "raw" => "{{base_url}}/laporan/peminjaman?filter=bulanan&tanggal=2026-07",
                                "host" => ["{{base_url}}"],
                                "path" => ["laporan", "peminjaman"],
                                "query" => [
                                    ["key" => "filter", "value" => "bulanan"],
                                    ["key" => "tanggal", "value" => "2026-07"]
                                ]
                            ]
                        ],
                        "status" => "Forbidden",
                        "code" => 403,
                        "_postman_previewlanguage" => "json",
                        "header" => [
                            ["key" => "Content-Type", "value" => "application/json"]
                        ],
                        "cookie" => [],
                        "body" => json_encode([
                            "error" => "Unauthorized"
                        ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES)
                    ]
                ];
                $updated = true;
                echo "Successfully updated request description and response examples.\n";
            }
        }
    }
}

if (!$updated) {
    die("Request item not found!\n");
}

$newJson = json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
file_put_contents($jsonPath, $newJson);
echo "Postman collection file written successfully.\n";

// Validate JSON syntax
$checkData = json_decode(file_get_contents($jsonPath), true);
if ($checkData !== null && json_last_error() === JSON_ERROR_NONE) {
    echo "VALIDATION PASSED: Postman collection JSON is valid.\n";
} else {
    echo "VALIDATION FAILED: JSON error - " . json_last_error_msg() . "\n";
}
