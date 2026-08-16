<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;

class LocalProvisioningController extends Controller
{
    /**
     * POST /api/dev/provision-account
     *
     * Development-only account bootstrap for local demos and tests. This is
     * intentionally unavailable outside local/testing environments and must
     * be protected by a key that is never committed to source control.
     */
    public function store(Request $request)
    {
        abort_unless(app()->environment('local', 'testing'), 404);

        $expectedKey = (string) config('services.local_provision.key');
        abort_unless(
            $expectedKey !== '' && hash_equals($expectedKey, (string) $request->header('X-Local-Provision-Key')),
            403,
            'Local provisioning key tidak valid.'
        );

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'username' => 'required|string|max:255|unique:users,username',
            'password' => 'required|string|min:8',
            'nama_opd' => 'nullable|string|max:255',
            'role' => 'required|in:admin,superadmin',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'username' => $validated['username'],
            'password' => Hash::make($validated['password']),
            'nama_opd' => $validated['nama_opd'] ?? null,
            'status' => '1',
        ]);

        $user->assignRole(Role::findOrCreate($validated['role'], 'web'));

        return response()->json([
            'success' => true,
            'message' => 'Akun development berhasil dibuat.',
            'data' => $user->load('roles:id,name'),
        ], 201);
    }
}
