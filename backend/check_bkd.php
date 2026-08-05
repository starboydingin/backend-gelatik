<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use Spatie\Permission\Models\Role;

$u = User::where('email', 'bkd@lampungprov.go.id')->first();
$role = Role::firstOrCreate(['name' => 'bkd', 'guard_name' => 'web']);
$u->assignRole($role);

echo "Role 'bkd' assigned to User 10 (bkd@lampungprov.go.id).\n";
echo "Roles: " . json_encode($u->getRoleNames()) . "\n";
