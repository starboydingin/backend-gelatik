<?php

namespace App\Providers;

use App\Models\Konsultasi;
use App\Models\Pinjam;
use App\Models\UsulanEmail;
use App\Policies\KonsultasiPolicy;
use App\Policies\PinjamPolicy;
use App\Policies\UsulanEmailPolicy;
use Illuminate\Support\Facades\Gate;
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

        // Event discovery in app/Listeners handled automatically by Laravel framework
    }
}
