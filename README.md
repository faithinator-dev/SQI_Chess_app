# SQI Checkmate Arena

SQI Checkmate Arena is a Flutter chess application with Supabase
authentication, player profiles, persistent settings, online games, and
realtime game state.

## Current production-backed features

- Supabase email authentication and auth gate
- Profile loading and profile editing (name, username, bio)
- Persistent player settings (sound, board, notifications, appearance, privacy)
- Supabase-backed completed game history
- Profile-backed statistics and result breakdown
- Realtime game updates and server-side move/resignation RPCs
- Practice and local play, which intentionally remain local-only

## Setup

Install Flutter, make sure `assets/.env` contains `SUPABASE_URL` and either
`SUPABASE_PUBLISHABLE_KEY` or `SUPABASE_ANON_KEY`, then run:

```bash
flutter pub get
flutter run
```

You can also provide these values with `--dart-define`; those values take
precedence over `assets/.env`.

The Flutter client must only use the Supabase publishable/anon key. Never put a
service-role key in the app.
## Supabase setup

1. Link the project with the Supabase CLI.
2. Apply the migrations in `supabase/migrations`.
3. Deploy the Edge Functions in `supabase/functions`.
4. Configure the profile/settings tables and the RPCs used by the app:
   `update_my_profile`, `update_my_profile_visibility`, `submit_game_move`,
   and `resign_game`.
5. Enable Realtime for `games` and `game_moves`.

The community-pages migration also seeds three starter channels: **General**,
**Announcements**, and **Study & Tactics**. Members can post in General and
Study & Tactics; Announcements is admin-posted and visible to members.

The client expects `profiles`, `user_settings`, `games`, `game_moves`, and the
community/notification tables used by their respective repositories. A missing
profile or empty game history is shown as an empty state; demo records are not
created by the client.

## Architecture

- `lib/core/models`: typed data models
- `lib/core/repositories`: Supabase access and RPC calls
- `lib/features`: screens and feature-specific UI
- `lib/app`: app shell, theme, and navigation
- `supabase/functions`: trusted server-side game operations
- `supabase/migrations`: database security and schema changes

## Testing and checks

```bash
flutter analyze
flutter test
```

Use a configured Supabase project for integration testing. Unit/widget tests
should inject repositories or use a local Supabase instance instead of relying
on production data.

## Scope still requiring backend work

Competitions/tournaments, admin monitoring, community moderation,
spectator discovery/replay, puzzles/lessons, rating history, avatar storage,
rate limiting, crash monitoring, legal pages, and release signing are not
claimed as complete by the current client. Their existing demo UI should not
be treated as production data.
