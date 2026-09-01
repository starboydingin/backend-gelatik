<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Passport\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, HasRoles, Notifiable;

    protected $fillable = [
        'id',
        'name',
        'username',
        'email',
        'password',
        'nama_opd',
        'bandwidth_download_mbps',
        'bandwidth_upload_mbps',
        'nip',
        'jabatan',
        'unit_kerja',
        'no_hp',
        'foto',
        'role',
        'status',
        'is_active',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'bandwidth_download_mbps' => 'integer',
            'bandwidth_upload_mbps' => 'integer',
        ];
    }

    // Relasi
    public function pinjams()
    {
        return $this->hasMany(Pinjam::class);
    }

    public function konsultasis()
    {
        return $this->hasMany(Konsultasi::class);
    }

    public function ratings()
    {
        return $this->hasMany(Rating::class);
    }

    public function usulanEmails()
    {
        return $this->hasMany(UsulanEmail::class);
    }

    public function whatsappSubscription()
    {
        return $this->hasOne(WhatsappSubscription::class);
    }

    public function chatbotConversations()
    {
        return $this->hasMany(ChatbotConversation::class);
    }

    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }

    public function notificationReads()
    {
        return $this->hasMany(NotificationRead::class);
    }
}
