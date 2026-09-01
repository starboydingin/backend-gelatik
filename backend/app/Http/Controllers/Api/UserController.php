<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;

class UserController extends Controller
{
    /** GET /api/admin/users */
    public function index(Request $request)
    {
        $query = User::with('roles:id,name');

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('username', 'like', "%{$search}%");
            });
        }

        $users = $query->latest()->paginate(15);

        return response()->json(['success' => true, 'data' => $users]);
    }

    /** POST /api/admin/users (superadmin provisions an admin account) */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'username' => 'required|string|unique:users,username',
            'password' => 'required|string|min:6',
            'nama_opd' => 'nullable|string',
            'bandwidth_download_mbps' => 'nullable|integer|min:0|max:1000000',
            'bandwidth_upload_mbps' => 'nullable|integer|min:0|max:1000000',
        ]);

        $attributes = [
            'name' => $request->name,
            'email' => $request->email,
            'username' => $request->username,
            'password' => Hash::make($request->password),
            'status' => '1',
        ];
        if ($request->filled('nama_opd')) {
            $attributes['nama_opd'] = $request->nama_opd;
        }
        $attributes['bandwidth_download_mbps'] = $request->input('bandwidth_download_mbps');
        $attributes['bandwidth_upload_mbps'] = $request->input('bandwidth_upload_mbps');

        $user = User::create($attributes);

        $user->assignRole(Role::findByName('admin', 'web'));

        return response()->json([
            'success' => true,
            'message' => 'Akun admin berhasil dibuat.',
            'data' => $user->load('roles:id,name'),
        ], 201);
    }

    /** GET /api/admin/users/{id} */
    public function show($id)
    {
        $user = User::with('roles')->findOrFail($id);

        return response()->json(['success' => true, 'data' => $user]);
    }

    /** PUT /api/admin/users/{id} */
    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);
        $this->authorizeManagement($request, $user);

        if ($request->has('role') && ! $request->user()->hasRole('superadmin')) {
            abort(403, 'Hanya superadmin yang dapat mengubah role.');
        }

        $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,'.$id,
            'username' => 'sometimes|string|unique:users,username,'.$id,
            'password' => 'nullable|string|min:6',
            'role' => 'nullable|string|exists:roles,name|not_in:superadmin',
            'nama_opd' => 'nullable|string',
            'bandwidth_download_mbps' => 'nullable|integer|min:0|max:1000000',
            'bandwidth_upload_mbps' => 'nullable|integer|min:0|max:1000000',
            'status' => 'nullable|in:0,1',
        ]);

        $updateData = $request->only([
            'name',
            'email',
            'username',
            'nama_opd',
            'bandwidth_download_mbps',
            'bandwidth_upload_mbps',
            'status',
        ]);
        if ($request->filled('password')) {
            $updateData['password'] = Hash::make($request->password);
        }

        $user->update($updateData);

        if ($request->has('role')) {
            $user->syncRoles([$request->role]);
        }

        return response()->json(['success' => true, 'message' => 'User berhasil diupdate.', 'data' => $user]);
    }

    /** DELETE /api/admin/users/{id} */
    public function destroy(Request $request, $id)
    {
        $user = User::findOrFail($id);
        $this->authorizeManagement($request, $user);
        $user->delete();

        return response()->json(['success' => true, 'message' => 'User berhasil dihapus.']);
    }

    /** POST /api/admin/users/{id}/activate */
    public function activate(Request $request, $id)
    {
        $user = User::findOrFail($id);
        $this->authorizeManagement($request, $user);
        $user->update(['status' => '1']);

        return response()->json([
            'success' => true,
            'message' => 'User berhasil diaktivasi.',
            'data' => $user,
        ]);
    }

    /** POST /api/admin/users/{id}/deactivate */
    public function deactivate(Request $request, $id)
    {
        $user = User::findOrFail($id);
        $this->authorizeManagement($request, $user);
        $user->update(['status' => '0']);

        return response()->json([
            'success' => true,
            'message' => 'User berhasil dinonaktifkan.',
            'data' => $user,
        ]);
    }

    private function authorizeManagement(Request $request, User $target): void
    {
        if ($target->hasRole('superadmin')) {
            abort(403, 'Akun superadmin tidak dapat dikelola melalui endpoint ini.');
        }

        if ($target->hasRole('admin') && ! $request->user()->hasRole('superadmin')) {
            abort(403, 'Hanya superadmin yang dapat mengelola akun admin.');
        }
    }
}
