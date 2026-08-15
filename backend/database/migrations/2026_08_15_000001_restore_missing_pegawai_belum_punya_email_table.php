<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /** Restore the legacy BKD source table only when a local database is missing it. */
    public function up(): void
    {
        if (Schema::hasTable('PegawaiBelumPunyaEMail')) {
            return;
        }

        Schema::create('PegawaiBelumPunyaEMail', function (Blueprint $table) {
            $table->string('ID_Peg', 32)->primary();
            $table->string('NIP_Baru', 24)->nullable();
            $table->string('Nama', 117)->nullable();
            $table->string('Unit_Kerja', 255)->nullable();
            $table->string('NJab', 255)->nullable();
            $table->string('NUnKer', 255)->nullable();
            $table->string('EmailUsulan', 35)->nullable();
            $table->string('EmailPribadi', 150)->nullable();
        });
    }

    public function down(): void
    {
        // Preserve imported BKD data; rollback intentionally does not drop this legacy source table.
    }
};
