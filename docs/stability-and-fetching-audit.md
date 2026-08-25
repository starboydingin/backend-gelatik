# Stability and fetching audit

This document records the verified fetch/realtime contract after the August
2026 stabilization pass. Laravel REST and MySQL remain authoritative; browser
and mobile caches are short-lived, account-scoped read accelerators.

## Request and invalidation map

| Resource | Main REST reads | Cache/invalidation | Realtime consumer |
| --- | --- | --- | --- |
| Dashboard/insights | `/dashboard`, `/admin/dashboard` | 30 s client TTL; 30/120 s Laravel SWR; invalidated by business mutations | active dashboard/Home only |
| Consultations | `/konsul`, `/konsul/{id}` | token + URL + query/page; `konsultasi` invalidation | consultation list/detail |
| Loans | `/pinjam`, `/pinjam/{id}` | token + URL + query/page; `peminjaman` invalidation | loan list/detail/calendar |
| Email requests | `/pengajuan-email*` | token + URL + query/page; `usulan_email` invalidation | email list/detail |
| Notifications | `/notifications` | 20 s; fresh read on `notification`; latest-response-wins | inbox and unread badge |
| Feedback | `/kritik-saran/mine`, `/admin/kritik-saran` | token-scoped; `kritik_saran` invalidation | user history/admin moderation |
| Reference data | `/faq`, `/topik`, `/items`, `/list-router-opd` | 5 min; resource-specific invalidation | owning page/provider only |

Website credentials live in `sessionStorage`, so user and admin sessions in
different tabs do not overwrite each other. Cache keys include the current
access token. Mobile keys include the secure-storage token and all query/page
parameters; logout explicitly clears the in-memory cache.

There is no focus/visibility-triggered global refresh. Normal navigation uses
lazy route chunks and per-page GET cache. Socket listeners are centralized and
removed during logout/disposal. Reconnect reconciliation is distinct from tab
activation.

## Backend findings and measurements

Measurements were taken against the local MySQL data set on 25 August 2026;
times include the Windows PHP development server and are not production SLAs.

| Check | Before | After |
| --- | --- | --- |
| Admin feedback page | 3 queries, 2,907-byte JSON, 4.06 ms median warm service call | 3 queries, 1,635-byte JSON, 4.11 ms median warm service call before reply data; populated responder remains bounded at 4 queries |
| Feedback user lookup plan | no index, filesort | `kritik_sarans_user_created_idx`, no filesort |
| Notification user lookup plan | primary-key scan with user filter | `notification_user_id_id_idx` |
| Admin dashboard cold → cached | cached response became `__PHP_Incomplete_Class` and lost all list rows | 2,045 ms → 1,390 ms locally; byte-identical 14,921-byte JSON; five recent rows retained |
| User dashboard cold → cached | nested Eloquent values were unsafe for the database cache | 1,436 ms → 1,267 ms locally; byte-identical 11,481-byte JSON |

Dashboard cache values are now arrays/scalars only. This is required by the
database cache store's safe unserialization policy and prevents the previous
“first page works, next navigation has empty data” regression.

Notification `mark-all-read` uses one bulk upsert instead of one query per
broadcast notification. Notification responses include an authoritative
`unread_count`; the dropdown still renders only five recent records but no
longer caps the badge at five.

## Operational verification

- Two tabs authenticated simultaneously as different admin/user accounts and
  retained their own routes and identities.
- A feedback reply created the durable notification and updated the user
  dropdown from 6 to 7 without reload after Socket.IO origin correction.
- WhatsApp health reported `connected` with the existing Baileys session.
- Starting a second realtime process returned a concise port-4000 conflict and
  did not initialize/take over WhatsApp.
- Flutter passed 263 tests and static analysis, Node passed 15 tests, and
  Laravel passed 8 unit tests (18 assertions). The website production build
  transformed 847 modules successfully; the Android debug APK also built.
- Android disables Kotlin incremental compilation because the project is on
  drive `E:` while the Windows Pub cache is on drive `C:`. This avoids the
  Kotlin cache path-relativization failure without changing application code.

The local PHP installation has no `pdo_sqlite`, so SQLite-backed Laravel feature
tests cannot execute on this workstation; MySQL integration checks and browser
regression testing cover the affected paths here.
