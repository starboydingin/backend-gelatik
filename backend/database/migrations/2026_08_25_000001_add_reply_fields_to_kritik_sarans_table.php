<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('kritik_sarans', function (Blueprint $table) {
            $table->text('balasan')->nullable()->after('saran');
            $table->unsignedBigInteger('dibalas_oleh')->nullable()->after('balasan');
            $table->timestamp('dibalas_pada')->nullable()->after('dibalas_oleh');
        });
    }

    public function down(): void
    {
        Schema::table('kritik_sarans', function (Blueprint $table) {
            $table->dropColumn(['balasan', 'dibalas_oleh', 'dibalas_pada']);
        });
    }
};
