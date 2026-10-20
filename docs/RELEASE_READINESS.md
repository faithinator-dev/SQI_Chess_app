# Release readiness

## Recommendation

**Not release-ready.** The Flutter client has useful local gameplay and secure
online-game code paths, but Supabase migrations and backend behavior remain
unverified.

## Verified locally

- Flutter source analysis completed with no errors.
- The full local Flutter test suite passed all 7 tests.
- Dart formatting completed for the changed learning screen.
- Profile/settings repositories enforce the current authenticated user boundary.
- Online move submission uses the Edge Function boundary rather than direct
  client writes.
- Service-role credentials are not present in Flutter source.
- Publishable configuration is supplied through `SUPABASE_URL` and
  `SUPABASE_PUBLISHABLE_KEY` dart defines.

## Blocked or incomplete

- Supabase SQL lint and migration execution.
- Phase 1/2 move, completion, draw, rating, RLS, concurrency, rollback, and
  Realtime integration tests.
- Competition lifecycle, pairings, standings, and admin audit operations.
- Puzzle catalogue, server-authorized completion/progress, and puzzle RLS
  verification.
- Public spectator discovery and visibility verification.
- Community feed migration and moderation.
- Platform builds, permissions, accessibility, crash reporting, and push
  notification provider configuration. The attempted web build is blocked by
  dart2js rejecting 64-bit integer literals in `dartchess 0.13.1`; this is not
  evidence of web support.

## Required configuration names

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- Edge Function server-side secret configuration for `submit-move`

Never place service-role or secret values in Flutter, source control, logs, or
client-visible configuration.

## Migration order

Apply all existing migrations in timestamp order, followed by
`20261009140000_secure_game_completion.sql` and
`20261010100000_phase3_6_foundation.sql`, followed by
`20261010110000_puzzles_foundation.sql`, only in a disposable local or
explicitly approved staging project.

## Release gate

Run SQL lint, migration checks, two-user RLS/RPC tests, Edge Function tests,
concurrency and rollback tests, Realtime tests, Flutter tests, supported
platform builds, and a manual regression suite. A mocked test or successful
Flutter analysis alone is insufficient.

## Community/admin follow-up (2026-10-10)

The community UI now uses admin-created pages with Supabase posts, likes, and
comments, subject to the unapplied migration `20261011100000_community_pages.sql`.
Admin fixture data was removed. Several admin operations remain unavailable
because the verified schema does not provide a secure management operation for
them; admin screens are not yet fully data-driven. Do not apply the migration
or claim the feature is production-ready before local/staging SQL and two-role
RLS verification.

Formatting was applied but the Dart command exited nonzero on a denied
telemetry-session file update. Flutter analysis and builds are inconclusive;
the analysis processes hung without diagnostics and were stopped. No tests,
SQL checks, migration execution, or remote Supabase access completed.

## Admin profile/role management follow-up (2026-10-11)

The Players screen now reads real profiles/presence and offers a role change
through the new `set_player_admin_role` RPC. The migration
`20261011110000_admin_role_management.sql` is unapplied, so the capability
cannot work against a database until reviewed and applied to disposable local
or approved staging Supabase. A current admin account is required. Competition,
pairing, match, and recording screens are not fully connected to live admin
datasets or trusted management operations. The release gate remains blocked.
Formatter telemetry permissions and a hanging analyzer prevented successful
validation; no test or build success is claimed.

## Lesson authoring and channel tags follow-up (2026-10-11)

Admin lesson authoring uses the existing lesson schema and a new admin-only
RLS migration, `20261011120000_admin_lesson_management.sql`. Community channels
reuse the page table/`page_id` migration and support text `#channel` tags plus
username suggestions for `@player`; mentions do not yet send notifications.
Both required migrations remain unapplied, so backend flows are not enabled
until local or approved staging validation. Targeted analysis hung without
output, and no tests or builds are verified. Release readiness remains blocked.
