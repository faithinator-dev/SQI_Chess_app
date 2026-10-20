
-- SQI CHECKMATE ARENA
-- Migration 1: Core database schema
-- Target: a fresh Supabase project
-- Does not insert application data.

create extension if not exists pgcrypto;

-- =========================================================
-- 1. BOT PROFILES
-- =========================================================

create table public.bot_profiles (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  username text not null unique,
  avatar_url text,
  description text,
  rating integer not null check (rating >= 100),
  difficulty text not null
    check (difficulty in ('Beginner', 'Intermediate', 'Advanced', 'Expert')),
  personality text,
  engine_strength integer not null default 1
    check (engine_strength between 1 and 20),
  enabled boolean not null default true,
  created_at timestamptz not null default timezone('utc', now())
);

-- =========================================================
-- 2. PLAYER PROFILES
-- =========================================================

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  full_name text not null,
  phone text,
  avatar_url text,
  bio text,
  skill_level text not null default 'Beginner'
    check (skill_level in ('Beginner', 'Intermediate', 'Advanced', 'Expert')),
  chess_rating integer not null default 1000
    check (chess_rating >= 0),
  games_played integer not null default 0 check (games_played >= 0),
  wins integer not null default 0 check (wins >= 0),
  losses integer not null default 0 check (losses >= 0),
  draws integer not null default 0 check (draws >= 0),
  current_streak integer not null default 0 check (current_streak >= 0),
  sqi_status text not null default 'Student',
  department text,
  level text,
  campus text,
  preferred_time_control text not null default 'Rapid',
  play_style text not null default 'Both',
  public_profile boolean not null default true,
  role text not null default 'player'
    check (role in ('player', 'admin')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- =========================================================
-- 3. PLAYER SETTINGS
-- =========================================================

create table public.user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  notifications boolean not null default true,
  email_notifications boolean not null default true,
  push_notifications boolean not null default true,
  match_invites boolean not null default true,
  community_mentions boolean not null default true,
  game_sounds boolean not null default true,
  vibration boolean not null default true,
  board_coordinates boolean not null default true,
  confirm_resignation boolean not null default true,
  reduce_motion boolean not null default false,
  appearance text not null default 'Dark'
    check (appearance in ('Dark', 'Light', 'System')),
  language text not null default 'English',
  timezone text not null default 'Africa/Lagos',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- =========================================================
-- 4. GAMES
-- =========================================================

create table public.games (
  id uuid primary key default gen_random_uuid(),
  game_type text not null
    check (game_type in ('online_random', 'online_friend', 'bot', 'lan', 'local')),
  status text not null default 'pending'
    check (status in ('pending', 'active', 'paused', 'completed', 'abandoned', 'cancelled')),
  time_control text not null,
  initial_time_seconds integer not null check (initial_time_seconds > 0),
  increment_seconds integer not null default 0 check (increment_seconds >= 0),
  white_player_id uuid references auth.users(id) on delete set null,
  black_player_id uuid references auth.users(id) on delete set null,
  bot_id uuid references public.bot_profiles(id) on delete set null,
  current_fen text,
  current_turn text check (current_turn is null or current_turn in ('white', 'black')),
  white_time_ms bigint,
  black_time_ms bigint,
  result text check (result is null or result in ('white', 'black', 'draw', 'abandoned')),
  termination_reason text,
  started_at timestamptz,
  ended_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  state_version bigint not null default 0
);

-- =========================================================
-- 5. GAME PLAYERS
-- =========================================================

create table public.game_players (
  game_id uuid not null references public.games(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  bot_id uuid references public.bot_profiles(id) on delete set null,
  color text not null check (color in ('white', 'black')),
  joined_at timestamptz not null default timezone('utc', now()),
  primary key (game_id, color),
  check (user_id is not null or bot_id is not null),
  check (not (user_id is not null and bot_id is not null))
);

-- =========================================================
-- 6. GAME MOVES
-- =========================================================

create table public.game_moves (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games(id) on delete cascade,
  move_number integer not null check (move_number > 0),
  ply integer not null check (ply > 0),
  color text not null check (color in ('white', 'black')),
  san text not null,
  uci text,
  fen_after text not null,
  remaining_time_ms bigint,
  created_at timestamptz not null default timezone('utc', now()),
  unique (game_id, ply)
);

-- =========================================================
-- 7. MATCHMAKING QUEUE
-- =========================================================

create table public.matchmaking_queue (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  time_control text not null,
  initial_time_seconds integer not null check (initial_time_seconds > 0),
  increment_seconds integer not null default 0 check (increment_seconds >= 0),
  rating integer not null check (rating >= 0),
  min_rating integer check (min_rating is null or min_rating >= 0),
  max_rating integer check (max_rating is null or max_rating >= 0),
  status text not null default 'searching'
    check (status in ('searching', 'matched', 'cancelled', 'expired')),
  matched_game_id uuid references public.games(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  expires_at timestamptz not null default timezone('utc', now()) + interval '2 minutes',
  updated_at timestamptz not null default timezone('utc', now())
);

-- =========================================================
-- 8. PLAYER PRESENCE
-- =========================================================

create table public.player_presence (
  user_id uuid primary key references auth.users(id) on delete cascade,
  status text not null default 'offline'
    check (status in ('online', 'away', 'playing', 'offline')),
  last_seen_at timestamptz not null default timezone('utc', now()),
  current_game_id uuid references public.games(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now())
);

-- =========================================================
-- 9. COMMUNITY POSTS
-- =========================================================

create table public.community_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  content text not null check (length(trim(content)) > 0),
  image_url text,
  is_pinned boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- =========================================================
-- 10. COMMUNITY COMMENTS
-- =========================================================

create table public.community_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  content text not null check (length(trim(content)) > 0),
  created_at timestamptz not null default timezone('utc', now())
);

-- =========================================================
-- 11. COMMUNITY POST LIKES
-- =========================================================

create table public.community_post_likes (
  post_id uuid not null references public.community_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (post_id, user_id)
);

-- =========================================================
-- 12. LESSONS
-- =========================================================

create table public.lessons (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  category text not null default 'Basics',
  difficulty text not null default 'Beginner'
    check (difficulty in ('Beginner', 'Intermediate', 'Advanced', 'Expert')),
  duration_minutes integer not null default 10 check (duration_minutes > 0),
  sort_order integer not null default 0,
  thumbnail_url text,
  content jsonb not null default '{}',
  is_published boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- =========================================================
-- 13. LESSON PROGRESS
-- =========================================================

create table public.lesson_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  progress integer not null default 0 check (progress between 0 and 100),
  completed boolean not null default false,
  last_position integer not null default 0 check (last_position >= 0),
  started_at timestamptz,
  completed_at timestamptz,
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, lesson_id)
);

-- =========================================================
-- 14. NOTIFICATIONS
-- =========================================================

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null
    check (type in ('match_ready', 'match_invite', 'community_like', 'community_comment', 'lesson', 'system')),
  title text not null,
  message text not null,
  data jsonb not null default '{}',
  read_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);