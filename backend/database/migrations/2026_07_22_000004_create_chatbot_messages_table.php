<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('chatbot_messages')) {
        Schema::create('chatbot_messages', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('conversation_id')->index();
            $table->enum('role', ['user', 'assistant']);
            $table->text('content');
            $table->enum('provider_used', ['gemini', 'groq']);
            $table->timestamps();
        });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('chatbot_messages');
    }
};
