<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('whatsapp_subscriptions')) {
        Schema::create('whatsapp_subscriptions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id')->index();
            $table->string('nomor_wa');
            $table->boolean('is_opt_in')->default(false);
            $table->timestamp('verified_at')->nullable();
            $table->string('last_delivery_status')->nullable();
            $table->timestamps();
        });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('whatsapp_subscriptions');
    }
};
