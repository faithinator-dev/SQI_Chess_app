# SQI Checkmate Arena Implementation Audit

**Audit date:** 2026-10-09  
**Source of truth:** repository contents, Supabase migrations/functions, Flutter
sources, tests, and README.

## Executive summary

SQI Checkmate Arena is a Flutter chess app with direct Supabase initialization,
email authentication, typed repositories, local chess engines, online
matchmaking, realtime game subscriptions, LAN sockets, profile/settings
screens, community/learning repositories, and broad prototype UI coverage.

The database foundation is further along than the UI integration. Supabase
migrations define core player, settings, game, matchmaking, presence,
community, lesson, and notification tables. They also define signup triggers,
profile/settings RPCs, matchmaking functions, game-action functions, RLS
policies, and realtime publication membership.

The highest-risk inconsistency was online move handling: the database provides a
secure `commit_validated_move` function and the repository includes a
`submit-move` Edge Function, while the online Flutter screen previously wrote
`game_moves` and `games` directly. Phase 1 now routes Flutter moves through the
Edge Function; backend integration testing remains required before production.
The strict local review also found and fixed a result-format mismatch between
the Edge Function and the RPC, plus RPC error-message mapping that did not
match the migration.

## Architecture and state management

- Flutter Material application with `MaterialApp`.
- No separate state-management package is configured; screens use StatefulWidget
  state, repositories, timers, sockets, and Supabase realtime channels.
- Supabase is initialized in `lib/main.dart` using `--dart-define` values.
- Repository classes construct typed models from Supabase responses.
- Chess rules and bot behavior are local through `dartchess` and custom bot
  classes.
- UI styling is mostly screen-local constants. `lib/app/theme.dart` provides a
  light Material theme, while many feature screens define their own dark
  palette.
- Tests currently consist of one widget smoke test. The app shell supports
  dependency injection of a Supabase client for that test.

## Navigation and screens

There is no centralized route table currently used by the app. Navigation is
primarily performed with `MaterialPageRoute` from feature screens.

The source contains screens for:

- Onboarding, guest entry/dashboard, login, registration, and email verification
- Dashboard and matches
- Online matchmaking and match-found flow
- Online chess match
- Bot/practice chess
- Local player-vs-player chess
- LAN chess
- Game result and game review/history
- Player profile, settings, statistics, and achievements
- Competitions, details, and lobby
- Admin dashboard, users, competitions, matches, pairings, recordings, and
  settings
- Spectator discovery, live match, board, and replay
- Community
- Learning

Screen presence does not imply backend completion. Several of these screens
still contain explicit mock/demo collections.

## Authentication and profile flows

Implemented:

- Supabase auth gate based on the current session.
- Login, registration, and email verification screens.
- Signup metadata is passed to the database trigger.
- `handle_new_user` creates a profile.
- `handle_new_user_settings` creates default settings.
- Profile repository loads and updates the current profile through an RPC.
- Settings repository loads/upserts persistent settings.
- Profile visibility is changed through an RPC.
- Logout and password update flows exist.

Required verification:

- Confirm all auth email/redirect settings in the deployed Supabase project.
- Confirm the signup triggers were applied to the same database used by the app.
- Confirm username uniqueness and validation behavior for hostile input.
- Add integration tests against a local/staging Supabase instance.

## Supabase schema and backend

### Tables present in migrations

- `bot_profiles`
- `profiles`
- `user_settings`
- `games`
- `game_players`
- `game_moves`
- `matchmaking_queue`
- `player_presence`
- `community_posts`
- `community_comments`
- `community_post_likes`
- `lessons`
- `lesson_progress`
- `notifications`

### Backend functions and triggers

- Timestamp trigger function.
- New-user profile and settings triggers.
- Profile and settings update functions.
- Notification read functions.
- Player presence function.
- Matchmaking join/leave/create/expiry functions.
- Game resignation function.
- Atomic validated move commit function.

### Realtime

The realtime publication migration adds:

- `community_comments`
- `community_post_likes`
- `community_posts`
- `game_moves`
- `games`
- `matchmaking_queue`
- `notifications`
- `player_presence`

The Flutter app uses realtime for online games and matchmaking. Deployment
should verify that the publication exists and that the relevant tables have
replica identity/configuration appropriate for the subscribed events.

## Game-state implementation

### Online games

Implemented:

- Matchmaking repository and queue subscriptions.
- Supabase game loading.
- Realtime game and move subscriptions.
- Board state reconstruction from FEN/moves.
- Online resignation and result presentation.
- Server-side game-action functions exist.
- Flutter online moves send only `game_id` and `uci` to `submit-move`.
- Resignation uses the authenticated `resign_game` RPC.
- Client state tracks `state_version`; older and duplicate realtime game
  updates are ignored.
