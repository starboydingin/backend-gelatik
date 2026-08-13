<?php

namespace App\Providers;

use App\Models\Konsultasi;
use App\Models\Pinjam;
use App\Models\UsulanEmail;
use App\Policies\KonsultasiPolicy;
use App\Policies\PinjamPolicy;
use App\Policies\UsulanEmailPolicy;
use Illuminate\Support\Facades\Gate;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Gate::policy(Pinjam::class, PinjamPolicy::class);
        Gate::policy(Konsultasi::class, KonsultasiPolicy::class);
        Gate::policy(UsulanEmail::class, UsulanEmailPolicy::class);

        ResetPassword::createUrlUsing(function (object $notifiable, string $token): string {
            return rtrim(config('app.frontend_url'), '/')
                .'/reset-password?token='.urlencode($token)
                .'&email='.urlencode($notifiable->getEmailForPasswordReset());
        });

        // Event discovery in app/Listeners handled automatically by Laravel framework
    }
}
