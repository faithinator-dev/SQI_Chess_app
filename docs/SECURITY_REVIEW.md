# Security review

**Scope:** static review of the current Flutter client, Supabase migrations,
Edge Function boundary, and Phase 3-6 foundation. No database or Edge Function
runtime was available.

| Severity | Area | Finding | Status |
|---|---|---|---|
| HIGH | Backend verification | Phase 1/2 completion, draw, rating, RLS, grants, concurrency, and Realtime behavior have not run against Postgres/Supabase. | Open; staging required |
| HIGH | Admin | Admin screens use local/demo data and no verified server-authorized admin mutation contract or audit log exists. | Open; do not expose as authoritative |
| HIGH | Learning | Published lesson content and progress require a real Supabase runtime to verify. | Open; staging required |
| MEDIUM | Puzzles | A published puzzle read schema and local trusted solution-line validator now exist, but no server-authorized completion/progress operation or production catalogue exists. | Open; add trusted backend validation |
| MEDIUM | Spectator | Public spectator reads depend on the unexecuted visibility/RLS migration. Existing spectator discovery is demo-driven. | Open; apply and test migration |
| MEDIUM | Community | The large community screen models channel chat, while the backend currently models posts/comments/likes. | Open; reconcile product contract |
| MEDIUM | Platform | LAN uses `dart:io` sockets and is not web-compatible. The web build is also blocked by dart2js rejecting 64-bit integer literals in `dartchess 0.13.1`; Android/iOS builds and permissions remain unverified. | Open; hide LAN on web, resolve the dependency/toolchain issue, or add another transport |
| LOW | Configuration | A publishable-key example was present in a source comment. | Fixed; removed from `lib/main.dart` |
| INFORMATIONAL | Secrets | No service-role or secret Supabase key was found in Flutter code. | Verified statically; recheck release artifacts |

Static review is not a security certification. The next review must include
authenticated two-user RLS tests, RPC permission tests, concurrent requests,
Edge Function authentication, and Realtime privacy checks on a disposable
local or approved staging project.

## Local validation update

- `flutter test`: passed all 7 tests.
- `flutter analyze --no-fatal-infos`: passed with five existing informational
  diagnostics and no errors.
- `flutter build web --no-pub`: blocked by the `dartchess 0.13.1` dart2js
  compatibility error described above.
- No Supabase project was contacted and no migration or function was deployed.

## Community/admin follow-up (2026-10-10)

- Community now expects authenticated reads from `community_pages`,
  `community_posts`, `community_post_likes`, and `community_comments`; write
  ownership continues to rely on existing post/comment/like RLS. The new
  migration gates page creation and updates on `profiles.role = 'admin'` and
  records `created_by = auth.uid()`.
- `20261011100000_community_pages.sql` is review-only and has not been run.
  Validate its RLS behavior with an admin and a non-admin user before use.
- Admin seed records were removed. Operations without a verified backend
  authorization contract are unavailable in the UI and do not mutate records.
- No migration, remote database, production data, or function was changed.
- Analyzer/build verification is inconclusive because Dart telemetry writes
  were denied and Flutter analysis hung. No security or release claim follows
  from static edits alone.

## Admin role management increment (2026-10-11)

- The verified profile schema stores `role` as `player` or `admin`; signup
  assigns `player`. No existing client role mutation endpoint was present.
- Added a review-only migration for `current_user_is_admin()`, admin-only
  profile SELECT access, an audit table, and the `set_player_admin_role`
  security-definer RPC. It authorizes by the caller's stored profile role,
  serializes concurrent role changes, preserves at least one admin, and logs
  changes. Direct authenticated writes to the audit table are revoked.
- The SQL has not run against PostgreSQL/Supabase. Syntax, grants, and behavior
  need local migration validation and two-role authorization tests.
- Admin user reads now request profile and presence fields covered by current
  schema/policies. Other admin data screens remain incomplete. No ratings,
  results, or statistics are client-editable through this change.
- `flutter analyze --no-pub` was stopped after 30 seconds without diagnostics;
  no test or platform build passed in this increment.

## Lesson authoring and channel tagging increment (2026-10-11)

- `20261011120000_admin_lesson_management.sql` grants authenticated lesson
  read/insert/update and gates all lesson reads beyond the existing published
  policy and all writes on the caller's `profiles.role = 'admin'`. It is
  review-only and unapplied. Lesson creation uses only columns confirmed in
  the initial schema. Admin lesson operations are enforced by RLS, not only by
  hiding UI controls.
- Community page/channel creation remains admin-only under the existing
  review-only page migration. Mention suggestions read only profiles visible
  under profile RLS. `@username` and `#channel` are stored/displayed as post
  text; mentions do not trigger notification events.
- Format completed before the Dart telemetry write failed. Targeted analyzer
  hung without output and was stopped. SQL, tests, and builds remain unverified.
