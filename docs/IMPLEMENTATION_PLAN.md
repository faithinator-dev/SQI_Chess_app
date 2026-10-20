# SQI Checkmate Arena Implementation Plan

This plan follows the repository audit in
[`IMPLEMENTATION_AUDIT.md`](./IMPLEMENTATION_AUDIT.md). Tasks are ordered by
security and dependency, not by screen count.

## Phase 1 — Secure online chess

### 1.1 Use one authoritative move path

**Dependencies:** existing `games`, `game_moves`, and validated move function.  
**Work:**

- Flutter now submits only `{game_id, uci}` to the `submit-move` Edge Function.
- The Edge Function remains the trusted validator and calls
  `commit_validated_move`; Flutter does not directly insert moves or update
  authoritative game state.
- The Edge Function result values and commit-error mapping match the exact
  `20261009000700_game_actions.sql` RPC contract.
- The UI waits for the authoritative game row/realtime update and refreshes on
  success or rejection, rather than applying an optimistic move.
- Equal or older `state_version` realtime/refresh data is ignored.

**Acceptance criteria:**

- A player can submit a legal move.
- An unauthenticated user cannot submit a move.
- A non-player cannot submit a move.
- A stale state version is rejected and the board reloads.
- Arbitrary FEN, result, clock, or color values cannot be used to cheat.

**Verification:** Dart formatting, targeted Flutter analysis, the focused model
test, the existing widget test, the full `flutter test` suite, and full
`flutter analyze --no-fatal-infos` complete successfully. Full analysis still
reports five pre-existing informational diagnostics outside the Phase 1 files;
it reports no errors. Edge Function/RPC integration tests and two-client
realtime testing remain blocked until a local or staging Supabase runtime is
available.

### 1.2 Secure resignation and results

**Dependencies:** 1.1.  
**Work:**

- Flutter now routes resignation through the authenticated `resign_game` RPC.
- The reviewed Phase 2 migration adds a transactional completion ledger and
  trusted profile statistics/rating updates.
- Checkmate, supported chess draws, agreed draws, resignation, and clock
  expiry use the same idempotent completion helper.
- Bot, LAN, local, abandoned, and incomplete games do not receive rating
  updates.

**Acceptance criteria:**

- Only a current player can resign.
- The winner is calculated on the server.
- Profile statistics change once per rated game.
- Repeated result submission does not double-count.

**Verification:** Client contract checks pass locally. SQL/RPC tests for both
players, spectators, stale requests, retries, concurrent completion, RLS, and
rollback require a local/staging Supabase runtime.

### 1.3 Secure draw offers

**Work:**

- Add `game_draw_offers` with one pending offer per active game.
- Use authenticated `offer_draw` and `respond_draw_offer` RPCs.
- Require the offer recipient to accept or decline.
- Bind offers to the current `state_version`; stale or completed offers fail.
- Publish offer changes through Supabase Realtime without allowing clients to
  update authoritative game results.

**Verification:** The Flutter client uses only the RPCs and read/subscription
  paths. Runtime verification of unauthorized, duplicate, stale, declined,
  accepted, and post-completion offers remains blocked on staging.

### 1.4 Rating policy

Approved product policy for this implementation:

- Standard Elo.
- Initial rating: 1000.
- K-factor: 32.
- Rated game types: `online_random` and `online_friend`.
- Eligibility: completed game with two authenticated human players.
- Bot, LAN, local, abandoned, and incomplete games are unrated.
- Rating updates occur only inside the trusted completion transaction.

The migration stores rating-before and rating-delta values in
`game_completions` for auditability. A rating-history table is intentionally
not added yet because no existing consumer or schema contract requires it.

### 1.5 Phase 2 staging gate

Do not apply `20261009140000_secure_game_completion.sql` to production until:

1. A disposable local or approved staging Supabase database is available.
2. Migrations apply cleanly in timestamp order.
3. The Edge Function has only server-side service-role configuration.
4. Two authenticated human test accounts and active rated/unrated games exist.
5. RPC grants and RLS are verified for players, spectators, and unauthorized
   users.
6. Concurrent move, draw response, resignation, timeout, and retry requests
   are executed.
7. Completion ledger uniqueness, profile counters, Elo deltas, rollback, and
   Realtime updates are verified.

### 1.6 Migration review result

All migrations were inspected in timestamp order. The Phase 2 migration has
the required base-table dependencies, preserves the existing RPC signatures,
and explicitly restores the intended grants after replacing the Phase 1 game
functions. Its Realtime publication addition is rerun-safe. No migration was
applied during this review.

The exact staging test cases are in
[`STAGING_INTEGRATION_TESTS.md`](./STAGING_INTEGRATION_TESTS.md). The current
workspace can run Flutter formatting, analysis, and tests, but cannot execute
SQL lint or integration tests because no local Postgres/Supabase runtime is
running.

## Phase 2 — Backend integration tests and data contracts

**Dependencies:** Phase 1.  
**Work:**

- Add a local/staging Supabase test workflow.
- Test signup triggers, RLS, profile/settings RPCs, matchmaking, games, moves,
  and realtime publication assumptions.
- Add typed response/error handling in repositories.
- Add explicit timeout, retry, and stale-state behavior.

