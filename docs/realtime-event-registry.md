# Gelatik realtime event registry

Laravel REST remains the source of truth. Socket.IO payloads contain only an
event identifier, resource metadata, and never a database row or credential.
Every client invalidates the mapped cache and reads the latest authorized REST
resource.

| Event | Target | Resource action |
| --- | --- | --- |
| `data.sync` | owning user and/or admin room | Refresh the mapped business resource after commit. |
| `insights.sync` | authenticated clients | Invalidate dashboard aggregation only. |
| `notification` | owning user or admin room | Refresh inbox, unread badge, and read state. |
| `pinjam.created`, `pinjam.status_changed` | owning user/admin room | Refresh loan list/detail and calendar. |
| `konsultasi.created`, `konsultasi.responded`, `konsultasi.status_changed` | owning user/admin room | Refresh consultation list/detail and calendar. |
| `usulan_email.created`, `usulan_email.status_changed` | owning user/admin room | Refresh email request list/detail. |
| `kritik_saran.created` | admin room | Refresh feedback moderation list. |
| `chatbot.conversation.*`, `chatbot.message.created` | owning user room | Refresh the matching chatbot session. |

Events are queued in `RealtimeDataSyncService` and flushed by Laravel's
post-response deferred-callback middleware. Bursts are coalesced per target,
event, entity, and resource. Web and mobile clients debounce per normalized
resource, so a specific business event followed by `data.sync` causes one
authoritative REST refresh rather than competing requests.

## Adding a shared resource

1. Persist the mutation through Laravel and let the transaction commit.
2. Register the model with `RealtimeDataObserver`, or explicitly call
   `RealtimeDataSyncService` for query-builder mutations.
3. Choose `user`, `admins`, `userAndAdmins`, `everyone`, or `insights` based
   on authorization—not on a client-provided room identifier.
4. Add the resource-to-endpoint mapping in web `src/lib/api.js` and mobile
   `ApiClient.invalidateCacheForResource`.
5. Refresh only the provider/page that owns the resource and add a test.

Socket reconnects reconcile the active website resource and the mobile account
providers from REST. Merely focusing or switching a healthy browser tab does
not invalidate cache, remount a page, or issue a network request.

Local browser origins must be listed explicitly in
`realtime-service/.env`/`.env.example`; the maintained development defaults are
`localhost:5173` and `127.0.0.1:5173` in addition to the legacy origins.
