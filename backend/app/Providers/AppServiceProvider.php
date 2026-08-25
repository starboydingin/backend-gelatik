<?php

namespace App\Providers;

use App\Models\Konsultasi;
use App\Models\KonsultasiResponse;
use App\Models\KritikSaran;
use App\Models\MasterItem;
use App\Models\MasterTopik;
use App\Models\Notification;
use App\Models\Pinjam;
use App\Models\PinjamItem;
use App\Models\Pengumuman;
use App\Models\PegawaiBelumPunyaEmail;
use App\Models\Rating;
use App\Models\Router;
use App\Models\RouterList;
use App\Models\Slider;
use App\Models\Setting;
use App\Models\User;
use App\Models\UsulanEmail;
use App\Models\WhatsappSubscription;
use App\Models\Faq;
use App\Observers\RealtimeDataObserver;
use App\Services\RealtimeDataSyncService;
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
        // One request can save a parent and several child rows. A shared sync
        // service batches their invalidation signals into one Socket.IO push.
        $this->app->singleton(RealtimeDataSyncService::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Gate::policy(Pinjam::class, PinjamPolicy::class);
        Gate::policy(Konsultasi::class, KonsultasiPolicy::class);
        Gate::policy(UsulanEmail::class, UsulanEmailPolicy::class);

        foreach ([
            User::class,
            Pinjam::class,
            PinjamItem::class,
            Konsultasi::class,
            KonsultasiResponse::class,
            UsulanEmail::class,
            Rating::class,
            KritikSaran::class,
            Notification::class,
            WhatsappSubscription::class,
            Faq::class,
            MasterTopik::class,
            MasterItem::class,
            Router::class,
            RouterList::class,
            Slider::class,
            Pengumuman::class,
            PegawaiBelumPunyaEmail::class,
            Setting::class,
        ] as $model) {
            $model::observe(RealtimeDataObserver::class);
        }

        ResetPassword::createUrlUsing(function (object $notifiable, string $token): string {
            return rtrim(config('app.frontend_url'), '/')
                .'/reset-password?token='.urlencode($token)
                .'&email='.urlencode($notifiable->getEmailForPasswordReset());
        });

        // Event discovery in app/Listeners handled automatically by Laravel framework
    }
}
