
-- SQI CHECKMATE ARENA
-- Migration 2: Indexes and Row Level Security
-- This file is for a fresh database migration.
-- Do not run it in the existing project's SQL Editor.

-- =========================================================
-- 1. PERFORMANCE INDEXES
-- =========================================================

CREATE INDEX IF NOT EXISTS community_comments_post_created_idx
  ON public.community_comments (post_id, created_at);

CREATE INDEX IF NOT EXISTS community_comments_user_id_idx
  ON public.community_comments (user_id);

CREATE INDEX IF NOT EXISTS community_post_likes_post_id_idx
  ON public.community_post_likes (post_id);

CREATE INDEX IF NOT EXISTS community_post_likes_user_id_idx
  ON public.community_post_likes (user_id);

CREATE INDEX IF NOT EXISTS community_posts_created_at_idx
  ON public.community_posts (created_at DESC);

CREATE INDEX IF NOT EXISTS community_posts_user_id_idx
  ON public.community_posts (user_id);

CREATE INDEX IF NOT EXISTS game_players_game_id_idx
  ON public.game_players (game_id);

CREATE INDEX IF NOT EXISTS game_players_user_id_idx
  ON public.game_players (user_id);

CREATE UNIQUE INDEX IF NOT EXISTS game_players_game_bot_unique_idx
  ON public.game_players (game_id, bot_id)
  WHERE bot_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS game_players_game_user_unique_idx
  ON public.game_players (game_id, user_id)
  WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS games_black_player_id_idx
  ON public.games (black_player_id);

CREATE INDEX IF NOT EXISTS games_created_at_idx
  ON public.games (created_at DESC);

CREATE INDEX IF NOT EXISTS games_status_idx
  ON public.games (status);

CREATE INDEX IF NOT EXISTS games_white_player_id_idx
  ON public.games (white_player_id);

CREATE INDEX IF NOT EXISTS lesson_progress_lesson_id_idx
  ON public.lesson_progress (lesson_id);

CREATE INDEX IF NOT EXISTS lessons_category_idx
  ON public.lessons (category);

CREATE INDEX IF NOT EXISTS lessons_is_published_idx
  ON public.lessons (is_published);

CREATE INDEX IF NOT EXISTS lessons_sort_order_idx
  ON public.lessons (sort_order);

CREATE UNIQUE INDEX IF NOT EXISTS matchmaking_one_searching_entry_per_user_idx
  ON public.matchmaking_queue (user_id)
  WHERE status = 'searching';

CREATE INDEX IF NOT EXISTS matchmaking_queue_rating_idx
  ON public.matchmaking_queue (rating);

CREATE INDEX IF NOT EXISTS matchmaking_queue_time_status_created_idx
  ON public.matchmaking_queue (time_control, status, created_at);

CREATE INDEX IF NOT EXISTS notifications_user_created_idx
  ON public.notifications (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS notifications_unread_idx
  ON public.notifications (user_id, read_at)
  WHERE read_at IS NULL;

CREATE INDEX IF NOT EXISTS player_presence_last_seen_idx
  ON public.player_presence (last_seen_at DESC);

CREATE INDEX IF NOT EXISTS player_presence_status_idx
  ON public.player_presence (status);

CREATE INDEX IF NOT EXISTS profiles_rating_idx
  ON public.profiles (chess_rating);

CREATE INDEX IF NOT EXISTS profiles_skill_level_idx
  ON public.profiles (skill_level);


-- =========================================================
-- 2. ENABLE ROW LEVEL SECURITY ON ALL PUBLIC TABLES
-- =========================================================

ALTER TABLE public.bot_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_moves ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matchmaking_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.player_presence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;


-- =========================================================
-- 3. BOT PROFILES
-- =========================================================

CREATE POLICY "Players can view enabled bots"
ON public.bot_profiles
FOR SELECT
TO authenticated
USING (enabled = true);


-- =========================================================
-- 4. COMMUNITY COMMENTS
-- =========================================================

CREATE POLICY "Authenticated users can view comments"
ON public.community_comments
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Users can create comments"
ON public.community_comments
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments"
ON public.community_comments
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own comments"
ON public.community_comments
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);


-- =========================================================
-- 5. COMMUNITY POST LIKES
-- =========================================================

CREATE POLICY "Authenticated users can view likes"
ON public.community_post_likes
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Users can like posts"
ON public.community_post_likes
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their own likes"
ON public.community_post_likes
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);


-- =========================================================
-- 6. COMMUNITY POSTS
-- =========================================================

CREATE POLICY "Authenticated users can view community posts"
ON public.community_posts
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Users can create their own posts"
ON public.community_posts
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own posts"
ON public.community_posts
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own posts"
ON public.community_posts
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);


-- =========================================================
-- 7. GAME MOVES
-- =========================================================

CREATE POLICY "Players can view moves from their games"
ON public.game_moves
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.games AS g
    WHERE g.id = game_moves.game_id
      AND (
        g.white_player_id = auth.uid()
        OR g.black_player_id = auth.uid()
      )
  )
);


-- =========================================================
-- 8. GAME PLAYERS
-- =========================================================

CREATE POLICY "Players can view game participants"
ON public.game_players
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.games AS g
    WHERE g.id = game_players.game_id
      AND (
        g.white_player_id = auth.uid()
        OR g.black_player_id = auth.uid()
      )
  )
);


-- =========================================================
-- 9. GAMES
-- =========================================================

CREATE POLICY "Players can view their games"
ON public.games
FOR SELECT
TO authenticated
USING (
  auth.uid() = white_player_id
  OR auth.uid() = black_player_id
);


-- =========================================================
-- 10. LESSON PROGRESS
-- =========================================================

CREATE POLICY "Users can insert their own lesson progress"
ON public.lesson_progress
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own lesson progress"
ON public.lesson_progress
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own lesson progress"
ON public.lesson_progress
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);


-- =========================================================
-- 11. LESSONS
-- =========================================================

CREATE POLICY "Anyone authenticated can view published lessons"
ON public.lessons
FOR SELECT
TO authenticated
USING (is_published = true);


-- =========================================================
-- 12. MATCHMAKING QUEUE
-- =========================================================

CREATE POLICY "Players can view own queue entry"
ON public.matchmaking_queue
FOR SELECT
TO authenticated
USING (user_id = auth.uid());


-- =========================================================
-- 13. NOTIFICATIONS
-- =========================================================

CREATE POLICY "Users can view their own notifications"
ON public.notifications
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);


-- =========================================================
-- 14. PLAYER PRESENCE
-- =========================================================

CREATE POLICY "Players can view presence"
ON public.player_presence
FOR SELECT
TO authenticated
USING (true);


-- =========================================================
-- 15. PROFILES
-- =========================================================

CREATE POLICY "Players can view their own profile"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  id = auth.uid()
  OR public_profile = true
);


-- =========================================================
-- 16. USER SETTINGS
-- =========================================================

CREATE POLICY "Users can view their own settings"
ON public.user_settings
FOR SELECT
TO authenticated
USING (user_id = auth.uid());
