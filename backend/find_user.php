<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$users = \App\Models\User::take(5)->get();
foreach ($users as $u) {
    echo "ID: {$u->id} | Email: " . var_export($u->email, true) . "\n";
    $u->password = \Illuminate\Support\Facades\Hash::make('password123');
    $u->save();
}
