<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class RoleController extends Controller
{
    /** GET /api/admin/roles */
    public function index()
    {
        $roles = Role::with('permissions')->get();
        return response()->json(['success' => true, 'data' => $roles]);
    }

    /** GET /api/admin/permissions */
    public function permissions()
    {
        $permissions = Permission::all();
        return response()->json(['success' => true, 'data' => $permissions]);
    }

    /** POST /api/admin/roles */
    public function store(Request $request)
    {
        $request->validate([
            'name'        => 'required|string|unique:roles,name',
            'permissions' => 'nullable|array',
        ]);

        $role = new Role();
        $role->name = $request->name;
        $role->guard_name = 'web';
        $role->save();

        if ($request->filled('permissions')) {
            try {
                $role->syncPermissions($request->permissions);
            } catch (\Spatie\Permission\Exceptions\PermissionDoesNotExist $e) {
                return response()->json(['success' => false, 'message' => $e->getMessage()], 422);
            }
        }

        return response()->json(['success' => true, 'message' => 'Role berhasil dibuat.', 'data' => $role->load('permissions')], 201);
    }

    /** GET /api/admin/roles/{id} */
    public function show($id)
    {
        $role = Role::with('permissions')->findOrFail($id);
        return response()->json(['success' => true, 'data' => $role]);
    }

    /** PUT /api/admin/roles/{id} */
    public function update(Request $request, $id)
    {
        $role = Role::findOrFail($id);

        $request->validate([
            'name'        => 'sometimes|string|unique:roles,name,' . $id,
            'permissions' => 'nullable|array',
        ]);

        if ($request->filled('name')) {
            $role->update(['name' => $request->name]);
        }

        if ($request->has('permissions')) {
            try {
                $role->syncPermissions($request->permissions);
            } catch (\Spatie\Permission\Exceptions\PermissionDoesNotExist $e) {
                return response()->json(['success' => false, 'message' => $e->getMessage()], 422);
            }
        }

        return response()->json(['success' => true, 'message' => 'Role berhasil diupdate.', 'data' => $role->load('permissions')]);
    }

    /** DELETE /api/admin/roles/{id} */
    public function destroy($id)
    {
        $role = Role::findOrFail($id);
        $role->delete();

        return response()->json(['success' => true, 'message' => 'Role berhasil dihapus.']);
    }
}
