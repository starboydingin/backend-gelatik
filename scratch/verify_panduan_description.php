<?php

$colPath = __DIR__ . '/../../layanantik-backend-api.postman_collection.json';
$colJson = json_decode(file_get_contents($colPath), true);

$panduanReq = $colJson['item'][0]['item'][0];
echo "NAME: " . $panduanReq['name'] . "\n";
echo "DESCRIPTION:\n";
echo $panduanReq['request']['description'] . "\n";
