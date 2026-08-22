<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChatbotConversation extends Model
{
    protected $fillable = [
        'user_id',
        'session_id',
        'unresolved_count',
        'escalation_context',
        'consultation_offer_pending',
        'escalated_konsultasi_id',
    ];

    protected function casts(): array
    {
        return [
            'unresolved_count' => 'integer',
            'consultation_offer_pending' => 'boolean',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function messages()
    {
        return $this->hasMany(ChatbotMessage::class, 'conversation_id');
    }

    public function escalatedKonsultasi()
    {
        return $this->belongsTo(Konsultasi::class, 'escalated_konsultasi_id');
    }
}
