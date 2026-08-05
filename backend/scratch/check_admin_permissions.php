<?php
require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use App\Models\User;

echo "=== PERMISSION CHECK ===\n";
$permissionExists = Permission::where('name', 'list laporan')->exists();
echo "'list laporan' permission exists in DB: " . ($permissionExists ? 'YES' : 'NO') . "\n";

$superadmin = Role::where('name', 'superadmin')->first();
if ($superadmin) {
    $hasSuperadmin = $superadmin->hasPermissionTo('list laporan');
    echo "Role 'superadmin' has 'list laporan': " . ($hasSuperadmin ? 'YES' : 'NO') . "\n";
} else {
    echo "Role 'superadmin' not found.\n";
}

$admin = Role::where('name', 'admin')->first();
if ($admin) {
    $hasAdmin = $admin->hasPermissionTo('list laporan');
    echo "Role 'admin' has 'list laporan': " . ($hasAdmin ? 'YES' : 'NO') . "\n";
    echo "Role 'admin' current permissions: " . json_encode($admin->permissions->pluck('name')) . "\n";
} else {
    echo "Role 'admin' not found.\n";
}

$bkd = Role::where('name', 'bkd')->first();
if ($bkd) {
    $hasBkd = $bkd->hasPermissionTo('list laporan');
    echo "Role 'bkd' has 'list laporan': " . ($hasBkd ? 'YES' : 'NO') . "\n";
}

$userRole = Role::where('name', 'user')->first();
if ($userRole) {
    $hasUser = $userRole->hasPermissionTo('list laporan');
    echo "Role 'user' has 'list laporan': " . ($hasUser ? 'YES' : 'NO') . "\n";
}
