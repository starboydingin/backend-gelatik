<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('kritik_sarans', function (Blueprint $table): void {
            $table->index(['user_id', 'created_at'], 'kritik_sarans_user_created_idx');
        });

        Schema::table('notification', function (Blueprint $table): void {
            $table->index(['user_id', 'id'], 'notification_user_id_id_idx');
            $table->index(['user_id', 'read'], 'notification_user_read_idx');
        });
    }

    public function down(): void
    {
        Schema::table('kritik_sarans', function (Blueprint $table): void {
            $table->dropIndex('kritik_sarans_user_created_idx');
        });

        Schema::table('notification', function (Blueprint $table): void {
            $table->dropIndex('notification_user_id_id_idx');
            $table->dropIndex('notification_user_read_idx');
        });
    }
};
