# SQI Checkmate Arena

## Product overview

SQI Checkmate Arena is a cross-platform Flutter chess application for learning,
playing, reviewing games, and participating in a chess club community. It uses
Supabase for authentication, profiles, settings, online game state, community
content, notifications, and persistent game history. It also supports local
practice, local two-player games, and nearby Wi-Fi games.

The application is designed around five main areas:

- **Home** - personal dashboard, notifications, learning recommendations, and
  recent community activity.
- **Play** - online matchmaking, friend games, local games, practice, and LAN
  games.
- **Learn** - lessons, chess fundamentals, categories, search, and puzzles.
- **Community** - club updates, posts, likes, and comments.
- **Profile** - player identity, rating, statistics, history, achievements,
  friends, and settings.

## Important status note

The repository contains both production-backed functionality and screens that
are foundations or administrative interfaces for future expansion. A screen
being present in the application does not automatically mean that every
backend workflow behind it is production-ready.

### Production-backed areas

- Email authentication and email verification.
- Password reset.
- Optional Google authentication flow.
- Player profiles and profile editing.
- Persistent user settings.
- Online friend games.
- Quick matchmaking.
- Server-validated online moves.
- Realtime online game updates.
- Resignation, draw offers, timeout handling, and game completion.
- Game history and player statistics.
- Community posts, likes, comments, and realtime feed updates.
- Notifications and unread notification counts.
- Supabase-backed lessons, with built-in fallback lessons.
- Local practice and local player-versus-player games.
- Nearby Wi-Fi/LAN games.

### Areas requiring further backend or release work

- Full competition/tournament operations and administration.
- Complete spectator discovery and replay workflows.
- Community moderation tooling and policies.
- Production puzzle and lesson content management.
- Rating history and a complete rating engine.
- Avatar/image storage.
- Rate limiting, abuse prevention, crash monitoring, and analytics.
- Legal pages, privacy documentation, and release signing.

## User experience

### First launch and onboarding

The app starts by loading its configuration and initializing Supabase. A new
user can go through onboarding before using the main application. Existing
authenticated users are sent to the dashboard. Guest access is available
through the guest entry flow and uses local guest preferences rather than a
Supabase account.

The application shows a startup error instead of silently continuing when
Supabase configuration is missing or invalid.

### Account creation and sign-in

Users can:

- Create an account with email and password.
- Sign in with email and password.
- Verify their email address.
- Request a password reset email.
- Use Google sign-in when the Supabase provider and platform deep links are
  configured.
- Sign out through account settings.

Authentication errors are translated into user-friendly messages for common
cases such as invalid credentials, unverified email, rate limiting, and network
failures.

### Home dashboard

The Home tab combines the most relevant information for a player:

- Current player profile and rating.
- Recent notifications.
- Unread notification count.
- Learning content and recommendations.
- Recent community posts.
- Realtime refresh when notifications or community content changes.

The dashboard uses loading states, retry controls, and empty states so a
temporary request failure does not make the entire home screen unusable.

## Playing chess

### Play hub

The Play area provides these game modes:

1. **Quick Match**
2. **Play with Friend**
3. **Play Computer**
4. **Local PvP**
5. **Wi-Fi**

The matches area also shows active online games and recent completed games.

### Quick Match

Quick Match places the signed-in user in a Supabase matchmaking queue. The
current default quick-match control is **10 minutes with no increment (10+0)**.
The backend pairs compatible players using time control and rating range.

The client uses both:

- Supabase Realtime notifications for queue changes.
- Periodic polling as a fallback if a Realtime event is delayed.

The player can cancel the search. Queue cleanup is attempted when leaving the
screen or cancelling.

The backend also supports the configured controls **5+0** and **3+2** for
dynamic matchmaking flows.

### Friend games

The friend-game flow lets a player:

1. Create a game.
2. Share the generated game ID.
3. Keep the game open while the opponent joins.
4. Open the game as White.

The opponent pastes the game ID and joins as Black. A game can be restricted
to an accepted friend when the invitation workflow is used. Friend games are
stored in Supabase and are available across devices while the game remains
active.

### Online game board

Online games use a server-authoritative flow:

