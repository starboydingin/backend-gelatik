<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('whatsapp_delivery_logs')) {
            return;
        }

        // The original enum cannot represent semantic events such as
        // `konsultasi.responded`. Keep the audit value lossless.
        if (in_array(DB::getDriverName(), ['mysql', 'mariadb'], true)) {
            DB::statement('ALTER TABLE whatsapp_delivery_logs MODIFY event_type VARCHAR(100) NOT NULL');
        }

        Schema::table('whatsapp_delivery_logs', function (Blueprint $table): void {
            $table->string('delivery_key', 64)->nullable()->unique()->after('id');
            $table->unsignedTinyInteger('attempts')->default(0)->after('status');
            $table->text('error')->nullable()->after('attempts');
        });
    }

    public function down(): void
    {
        if (! Schema::hasTable('whatsapp_delivery_logs')) {
            return;
        }

        Schema::table('whatsapp_delivery_logs', function (Blueprint $table): void {
            $table->dropUnique(['delivery_key']);
            $table->dropColumn(['delivery_key', 'attempts', 'error']);
        });
    }
};
