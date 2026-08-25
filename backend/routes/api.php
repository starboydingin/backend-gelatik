<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AdminDashboardController;
use App\Http\Controllers\Api\AttachmentController;
use App\Http\Controllers\Api\CalendarController;
use App\Http\Controllers\Api\ChatbotController;
use App\Http\Controllers\Api\ChatbotUrlController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\FaqController;
use App\Http\Controllers\Api\InternalWebhookController;
use App\Http\Controllers\Api\ItemController;
use App\Http\Controllers\Api\KonsultasiController;
use App\Http\Controllers\Api\KritikSaranController;
use App\Http\Controllers\Api\LaporanController;
use App\Http\Controllers\Api\LocalProvisioningController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\OpdController;
use App\Http\Controllers\Api\PegawaiController;
use App\Http\Controllers\Api\PengumumanController;
use App\Http\Controllers\Api\PinjamController;
use App\Http\Controllers\Api\RatingController;
use App\Http\Controllers\Api\RoleController;
use App\Http\Controllers\Api\RouterController;
use App\Http\Controllers\Api\SettingController;
use App\Http\Controllers\Api\SliderController;
use App\Http\Controllers\Api\TopikController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\UsulanEmailController;
use App\Http\Controllers\Api\WhatsappNotifController;
use Illuminate\Support\Facades\Route;

// Internal Webhook untuk WhatsApp Gateway (Node.js -> Laravel)
Route::post('/internal/wa/webhook-delivery-status', [InternalWebhookController::class, 'waDeliveryStatus']);

// Auth
Route::post('/login', [AuthController::class, 'login'])->name('login');
Route::post('/register', [AuthController::class, 'register']);
Route::post('/forgot-password', [AuthController::class, 'forgotPassword'])->middleware('throttle:3,1');
Route::post('/forgot-password/verify', [AuthController::class, 'verifyPasswordResetOtp'])->middleware('throttle:5,1');
Route::post('/reset-password', [AuthController::class, 'resetPassword'])->middleware('throttle:5,1');

// Development/test only: bootstrap separate presentation accounts without
// touching existing users. This route is never registered in production.
if (app()->environment('local', 'testing')) {
    Route::post('/dev/provision-account', [LocalProvisioningController::class, 'store'])
        ->middleware('throttle:3,1');
}

// OPD List
Route::get('/opd', [OpdController::class, 'index']);

// Kritik & Saran
Route::post('/kritik-saran', [KritikSaranController::class, 'store']);
Route::get('/kritik-saran/search', [KritikSaranController::class, 'search']);