1. The client sends a UCI move such as `e2e4`.
2. The trusted Edge Function authenticates the player.
3. The server loads the current game position.
4. The server checks the player color and turn.
5. The server validates the move using `chess.js`.
6. The server calculates the updated FEN, SAN, clock, and result.
7. The server commits the move atomically.
8. The updated game is broadcast through Supabase Realtime.

The client does not decide whether an online move is legal. This prevents a
modified client from directly writing an arbitrary board position.

The online board supports:

- White and Black sides.
- Move history.
- Turn indicators.
- Clocks and increments.
- Realtime opponent moves.
- Draw offers and responses.
- Resignation.
- Timeout handling.
- Checkmate and supported draw results.
- Result dialogs.
- Game review after completion.
- Recovery by refreshing the authoritative game state when a Realtime update
  is delayed.

### Play Computer

Practice mode provides local chess against the application’s chess bot. It is
intended for training and does not create an online game or affect server
matchmaking.

Bot difficulty and chess behavior are implemented in the local chess services.

### Local PvP

Local PvP allows two people to play on the same device. The board and clock
remain local to the device. It is useful when no network connection is
available and is separate from online game history.

### Wi-Fi/LAN games

Wi-Fi mode is for two devices on the same local network:

```text
Device A (host)  <-- local Wi-Fi -->  Device B (joiner)
       TCP server on port 4040
       UDP discovery on port 4041
```

The host:

- Opens a TCP server on port `4040`.
- Advertises a room over UDP discovery port `4041`.
- Displays available private IPv4 addresses.
- Shows a room code and optional QR invite.
- Plays White.

The joiner:

- Discovers nearby advertised games, or enters the host IPv4 address
  manually.
- Can scan the host QR code on supported mobile platforms.
- Connects to the host TCP server.
- Plays Black.

LAN messages are newline-delimited JSON. The LAN game screen validates moves
locally and synchronizes board state and clocks between the two connected
devices.

#### LAN troubleshooting

- Put both devices on the same Wi-Fi network.
- Do not use a guest network that isolates clients.
- Disable VPNs and virtual network adapters while testing.
- Do not enter `localhost`; enter the host device's private IPv4 address.
- Keep the host screen open.
- Allow local-network access on iOS.
- Allow the app through the platform firewall if using a desktop host.
- On Android, the app declares Internet and Wi-Fi multicast permissions.
- Emulators may not be able to discover a physical phone automatically.
- If discovery fails, use manual IP connection.

LAN mode is not internet multiplayer. It does not work between two devices on
different networks without an additional relay or VPN.

## Learning

The Learn tab provides chess education organized into:

- All.
- Basics.
- Openings.
- Tactics.
- Strategy.
- Endgames.

Users can search lessons and open guided lesson steps. Lessons can include
explanations, tips, chessboard positions, and move sequences. Built-in piece
lessons are available locally so the learning area can still show useful
content if the Supabase lesson request fails.

The lesson system is designed to support:

- Published Supabase lessons.
- Lesson categories.
- Lesson progress.
- Guided move sequences.
- Puzzle-style practice.
- Retry and empty states.

## Community

The Community tab is the club's social feed. Users can:

- Read community posts.
- Like or unlike posts.
- Open comments.
- Read comments.
- Add comments.
- Refresh the feed.

Administrators can publish club updates. The feed uses Supabase Realtime so
new posts and changes can appear without requiring a full app restart.

The database contains starter channels/content for:

- General.
- Announcements.
- Study & Tactics.

Announcements are intended to be admin-posted while other club areas can be
member-facing according to their configured policies.

## Profile and player identity

The Profile area displays:

- Display name and username.
- Bio.
- Chess rating.
- Win, loss, and draw statistics.
- Recent games.
- Achievements.
- Game history.
- Friends.
- Settings.
- Admin tools for users with administrator access.

Users can edit their name, username, and bio. Usernames are validated by the
backend and duplicate usernames are reported clearly.

### Friends

The friends feature supports:

- Searching for a player by username.
- Sending friend requests.
- Accepting or declining requests.
- Removing a friend.
- Creating friend games.

Friend requests and friend-game invitations are protected by authenticated
Supabase functions and row-level security policies.

