<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('unker_list_router', function (Blueprint $table): void {
            $table->unsignedInteger('bandwidth_download_mbps')->nullable()->after('lokasi');
            $table->unsignedInteger('bandwidth_upload_mbps')->nullable()->after('bandwidth_download_mbps');
        });
    }

    public function down(): void
    {
        Schema::table('unker_list_router', function (Blueprint $table): void {
            $table->dropColumn(['bandwidth_download_mbps', 'bandwidth_upload_mbps']);
        });
    }
};