Route::middleware('auth:api')->group(function () {

    // Auth
    Route::get('/me', [AuthController::class, 'me']);
    Route::patch('/me', [AuthController::class, 'updateProfile']);
    Route::post('/me/change-password', [AuthController::class, 'changePassword']);
    Route::get('/me/activity-log', [AuthController::class, 'activityLog']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Dashboard
    Route::get('/slider', [SliderController::class, 'index']);
    Route::get('/dashboard', [DashboardController::class, 'index']);
    Route::get('/dashboard/calendar', [CalendarController::class, 'index']);

    // Riwayat kritik & saran milik akun yang sedang masuk.
    Route::get('/kritik-saran/mine', [KritikSaranController::class, 'mine']);

    // Peminjaman Aset TIK
    Route::get('/pinjam', [PinjamController::class, 'index']);
    Route::post('/pinjam', [PinjamController::class, 'store']);
    Route::get('/pinjam/{id}', [PinjamController::class, 'show']);
    Route::get('/pinjam/{id}/attachment/{kind?}', [AttachmentController::class, 'pinjam'])
        ->where('kind', 'document|return-proof');
    Route::put('/pinjam/{id}', [PinjamController::class, 'update']);
    Route::delete('/pinjam/{id}', [PinjamController::class, 'destroy']);
    Route::post('/pinjam/{id}/status', [PinjamController::class, 'updateStatus']);
    Route::post('/pinjam/{id}', [PinjamController::class, 'tambahItem']);
    Route::delete('/pinjam/{p}/item/{id}', [PinjamController::class, 'hapusItem']);

    // Konsultasi TIK
    Route::get('/konsul', [KonsultasiController::class, 'index']);
    Route::post('/konsul', [KonsultasiController::class, 'store']);
    Route::get('/konsul/{id}', [KonsultasiController::class, 'show']);
    Route::get('/konsul/{id}/attachment', [AttachmentController::class, 'konsultasi']);
    Route::get('/konsul/{id}/responses/{responseId}/attachment', [AttachmentController::class, 'konsultasiResponse']);
    Route::put('/konsul/{id}', [KonsultasiController::class, 'update']);
    Route::delete('/konsul/{id}', [KonsultasiController::class, 'destroy']);
    Route::post('/konsul/{id}/response', [KonsultasiController::class, 'respond']);
    Route::post('/konsul/{id}/status', [KonsultasiController::class, 'updateStatus']);

    // Item / Aset
    Route::get('/item', [ItemController::class, 'item']);
    Route::get('/items', [ItemController::class, 'index']);
    Route::get('/items/search/{keyword}', [ItemController::class, 'search']);
    Route::get('/items/{id}', [ItemController::class, 'show']);

    // Topik & FAQ
    Route::get('/topik', [TopikController::class, 'index']);
    Route::get('/faq', [FaqController::class, 'index']);

    // Rating
    Route::post('/rating', [RatingController::class, 'store']);
    Route::post('/rating/update', [RatingController::class, 'update']);
    Route::get('/rating', [RatingController::class, 'index']);

    // Layanan Internet — Router OPD
    Route::get('/list-router-opd', [RouterController::class, 'listRouterOpd']);

    // Pegawai Belum Punya Email (FR-B07: ID_Peg tidak muncul di response)
    Route::get('/pegawai', [PegawaiController::class, 'index']);

    // Usulan Email Resmi
    Route::post('/pengajuan-email', [UsulanEmailController::class, 'store']);
    Route::get('/pengajuan-email', [UsulanEmailController::class, 'index']);
    Route::get('/pengajuan-email/{id}', [UsulanEmailController::class, 'show']);
    Route::put('/pengajuan-email/{id}', [UsulanEmailController::class, 'update']);
    Route::post('/pengajuan-email/{id}/verifikasi', [UsulanEmailController::class, 'verifikasi']);
    Route::post('/pengajuan-email/{id}/buat-email-resmi', [UsulanEmailController::class, 'buatEmailResmi']);
    Route::post('/pengajuan-email/{id}/tolak-email', [UsulanEmailController::class, 'tolakEmail']);

    // Pengumuman
    Route::get('/pengumuman', [PengumumanController::class, 'index']);

    // Manajemen Notifikasi User/Admin
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::post('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);

    // Chatbot Config (Chatbase iframe)
    Route::get('/chatbot', [ChatbotUrlController::class, 'index']);

    Route::middleware('role:admin|superadmin,api')->group(function () {
        // Admin dashboard and notification management
        Route::get('/admin/dashboard', [AdminDashboardController::class, 'index']);
        Route::get('/admin/notifications', [NotificationController::class, 'adminIndex']);
        Route::post('/admin/notifications', [NotificationController::class, 'store']);
        Route::put('/admin/notifications/{id}', [NotificationController::class, 'update']);
        Route::delete('/admin/notifications/{id}', [NotificationController::class, 'destroy']);

        // Admin: master data used by both web and mobile clients
        Route::get('/admin/items', [ItemController::class, 'adminIndex']);
        Route::post('/admin/items', [ItemController::class, 'store']);
        Route::put('/admin/items/{id}', [ItemController::class, 'update']);
        Route::delete('/admin/items/{id}', [ItemController::class, 'destroy']);
        Route::get('/admin/topik', [TopikController::class, 'adminIndex']);
        Route::post('/admin/topik', [TopikController::class, 'store']);
        Route::put('/admin/topik/{id}', [TopikController::class, 'update']);
        Route::delete('/admin/topik/{id}', [TopikController::class, 'destroy']);
        Route::get('/admin/faq', [FaqController::class, 'adminIndex']);
        Route::post('/admin/faq', [FaqController::class, 'store']);
        Route::put('/admin/faq/{id}', [FaqController::class, 'update']);
        Route::delete('/admin/faq/{id}', [FaqController::class, 'destroy']);
        Route::get('/admin/sliders', [SliderController::class, 'adminIndex']);
        Route::post('/admin/sliders', [SliderController::class, 'store']);
        Route::put('/admin/sliders/{id}', [SliderController::class, 'update']);
        Route::delete('/admin/sliders/{id}', [SliderController::class, 'destroy']);
        Route::get('/admin/routers', [RouterController::class, 'adminIndex']);
        Route::post('/admin/routers', [RouterController::class, 'store']);
        Route::put('/admin/routers/{id}', [RouterController::class, 'update']);
        Route::delete('/admin/routers/{id}', [RouterController::class, 'destroy']);

        Route::get('/admin/pengumuman', [PengumumanController::class, 'adminIndex']);
        Route::post('/admin/pengumuman', [PengumumanController::class, 'store']);
        Route::put('/admin/pengumuman/{id}', [PengumumanController::class, 'update']);
        Route::delete('/admin/pengumuman/{id}', [PengumumanController::class, 'destroy']);

        // Admin: Kritik & Saran
        Route::get('/admin/kritik-saran', [KritikSaranController::class, 'index']);
        Route::post('/admin/kritik-saran/{kritikSaran}/reply', [KritikSaranController::class, 'reply']);
        Route::post('/admin/kritik-saran/bulk-delete', [KritikSaranController::class, 'bulkDelete']);

        // Admin: User Management
        Route::get('/admin/users', [UserController::class, 'index']);
        Route::post('/admin/users', [UserController::class, 'store'])
            ->middleware('role:superadmin,api');
        Route::get('/admin/users/{id}', [UserController::class, 'show']);
        Route::put('/admin/users/{id}', [UserController::class, 'update']);
        Route::delete('/admin/users/{id}', [UserController::class, 'destroy']);
        Route::post('/admin/users/{id}/activate', [UserController::class, 'activate']);
        Route::post('/admin/users/{id}/deactivate', [UserController::class, 'deactivate']);

        // Admin: Role & Permission Management
        Route::get('/admin/roles', [RoleController::class, 'index']);
        Route::post('/admin/roles', [RoleController::class, 'store'])
            ->middleware('role:superadmin,api');
        Route::get('/admin/roles/{id}', [RoleController::class, 'show']);
        Route::put('/admin/roles/{id}', [RoleController::class, 'update'])
            ->middleware('role:superadmin,api');
        Route::delete('/admin/roles/{id}', [RoleController::class, 'destroy'])
            ->middleware('role:superadmin,api');
        Route::get('/admin/permissions', [RoleController::class, 'permissions']);

        // Admin: System Settings (m_settings)
        Route::get('/admin/settings', [SettingController::class, 'index']);
        Route::put('/admin/settings', [SettingController::class, 'update']);
    });

    // F-WA: Notifikasi WhatsApp
    Route::post('/notifikasi/wa/subscribe', [WhatsappNotifController::class, 'subscribe']);
    Route::delete('/notifikasi/wa/subscribe', [WhatsappNotifController::class, 'unsubscribe']);
    Route::get('/notifikasi/wa/status', [WhatsappNotifController::class, 'status']);

    // F-BOT: Chatbot AI Native
    Route::post('/chatbot/message', [ChatbotController::class, 'message']);
    Route::get('/chatbot/conversations/latest', [ChatbotController::class, 'latestConversation']);
    Route::get('/chatbot/history', [ChatbotController::class, 'history']);
    Route::delete('/chatbot/history', [ChatbotController::class, 'deleteHistory']);

    // F-LAPORAN: Laporan Peminjaman
    Route::get('/laporan/peminjaman', [LaporanController::class, 'peminjaman']);
    Route::get('/laporan/{type}/data', [LaporanController::class, 'index']);
    Route::get('/laporan/{type}/export', [LaporanController::class, 'export'])->middleware('throttle:10,1');
});