**Acceptance criteria:**

- Every repository operation has success and expected-error coverage.
- RLS blocks cross-user reads/writes.
- Migrations apply cleanly in timestamp order to a new database.

## Phase 3 — Remove player-facing demo data

**Dependencies:** Phase 2.  
**Work:**

- Replace archive history with the real game-history repository.
- Replace spectator discovery/replay data with database-backed queries.
- Replace community feed/member/live-game demo data with repositories.
- Replace achievements with a defined backend contract or label as unavailable.
- Remove hard-coded player names, ratings, match IDs, and dates.

**Acceptance criteria:**

- Empty backend data produces an empty state, not fake records.
- Loading, error, retry, offline, and permission-denied states are visible.
- No production screen displays named demo users.

## Phase 4 — Shared SQI UI system and fixed game layouts

**Dependencies:** none, but should follow Phase 3 for touched screens.  
**Work:**

- Extract color, typography, spacing, card, button, and input tokens.
- Align global light/dark/system theme behavior with feature screens.
- Keep game boards fixed and non-page-scrolling on phone portrait/landscape.
- Keep only intentional internal move-list scrolling.
- Add accessibility labels, contrast checks, and minimum touch targets.

**Acceptance criteria:**

- Online, bot, local PvP, and LAN screens use the same fixed-board structure.
- No game screen requires vertical page scrolling to make a move.
- Theme changes do not break board contrast or controls.

## Phase 5 — Competition and tournament backend

**Dependencies:** secure online games and an approved tournament format.  
**Work:**

- Agree on Swiss/Arena/Knockout/Round Robin requirements before schema work.
- Add events, registrations, rounds, pairings, results, standings, and audit
  tables.
- Implement transactional lifecycle and pairing RPCs.
- Replace competition/admin demo screens with repositories.

**Acceptance criteria:**

- Duplicate registration is impossible.
- Pairings cannot conflict.
- Only authorized operations can alter lifecycle/results.
- Standings are server-calculated and auditable.

## Phase 6 — Secure admin portal

**Dependencies:** competition schema if competitions are administered there.  
**Work:**

- Define authoritative admin role/claims strategy.
- Add server-side admin guards to every privileged RPC/function.
- Add audit logs.
- Add paginated database-backed users, matches, competitions, moderation, and
  monitoring views.

**Acceptance criteria:**

- A normal player cannot invoke any admin operation.
- Admin role changes cannot be self-assigned.
- Destructive actions require confirmation and create an audit entry.

## Phase 7 — Spectator and replay

**Dependencies:** Phase 1 and public-game policy decision.  
**Work:**

- Add public/unlisted/private visibility.
- Add spectator count/presence strategy.
- Add safe read policies and realtime subscriptions.
- Build replay from persisted moves without demo fallback data.

**Acceptance criteria:**

- Private games are not discoverable.
- Public board/clock updates are realtime.
- Finished games can be replayed from authoritative moves.

## Phase 8 — Community, learning, and notifications

**Dependencies:** Phase 2 security baseline.  
**Work:**

- Add reports, moderation, and notification generation.
- Add pagination and content limits.
- Complete lesson publishing/progress administration.
- Define puzzle schema, validation, progress, and difficulty/rating.

**Acceptance criteria:**

- Invalid/oversized input is rejected.
- Moderation actions are authorized and audited.
- Progress is durable and scoped to the authenticated user.

## Phase 9 — Platform and release readiness

**Dependencies:** feature scope completion.  
**Work:**

- Hide LAN on Web or implement a WebRTC/WebSocket alternative.
- Verify Android/iOS internet and local-network permissions.
- Add release configuration, signing, icon/splash/versioning.
- Add crash/error/performance monitoring.
- Add privacy policy, terms, community rules, and account deletion.

**Acceptance criteria:**

- Android, iOS, and supported Web builds complete successfully.
- No service-role/secret key is present in Flutter artifacts.
- Production configuration is separate from development configuration.

## Phase 10 — Final QA

**Dependencies:** all required release phases.  
**Work:**

- Run guest, registration, login, verification, practice, local PvP, bot, LAN,
  online, profile, settings, history, competitions, spectator, community, and
  admin regression suites.
- Test offline, slow network, reconnect, duplicate taps, stale state, denied
  permissions, and empty backend data.
- Test multiple users/devices for realtime and authorization boundaries.

**Release gate:**

- No critical/high security findings.
- No known demo data on production-backed screens.
- Analyzer, unit/widget, integration, and platform checks pass.
- Migration and rollback procedures are documented.

## Phase 3-6 implementation increment

The first Phase 3-6 milestone is documented in
[`PHASE_3_6_IMPLEMENTATION_PLAN.md`](./PHASE_3_6_IMPLEMENTATION_PLAN.md) and
[`PHASE_3_6_IMPLEMENTATION_REPORT.md`](./PHASE_3_6_IMPLEMENTATION_REPORT.md).
It adds reviewable competition/spectator schema foundations and replaces the
competition list's demo runtime data with repository reads. Organizer/admin
mutations, public spectator discovery, and the channel-chat community screen
remain blocked on additional backend contracts and staging verification.
