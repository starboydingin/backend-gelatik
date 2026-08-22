<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('chatbot_conversations', function (Blueprint $table): void {
            $table->string('escalation_context', 40)->nullable()->after('unresolved_count');
            $table->boolean('consultation_offer_pending')->default(false)->after('escalation_context');
        });
    }

    public function down(): void
    {
        Schema::table('chatbot_conversations', function (Blueprint $table): void {
            $table->dropColumn(['escalation_context', 'consultation_offer_pending']);
        });
    }
};
