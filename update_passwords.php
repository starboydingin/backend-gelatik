<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$count = \App\Models\User::where('status', '1')->update([
    'password' => \Illuminate\Support\Facades\Hash::make('password123')
]);

echo "Updated $count active users password to 'password123'\n";