### Game history and statistics

Completed online games are stored in Supabase. The app can show:

- Active games.
- Completed games.
- Move history.
- Game results.
- Opponent details.
- Statistics and result breakdowns.
- A review board for completed games.

Local practice and local PvP are intentionally local-only unless a future
feature explicitly adds persistence for them.

### Achievements

The profile includes an achievements area for player milestones. The visible
achievement experience is part of the application foundation and can be
expanded as more server-backed achievement rules are added.

## Settings

Settings are grouped into a settings overview and individual pages:

- App preferences.
- Game preferences.
- Notification preferences.
- Privacy preferences.
- Profile editing.
- Account actions.
- About and support.

Supported preferences include areas such as:

- Appearance: Light, Dark, or System.
- Sound.
- Board preferences.
- Notifications.
- Privacy and profile visibility.

Settings are persisted through the user settings repository for signed-in
users and through local guest preferences for guest users where applicable.

## Spectator, competitions, archive, and administration

The codebase includes dedicated foundations for:

- Spectator discovery.
- Spectator match views.
- Spectator board rendering.
- Replay controls.
- Competitions and competition details.
- Competition lobbies.
- Admin dashboard.
- User management.
- Match administration.
- Pairings.
- Lessons administration.
- Community administration.
- Recordings and app updates.
- Analytics dashboards.

These screens are intended for continued development and require their
corresponding database policies, data, admin workflows, and operational
testing before being presented as complete production features.

## Technical architecture

### Flutter client

The main code is organized as follows:

```text
lib/
  app/
    app.dart                 Application shell and startup
    router.dart              Feature navigation and route entry points
    theme.dart               Theme and visual styling
  core/
    chess/                   Chess bot and chess-related services
    config/                  Runtime configuration
    models/                  Typed data models
    repositories/            Supabase and persistence access
    services/                Shared application services
  features/
    auth/                    Login, registration, verification
    community/               Community feed and comments
    competitions/            Competition screens
    dashboard/               Main tabs and home dashboard
    guest/                   Guest entry and guest preferences
    learn/                   Lessons and puzzles
    matches/                 Matchmaking, friends, and LAN lobby
    match/                   Online and local chess boards
    profile/                 Profile, history, friends, settings
    spectator/               Spectator and replay screens
    admin/                   Administrative screens
```

### Repositories

Repositories isolate backend access from UI code. Important repositories
include:

- `ProfileRepository`
- `SettingsRepository`
- `ChessGameRepository`
- `CommunityRepository`
- `LessonRepository`
- `NotificationRepository`
- `FriendsRepository`
- `AdminRepository`
- `MatchmakingRepository`

This separation makes it possible to test UI with injected clients or fake
repositories instead of depending on production data.

### Supabase backend

Supabase provides:

- Authentication.
- PostgreSQL tables.
- Row-level security.
- RPC functions.
- Edge Functions.
- Realtime table changes.

Important backend entities include:

- `profiles`
- `user_settings`
- `games`
- `game_moves`
- `game_players`
- `matchmaking_queue`
- `friend_requests`
- `game_draw_offers`
- `community_posts`
- `community_comments`
- `community_post_likes`
- `notifications`
- `player_presence`
- `lessons`
- `lesson_progress`
- `competitions`

Database migrations are stored in `supabase/migrations`.

### Trusted move processing

The `submit-move` Edge Function is the trusted online move boundary. It
authenticates the access token, validates the requested move against the
authoritative FEN, checks the player's turn and clock, calculates the result,
and commits the move through a protected database function.

The client must never receive or contain a Supabase service-role key.

## Configuration

The app loads Supabase configuration from `assets/.env` or compile-time
defines. The expected values are:

