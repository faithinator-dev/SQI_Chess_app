# SQI Checkmate Arena staging integration tests

This document is a runbook for a disposable local Supabase stack or an
explicitly approved staging project. It is not a production deployment guide.
The current repository has no running local Postgres/Supabase instance, so the
tests below have not been executed from this checkout.

## Safety rules

- Never use a production project for these tests.
- Do not run `supabase link`, `supabase db push`, or `supabase functions deploy`
  until the target project and deployment are explicitly approved.
- Use placeholders for all URLs, project references, access tokens, and
  service-role secrets.
- The service-role secret must exist only in the Edge Function environment or
  local Supabase secret store. It must never be placed in Flutter, test source,
  shell history, or committed files.
- Use two authenticated human test users and a third unauthenticated or
  non-player client.

## Required tools and environment

Install and verify:

```powershell
supabase --version
docker version
flutter --version
```

The local Supabase CLI requires Docker. Start the disposable stack from the
repository root:

```powershell
supabase start
supabase status
```

If Docker is unavailable, stop at this point. Do not substitute a production
project.

The migration sequence must be applied to a clean database in this order:

1. `20261009000100_initial_schema.sql`
2. `20261009000200_indexes_and_rls.sql`
3. `20261009000300_account_functions_and_triggers.sql`
4. `20261009000400_profile_and_settings_functions.sql`
5. `20261009000500_matchmaking_functions.sql`
6. `20261009000600_notifications_and_presence.sql`
7. `20261009000700_game_actions.sql`
8. `20261009000800_realtime_publication.sql`
9. `20261009110000_profile_game_security.sql`
10. `20261009140000_secure_game_completion.sql`
11. `20261010100000_phase3_6_foundation.sql`
12. `20261010110000_puzzles_foundation.sql`

Use the CLI's normal local migration workflow and inspect failures. Do not
manually skip a failed migration.

After migrations:

```powershell
supabase db lint --local --fail-on error
supabase status
```

The final migration assumes the Supabase-managed `supabase_realtime`
publication exists. Its draw-offer publication addition is idempotent, but the
publication itself is a platform prerequisite.

## Edge Function setup

