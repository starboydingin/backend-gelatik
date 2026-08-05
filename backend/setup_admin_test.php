<?php
/**
 * Setup admin user for investigation testing.
 * Run standalone: php setup_admin_test.php
 */

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use App\Models\UsulanEmail;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use Illuminate\Support\Facades\DB;

echo "=== SETUP ADMIN USER FOR TESTING ===\n\n";

// 1. Activate superadmin
$user = User::find(1);
$user->update(['status' => '1']);
echo "1. User id=1 status set to '1' (active)\n";

// 2. Create admin role if not exists
$role = Role::where('name', 'admin')->where('guard_name', 'web')->first();
if (!$role) {
    $maxRoleId = DB::table('roles')->max('id') + 1;
    DB::table('roles')->insert([
        'id' => $maxRoleId,
        'name' => 'admin',
        'guard_name' => 'web',
        'created_at' => now(),
        'updated_at' => now(),
    ]);
    $role = Role::find($maxRoleId);
    echo "2. Created admin role id={$role->id}\n";
} else {
    echo "2. Admin role already exists id={$role->id}\n";
}

// 3. Get all unique permission names
$perms = Permission::where('guard_name', 'web')
    ->pluck('name')
    ->unique()
    ->values()
    ->toArray();
echo "3. Total unique permissions: " . count($perms) . "\n";

// 4. Sync all permissions to admin role
$role->syncPermissions($perms);
echo "4. Synced all permissions to admin role\n";

// 5. Assign admin role to user
$user->syncRoles(['admin']);
echo "5. Assigned admin role to user id=1\n";

// 6. Create a fresh UsulanEmail with status 'diajukan' for testing
$existing = UsulanEmail::where('status', 'diajukan')->first();
if (!$existing) {
    $maxId = DB::table('usulan_email')->max('id') + 1;
    UsulanEmail::create([
        'id' => $maxId,
        'id_peg_bkd' => 51512,
        'email_pribadi' => 'test.investigasi@gmail.com',
        'status' => 'diajukan',
        'created_by' => 1,
    ]);
    echo "6. Created UsulanEmail id={$maxId} with status='diajukan'\n";
} else {
    echo "6. UsulanEmail with status='diajukan' already exists (id={$existing->id})\n";
}

echo "\n=== SETUP COMPLETE ===\n";
