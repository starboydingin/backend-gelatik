<?php
require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Role;

$maxId = DB::table('users')->max('id');
echo "Max User ID: {$maxId}\n";

function getOrCreateUserWithRole($roleName, $email, $name) {
    $user = User::where('email', $email)->first();
    if (!$user) {
        $nextId = (int) DB::table('users')->max('id') + 1;
        $user = new User();
        $user->id = $nextId;
        $user->name = $name;
        $user->username = strstr($email, '@', true) . '_' . rand(1000, 9999);
        $user->email = $email;
        $user->password = bcrypt('password123');
        $user->status = '1';
        $user->save();
    }
    
    $role = Role::firstOrCreate(['name' => $roleName, 'guard_name' => 'web']);
    if (!$user->hasRole($roleName)) {
        $user->assignRole($role);
    }
    return $user;
}

$userNormal = getOrCreateUserWithRole('user', 'test_user_normal@example.com', 'Test User Normal');
$userBkd    = getOrCreateUserWithRole('bkd', 'test_user_bkd@example.com', 'Test User BKD');
$userAdmin  = getOrCreateUserWithRole('admin', 'test_user_admin@example.com', 'Test User Admin');
$userSuper  = getOrCreateUserWithRole('superadmin', 'test_user_superadmin@example.com', 'Test User Superadmin');

$controller = app()->make(\App\Http\Controllers\Api\LaporanController::class);

$testCases = [
    'User biasa (role: user)' => $userNormal,
    'User BKD (role: bkd)' => $userBkd,
    'User Admin (role: admin)' => $userAdmin,
    'User Superadmin (role: superadmin)' => $userSuper,
];

echo "=========================================================\n";
echo "TEST AUTHORIZATION GET /api/laporan/peminjaman (BEFORE CHANGE)\n";
echo "=========================================================\n";

foreach ($testCases as $label => $u) {
    $req = Request::create('/api/laporan/peminjaman', 'GET', [
        'filter' => 'bulanan',
        'tanggal' => '2026-07'
    ]);
    $req->setUserResolver(fn() => $u);
    
    $response = $controller->peminjaman($req);
    $status = $response->getStatusCode();
    echo sprintf("%-40s => HTTP Status: %d (%s)\n", $label, $status, $status === 200 ? 'ALLOWED' : 'FORBIDDEN (403)');
}
