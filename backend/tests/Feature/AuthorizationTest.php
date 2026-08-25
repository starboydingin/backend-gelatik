<?php

namespace Tests\Feature;

use App\Events\KonsultasiCreated;
use App\Models\Faq;
use App\Models\Konsultasi;
use App\Models\Pinjam;
use App\Models\PinjamItem;
use App\Models\User;
use App\Models\UsulanEmail;
use App\Services\ChatbotService;
use App\Services\DashboardService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Laravel\Passport\Passport;
use Maatwebsite\Excel\Facades\Excel;
use Mockery\MockInterface;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

class AuthorizationTest extends TestCase
{
    private User $userA;

    private User $userB;

    private User $admin;

    private User $superadmin;

    private User $bkd;

    protected function setUp(): void
    {
        parent::setUp();

        Event::fake();
        $this->createLegacyTestSchema();
        app(PermissionRegistrar::class)->forgetCachedPermissions();

        foreach (['user', 'admin', 'superadmin', 'bkd'] as $role) {
            Role::create(['name' => $role, 'guard_name' => 'web']);
        }

        $this->userA = $this->createUser(1, 'user-a@example.test', 'user');
        $this->userB = $this->createUser(2, 'user-b@example.test', 'user');
        $this->admin = $this->createUser(3, 'admin@example.test', 'admin');
        $this->bkd = $this->createUser(4, 'bkd@example.test', 'bkd');
        $this->superadmin = $this->createUser(5, 'superadmin@example.test', 'superadmin');

        $this->seedResources();
    }

    public function test_unauthenticated_request_is_rejected(): void
    {
        $this->getJson('/api/pinjam')->assertUnauthorized();
    }

    public function test_chatbot_requires_authentication_and_valid_payload(): void
    {
        $this->postJson('/api/chatbot/message', ['message' => 'Halo'])->assertUnauthorized();

        $this->actingAsApi($this->userA);
        $this->postJson('/api/chatbot/message', [])->assertUnprocessable();
    }

    public function test_chatbot_returns_safe_success_contract_without_secret_leakage(): void
    {
        $this->mock(ChatbotService::class, function (MockInterface $mock): void {
            $mock->shouldReceive('sendMessage')->once()->andReturn([
                'success' => true,
                'session_id' => 'session-test',
                'reply' => 'Silakan buka menu Peminjaman.',
                'provider' => 'gemini',
            ]);
        });

        $this->actingAsApi($this->userA);
        $response = $this->postJson('/api/chatbot/message', ['message' => 'Cara pinjam alat?'])
            ->assertOk()
            ->assertJsonPath('data.session_id', 'session-test')
            ->assertJsonPath('data.reply', 'Silakan buka menu Peminjaman.');

        $this->assertStringNotContainsString('api_key', strtolower($response->getContent()));
        $this->assertStringNotContainsString('secret', strtolower($response->getContent()));
    }

    public function test_chatbot_maps_external_timeout_to_safe_gateway_timeout(): void
    {
        $this->mock(ChatbotService::class, function (MockInterface $mock): void {
            $mock->shouldReceive('sendMessage')->once()->andReturn([
                'success' => false,
                'error' => 'Maaf, layanan chatbot sedang tidak tersedia saat ini.',
                'error_code' => 'upstream_timeout',
            ]);
        });

        $this->actingAsApi($this->userA);
        $this->postJson('/api/chatbot/message', ['message' => 'Halo'])
            ->assertStatus(504)
            ->assertJson([
                'success' => false,
                'message' => 'Maaf, layanan chatbot sedang tidak tersedia saat ini.',
            ]);
    }

