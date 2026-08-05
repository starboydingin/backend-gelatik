<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class NewPermissionsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $newPermissions = [
            'list laporan',
            'export laporan',
            'manage notifikasi-wa',
        ];

        foreach ($newPermissions as $permName) {
            $existing = DB::table('permissions')->where('name', $permName)->first();
            if (!$existing) {
                $nextId = DB::table('permissions')->max('id') + 1;
                DB::table('permissions')->insert([
                    'id'         => $nextId,
                    'name'       => $permName,
                    'guard_name' => 'web',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }

        $superadminRole = Role::where('name', 'superadmin')->first();
        if ($superadminRole) {
            $superadminRole->givePermissionTo($newPermissions);
        }

        $adminRole = Role::where('name', 'admin')->first();
        if ($adminRole) {
            $adminRole->givePermissionTo($newPermissions);
        }
    }
}