The `submit-move` function requires these server-only variables:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY` or the approved server-side secret equivalent

For a local stack, configure them through the Supabase local secret mechanism
and verify with `supabase secrets list`. Do not print secret values.

Serve the function locally only after migrations and test users are ready:

```powershell
supabase functions serve submit-move
```

The Flutter request contract is exactly:

```json
{"game_id":"<uuid>","uci":"e2e4"}
```

The function must return `success`, `game_id`, `move`, `result`,
`termination_reason`, `state_version`, and `committed` on success. The
database RPC accepts the internal fields documented in
`20261009000700_game_actions.sql` and overridden by
`20261009140000_secure_game_completion.sql`; Flutter must not call that
service-role-only RPC.

## Seed controlled test data

Create two auth users through the local Auth API or Supabase Studio, allowing
the signup triggers to create profiles and settings. Record only the generated
test UUIDs in an uncommitted local test note.

Create active games only through the existing authenticated matchmaking RPC or
an approved staging-only fixture using the database owner. For each fixture,
verify:

- `game_type`
- `status = 'active'`
- both human player IDs
- `current_fen = 'startpos'` or a valid FEN
- `current_turn`
- positive clocks
- `state_version`
- `white_time_ms` and `black_time_ms`
- `started_at` and `updated_at`

Create one `online_random` rated fixture and one `bot`/unrated fixture. Do not
use a client write to manufacture authoritative moves or results.

## Test matrix

### Migration and contract tests

1. Apply all migrations to an empty database.
2. Re-run the final migration in a disposable reset test; it must not fail due
   to the draw-offer publication membership check.
3. Inspect function signatures in `pg_proc` and confirm:
   - `offer_draw(uuid)` is executable by `authenticated`.
   - `respond_draw_offer(uuid, boolean)` is executable by `authenticated`.
   - `expire_game_on_timeout(uuid)` is executable by `authenticated`.
   - `resign_game(uuid)` is executable by `authenticated`.
   - `commit_validated_move(...)` is executable only by `service_role`.
   - `apply_game_completion(...)` is not executable by `anon` or
     `authenticated`.
4. Confirm `game_draw_offers` and `game_completions` have RLS enabled.
5. Confirm no `INSERT`, `UPDATE`, or `DELETE` policy exists for clients on
   `games`, `game_moves`, `game_draw_offers`, or `game_completions`.
6. Confirm `game_draw_offers` is in `supabase_realtime`.

### Move validation tests

For each request, query the game before and after and record `state_version`,
move count, FEN, turn, status, result, and profile counters.

1. Authenticated player submits a legal move such as `e2e4`.
   - Expect HTTP 200.
   - Expect one move, state version +1, authoritative FEN, and next turn.
2. Submit malformed UCI.
   - Expect `INVALID_UCI`.
   - Expect no database change.
3. Submit a legal-shape but illegal move.
   - Expect `ILLEGAL_MOVE`.
   - Expect no database change.
4. Unauthenticated request.
   - Expect `AUTH_REQUIRED` or `INVALID_SESSION`.
5. Authenticated non-player request.
   - Expect `NOT_A_GAME_PLAYER`.
6. Submit with a concurrent state change.
   - Expect `STALE_GAME_STATE`, `NOT_YOUR_TURN`, or
     `MOVE_ALREADY_COMMITTED`.
   - Expect exactly one committed move.
7. Submit after completion.
   - Expect `GAME_NOT_ACTIVE`.
   - Expect no new move or counter change.
8. Send two concurrent moves from the same pre-move state.
   - Expect exactly one success and one safe conflict.

### Draw-offer tests

1. Player A offers a draw in an active human game.
   - Expect one pending row with the current `state_version`.
   - Game result/status must remain unchanged.
2. Player A offers again while one is pending.
   - Expect a unique-constraint/RPC failure.
3. Player B declines.
   - Expect offer `declined`, no game completion, no rating/statistics change.
4. Player B accepts while the game is active and unchanged.
   - Expect game `completed`, result `draw`, termination `agreement`,
     state version +1, and one completion row.
5. A non-player tries to respond.
   - Expect authorization failure and no state change.
6. Advance the game, then respond to an old offer.
   - Expect `Draw offer is stale`.
7. Try to respond after resignation, timeout, or checkmate.
   - Expect unavailable/stale failure and no second completion.
8. Verify both authenticated clients receive the draw-offer and completed-game
   Realtime events.

### Completion, ratings, and statistics

For a rated `online_random` or `online_friend` game with both profiles at
known ratings:

1. Complete by checkmate.
2. Complete a separate game by resignation.
3. Complete a separate game by timeout.
4. Complete a separate game by agreed draw.
5. For each game, assert exactly one `game_completions` row.
6. Assert both players' `games_played` increment exactly once.
7. Assert wins/losses/draws match the authoritative result.
8. Assert Elo uses K=32 and expected score from the pre-game ratings.
9. Retry the same completion through a repeated RPC request or replayed client
   request; assert no second ledger row, counter change, or rating change.
10. Force a profile-update failure in a disposable transaction fixture; assert
    the game completion and profile updates roll back together.
11. Repeat with a bot/LAN/local game; assert no rating or profile statistic
    changes.
12. Mark a game abandoned/disconnected without a trusted result; assert no
    winner and no rating update.

### Timeout tests

1. Use a fixture whose current player clock is already expired based on
   `updated_at`.
2. Call `expire_game_on_timeout` as the current player.
3. Assert the opponent wins, termination is `timeout`, completion is applied
   once, presence is released, and pending offers are closed.
4. Call it as the non-player or before expiry; assert rejection.
5. Race timeout with a legal move; assert one terminal state and one completion
   ledger row.

### RLS and permissions

Using player A, player B, and a non-player:

1. Player A can read their game, moves, draw offers, and completion.
2. Player B can read the same game records.
3. Non-player cannot read private game records or offer records.
4. Authenticated clients cannot insert/update/delete authoritative game,
   move, offer, or completion rows directly.
5. Anonymous clients cannot execute game RPCs.
6. Authenticated clients cannot execute `commit_validated_move` or
   `apply_game_completion`.
7. Verify only the intended RPCs are granted to `authenticated`.

### Realtime and rollback

1. Subscribe two authenticated clients to `games`, `game_moves`, and
   `game_draw_offers`.
2. Commit a move, draw offer, decline, accepted draw, resignation, and timeout.
3. Assert no duplicate board application and matching state versions.
4. Disconnect/reconnect one client and verify refresh reconciliation.
5. Force a transactional failure and confirm no partial result, move, rating,
   statistics, presence, or ledger state remains.

## Mock/local-only coverage

These can run without Supabase:

- `flutter analyze`
- `dart format`
- Flutter widget/model tests
- Repository request-shape tests using a fake client, if added
- Pure Elo calculation tests, if extracted from SQL into a documented test
  helper

These require a real Supabase database and auth context:

- Migration application and SQL lint
- RLS and RPC grants
- Edge Function authentication and service-role lookup
- Atomic move commit
- Draw-offer uniqueness/staleness
- Completion idempotency and transaction rollback
- Elo/statistics updates
- Concurrent requests
- Realtime publication delivery

## Current readiness result

The repository is locally code-checked but staging-blocked. In the current
workspace:

- Full Flutter tests pass.
- Full Flutter analysis completes with five pre-existing informational
  diagnostics and no errors.
- Local Supabase lint cannot connect because Postgres is not running on
  `127.0.0.1:54322`.
- No production or linked Supabase project has been contacted.
# Phase 3-6 foundation additions

Before testing competition or spectator behavior, apply
`20261010100000_phase3_6_foundation.sql` after the existing Phase 1 and Phase 2
migrations in a disposable database. Verify that:

1. `games.visibility` defaults to `private` for existing rows.
2. Published competitions are readable to authenticated users, while drafts
   are visible only to their organizer.
3. Registration is capacity-limited under two concurrent requests.
4. A user can register, withdraw, and register again through the RPCs only.
5. A player cannot insert or update competition registrations directly.
6. Public active/completed games and moves are readable to an authenticated
   spectator, while private and unlisted games are not discoverable.
7. A spectator cannot call move, resignation, draw, or completion operations.
8. Competition and public-game Realtime behavior is verified after enabling the
   relevant publication membership.

Organizer lifecycle, pairing generation, standings, admin audit operations,
community moderation, and notifications do not yet have implementation
contracts in this migration and must not be tested as if they were available.
