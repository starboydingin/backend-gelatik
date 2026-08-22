<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('chatbot_conversations', function (Blueprint $table): void {
            $table->unsignedTinyInteger('unresolved_count')->default(0)->after('session_id');
            $table->unsignedBigInteger('escalated_konsultasi_id')->nullable()->index()->after('unresolved_count');
        });
    }

    public function down(): void
    {
        Schema::table('chatbot_conversations', function (Blueprint $table): void {
            $table->dropIndex(['escalated_konsultasi_id']);
            $table->dropColumn(['unresolved_count', 'escalated_konsultasi_id']);
        });
    }
};
