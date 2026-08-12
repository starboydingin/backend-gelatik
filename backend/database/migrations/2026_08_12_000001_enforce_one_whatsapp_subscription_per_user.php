<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('whatsapp_subscriptions')) {
            return;
        }

        // Preserve the newest setting if a pre-existing database contains
        // duplicate rows from an older schema without a unique constraint.
        DB::table('whatsapp_subscriptions')
            ->select('user_id')
            ->groupBy('user_id')
            ->havingRaw('COUNT(*) > 1')
            ->pluck('user_id')
            ->each(function ($userId): void {
                $latestId = DB::table('whatsapp_subscriptions')
                    ->where('user_id', $userId)
                    ->orderByDesc('updated_at')
                    ->orderByDesc('id')
                    ->value('id');

                DB::table('whatsapp_subscriptions')
                    ->where('user_id', $userId)
                    ->where('id', '!=', $latestId)
                    ->delete();
            });

        Schema::table('whatsapp_subscriptions', function ($table): void {
            $table->unique('user_id', 'whatsapp_subscriptions_user_id_unique');
        });
    }

    public function down(): void
    {
        if (Schema::hasTable('whatsapp_subscriptions')) {
            Schema::table('whatsapp_subscriptions', function ($table): void {
                $table->dropUnique('whatsapp_subscriptions_user_id_unique');
            });
        }
    }
};
