<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;

$u = User::find(1);
echo "User 1:\n";
echo "Roles: " . json_encode($u->getRoleNames()) . "\n";
echo "hasRole('admin'): " . ($u->hasRole('admin') ? 'YES' : 'NO') . "\n";
echo "hasPermissionTo('list laporan'): " . ($u->hasPermissionTo('list laporan') ? 'YES' : 'NO') . "\n";
echo "hasPermissionTo('list laporan', 'web'): " . ($u->hasPermissionTo('list laporan', 'web') ? 'YES' : 'NO') . "\n";
echo "hasPermissionTo('list laporan', 'api'): " . ($u->hasPermissionTo('list laporan', 'api') ? 'YES' : 'NO') . "\n";
echo "getAllPermissions: " . json_encode($u->getAllPermissions()->pluck('name')) . "\n";
