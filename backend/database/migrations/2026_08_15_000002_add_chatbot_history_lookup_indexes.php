<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /** Speed up the authenticated conversation lookup and chronological history query. */
    public function up(): void
    {
        Schema::table('chatbot_conversations', function (Blueprint $table) {
            $table->index(['user_id', 'session_id'], 'chatbot_conversations_user_session_index');
        });

        Schema::table('chatbot_messages', function (Blueprint $table) {
            $table->index(['conversation_id', 'created_at'], 'chatbot_messages_conversation_created_index');
        });
    }

    public function down(): void
    {
        Schema::table('chatbot_messages', function (Blueprint $table) {
            $table->dropIndex('chatbot_messages_conversation_created_index');
        });

        Schema::table('chatbot_conversations', function (Blueprint $table) {
            $table->dropIndex('chatbot_conversations_user_session_index');
        });
    }
};
