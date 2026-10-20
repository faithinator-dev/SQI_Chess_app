# Remaining phases implementation plan

## Starting state

Phases 1 and 2 have secure client-side contracts and local Flutter checks, but
their SQL, Edge Function, RLS, transaction, concurrency, and Realtime behavior
remain unverified because no local or approved staging Supabase runtime is
available.

The Phase 3-6 foundation increment added competition models/repository code and
the reviewable migration
`20261010100000_phase3_6_foundation.sql`. Competition organizer operations,
pairing generation, standings, admin authorization/auditing, complete
spectator discovery, and the community feed migration remain incomplete.

Phase 7 learning now loads published lessons through `LessonRepository` and
hydrates progress from `lesson_progress`. Lesson `content.steps` is the
verified content contract consumed by the player. No production puzzle
catalogue exists yet.

Phase 8 platform support is constrained by LAN's `dart:io` implementation.
Android/iOS build and permission verification has not been completed. The
attempted web build is currently blocked by dart2js rejecting 64-bit integer
literals in `dartchess 0.13.1`.

Phase 9 profile/settings repositories exist. The dashboard provides in-app
notification loading, unread counts, mark-read, mark-all-read, and Realtime
cleanup through the existing repository, but backend behavior and
push-provider configuration are not verified.

## Safe implementation order

1. Verify all existing migrations and Phase 1-3 foundation migrations on a
   disposable Supabase stack.
2. Define a reviewable puzzle schema and trusted solution validation before
   exposing puzzle progress.
3. Populate only reviewed puzzle fixtures in a development/staging workflow.
4. Add a coherent community feed UI using existing post/comment/like tables.
5. Add spectator discovery backed by the visibility policies and reuse the
   existing read-only live board.
6. Add tournament lifecycle, pairing, standings, and admin audit RPCs only
   after role and authorization contracts are approved.
7. Complete profile/settings/notification UI and test ownership boundaries.
8. Run platform-specific builds, accessibility checks, security review, and
   staging integration tests.

## Release gate

No phase is production-complete until backend behavior is executed against a
real disposable local or approved staging Supabase environment. Mocked or
static checks do not prove RLS, SQL transaction, Edge Function, or Realtime
behavior.
