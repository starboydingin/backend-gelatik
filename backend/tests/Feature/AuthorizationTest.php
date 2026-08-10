<?php

namespace Tests\Feature;

use App\Models\Konsultasi;
use App\Models\Pinjam;
use App\Models\PinjamItem;
use App\Models\User;
use App\Models\UsulanEmail;
use App\Services\ChatbotService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Schema;
use Laravel\Passport\Passport;
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
            'tanggal_mulai' => '2026-08-10',
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

    public function test_konsultasi_detail_and_list_enforce_ownership(): void
    {
        $this->actingAsApi($this->userA);
        $this->getJson('/api/konsul/201')->assertOk()->assertJsonPath('data.id', 201);
        $this->getJson('/api/konsul/202')->assertForbidden();
        $this->getJson('/api/konsul')->assertOk()->assertJsonCount(1, 'data.data');

        $this->actingAsApi($this->admin);
        $this->getJson('/api/konsul')->assertOk()->assertJsonCount(2, 'data.data');
    }

    public function test_only_owner_or_admin_can_respond_to_konsultasi(): void
    {
        $this->actingAsApi($this->userA);
        $this->postJson('/api/konsul/202/response', ['isi_respon' => 'Lintas user'])->assertForbidden();
        $this->postJson('/api/konsul/201/response', ['isi_respon' => 'Balasan pemilik'])->assertCreated();

        $this->actingAsApi($this->admin);
        $this->postJson('/api/konsul/202/response', ['isi_respon' => 'Balasan admin'])->assertCreated();
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

        $response = $this->postJson('/api/konsul/'.$konsultasiId.'/response', [
            'isi_respon' => 'Informasi tambahan dari pemilik.',
        ])->assertCreated();

        $responseId = $response->json('data.id');
        $this->assertIsInt($responseId);
        $this->assertDatabaseHas('tr_konsultasi_response', [
            'id' => $responseId,
            'konsultasi_id' => $konsultasiId,
            'user_id' => $this->userA->id,
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