- Rejected moves refresh authoritative state and do not apply an optimistic
  board move.

Not production-safe yet:

- The secure `submit-move` Edge Function and
  `commit_validated_move` function are now the online Flutter write path.
- The Edge Function validates client intent and computes authoritative FEN,
  clocks, result, and termination fields before the atomic commit.
- Draw offers are explicitly not connected to a secure backend operation.
- No local/staging Supabase runtime is configured, so the Edge Function and
  RPC cannot be integration-tested from this checkout.
- Draw offers and rated completion now have a reviewed migration, but that
  migration has not been applied or exercised against Supabase.

### Bot/practice games

- Uses local `dartchess` positions and a local bot engine.
- Board and result behavior works locally.
- No Supabase game record or rated statistics update is written.
- This is currently an offline/practice mode, not persistent game history.

### Local PvP

- Uses local board state, clocks, move history, draw, resignation, and result
  handling.
- Does not require authentication or network connectivity.
- Does not create a Supabase game record or history entry.
- This is appropriate for an offline mode unless product requirements change.

### LAN

- Uses `dart:io` sockets and a host/client protocol.
- Board, clocks, move exchange, draw, resignation, and disconnect handling are
  local-network features.
- No Supabase persistence is currently performed.
- Web compatibility is not available for this implementation because
  `dart:io` sockets are not a web transport.

### Phase 1 local verification

Inspected:

- `chess_game_repository.dart`, `chess_match_screen.dart`, and
  `chess_game_model.dart`
- `submit-move/index.ts`
- `20261009000700_game_actions.sql`
- Online realtime subscription, lifecycle cleanup, and existing tests

Fixed:

- Edge Function result values now match the RPC contract (`white`, `black`,
  `draw`).
- Edge Function commit-error matching now matches the exact SQL exception
  messages for stale state, wrong turn, duplicate move, and inactive game.
- Equal or older realtime state versions are ignored; refreshes cannot apply
  older game rows.
- Added model tests for state-version preservation and legacy defaulting.

Commands and results:

- `dart format --output=none lib/core/models/chess_game_model.dart lib/core/repositories/chess_game_repository.dart lib/features/match/chess_match_screen.dart test/chess_game_model_test.dart` —
  passed; one repository file was reformatted.
- Targeted `flutter analyze --no-fatal-infos` on the three affected Dart files —
  passed with no issues.
- Focused tests for `chess_game_model_test.dart` and `widget_test.dart` —
  passed (2 tests).
- Full `flutter test` — passed (3 tests).
- Full `flutter analyze --no-fatal-infos` — completed with 5 pre-existing
  informational diagnostics outside the Phase 1 files; no errors.

Staging prerequisites:

1. Start a disposable local Supabase stack or provide an approved staging
   project; do not use production.
2. Apply migrations in timestamp order, including
   `20261009000700_game_actions.sql` and the realtime publication migration.
3. Deploy `submit-move` with `SUPABASE_URL` and a server-side service-role
   secret configured only in the Edge Function environment.
4. Create two authenticated test users and an active game with valid player
   IDs, FEN, clocks, turn, and `state_version`.
5. Run two-client tests for legal, illegal, wrong-player, stale, duplicate,
   timeout, resignation, completed-game, and concurrent submissions.
6. Verify realtime publication delivery and RLS behavior without placing any
   service-role secret in Flutter.

### Phase 2 secure completion audit

The pre-Phase-2 schema had no draw-offer table, completion ledger, rating
history, or trusted profile-statistics update function. The existing
`profiles` counters (`games_played`, `wins`, `losses`, `draws`) and
`chess_rating` are the only rating/statistics storage. `games.game_type`
identifies `online_random`, `online_friend`, `bot`, `lan`, and `local`, but
there was no rated-game policy.

The approved policy for this implementation is:

- `online_random` and `online_friend` are rated.
- Elo uses initial rating 1000 and K-factor 32.
- Only completed games with two authenticated human players update ratings
  and counters.
- Bot, LAN, and local games are unrated and do not update Supabase profile
  ratings/statistics.
- Abandoned games are not assigned a winner by the completion pipeline.

The reviewed migration
`20261009140000_secure_game_completion.sql` adds:

- `game_draw_offers`, with one pending offer per game and participant-only
  read access.
- `game_completions`, a one-row-per-game idempotency ledger containing result,
  termination reason, and rating deltas.
- `offer_draw`, `respond_draw_offer`, and
  `expire_game_on_timeout` authenticated RPCs.
