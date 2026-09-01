<?php

namespace App\Observers;

use App\Models\Faq;
use App\Models\Konsultasi;
use App\Models\KonsultasiResponse;
use App\Models\KritikSaran;
use App\Models\MasterItem;
use App\Models\MasterTopik;
use App\Models\PegawaiBelumPunyaEmail;
use App\Models\Pengumuman;
use App\Models\Pinjam;
use App\Models\PinjamItem;
use App\Models\Rating;
use App\Models\Router;
use App\Models\RouterList;
use App\Models\Setting;
use App\Models\Slider;
use App\Models\User;
use App\Models\UsulanEmail;
use App\Models\WhatsappSubscription;
use App\Services\RealtimeDataSyncService;
use Illuminate\Contracts\Events\ShouldHandleEventsAfterCommit;
use Illuminate\Database\Eloquent\Model;

/** Keeps every signed-in client fresh after persisted model changes. */
class RealtimeDataObserver implements ShouldHandleEventsAfterCommit
{
    public function __construct(private RealtimeDataSyncService $sync) {}

    public function created(Model $model): void
    {
        $this->publish($model);
    }

    public function updated(Model $model): void
    {
        $this->publish($model);
    }

    public function deleted(Model $model): void
    {
        $this->publish($model);
    }

    public function restored(Model $model): void
    {
        $this->publish($model);
    }

    private function publish(Model $model): void
    {
        // Some reference tables use non-incrementing string keys. The event
        // carries no record data, so a stable positive sentinel is enough for
        // clients to invalidate and fetch the authoritative list again.
        $entityId = max(1, (int) $model->getKey());

        if ($model instanceof Pinjam) {
            $this->personal($model->user_id, 'peminjaman', $entityId, true);

            return;
        }
        if ($model instanceof PinjamItem) {
            $pinjam = Pinjam::withTrashed()->find($model->pinjam_id);
            $this->personal($pinjam?->user_id, 'peminjaman', (int) ($pinjam?->id ?? $entityId), true);

            return;
        }
        if ($model instanceof Konsultasi) {
            $this->personal($model->user_id, 'konsultasi', $entityId, true);

            return;
        }
        if ($model instanceof KonsultasiResponse) {
            $konsultasi = Konsultasi::withTrashed()->find($model->konsultasi_id);
            $this->personal($konsultasi?->user_id, 'konsultasi', (int) ($konsultasi?->id ?? $entityId), true);

            return;
        }
        if ($model instanceof UsulanEmail) {
            $this->personal($model->created_by, 'usulan_email', $entityId, true);

            return;
        }
        if ($model instanceof Rating) {
            $this->personal($model->user_id, 'rating', $entityId, true);

            return;
        }
        if ($model instanceof KritikSaran) {
            $this->personal($model->user_id, 'kritik_saran', $entityId);

            return;
        }
        if ($model instanceof User) {
            $this->sync->userAndAdmins($entityId, 'user', $entityId);

            return;
        }
        if ($model instanceof WhatsappSubscription) {
            $this->sync->user((int) $model->user_id, 'whatsapp_subscription', $entityId);

            return;
        }
        if ($model instanceof Setting) {
            $this->sync->admins('settings', $entityId);

            return;
        }

        $publicResource = match (true) {
            $model instanceof Faq => 'faq',
            $model instanceof MasterTopik => 'mastertopik',
            $model instanceof MasterItem => 'masteritem',
            $model instanceof Router => 'router',
            $model instanceof RouterList => 'routerlist',
            $model instanceof Slider => 'slider',
            $model instanceof Pengumuman => 'pengumuman',
            // This reference table is consumed by the email proposal flow.
            $model instanceof PegawaiBelumPunyaEmail => 'usulan_email',
            default => null,
        };
        if ($publicResource !== null) {
            $this->sync->everyone($publicResource, $entityId);
        }
    }

    private function personal(mixed $userId, string $resource, int $entityId, bool $refreshInsights = false): void
    {
        $this->sync->userAndAdmins((int) $userId, $resource, $entityId);
        if ($refreshInsights) {
            $this->sync->insights($resource);
        }
    }
}
