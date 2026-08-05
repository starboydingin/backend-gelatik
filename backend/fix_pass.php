<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$user = \App\Models\User::where('email', 'diskominfotik@lampungprov.go.id')->first();
if ($user) {
    $user->password = \Illuminate\Support\Facades\Hash::make('password123');
    $user->save();
    echo "Saved user password for {$user->email}\n";
} else {
    echo "User not found\n";
}
