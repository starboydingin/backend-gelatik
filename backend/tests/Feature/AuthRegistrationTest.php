<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Laravel\Passport\ClientRepository;
use Laravel\Passport\Passport;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

class AuthRegistrationTest extends TestCase
{
    private const OPD = 'Dinas Komunikasi dan Informatika';

    protected function setUp(): void
    {
        parent::setUp();

        $this->createAuthSchema();
        app(PermissionRegistrar::class)->forgetCachedPermissions();
        Role::create(['name' => 'user', 'guard_name' => 'web']);
        Role::create(['name' => 'admin', 'guard_name' => 'web']);
        app(ClientRepository::class)->createPersonalAccessGrantClient(
            'Layanantik Test Personal Access Client',
            'users'
        );

        \DB::table('unker_list_router')->insert([
            'id' => 1,
            'nama_opd' => self::OPD,
            'status' => '1',
        ]);
    }

    public function test_registration_activates_user_and_returns_auth_contract(): void
    {
        $response = $this->postJson('/api/register', $this->validPayload())
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Registrasi berhasil. Akun Anda sudah aktif.')
            ->assertJsonPath('data.user.status', '1')
            ->assertJsonPath('data.user.email', 'pegawai.baru@example.test')
            ->assertJsonPath('data.token_type', 'Bearer')
            ->assertJsonStructure(['data' => ['user', 'access_token', 'token_type']]);

        $token = $response->json('data.access_token');
        $this->assertIsString($token);
        $this->assertNotSame('', $token);

        $user = User::where('email', 'pegawai.baru@example.test')->firstOrFail();
        $this->assertSame('1', (string) $user->status);
        $this->assertTrue($user->hasRole('user'));
        $this->assertFalse($user->hasAnyRole(['admin', 'superadmin']));
        $this->assertTrue(Hash::check('password123', $user->password));
        $this->assertNotSame('password123', $user->password);
    }

    public function test_newly_registered_user_can_login_without_admin_approval(): void
    {
        $this->postJson('/api/register', $this->validPayload())->assertCreated();

        $this->postJson('/api/login', [
            'identifier' => 'pegawai.baru@example.test',
            'password' => 'password123',
        ])->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.status', '1')
            ->assertJsonPath('data.token_type', 'Bearer')
            ->assertJsonStructure(['data' => ['access_token']]);
    }

    public function test_public_registration_cannot_self_assign_a_privileged_role(): void
    {
        $this->postJson('/api/register', $this->validPayload([
            'role' => 'admin',
            'is_admin' => true,
        ]))->assertCreated();

        $user = User::where('email', 'pegawai.baru@example.test')->firstOrFail();
        $this->assertTrue($user->hasRole('user'));
        $this->assertFalse($user->hasAnyRole(['admin', 'superadmin']));
    }

    public function test_me_exposes_spatie_roles_for_realtime_room_authorization(): void
    {
        $admin = $this->createUser('realtime.admin@example.test', '1');
        $admin->assignRole('admin');

        Passport::actingAs($admin);

        $this->getJson('/api/me')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.id', $admin->id)
            ->assertJsonPath('data.roles.0.name', 'admin')
            ->assertJsonMissingPath('data.password');
    }

    public function test_inactive_existing_user_remains_inactive_and_cannot_login(): void
    {
        $inactive = $this->createUser('inactive@example.test', '0');

        $this->postJson('/api/login', [
            'identifier' => $inactive->email,
            'password' => 'password123',
        ])->assertForbidden()
            ->assertJsonPath('message', 'Akun Anda belum aktif atau telah dinonaktifkan.');

        $this->assertSame('0', (string) $inactive->fresh()->status);
    }

    public function test_admin_can_still_deactivate_an_account_and_login_is_rejected(): void
    {
        $admin = $this->createUser('admin@example.test', '1');
        $admin->assignRole('admin');
        $user = $this->createUser('target@example.test', '1');
        $user->assignRole('user');

        Passport::actingAs($admin);
        $this->postJson("/api/admin/users/{$user->id}/deactivate")
            ->assertOk()
            ->assertJsonPath('data.status', '0');

        $this->postJson('/api/login', [
            'identifier' => $user->email,
            'password' => 'password123',
        ])->assertForbidden();
    }

    public function test_registration_validation_and_opd_contract_remain_enforced(): void
    {
        $invalid = $this->validPayload([
            'email' => 'bukan-email',
            'nip' => '123',
            'nama_opd' => 'OPD Tidak Terdaftar',
            'password_confirmation' => 'berbeda',
        ]);

        $this->postJson('/api/register', $invalid)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email', 'nip', 'password']);

        $invalid['email'] = 'valid@example.test';
        $invalid['nip'] = '199501012022031002';
        $invalid['password_confirmation'] = 'password123';
        $this->postJson('/api/register', $invalid)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['nama_opd']);
    }

    public function test_duplicate_email_and_nip_are_rejected(): void
    {
        $this->postJson('/api/register', $this->validPayload())->assertCreated();

        $this->postJson('/api/register', $this->validPayload([
            'nip' => '199501012022031002',
        ]))->assertUnprocessable()->assertJsonValidationErrors(['email']);

        $this->postJson('/api/register', $this->validPayload([
            'email' => 'pegawai.lain@example.test',
        ]))->assertUnprocessable()->assertJsonValidationErrors(['nip']);
    }

    private function validPayload(array $overrides = []): array
    {
        return array_merge([
            'name' => 'Pegawai Baru',
            'email' => 'pegawai.baru@example.test',
            'nip' => '199501012022031001',
            'no_hp' => '081234567890',
            'nama_opd' => self::OPD,
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ], $overrides);
    }

    private function createUser(string $email, string $status): User
    {
        return User::create([
            'name' => 'Test User',
            'username' => str_replace(['@', '.'], '-', $email),
            'email' => $email,
            'password' => Hash::make('password123'),
            'status' => $status,
        ]);
    }

    private function createAuthSchema(): void
    {
        Schema::dropAllTables();

        Schema::create('users', function (Blueprint $table): void {
            $table->id();
            $table->string('name');
            $table->string('nama_opd')->nullable();
            $table->string('username')->unique();
            $table->string('nip', 18)->nullable()->unique();
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->rememberToken();
            $table->string('no_hp')->nullable();
            $table->string('status')->default('0');
            $table->timestamps();
        });
        Schema::create('unker_list_router', function (Blueprint $table): void {
            $table->unsignedBigInteger('id')->primary();
            $table->string('nama_opd');
            $table->string('status')->default('1');
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
        Schema::create('oauth_clients', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->nullableMorphs('owner');
            $table->string('name');
            $table->string('secret')->nullable();
            $table->string('provider')->nullable();
            $table->text('redirect_uris');
            $table->text('grant_types');
            $table->boolean('revoked');
            $table->timestamps();
        });
        Schema::create('oauth_access_tokens', function (Blueprint $table): void {
            $table->char('id', 80)->primary();
            $table->unsignedBigInteger('user_id')->nullable()->index();
            $table->uuid('client_id');
            $table->string('name')->nullable();
            $table->text('scopes')->nullable();
            $table->boolean('revoked');
            $table->timestamps();
            $table->dateTime('expires_at')->nullable();
        });
        Schema::create('oauth_refresh_tokens', function (Blueprint $table): void {
            $table->char('id', 80)->primary();
            $table->char('access_token_id', 80)->index();
            $table->boolean('revoked');
            $table->dateTime('expires_at')->nullable();
        });
    }
}