    public function test_chatbot_replaces_a_missing_browser_session_with_a_new_private_session(): void
    {
        Schema::create('chatbot_conversations', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('user_id')->index();
            $table->string('session_id');
            $table->unsignedTinyInteger('unresolved_count')->default(0);
            $table->string('escalation_context', 40)->nullable();
            $table->boolean('consultation_offer_pending')->default(false);
            $table->unsignedBigInteger('escalated_konsultasi_id')->nullable();
            $table->timestamps();
        });
        Schema::create('chatbot_messages', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('conversation_id')->index();
            $table->enum('role', ['user', 'assistant']);
            $table->text('content');
            $table->enum('provider_used', ['gemini', 'groq']);
            $table->timestamps();
        });

        $response = app(ChatbotService::class)->sendMessage(
            $this->userA,
            'Halo',
            'browser-session-yang-sudah-dihapus',
        );

        $this->assertTrue($response['success']);
        $this->assertNotSame('browser-session-yang-sudah-dihapus', $response['session_id']);
        $this->assertDatabaseHas('chatbot_conversations', [
            'user_id' => $this->userA->id,
            'session_id' => $response['session_id'],
        ]);

        $secondDevice = app(ChatbotService::class)->sendMessage(
            $this->userA,
            'Terima kasih',
            'mobile-session-yang-sudah-kedaluwarsa',
        );
        $this->assertSame($response['session_id'], $secondDevice['session_id']);
        $this->assertDatabaseCount('chatbot_conversations', 1);

        $latest = app(ChatbotService::class)->latestConversation($this->userA);
        $this->assertSame($response['session_id'], $latest['session_id']);
        $this->assertCount(4, $latest['messages']);

        $otherConversationId = \DB::table('chatbot_conversations')->insertGetId([
            'user_id' => $this->userA->id,
            'session_id' => 'old-mobile-session',
            'created_at' => now()->subDay(),
            'updated_at' => now()->subDay(),
        ]);
        \DB::table('chatbot_messages')->insert([
            'conversation_id' => $otherConversationId,
            'role' => 'user',
            'content' => 'Pesan lama',
            'provider_used' => 'gemini',
            'created_at' => now()->subDay(),
            'updated_at' => now()->subDay(),
        ]);

        $this->assertTrue(app(ChatbotService::class)->deleteHistory(
            $this->userA,
            $response['session_id'],
        ));
        $this->assertDatabaseCount('chatbot_conversations', 0);
        $this->assertDatabaseCount('chatbot_messages', 0);
        $this->assertTrue(app(ChatbotService::class)->deleteHistory(
            $this->userA,
            'stale-session',
        ));
    }

    public function test_chatbot_answers_a_relevant_active_faq_without_waiting_for_ai(): void
    {
        Schema::create('chatbot_conversations', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('user_id')->index();
            $table->string('session_id');
            $table->unsignedTinyInteger('unresolved_count')->default(0);
            $table->string('escalation_context', 40)->nullable();
            $table->boolean('consultation_offer_pending')->default(false);
            $table->unsignedBigInteger('escalated_konsultasi_id')->nullable();
            $table->timestamps();
        });
        Schema::create('chatbot_messages', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('conversation_id')->index();
            $table->enum('role', ['user', 'assistant']);
            $table->text('content');
            $table->enum('provider_used', ['gemini', 'groq']);
            $table->timestamps();
        });
        Schema::create('faq', function (Blueprint $table): void {
            $table->unsignedBigInteger('id')->primary();
            $table->unsignedBigInteger('topik_id');
            $table->string('judul');
            $table->text('detail');
            $table->string('status')->default('1');
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();
            $table->softDeletes();
            $table->timestamps();
        });
        Faq::create([
            'id' => 701,
            'topik_id' => 601,
            'judul' => 'Cara reset password WiFi',
            'detail' => '<p>Hubungi helpdesk untuk verifikasi identitas sebelum password WiFi direset.</p>',
            'status' => '1',
        ]);
        Faq::create([
            'id' => 702,
            'topik_id' => 601,
            'judul' => 'Password WiFi lama',
            'detail' => 'FAQ ini tidak boleh dikirim.',
            'status' => '0',
        ]);

        Http::preventStrayRequests();

        $response = app(ChatbotService::class)->sendMessage(
            $this->userA,
            'Bagaimana reset password WiFi saya?',
            null,
        );

        $this->assertTrue($response['success']);
        $this->assertSame('faq', $response['provider']);
        $this->assertStringContainsString('Cara reset password WiFi', $response['reply']);
        $this->assertStringContainsString('Hubungi helpdesk untuk verifikasi identitas', $response['reply']);
        $this->assertStringNotContainsString('FAQ ini tidak boleh dikirim.', $response['reply']);
        Http::assertNothingSent();
    }

    public function test_chatbot_quick_questions_return_complete_active_faq_answers_without_ai(): void
    {
        Schema::create('chatbot_conversations', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('user_id')->index();
            $table->string('session_id');
            $table->unsignedTinyInteger('unresolved_count')->default(0);
            $table->string('escalation_context', 40)->nullable();
            $table->boolean('consultation_offer_pending')->default(false);
            $table->unsignedBigInteger('escalated_konsultasi_id')->nullable();
            $table->timestamps();
        });
        Schema::create('chatbot_messages', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('conversation_id')->index();
            $table->enum('role', ['user', 'assistant']);
            $table->text('content');
            $table->enum('provider_used', ['gemini', 'groq']);
            $table->timestamps();
        });
        Schema::create('faq', function (Blueprint $table): void {
            $table->unsignedBigInteger('id')->primary();
            $table->unsignedBigInteger('topik_id');
            $table->string('judul');
            $table->text('detail');
            $table->string('status')->default('1');
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();
            $table->softDeletes();
            $table->timestamps();
        });

        $faqs = [
            [701, 'Cara pinjam aset/perangkat untuk video conference', '<p>Login ke Gelatik.</p><ol><li>Buka menu Pinjam Aset.</li><li>Isi formulir dan pilih perangkat.</li><li>Kirim pengajuan.</li></ol>'],
            [702, 'WiFi terhubung tetapi tidak ada internet', '<p>Uji perangkat lain dan restart WiFi.</p><p>Jika belum selesai, hubungi helpdesk TIK.</p>'],
            [703, 'Pengajuan reset kata sandi email resmi', '<p>Pastikan email pribadi aktif.</p><p>Kirim formulir reset lalu ikuti petunjuk yang diterima.</p>'],
            [704, 'Cara mengajukan sertifikat elektronik/TTE', '<p>Buka Konsultasi TIK dan pilih topik TTE.</p><p>Lengkapi identitas serta unggah surat instansi.</p>'],
            [705, 'Cara mendapatkan akun email resmi Pemprov Lampung', '<p>Ajukan surat permohonan melalui BKD.</p><ul><li>Lampirkan fotokopi e-KTP.</li><li>Lampirkan SK jabatan terakhir.</li></ul>'],
            [706, 'WiFi terhubung tetapi tidak ada internet lama', '<p>Jawaban nonaktif tidak boleh dipakai.</p>'],
        ];
        foreach ($faqs as [$id, $judul, $detail]) {
            Faq::create([
                'id' => $id,
                'topik_id' => 601,
                'judul' => $judul,
                'detail' => $detail,
                'status' => $id === 706 ? '0' : '1',
            ]);
        }

        Http::preventStrayRequests();
        $questions = [
            'Bagaimana cara mengajukan peminjaman aset TIK?' => 'Kirim pengajuan.',
            'WiFi terhubung tetapi tidak ada internet. Apa yang harus dilakukan?' => 'hubungi helpdesk TIK.',
            'Bagaimana cara reset kata sandi email resmi?' => 'ikuti petunjuk yang diterima.',
            'Bagaimana cara mengajukan sertifikat elektronik TTE?' => 'unggah surat instansi.',
            'Bagaimana cara mengajukan usulan email dinas?' => 'Lampirkan SK jabatan terakhir.',
        ];

        $sessionId = null;
        foreach ($questions as $question => $expectedEnding) {
            $response = app(ChatbotService::class)->sendMessage(
                $this->userA,
                $question,
                $sessionId,
            );
            $sessionId = $response['session_id'];

            $this->assertTrue($response['success']);
            $this->assertSame('faq', $response['provider']);
            $this->assertStringContainsString($expectedEnding, $response['reply']);
            $this->assertStringNotContainsString('<p>', $response['reply']);
            $this->assertStringNotContainsString('**', $response['reply']);
            $this->assertStringNotContainsString('Jawaban nonaktif', $response['reply']);
        }
    }

    public function test_chatbot_offers_consultation_after_repeated_unresolved_issue(): void
    {
        Schema::create('chatbot_conversations', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('user_id')->index();
            $table->string('session_id');
            $table->unsignedTinyInteger('unresolved_count')->default(0);
            $table->string('escalation_context', 40)->nullable();
            $table->boolean('consultation_offer_pending')->default(false);
            $table->unsignedBigInteger('escalated_konsultasi_id')->nullable();
            $table->timestamps();
        });
        Schema::create('chatbot_messages', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('conversation_id')->index();
            $table->enum('role', ['user', 'assistant']);
            $table->text('content');
            $table->enum('provider_used', ['gemini', 'groq']);
            $table->timestamps();
        });
        Schema::create('faq', function (Blueprint $table): void {
            $table->unsignedBigInteger('id')->primary();
            $table->unsignedBigInteger('topik_id');
            $table->string('judul');
            $table->text('detail');
            $table->string('status')->default('1');
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();
            $table->softDeletes();
            $table->timestamps();
        });
        config()->set('services.chatbot.gemini.key', 'test-key');
        Http::fake([
            'https://generativelanguage.googleapis.com/*' => Http::response([
                'candidates' => [['content' => ['parts' => [['text' => 'Silakan coba langkah berikutnya.']]]]],
            ]),
        ]);

        $service = app(ChatbotService::class);
        $first = $service->sendMessage($this->userA, 'Internet kantor tidak bisa digunakan', null);
        $service->sendMessage($this->userA, 'Masih tidak bisa', $first['session_id']);
        $result = $service->sendMessage($this->userA, 'Tetap tidak bisa', $first['session_id']);

        $this->assertTrue($result['success']);
        $this->assertStringContainsString('konsultasi', strtolower($result['reply']));
        $this->assertStringContainsString("Nama:\nOPD:\nDetail Permasalahan:", $result['reply']);
        $this->assertStringNotContainsString('Lokasi/OPD:', $result['reply']);
        $this->assertStringNotContainsString('Detail tambahan:', $result['reply']);
        $this->assertDatabaseHas('chatbot_conversations', [
            'user_id' => $this->userA->id,
            'session_id' => $first['session_id'],
            'consultation_offer_pending' => true,
        ]);

        $consultationCountBefore = \DB::table('tr_konsultasi')->count();
        $partial = $service->sendMessage(
            $this->userA,
            'Nama: Adwika',
            $first['session_id'],
        );
        $this->assertSame('consultation_offer', $partial['provider']);
        $this->assertStringContainsString("Nama:\nOPD:\nDetail Permasalahan:", $partial['reply']);
        $this->assertDatabaseCount('tr_konsultasi', $consultationCountBefore);

        $created = $service->sendMessage(
            $this->userA,
            'Nama: Adwika, OPD: Dinas Kesehatan, Detail Permasalahan: setelah mencoba beberapa cara, internet wifi masih tidak bisa',
            $first['session_id'],
        );

        $this->assertTrue($created['success']);
        $this->assertTrue($created['escalated']);
        $this->assertSame('consultation_created', $created['provider']);
        $this->assertStringContainsString('Konsultasi sudah saya buatkan', $created['reply']);
        $this->assertStringContainsString('Jika ada pertanyaan lain, silakan ditanyakan yaa.', $created['reply']);
        $this->assertStringContainsString('#'.$created['konsultasi_id'], $created['reply']);
        $this->assertDatabaseHas('tr_konsultasi', [
            'id' => $created['konsultasi_id'],
            'user_id' => $this->userA->id,
            'faq_id' => 601,
            'status' => 'Menunggu',
            'created_by' => $this->userA->id,
        ]);
        $consultationMessage = (string) \DB::table('tr_konsultasi')
            ->where('id', $created['konsultasi_id'])
            ->value('pesan');
        $this->assertStringContainsString('Nama: Adwika', $consultationMessage);
        $this->assertStringContainsString('OPD: Dinas Kesehatan', $consultationMessage);
        $this->assertStringContainsString('Detail Permasalahan: setelah mencoba beberapa cara, internet wifi masih tidak bisa', $consultationMessage);
        $this->assertDatabaseHas('notification', [
            'user_id' => 0,
            'type' => 'konsultasi',
            'item_id' => $created['konsultasi_id'],
            'read' => false,
        ]);
        Event::assertDispatched(KonsultasiCreated::class);
        $this->assertDatabaseCount('tr_konsultasi', $consultationCountBefore + 1);

        $service->sendMessage(
            $this->userA,
            "Nama: Adwika\nOPD: Dinas Kesehatan\nDetail Permasalahan: WiFi kantor tetap tidak terhubung.",
            $first['session_id'],
        );
        $this->assertDatabaseCount('tr_konsultasi', $consultationCountBefore + 1);
    }

    public function test_user_can_view_own_pinjam_but_not_another_users_pinjam(): void
    {
        $this->actingAsApi($this->userA);

        $this->getJson('/api/pinjam/101')->assertOk()->assertJsonPath('data.id', 101);
        $this->getJson('/api/pinjam/102')->assertForbidden();
    }

    public function test_user_cannot_update_or_delete_another_users_pinjam(): void
    {
        $this->actingAsApi($this->userA);

        $this->putJson('/api/pinjam/102', ['keterangan' => 'Tidak boleh'])->assertForbidden();
        $this->deleteJson('/api/pinjam/102')->assertForbidden();
    }

    public function test_user_cannot_modify_items_on_another_users_pinjam(): void
    {
        $this->actingAsApi($this->userA);

        $this->postJson('/api/pinjam/102', [
            'items' => [['item_id' => 501, 'quantity' => 1]],
        ])->assertForbidden();
        $this->deleteJson('/api/pinjam/102/item/702')->assertForbidden();
    }

    public function test_pinjam_list_is_filtered_for_user_and_complete_for_admin(): void
    {
        $this->actingAsApi($this->userA);
        $this->getJson('/api/pinjam')
            ->assertOk()
            ->assertJsonCount(1, 'data.data')
            ->assertJsonPath('data.data.0.id', 101);

        $this->actingAsApi($this->admin);
        $this->getJson('/api/pinjam')->assertOk()->assertJsonCount(2, 'data.data');
    }

    public function test_user_cannot_change_pinjam_status_but_admin_can(): void
    {
        $this->actingAsApi($this->userA);
        $this->postJson('/api/pinjam/101/status', ['status' => 'Proses'])->assertForbidden();

        $this->actingAsApi($this->admin);
        $this->postJson('/api/pinjam/101/status', ['status' => 'Proses'])
            ->assertOk()
            ->assertJsonPath('data.status', 'Proses');
    }

    public function test_authenticated_user_can_create_pinjam_with_generated_parent_and_item_ids(): void
    {
        $this->actingAsApi($this->userA);

        $response = $this->postJson('/api/pinjam', [
            'nama_pic' => 'User A',
            'jabatan_pic' => 'Staf TIK',
            'instansi_pic' => 'Diskominfotik',
            'kontak_pic' => '081234567890',
            'jenis_identitas' => 'NIP',
            'nomor_identitas' => '198804122014031002',
            'alamat_peminjam' => 'Bandar Lampung',
            'jenis_durasi' => 'harian',
            'tanggal_mulai' => now()->addDay()->toDateString(),
            'jam_mulai' => '08:00',
            'durasi_peminjaman' => 2,
            'keterangan' => 'Integrasi mobile',
            'items' => [
                ['item_id' => 501, 'quantity' => 1],
            ],
        ])->assertCreated()
            ->assertJsonPath('data.user_id', $this->userA->id)
            ->assertJsonPath('data.status', 'Menunggu');

        $pinjamId = $response->json('data.id');
        $this->assertIsInt($pinjamId);
        $this->assertDatabaseHas('pinjam_item', [
            'pinjam_id' => $pinjamId,
            'item_id' => 501,
            'quantity' => 1,
        ]);
    }

    public function test_pinjam_rejects_past_dates_and_accepts_today_and_future_dates(): void
    {
        $this->actingAsApi($this->userA);
        $payload = [
            'nama_pic' => 'User A',
            'instansi_pic' => 'Diskominfotik',
            'kontak_pic' => '081234567890',
            'jenis_identitas' => 'NIP',
            'nomor_identitas' => '198804122014031002',
            'alamat_peminjam' => 'Bandar Lampung',
            'jenis_durasi' => 'harian',
            'durasi_peminjaman' => 1,
            'items' => [['item_id' => 501, 'quantity' => 1]],
        ];

        $this->postJson('/api/pinjam', $payload + [
            'tanggal_mulai' => now()->subDay()->toDateString(),
        ])->assertUnprocessable()->assertJsonValidationErrors('tanggal_mulai');

        foreach ([0, 1, 2, 7, 30, 65] as $days) {
            $this->postJson('/api/pinjam', $payload + [
                'tanggal_mulai' => now()->addDays($days)->toDateString(),
            ])->assertCreated();
        }
    }

    public function test_attachment_access_is_scoped_to_owner_and_privileged_roles(): void
    {
        Storage::fake('public');
        Storage::disk('public')->put('dokumen_peminjaman/surat.pdf', '%PDF test');
        Pinjam::whereKey(101)->update(['url_dokumen' => 'dokumen_peminjaman/surat.pdf']);

        $this->actingAsApi($this->userA);
        $this->get('/api/pinjam/101/attachment/document')->assertOk();
        $this->get('/api/pinjam/102/attachment/document')->assertForbidden();
        $this->get('/api/pinjam/999999/attachment/document')->assertNotFound();

        $this->actingAsApi($this->admin);
        $this->get('/api/pinjam/101/attachment/document')->assertOk();

        $this->actingAsApi($this->superadmin);
        $this->get('/api/pinjam/101/attachment/document')->assertOk();

        Pinjam::whereKey(101)->update(['url_dokumen' => 'dokumen_peminjaman/missing.pdf']);
        $this->get('/api/pinjam/101/attachment/document')->assertNotFound();
    }

    public function test_konsultasi_cannot_be_deleted_after_processing_started(): void
    {
        $this->actingAsApi($this->userA);
        Konsultasi::whereKey(201)->update(['status' => 'Diproses']);

        $this->deleteJson('/api/konsul/201')
            ->assertStatus(409)
            ->assertJsonPath('success', false);

        $this->assertDatabaseHas('tr_konsultasi', ['id' => 201, 'deleted_at' => null]);
    }

    public function test_konsultasi_detail_and_list_enforce_ownership(): void
    {
        $this->actingAsApi($this->userA);
        $this->getJson('/api/konsul/201')->assertOk()->assertJsonPath('data.id', 201);
        $this->getJson('/api/konsul/202')->assertForbidden();
        $this->getJson('/api/konsul')->assertOk()->assertJsonCount(1, 'data.data');

        $this->actingAsApi($this->admin);
        $this->getJson('/api/konsul')->assertOk()->assertJsonCount(2, 'data.data');
    }

    public function test_only_admin_can_respond_to_konsultasi(): void
    {
        \DB::table('whatsapp_subscriptions')->insert([
            'user_id' => $this->userB->id,
            'nomor_wa' => '081234567890',
            'is_opt_in' => true,
            'verified_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        Http::fake([
            'http://127.0.0.1:4000/internal/wa/send' => Http::response([
                'success' => true,
                'status' => 'delivered',
            ]),
            '*' => Http::response(['success' => true]),
        ]);

        $this->actingAsApi($this->userA);
        $this->postJson('/api/konsul/202/response', ['isi_respon' => 'Lintas user'])->assertForbidden();
        $this->postJson('/api/konsul/201/response', ['isi_respon' => 'Balasan pemilik'])->assertForbidden();

        $this->actingAsApi($this->admin);
        $this->postJson('/api/konsul/202/response', ['isi_respon' => 'Balasan admin'])->assertCreated();
        Http::assertSent(fn ($request): bool => $request->url() === 'http://127.0.0.1:4000/internal/wa/send'
            && $request['reference']['event_type'] === 'konsultasi.responded'
            && (int) $request['reference']['user_id'] === $this->userB->id);
        $this->assertDatabaseHas('whatsapp_subscriptions', [
            'user_id' => $this->userB->id,
            'last_delivery_status' => 'delivered',
        ]);
    }

    public function test_konsultasi_create_and_response_receive_generated_ids(): void
    {
        $this->actingAsApi($this->userA);

        $createResponse = $this->postJson('/api/konsul', [
            'topik_id' => 601,
            'judul' => 'Konsultasi dari mobile',
            'deskripsi' => 'Mohon bantuan integrasi.',
        ])->assertCreated()
            ->assertJsonPath('data.user_id', $this->userA->id)
            ->assertJsonPath('data.status', 'Menunggu');

        $konsultasiId = $createResponse->json('data.id');
        $this->assertIsInt($konsultasiId);

        $this->actingAsApi($this->admin);
        $response = $this->postJson('/api/konsul/'.$konsultasiId.'/response', [
            'isi_respon' => 'Tanggapan petugas TIK.',
        ])->assertCreated();

        $responseId = $response->json('data.id');
        $this->assertIsInt($responseId);
        $this->assertDatabaseHas('tr_konsultasi_response', [
            'id' => $responseId,
            'konsultasi_id' => $konsultasiId,
            'user_id' => $this->admin->id,
        ]);
    }

    public function test_user_cannot_change_konsultasi_status_but_admin_can(): void
    {
        $this->actingAsApi($this->userA);
        $this->postJson('/api/konsul/201/status', ['status' => 'Diproses'])->assertForbidden();

        $this->actingAsApi($this->admin);
        $this->postJson('/api/konsul/201/status', ['status' => 'Diproses'])
            ->assertOk()
            ->assertJsonPath('data.status', 'Diproses');
    }

    public function test_invalid_konsultasi_status_transition_returns_bad_request(): void
    {
        Konsultasi::findOrFail(201)->update(['status' => 'Selesai']);

        $this->actingAsApi($this->admin);
        $this->postJson('/api/konsul/201/status', ['status' => 'Diproses'])
            ->assertBadRequest()
            ->assertJsonPath('success', false)
            ->assertJsonStructure(['message']);
    }

    public function test_user_cannot_delete_another_users_konsultasi(): void
    {
        $this->actingAsApi($this->userA);
        $this->deleteJson('/api/konsul/202')->assertForbidden();
    }

    public function test_usulan_email_detail_and_list_enforce_scope(): void
    {
        $this->actingAsApi($this->userA);
        $this->getJson('/api/pengajuan-email/301')->assertOk();
        $this->getJson('/api/pengajuan-email/302')->assertForbidden();
        $this->getJson('/api/pengajuan-email')->assertOk()->assertJsonCount(1, 'data.data');

        $this->actingAsApi($this->bkd);
        $this->getJson('/api/pengajuan-email')->assertOk()->assertJsonCount(2, 'data.data');
    }

    public function test_unauthorized_roles_cannot_process_usulan_email(): void
    {
        $this->actingAsApi($this->userA);

        $this->postJson('/api/pengajuan-email/301/verifikasi', ['disetujui' => true])->assertForbidden();
        $this->postJson('/api/pengajuan-email/301/buat-email-resmi', [
            'email_resmi' => 'pegawai@lampungprov.go.id',
        ])->assertForbidden();
        $this->postJson('/api/pengajuan-email/301/tolak-email', ['catatan' => 'Tidak valid'])->assertForbidden();
    }

    public function test_bkd_can_verify_and_reject_but_cannot_create_official_email(): void
    {
        $this->actingAsApi($this->bkd);

        $this->postJson('/api/pengajuan-email/301/verifikasi', [
            'catatan' => 'Valid',
        ])->assertOk()
            ->assertJsonPath('data.status', 'diajukan')
            ->assertJsonPath('data.diverifikasi_oleh', $this->bkd->name)
            ->assertJsonPath('data.catatan', 'Valid');

        $this->postJson('/api/pengajuan-email/301/buat-email-resmi', [
            'email_resmi' => 'pegawai@lampungprov.go.id',
        ])->assertForbidden();

        $this->actingAsApi($this->admin);
        $this->postJson('/api/pengajuan-email/301/buat-email-resmi', [
            'email_resmi' => 'pegawai@lampungprov.go.id',
        ])->assertOk()->assertJsonPath('data.status', 'disetujui');

        $this->actingAsApi($this->bkd);

        $this->postJson('/api/pengajuan-email/302/tolak-email', ['catatan' => 'Tidak valid'])
            ->assertOk()
            ->assertJsonPath('data.status', 'ditolak');
    }

    public function test_admin_can_create_official_email(): void
    {
        $this->actingAsApi($this->admin);

        $this->postJson('/api/pengajuan-email/301/buat-email-resmi', [
            'email_resmi' => 'pegawai@lampungprov.go.id',
        ])->assertOk()->assertJsonPath('data.status', 'disetujui');
    }

    public function test_email_submission_accepts_visible_nip_and_legacy_id_without_exposing_id_peg(): void
    {
        $this->actingAsApi($this->userA);

        $this->getJson('/api/pegawai')
            ->assertOk()
            ->assertJsonPath('data.data.0.NIP_Baru', '198001012010011001')
            ->assertJsonMissing(['ID_Peg' => '9101']);

        $this->postJson('/api/pengajuan-email', [
            'nip' => '198001012010011001',
            'email_pribadi' => 'nip-flow@example.test',
        ])->assertCreated()->assertJsonPath('data.status', 'diajukan');

        $this->postJson('/api/pengajuan-email', [
            'id_peg' => '9101',
            'email_pribadi' => 'legacy-flow@example.test',
        ])->assertCreated()->assertJsonPath('data.status', 'diajukan');

        $this->postJson('/api/pengajuan-email', [
            'nip' => '000000000000000000',
            'email_pribadi' => 'missing@example.test',
        ])->assertUnprocessable()->assertJsonValidationErrors('nip');
    }

    public function test_admin_routes_reject_user_and_allow_admin(): void
    {
        $this->actingAsApi($this->userA);
        $this->getJson('/api/admin/users')->assertForbidden();

        $this->actingAsApi($this->bkd);
        $this->getJson('/api/admin/users')->assertForbidden();

        $this->actingAsApi($this->admin);
        $this->getJson('/api/admin/users')->assertOk();

        $this->actingAsApi($this->superadmin);
        $this->getJson('/api/admin/users')->assertOk();
    }

    public function test_superadmin_dashboard_uses_roles_across_the_configured_web_guard(): void
    {
        Schema::create('activity_log', function (Blueprint $table): void {
            $table->id();
            $table->string('description');
            $table->string('causer_type')->nullable();
            $table->unsignedBigInteger('causer_id')->nullable();
            $table->timestamps();
        });
        \DB::table('activity_log')->insert([
            'description' => 'Memperbarui layanan',
            'causer_type' => User::class,
            'causer_id' => $this->admin->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $this->mock(DashboardService::class, function (MockInterface $mock): void {
            $mock->shouldReceive('getStatistikInternal')->once()->andReturn([]);
        });

        $this->actingAsApi($this->superadmin);
        $first = $this->getJson('/api/admin/dashboard')
            ->assertOk()
            ->assertJsonPath('data.scope', 'superadmin')
            ->assertJsonPath('data.admin_activity.0.actor', $this->admin->name);
        $second = $this->getJson('/api/admin/dashboard')->assertOk();

        $this->assertSame($first->json('data'), $second->json('data'));
    }

    public function test_service_reports_are_restricted_and_export_filtered_queries(): void
    {
        $this->actingAsApi($this->userA);
        $this->getJson('/api/laporan/konsultasi/data')->assertForbidden();

        $this->actingAsApi($this->admin);
        $this->getJson('/api/laporan/konsultasi/data?status=Menunggu')
            ->assertOk()
            ->assertJsonPath('data.data.0.status', 'Menunggu');

        Excel::fake();
        $this->get('/api/laporan/konsultasi/export?format=csv&status=Menunggu')->assertOk();
        Excel::assertDownloaded('konsultasi-'.now()->format('Ymd-His').'.csv');
    }

    public function test_admin_master_data_and_announcements_are_role_gated(): void
    {
        $this->actingAsApi($this->userA);
        $this->getJson('/api/admin/items')->assertForbidden();
        $this->postJson('/api/admin/pengumuman', [
            'judul' => 'Tidak boleh',
            'konten' => 'Percobaan dari user.',
        ])->assertForbidden();
        $this->postJson('/api/admin/routers', [
            'nama_opd' => 'OPD User',
            'identity_router' => 'router-user',
        ])->assertForbidden();

        $this->actingAsApi($this->admin);
        $this->getJson('/api/admin/items')
            ->assertOk()
            ->assertJsonPath('data.0.nama', 'Laptop Test');

        $router = $this->postJson('/api/admin/routers', [
            'nama_opd' => 'OPD Test',
            'identity_router' => 'router-test',
            'interface' => 'ether1',
            'lokasi' => 'Ruang server',
            'status' => 1,
        ])->assertCreated()->json('data');

        $this->putJson('/api/admin/routers/'.$router['id'], ['lokasi' => 'Ruang NOC'])
            ->assertOk()
            ->assertJsonPath('data.lokasi', 'Ruang NOC');
        $this->deleteJson('/api/admin/routers/'.$router['id'])->assertOk();
    }

    public function test_only_superadmin_can_provision_an_active_admin_account(): void
    {
        $payload = [
            'name' => 'Provisioned Admin',
            'email' => 'provisioned.admin@example.test',
            'username' => 'provisioned-admin',
            'password' => 'safe-development-password',
            'role' => 'superadmin',
        ];

        $this->postJson('/api/admin/users', $payload)->assertUnauthorized();

        $this->actingAsApi($this->userA);
        $this->postJson('/api/admin/users', $payload)->assertForbidden();

        $this->actingAsApi($this->admin);
        $this->postJson('/api/admin/users', $payload)->assertForbidden();

        $this->actingAsApi($this->superadmin);
        $response = $this->postJson('/api/admin/users', $payload)
            ->assertCreated()
            ->assertJsonPath('data.status', '1')
            ->assertJsonPath('data.roles.0.name', 'admin');

        $created = User::findOrFail($response->json('data.id'));
        $this->assertTrue($created->hasRole('admin'));
        $this->assertFalse($created->hasRole('superadmin'));
        $this->assertNotSame($payload['password'], $created->password);
    }

    public function test_admin_cannot_escalate_roles_or_manage_privileged_accounts(): void
    {
        $this->actingAsApi($this->admin);
        $this->putJson('/api/admin/users/'.$this->userA->id, ['role' => 'admin'])
            ->assertForbidden();
        $this->postJson('/api/admin/users/'.$this->superadmin->id.'/deactivate')
            ->assertForbidden();

        $this->actingAsApi($this->superadmin);
        $this->putJson('/api/admin/users/'.$this->userA->id, ['role' => 'superadmin'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('role');
    }

    private function actingAsApi(User $user): void
    {
        Passport::actingAs($user);
    }

    private function createUser(int $id, string $email, string $role): User
    {
        $user = User::create([
            'id' => $id,
            'name' => strtoupper($role).' '.$id,
            'username' => $role.$id,
            'email' => $email,
            'password' => 'not-used',
            'status' => '1',
        ]);
        $user->assignRole($role);

        return $user;
    }

    private function seedResources(): void
    {
        foreach ([[101, 1], [102, 2]] as [$id, $userId]) {
            Pinjam::create([
                'id' => $id,
                'user_id' => $userId,
                'status' => 'Menunggu',
                'tanggal_mulai' => '2026-08-10',
                'tanggal_selesai' => '2026-08-11 00:00:00',
                'created_by' => $userId,
            ]);
        }

        PinjamItem::create(['id' => 701, 'pinjam_id' => 101, 'item_id' => 501, 'quantity' => 1]);
        PinjamItem::create(['id' => 702, 'pinjam_id' => 102, 'item_id' => 501, 'quantity' => 1]);

        foreach ([[201, 1], [202, 2]] as [$id, $userId]) {
            Konsultasi::create([
                'id' => $id,
                'user_id' => $userId,
                'faq_id' => 601,
                'judul' => 'Konsultasi '.$id,
                'pesan' => 'Pesan',
                'status' => 'Menunggu',
                'created_by' => $userId,
            ]);
        }

        foreach ([[301, 1], [302, 2]] as [$id, $userId]) {
            UsulanEmail::create([
                'id' => $id,
                'id_peg_bkd' => 9000 + $id,
                'email_pribadi' => 'pegawai'.$id.'@example.test',
                'status' => 'diajukan',
                'created_by' => $userId,
            ]);
        }
    }

    private function createLegacyTestSchema(): void
    {
        Schema::dropAllTables();

        Schema::create('users', function (Blueprint $table): void {
            $table->id();
            $table->string('name');
            $table->string('nama_opd')->nullable();
            $table->string('nip')->nullable();
            $table->string('username')->unique();
            $table->string('email')->unique();
            $table->string('password');
            $table->string('status')->default('1');
            $table->rememberToken();
            $table->timestamps();
        });
        Schema::create('roles', function (Blueprint $table): void {
            $table->id();
            $table->string('name');
            $table->string('guard_name');
            $table->timestamps();
            $table->unique(['name', 'guard_name']);
        });
        Schema::create('permissions', function (Blueprint $table): void {
            $table->id();
            $table->string('name');
            $table->string('guard_name');
            $table->timestamps();
            $table->unique(['name', 'guard_name']);
        });
        Schema::create('model_has_roles', function (Blueprint $table): void {
            $table->unsignedBigInteger('role_id');
            $table->string('model_type');
            $table->unsignedBigInteger('model_id');
            $table->primary(['role_id', 'model_id', 'model_type']);
        });
        Schema::create('model_has_permissions', function (Blueprint $table): void {
            $table->unsignedBigInteger('permission_id');
            $table->string('model_type');
            $table->unsignedBigInteger('model_id');
            $table->primary(['permission_id', 'model_id', 'model_type']);
        });
        Schema::create('role_has_permissions', function (Blueprint $table): void {
            $table->unsignedBigInteger('permission_id');
            $table->unsignedBigInteger('role_id');
            $table->primary(['permission_id', 'role_id']);
        });
        Schema::create('master_item', function (Blueprint $table): void {
            $table->unsignedBigInteger('id')->primary();
            $table->string('nama');
            $table->text('deskripsi')->nullable();
            $table->integer('stok')->default(0);
            $table->softDeletes();
            $table->timestamps();
        });
        Schema::create('tr_permintaan_pinjam', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('nama_pic')->nullable();
            $table->string('jabatan_pic')->nullable();
            $table->string('instansi_pic')->nullable();
            $table->string('kontak_pic')->nullable();
            $table->string('jenis_identitas')->nullable();
            $table->string('nomor_identitas')->nullable();
            $table->string('alamat_peminjam')->nullable();
            $table->string('jenis_durasi')->nullable();
            $table->date('tanggal_mulai')->nullable();
            $table->time('jam_mulai')->nullable();
            $table->unsignedBigInteger('durasi_peminjaman')->default(0);
            $table->dateTime('tanggal_selesai')->nullable();
            $table->string('status')->default('Menunggu');
            $table->text('keterangan')->nullable();
            $table->text('url_dokumen')->nullable();
            $table->text('catatan_petugas')->nullable();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();
            $table->dateTime('waktu_pengembalian')->nullable();
            $table->string('bukti_pengembalian')->nullable();
            $table->softDeletes();
            $table->timestamps();
        });
        Schema::create('pinjam_item', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('pinjam_id');
            $table->unsignedBigInteger('item_id');
            $table->integer('quantity');
            $table->timestamps();
        });
        Schema::create('master_topik', function (Blueprint $table): void {
            $table->unsignedBigInteger('id')->primary();
            $table->string('topik');
            $table->string('status')->default('1');
            $table->softDeletes();
            $table->timestamps();
        });
        Schema::create('tr_konsultasi', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('faq_id');
            $table->string('judul');
            $table->text('pesan');
            $table->text('file')->nullable();
            $table->string('status')->default('Menunggu');
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by')->nullable();
            $table->softDeletes();
            $table->timestamps();
        });
        Schema::create('tr_konsultasi_response', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('konsultasi_id');
            $table->unsignedBigInteger('user_id');
            $table->text('pesan');
            $table->text('file')->nullable();
            $table->softDeletes();
            $table->timestamps();
        });

        Schema::create('notification', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('judul');
            $table->text('message');
            $table->string('type')->nullable();
            $table->unsignedBigInteger('item_id')->nullable();
            $table->boolean('read')->default(false);
            $table->timestamps();
        });
        Schema::create('whatsapp_subscriptions', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('user_id')->unique();
            $table->string('nomor_wa');
            $table->boolean('is_opt_in')->default(false);
            $table->timestamp('verified_at')->nullable();
            $table->string('last_delivery_status')->nullable();
            $table->timestamps();
        });
        Schema::create('usulan_email', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('id_peg_bkd');
            $table->string('email_pribadi');
            $table->string('email_resmi')->nullable();
            $table->string('status')->default('draft');
            $table->dateTime('tanggal_verifikasi')->nullable();
            $table->string('diverifikasi_oleh')->nullable();
            $table->text('catatan')->nullable();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();
            $table->timestamps();
        });
        Schema::create('PegawaiBelumPunyaEMail', function (Blueprint $table): void {
            $table->string('ID_Peg', 32)->primary();
            $table->string('NIP_Baru', 24)->nullable();
            $table->string('Nama', 117)->nullable();
            $table->string('Unit_Kerja', 255)->nullable();
            $table->string('NJab', 255)->nullable();
            $table->string('NUnKer', 255)->nullable();
            $table->string('EmailUsulan', 35)->nullable();
            $table->string('EmailPribadi', 150)->nullable();
        });
        Schema::create('unker_list_router', function (Blueprint $table): void {
            $table->id();
            $table->string('nama_opd');
            $table->text('identity_router');
            $table->string('interface')->nullable();
            $table->text('lokasi')->nullable();
            $table->integer('status')->default(1);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();
            $table->timestamps();
        });

        \DB::table('master_item')->insert([
            'id' => 501,
            'nama' => 'Laptop Test',
            'deskripsi' => 'Fixture',
            'stok' => 10,
        ]);
        \DB::table('master_topik')->insert([
            'id' => 601,
            'topik' => 'Jaringan',
            'status' => '1',
        ]);
        \DB::table('PegawaiBelumPunyaEMail')->insert([
            'ID_Peg' => '9101',
            'NIP_Baru' => '198001012010011001',
            'Nama' => 'Pegawai Test',
        ]);
    }
}
