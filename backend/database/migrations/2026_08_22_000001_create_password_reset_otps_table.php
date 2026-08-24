<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('password_reset_otps', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->unsignedBigInteger('user_id')->index();
            $table->string('otp_hash');
            $table->string('reset_token_hash', 64)->nullable()->unique();
            $table->unsignedTinyInteger('attempts')->default(0);
            // dateTime avoids implicit TIMESTAMP defaults on the legacy
            // MySQL/MariaDB runtime while preserving the required precision.
            $table->dateTime('expires_at')->index();
            $table->dateTime('verified_at')->nullable();
            $table->dateTime('consumed_at')->nullable();
            $table->dateTime('last_sent_at');
            $table->timestamps();

            $table->index(['user_id', 'consumed_at', 'expires_at'], 'password_reset_otps_lookup_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('password_reset_otps');
    }
};
