<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$users = \App\Models\User::where('status', '1')->take(15)->get();
foreach ($users as $u) {
    echo "ID: {$u->id} | Email: {$u->email} | Name: {$u->name} | Status: {$u->status} | Roles: " . implode(', ', $u->getRoleNames()->toArray()) . "\n";
}
