<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Services\RealtimeDataSyncService;

class SettingController extends Controller
{
    /** GET /api/admin/settings */
    public function index()
    {
        $settings = DB::table('m_settings')->get();
        return response()->json(['success' => true, 'data' => $settings]);
    }

    /** PUT /api/admin/settings */
    public function update(Request $request)
    {
        $request->validate([
            'settings'                 => 'required_without:setting_name|array',
            'settings.*.setting_name'  => 'required_with:settings|string',
            'settings.*.setting_val'   => 'nullable|string',
            'setting_name'             => 'required_without:settings|string',
            'setting_val'              => 'nullable|string',
        ]);

        if ($request->has('settings')) {
            foreach ($request->settings as $item) {
                DB::table('m_settings')
                    ->where('setting_name', $item['setting_name'])
                    ->update(['setting_val' => $item['setting_val'], 'updated_at' => now()]);
            }
        } else {
            DB::table('m_settings')
                ->where('setting_name', $request->setting_name)
                ->update(['setting_val' => $request->setting_val, 'updated_at' => now()]);
        }

        $settings = DB::table('m_settings')->get();
        app(RealtimeDataSyncService::class)->admins('settings', 1);

        return response()->json([
            'success' => true,
            'message' => 'Pengaturan sistem berhasil diupdate.',
            'data'    => $settings,
        ]);
    }
}
