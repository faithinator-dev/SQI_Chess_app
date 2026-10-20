# Phases 3-6 implementation report

## Completed in this increment

- Added the reviewable migration
  `20261010100000_phase3_6_foundation.sql`.
- Added typed `CompetitionModel`.
- Added `CompetitionRepository` for published competition reads and
  authenticated register/withdraw RPC calls.
- Removed hardcoded competition records from the competition list runtime path.
  The existing card/detail presentation is retained through a compatibility
  map until the detail and lobby screens accept typed models.
- Added explicit loading, empty, and unavailable/retry states to the
  competition list.

## Migration contents

- `games.visibility` with `private`, `unlisted`, and `public` values.
- Competition, registration, round, and pairing tables.
- Foreign keys, uniqueness constraints, capacity/status checks, and indexes.
- Published competition read policies.
- Authenticated registration and withdrawal functions with row locking and
  capacity checks.
- Public active/completed game and move read policies for spectators.

The migration has not been applied to any database.

## Deliberately not completed

- Organizer/admin mutation RPCs and audit logs.
- Pairing generation and standings.
- Full admin dashboard data replacement.
- Public spectator discovery and replay screen replacement.
- Community screen replacement. The current screen is a channel-chat prototype,
  while the existing backend is a post feed; silently mapping one to the other
  would lose behavior.
- Moderation, reports, notifications, and private media storage.

These require additional backend contracts and staging verification. Existing
local PvP, bot, LAN, and secure online-game code was not changed.

## Verification

Completed:

- Dart formatting for the three changed Dart files.
- Targeted problem diagnostics: no errors.
- `flutter analyze --no-fatal-infos`: passed with the five existing
  informational diagnostics documented in the main audit.

Inconclusive:

- `flutter test`: Flutter could not compile the test isolate because the
  Windows temporary disk was full (`OS error 112`). This is not a test pass.
- Supabase SQL lint and integration tests remain blocked until a local or
  approved staging runtime is available. No claim of backend integration
  success is made.
