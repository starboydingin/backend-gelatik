<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('whatsapp_delivery_logs')) {
        Schema::create('whatsapp_delivery_logs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id')->index();
            $table->enum('event_type', ['pinjam', 'konsul', 'usulan_email', 'pengumuman']);
            $table->unsignedBigInteger('reference_id');
            $table->string('status');
            $table->timestamp('sent_at')->nullable();
            $table->timestamps();
        });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('whatsapp_delivery_logs');
    }
};
