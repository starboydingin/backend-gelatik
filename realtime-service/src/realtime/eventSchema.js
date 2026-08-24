const crypto = require('node:crypto');

const EVENT_CONTRACTS = Object.freeze({
    'notification': ['status'],
    'pinjam.created': ['status'],
    'pinjam.status_changed': ['status', 'old_status'],
    'konsultasi.created': ['status'],
    'konsultasi.responded': ['status', 'response_id'],
    'konsultasi.status_changed': ['status', 'old_status'],
});

const ALLOWED_EVENTS = new Set([
    ...Object.keys(EVENT_CONTRACTS),
    'pengumuman.created',
    'usulan_email.created',
    'usulan_email.status_changed',
    'chatbot.conversation.created',
    'chatbot.conversation.updated',
    'chatbot.conversation.deleted',
    'chatbot.message.created',
]);

const SENSITIVE_KEYS = new Set([
    'token',
    'access_token',
    'password',
    'authorization',
    'user_password',
]);

function isPositiveInteger(value) {
    const parsed = typeof value === 'string' && /^\d+$/.test(value)
        ? Number.parseInt(value, 10)
        : value;
    return Number.isInteger(parsed) && parsed > 0;
}

function containsSensitiveKey(value) {
    if (!value || typeof value !== 'object') return false;
    return Object.entries(value).some(([key, child]) =>
        SENSITIVE_KEYS.has(key.toLowerCase()) || containsSensitiveKey(child));
}

function normalizePayload(eventName, payload) {
    if (!ALLOWED_EVENTS.has(eventName)) {
        throw new Error('Unsupported event name');
    }
    if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
        throw new Error('Payload must be an object');
    }
    if (containsSensitiveKey(payload)) {
        throw new Error('Sensitive fields are not allowed in realtime payload');
    }

    const contract = EVENT_CONTRACTS[eventName];
    const eventId = payload.event_id || crypto.randomUUID();
    const type = payload.type || eventName;
    const entityId = payload.entity_id;
    const createdAt = payload.created_at || new Date().toISOString();

    if (typeof eventId !== 'string' || eventId.length < 8 || eventId.length > 100) {
        throw new Error('event_id must be a non-empty string');
    }
    if (type !== eventName) {
        throw new Error('Payload type must match event name');
    }
    if (Number.isNaN(Date.parse(createdAt))) {
        throw new Error('created_at must be a valid timestamp');
    }

    if (!contract) {
        const legacyPayload = { event_id: eventId, type, created_at: new Date(createdAt).toISOString() };
        for (const [key, value] of Object.entries(payload)) {
            if (SENSITIVE_KEYS.has(key.toLowerCase()) || key === 'event_id' || key === 'type' || key === 'created_at') continue;
            if (value === null || ['string', 'number', 'boolean'].includes(typeof value)) legacyPayload[key] = value;
        }
        return legacyPayload;
    }

    if (!isPositiveInteger(entityId)) {
        throw new Error('entity_id must be a positive integer');
    }

    for (const field of contract || []) {
        if (field === 'response_id') {
            if (!isPositiveInteger(payload[field])) {
                throw new Error(`${field} must be a positive integer`);
            }
        } else if (typeof payload[field] !== 'string' || payload[field].trim() === '') {
            throw new Error(`${field} must be a non-empty string`);
        }
    }

    if (payload.message !== undefined &&
        (typeof payload.message !== 'string' || payload.message.length > 500)) {
        throw new Error('message must be a string of at most 500 characters');
    }

    const allowedFields = [
        'event_id', 'type', 'entity_id', 'status', 'old_status',
        'response_id', 'created_at', 'message',
    ];
    return Object.fromEntries(
        allowedFields
            .filter((field) => payload[field] !== undefined || field === 'event_id' || field === 'type' || field === 'entity_id' || field === 'created_at')
            .map((field) => [
                field,
                field === 'entity_id' || field === 'response_id'
                    ? Number.parseInt(payload[field] ?? entityId, 10)
                    : (field === 'event_id' ? eventId : field === 'type' ? type : field === 'created_at' ? new Date(createdAt).toISOString() : payload[field]),
            ]),
    );
}

module.exports = {
    ALLOWED_EVENTS,
    EVENT_CONTRACTS,
    normalizePayload,
};
