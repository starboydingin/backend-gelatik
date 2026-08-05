<?php
require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

echo "=== ROLES IN TABLE ===\n";
$roles = DB::table('roles')->get();
foreach ($roles as $r) {
    echo "ID: {$r->id} | Name: {$r->name} | Guard: {$r->guard_name}\n";
}