- `apply_game_completion`, callable only by trusted database functions.
- Replacements for `resign_game` and `commit_validated_move` so resignation,
  timeout, agreement, checkmate, and supported chess draws use one transactional
  completion path.
- Realtime publication membership for draw offers.

Migration-order review:

- `20261009000100` creates the base tables and constraints.
- `20261009000200` adds indexes and the initial RLS policies.
- `20261009000300` adds signup and timestamp triggers.
- `20261009000400` adds profile/settings RPCs.
- `20261009000500` adds matchmaking RPCs and creates online games.
- `20261009000600` adds presence/notification RPCs.
- `20261009000700` adds the original resignation and service-role move RPCs.
- `20261009000800` adds the existing Realtime tables.
- `20261009110000` adds conditional profile/game access policies.
- `20261009140000` adds draw/completion tables and replaces the game-action
  functions.

The order supplies every table and function dependency used by the final
migration. The final migration's publication addition was made rerun-safe; the
Supabase-managed `supabase_realtime` publication must still exist. The earlier
game-action definitions are intentionally superseded by the final
`CREATE OR REPLACE` definitions, and their service-role/authenticated grants
are explicitly restored. No duplicate overloads are introduced because the
signatures are unchanged.

Contract findings:

- Flutter sends only `{game_id, uci}` to `submit-move`; the Edge Function
  computes the remaining RPC arguments and uses the service-role-only
  `commit_validated_move` signature.
- Edge Function result values (`white`, `black`, `draw`) match the `games`
  constraint and final completion RPC.
- `resign_game`, draw RPCs, and timeout RPCs are authenticated; clients cannot
  call `apply_game_completion` or `commit_validated_move`.
- Completion locks the game row, inserts a unique ledger row, locks both
  profiles for rated games, and updates game/profile/presence state in one
  transaction. A conflict or failure rolls the transaction back.
- Draw offers are participant-readable only and have no client write policy.
  Their state-version check rejects offers after a move or other completion.
- The migration does not add rating history because no such existing contract
  exists; rating deltas are recorded in the completion ledger instead.

Review limitations:

- SQL syntax, function ownership, RLS enforcement, publication membership,
  transaction rollback, and concurrent locking were not executable locally
  because Postgres/Docker is unavailable.
- The Edge Function's deployed JWT configuration and server secret names still
  require staging verification.
- The client clock only requests timeout completion after its local display
  reaches zero; staging must race timeout against a legal move to verify the
  server remains authoritative.

The Flutter online screen now sends draw offers through `offer_draw`, responds
through `respond_draw_offer`, listens for pending offer events, and submits
server-authorized timeout handling when its displayed clock reaches zero.
It does not write results, ratings, statistics, or draw-offer rows directly.

This is locally contract-reviewed only. SQL execution, transaction rollback,
RLS, RPC permissions, concurrent completion, and Realtime delivery still
require staging validation.

Local verification for this phase:

- `dart format --output=none lib/core/repositories/chess_game_repository.dart
  lib/features/match/chess_match_screen.dart` — passed.
- Targeted `flutter analyze --no-fatal-infos` for the changed client files —
  passed with no issues.
- Focused model/widget tests — passed (2 tests).
- Full `flutter test` — passed (3 tests).
- Full `flutter analyze --no-fatal-infos` — completed with the same five
  pre-existing informational diagnostics outside the Phase 2 files and no
  errors.
- `supabase db lint --local --fail-on error` — attempted and blocked because no
  local Supabase database is running (`127.0.0.1:54322` refused the
  connection). No live or linked database was contacted.

## Profile, history, and statistics

Implemented:

- Profile screen reads real profile/statistic columns.
- Settings screen reads and persists real user settings.
- Game history queries completed games for the authenticated player and loads
  opponent profiles.
- Statistics screen reads real profile counters and shows empty/error states.

Remaining:

- Rating-history table and historical chart data.
- Staging verification of the new trusted backend mechanism that updates
  profile counters after every rated result.
- Persistent records for bot, local, and LAN games.
- Avatar upload/storage flow.

## Admin functionality and authorization

The repository contains extensive admin UI screens, but many values are
hard-coded or explicitly marked as mock. There is no demonstrated complete
admin repository/service layer for users, competitions, pairings, recordings,
monitoring, or audit logs.

The profiles table has a `role` column and RLS exists, but production admin
authorization must be enforced in server-side policies/functions. A client
must not decide that a user is an administrator based only on locally loaded
profile data.

Required work:

- Server-side admin role checks.
- Admin-only RPCs/Edge Functions.
- Audit-log table and writes.
- Database-backed pagination/search/filtering.
- Tests proving ordinary users cannot invoke admin operations.

