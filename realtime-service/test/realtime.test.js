const assert = require('node:assert/strict');
const test = require('node:test');

const { validateRuntimeConfig } = require('../src/config');
const { normalizePayload } = require('../src/realtime/eventSchema');
const {
    createAuthMiddleware,
    createBroadcaster,
    createConnectionRegistry,
    getRoleRooms,
    getRoomsForIdentity,
} = require('../src/socket/socketHandler');

const validEnv = {
    LARAVEL_BASE_URL: 'http://127.0.0.1:8000',
    INTERNAL_SERVICE_API_KEY: 'test-internal-key',
    SOCKET_CORS_ORIGINS: 'http://localhost:8000',
};

test('runtime configuration validates required values', () => {
    assert.equal(validateRuntimeConfig(validEnv).ok, true);
    assert.equal(validateRuntimeConfig({}).ok, false);
    assert.match(validateRuntimeConfig({}).errors.join(','), /LARAVEL_BASE_URL/);
});

test('socket without token is rejected', async () => {
    let error;
    await createAuthMiddleware({ verifyToken: async () => ({ id: 1 }) })(
        { handshake: { auth: {} } },
        (nextError) => { error = nextError; },
    );
    assert.equal(error.message, 'unauthorized');
});

test('invalid token and backend verification failures are rejected', async () => {
    for (const verifyToken of [
        async () => { throw new Error('invalid'); },
        async () => { throw new Error('backend unavailable'); },
    ]) {
        let error;
        await createAuthMiddleware({ verifyToken })(
            { handshake: { auth: { token: 'secret' } } },
            (nextError) => { error = nextError; },
        );
        assert.equal(error.message, 'unauthorized');
    }
});

test('authenticated user can only receive own user room', async () => {
    const socket = { handshake: { auth: { token: 'secret' } } };
    let nextError;
    await createAuthMiddleware({ verifyToken: async () => ({ id: 42, role: 'user' }) })(socket, (error) => {
        nextError = error;
    });
    assert.equal(nextError, undefined);
    assert.deepEqual(socket.authenticatedRooms, ['user_42']);
    assert.equal(getRoomsForIdentity({ id: 42, role: 'user', requestedRoom: 'user_7' }).includes('user_7'), false);
});

test('admin room is restricted to admin and superadmin identities', () => {
    assert.deepEqual(getRoomsForIdentity({ id: 1, role: 'admin' }), ['user_1', 'role_admin']);
    assert.deepEqual(getRoomsForIdentity({ id: 2, role: 'superadmin' }), ['user_2', 'role_superadmin']);
    assert.deepEqual(getRoomsForIdentity({ id: 3, role: 'user' }), ['user_3']);
    assert.deepEqual(getRoleRooms('admin'), ['role_admin', 'role_superadmin']);
    assert.throws(() => getRoleRooms('user'));
});

test('valid event payload is normalized to the minimal contract', () => {
    const payload = normalizePayload('pinjam.status_changed', {
        event_id: 'evt-12345678',
        type: 'pinjam.status_changed',
        entity_id: '8',
        status: 'Proses',
        old_status: 'Menunggu',
        created_at: '2026-08-06T00:00:00.000Z',
        message: 'Status berubah',
        extra_sensitive_row: 'discarded',
    });
    assert.deepEqual(payload, {
        event_id: 'evt-12345678',
        type: 'pinjam.status_changed',
        entity_id: 8,
        status: 'Proses',
        old_status: 'Menunggu',
        created_at: '2026-08-06T00:00:00.000Z',
        message: 'Status berubah',
    });
});

test('malformed or sensitive payload is rejected safely', () => {
    assert.throws(() => normalizePayload('pinjam.status_changed', { entity_id: 1 }), /status/);
    assert.throws(() => normalizePayload('pinjam.status_changed', {
        entity_id: 1, status: 'Proses', old_status: 'Menunggu', token: 'secret',
    }), /Sensitive/);
    assert.throws(() => normalizePayload('pinjam.status_changed', {
        entity_id: 0, status: 'Proses', old_status: 'Menunggu',
    }), /entity_id/);
});

test('events are routed to the correct user or admin rooms', () => {
    const calls = [];
    const fakeIo = {
        to(room) {
            return { emit(event, payload) { calls.push({ room, event, payload }); } };
        },
        emit(event, payload) { calls.push({ room: 'all', event, payload }); },
    };
    const broadcaster = createBroadcaster(fakeIo);
    broadcaster.broadcastToUser(9, 'pinjam.status_changed', { entity_id: 1 });
    broadcaster.broadcastToRole('admin', 'pinjam.created', { entity_id: 2 });
    assert.deepEqual(calls.map((call) => call.room), ['user_9', 'role_admin', 'role_superadmin']);
});

test('disconnect removes connection state', () => {
    const registry = createConnectionRegistry();
    registry.add('socket-1', ['user_1']);
    assert.equal(registry.has('socket-1'), true);
    assert.deepEqual(registry.rooms('socket-1'), ['user_1']);
    registry.remove('socket-1');
    assert.equal(registry.has('socket-1'), false);
    assert.equal(registry.size(), 0);
});
