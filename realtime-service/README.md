# Realtime service

The service exposes Socket.IO for authenticated foreground application events and an internal HTTP endpoint used by Laravel. The WhatsApp gateway remains a separate integration in this process.

## Authentication and rooms

Clients connect with the existing Laravel Passport access token in the Socket.IO handshake auth:

```js
{ auth: { token: accessToken } }
```

The service verifies that token against `GET /api/me`. It then assigns rooms from the verified identity only:

- `user_{id}` for the authenticated user;
- `role_admin` for `admin`;
- `role_superadmin` for `superadmin`.

There is no client-controlled room join event. Laravel targets `user` or the logical `admin` role through the authenticated internal API.

## Event contract

Peminjaman and Konsultasi events use this minimal payload:

```json
{
  "event_id": "uuid-or-unique-id",
  "type": "pinjam.status_changed",
  "entity_id": 123,
  "status": "Proses",
  "old_status": "Menunggu",
  "response_id": 456,
  "created_at": "2026-08-06T00:00:00.000Z",
  "message": "Status peminjaman berubah"
}
```

Only fields relevant to an event are sent. Tokens, passwords, full user objects, attachments, and raw database rows are rejected. Flutter treats REST as authoritative: a valid event triggers a coalesced REST refresh.

Supported application events are `pinjam.created`, `pinjam.status_changed`, `konsultasi.created`, `konsultasi.responded`, and `konsultasi.status_changed`. Existing announcement/email broadcasts remain compatible but are not part of the mobile status contract.

## Operations

Copy `.env.example` to `.env`, configure `LARAVEL_BASE_URL`, `INTERNAL_SERVICE_API_KEY`, and production CORS origins, then run `npm test` or `npm start`. Tests use only fakes and do not require Laravel, Socket.IO clients, or a WhatsApp session.
