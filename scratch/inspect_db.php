<?php
require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

echo "=== USER LIST & ROLES ===\n";
$users = User::all();
foreach ($users as $u) {
    echo "ID: {$u->id} | Email: {$u->email} | Name: {$u->name} | Roles: " . implode(', ', $u->getRoleNames()->toArray()) . "\n";
}

echo "\n=== ROLES & PERMISSIONS ===\n";
$roles = Role::all();
foreach ($roles as $r) {
    echo "Role: {$r->name} (guard: {$r->guard_name}) -> Permissions: " . implode(', ', $r->permissions->pluck('name')->toArray()) . "\n";
}