## Competitions and tournaments

UI screens exist for competition browsing, details, and lobbies. The core
database migrations do not define competition, registration, participant,
pairing, round, standings, bracket, or result tables. Existing competition
screens contain hard-coded competition/player data.

The competition system is therefore prototype UI only and is not complete.
The format, scoring, lifecycle, dispute, and pairing rules must be agreed
before schema and secure RPC implementation.

## Spectator and replay

Spectator screens exist, but current discovery/replay data includes demo
players, demo games, fallback FEN, or static move collections. There is no
complete public-game discovery policy/model in the current migrations.

Required work:

- Public/unlisted game visibility model.
- Secure spectator read policies.
- Active-game query and filters.
- Realtime board/clock subscriptions.
- Persisted move replay for finished games.

## Community

Repositories exist for posts, comments, and likes, and the schema/RLS includes
those tables. The main community screen still contains hard-coded members/live
games and requires careful separation between database-backed sections and
prototype sections.

Missing:

- Reports and moderation schema.
- Notification generation and moderation workflow.
- Database-backed member/live-game counts.
- Pagination and robust input limits.

## Puzzles and learning

Learning screens/repositories exist and migrations define `lessons` and
`lesson_progress`. There is no puzzle schema in the current migrations.
Published lesson access and user progress are partially represented, but
content administration and complete persistence verification are needed.

## LAN, web, and platform compatibility

- LAN depends on `dart:io` sockets and must be hidden or replaced on Web.
- Android/iOS local-network permissions need explicit review.
- Internet permission and production entitlements need verification.
- No evidence of complete Android, iOS, and Web test coverage was found.

## UX and design-system status

Many screens use a consistent SQI dark palette, but the global theme is light
and feature screens duplicate colors, spacing, card, and button definitions.
The playable game screens are being standardized around fixed, non-scrolling
board layouts.

Asynchronous profile/history/statistics screens now include loading, empty,
error, retry, and refresh behavior. Other major screens still need a systematic
state audit.

## Demo/mock data inventory

Explicit demo or mock data remains in:

- Archive match history and game review fallback moves
- Admin dashboard/users/competitions/matches/pairings/recordings
- Community member/feed/live-game sections
- Competitions and competition lobby
- Spectator discovery/live/replay
- Achievements preview

These screens must not be described as production-backed until their data
sources are replaced or the UI is explicitly labeled as demo mode.

## Security findings

1. **High:** The new completion/draw migration has not been applied or
   integration-tested against a local/staging Supabase runtime.
2. **High:** Admin UI exists without demonstrated server-side admin operation
   enforcement and audit logging.
3. **Medium:** RLS migrations are split across multiple files, including an
   additional security migration with overlapping policy intent. Deployment
   order must be verified on a clean database.
4. **Medium:** Input limits and abuse/rate-limiting strategy are not evident for
   community, matchmaking, and repeated game actions.
5. **Medium:** The Supabase URL and publishable key are present in a comment in
   `lib/main.dart`; the publishable key is not a service secret, but runtime
   configuration should be kept out of source comments.

## Recommended implementation order

1. Secure online move, resignation, result, clock, and rating updates.
2. Add integration tests for auth, profile creation, RLS, matchmaking, and games.
3. Remove or label remaining demo data on the player-facing surfaces.
4. Establish the shared SQI design tokens and fixed game-screen layout.
5. Define and implement competition/tournament schema and secure lifecycle RPCs.
6. Implement admin authorization, audit logs, and database-backed admin views.
7. Implement spectator visibility/replay contracts.
8. Complete community moderation, puzzles, learning administration, and
   notifications.
9. Add platform compatibility/permissions and release monitoring/legal work.
10. Run full cross-platform regression QA.

## Phase 3-6 initial implementation review

The repository audit found no competition/tournament tables or admin mutation
contracts. Spectator discovery is demo-driven while the existing player-only
game RLS policies prevent public spectators from reading games and moves. The
community screen is a channel-chat prototype, whereas the existing Supabase
schema is a post/comment/like feed.

The reviewable migration
`20261010100000_phase3_6_foundation.sql` adds competition registrations,
rounds, pairings, public-game visibility, authenticated registration/withdrawal
RPCs, and narrowly scoped read policies. It has not been applied or executed.
The competition list now loads real competition rows through
`CompetitionRepository` and exposes loading, empty, error, and retry states.

Organizer/admin operations, pairing generation, standings, moderation,
notifications, public spectator discovery UI, and community feed migration
remain incomplete by design. They require additional contracts and real RLS,
RPC, concurrency, and Realtime verification before being exposed.
