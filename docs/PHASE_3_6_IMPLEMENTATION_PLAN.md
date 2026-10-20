# Phases 3-6 implementation plan

## Scope

Phases 1 and 2 remain unchanged and still require a real Supabase runtime for
backend verification. This work starts the next feature group without
replacing the secure game-completion pipeline.

## Milestone A: backend contracts

- Add competition, registration, round, and pairing tables.
- Add public-game visibility for spectator discovery.
- Add RLS policies for published competition reads and public game reads.
- Add authenticated registration and withdrawal RPCs.
- Keep organizer/admin writes out of direct client access until role checks and
  audited server operations are implemented.

## Milestone B: player-facing data

- Add typed competition models and a repository.
- Replace competition list demo records with repository reads.
- Preserve existing competition detail/lobby UI while their write actions are
  migrated to RPCs.
- Replace spectator discovery with a repository-backed public-game query.
- Reuse `ChessSpectatorScreen` for authoritative FEN, moves, clocks, and
  realtime updates.

## Milestone C: administration

- Add audited admin RPCs for competition lifecycle, pairing generation,
  moderation, and role changes.
- Verify the existing `profiles.role` authorization model in staging before
  exposing admin mutations.
- Replace hardcoded admin metrics and lists with paginated repository queries.

## Milestone D: community

- Use the existing post/comment/like schema and repository as the product
  contract.
- Replace the channel-chat demo screen with a feed-oriented UI, or add a
  separately reviewed channel/message schema if chat is required.
- Add reports, moderation, and notification RPCs with RLS and idempotency.

## Gate

No production deployment is permitted until the new migration is applied and
tested on a disposable local or approved staging Supabase project. SQL syntax,
RLS, RPC privileges, concurrent registration, public-game privacy, and
Realtime delivery are not verified by Flutter unit tests.