```text
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

`SUPABASE_ANON_KEY` is also supported for compatibility. Compile-time
`--dart-define` values take precedence over the environment asset.

Example:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

Never commit a service-role key, secret key, database password, or other
privileged credential to the Flutter application.

## Local development

### Requirements

- Flutter SDK compatible with the Dart constraint in `pubspec.yaml`.
- Android Studio or Xcode for mobile builds as appropriate.
- A Supabase project for authenticated and online features.
- Supabase CLI for applying migrations and deploying functions.

### Install and run

```bash
flutter pub get
flutter run
```

### Supabase setup

1. Create or select a Supabase project.
2. Configure `assets/.env` or use `--dart-define`.
3. Link the local project with the Supabase CLI.
4. Apply all files in `supabase/migrations`.
5. Deploy `supabase/functions/submit-move`.
6. Deploy `supabase/functions/matchmaking` if the deployed flow uses it.
7. Enable/configure authentication providers.
8. Enable Realtime for the tables used by online games, matchmaking,
   notifications, community content, and game draw offers.
9. Configure Google redirect/deep-link settings if Google sign-in is enabled.

The Google setup guide is in `docs/GOOGLE_AUTH_SETUP.md`.

### Validation commands

```bash
flutter analyze
flutter test
dart format lib test
```

For integration tests, use a dedicated Supabase environment rather than
uncontrolled production data.

## Platform permissions and deep links

### Android

The Android manifest declares:

- Internet access.
- Wi-Fi multicast access for LAN discovery.

The app also registers the `sqi-chess-club://login-callback` deep link for
authentication callbacks.

### iOS

The iOS configuration includes:

- Camera permission for QR scanning.
- Local network permission for nearby games.
- Bonjour service metadata for LAN discovery.
- The authentication callback deep link.

Users must approve camera and local-network prompts when the corresponding
features are used.

## Data and security model

The app uses authenticated Supabase access for private player data. Row-level
security policies restrict users to records they are allowed to view or
modify.

Security principles:

- Publishable/anon keys may be present in the client; service-role keys may
  not.
- Online board state is authoritative on the server.
- Online move requests are checked for player identity, turn, legality,
  clock, and state version.
- Game updates are committed atomically to prevent conflicting moves.
- Friend-game joins are checked by trusted database functions.
- Realtime is used for delivery, but the client can refresh authoritative
  state when events are delayed.
- LAN mode is trusted only for the local match session and is not an
  internet security boundary.

## Network behavior

There are two separate network paths:

### Internet play

```text
Flutter app -> Supabase Auth/Postgres/Realtime/Edge Function
```

This path requires working internet access and valid authentication for
private games.

### Local Wi-Fi play

```text
Flutter host -> TCP 4040 -> Flutter joiner
                    ^
                    |
                UDP 4041 discovery
```

This path does not require Supabase but does require both devices to be able
to communicate directly on the same local network.

## Known limitations

- Guest users do not have the same server-backed identity and history as
  signed-in users.
- Local practice and local PvP do not automatically become online records.
- LAN games end when the local host/client connection is lost; there is no
  internet relay or reconnect service.
- LAN discovery can fail on isolated guest Wi-Fi, VPNs, firewalls, emulator
  networking, or networks that block multicast/broadcast traffic.
- Online games depend on Supabase availability, authentication, Realtime,
  migrations, and deployed Edge Functions.
- Realtime is not the only recovery mechanism; screens refresh authoritative
  state when necessary.
- Competition, spectator, moderation, analytics, and some admin workflows
  still require completion and operational verification.
- Account deletion is not currently exposed as a complete self-service
  workflow.
- Production release hardening still needs signing, monitoring, legal pages,
  abuse controls, and platform-store review.

## Recommended user support checklist

When a user reports that a feature does not work, collect:

1. Platform and app build.
2. Whether the user is signed in or using guest mode.
3. Exact screen and action that failed.
4. Exact error message.
5. Whether the issue affects online, LAN, or local play.
6. Network type and whether VPN/guest Wi-Fi is enabled.
7. Whether the problem affects one device or both players.
8. Whether retrying or reopening the screen changes the result.

For an online game, verify Supabase authentication, migrations, Edge Function
deployment, Realtime configuration, and row-level security. For a LAN game,
verify private IP address, same-network connectivity, firewall access, and
multicast/broadcast support.

## Project conventions

- Keep UI in feature folders.
- Keep Supabase access in repositories or trusted functions.
- Use typed models for database records.
- Preserve row-level security and authenticated function permissions.
- Show explicit loading, error, retry, and empty states.
- Keep local-only chess flows separate from server-backed online games.
- Validate changes with `flutter analyze` and targeted tests.