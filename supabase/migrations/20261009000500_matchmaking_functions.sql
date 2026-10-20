
-- SQI CHECKMATE ARENA
-- Migration 5: Matchmaking functions
-- Intended for a fresh Supabase database.

-- =========================================================
-- 1. JOIN MATCHMAKING
-- =========================================================

CREATE OR REPLACE FUNCTION public.join_matchmaking(
  p_time_control text,
  p_initial_time_seconds integer,
  p_increment_seconds integer,
  p_rating integer
)
RETURNS public.matchmaking_queue
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid;
  v_profile_rating integer;
  v_queue public.matchmaking_queue;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_time_control IS NULL
     OR NOT (
       (p_time_control = '10+0'
        AND p_initial_time_seconds = 600
        AND p_increment_seconds = 0)
       OR
       (p_time_control = '5+0'
        AND p_initial_time_seconds = 300
        AND p_increment_seconds = 0)
       OR
       (p_time_control = '3+2'
        AND p_initial_time_seconds = 180
        AND p_increment_seconds = 2)
     ) THEN
    RAISE EXCEPTION 'Unsupported time control';
  END IF;

  SELECT p.chess_rating
  INTO v_profile_rating
  FROM public.profiles AS p
  WHERE p.id = v_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Player profile not found';
  END IF;

  -- The server uses the stored profile rating, not the
  -- rating supplied by the client.
  UPDATE public.matchmaking_queue
  SET
    status = 'cancelled',
    updated_at = pg_catalog.now()
  WHERE user_id = v_user_id
    AND status = 'searching';

  INSERT INTO public.matchmaking_queue (
    user_id,
    time_control,
    initial_time_seconds,
    increment_seconds,
    rating,
    min_rating,
    max_rating,
    status
  )
  VALUES (
    v_user_id,
    p_time_control,
    p_initial_time_seconds,
    p_increment_seconds,
    v_profile_rating,
    GREATEST(0, v_profile_rating - 300),
    v_profile_rating + 300,
    'searching'
  )
  RETURNING * INTO v_queue;

  RETURN v_queue;
END;
$$;


-- =========================================================
-- 2. LEAVE MATCHMAKING
-- =========================================================

CREATE OR REPLACE FUNCTION public.leave_matchmaking()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  UPDATE public.matchmaking_queue
  SET
    status = 'cancelled',
    updated_at = pg_catalog.now()
  WHERE user_id = v_user_id
    AND status = 'searching';
END;
$$;


-- =========================================================
-- 3. CREATE A MATCHED GAME
-- =========================================================

CREATE OR REPLACE FUNCTION public.create_matched_game(
  p_queue_a uuid,
  p_queue_b uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid;
  v_a public.matchmaking_queue;
  v_b public.matchmaking_queue;
  v_game_id uuid;
  v_white_user uuid;
  v_black_user uuid;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_queue_a IS NULL OR p_queue_b IS NULL
     OR p_queue_a = p_queue_b THEN
    RAISE EXCEPTION 'Two different queue entries are required';
  END IF;

  -- Lock queue rows in a consistent order.
  IF p_queue_a::text < p_queue_b::text THEN
    SELECT * INTO v_a
    FROM public.matchmaking_queue
    WHERE id = p_queue_a
    FOR UPDATE;

    SELECT * INTO v_b
    FROM public.matchmaking_queue
    WHERE id = p_queue_b
    FOR UPDATE;
  ELSE
    SELECT * INTO v_b
    FROM public.matchmaking_queue
    WHERE id = p_queue_b
    FOR UPDATE;

    SELECT * INTO v_a
    FROM public.matchmaking_queue
    WHERE id = p_queue_a
    FOR UPDATE;
  END IF;

  IF v_a.id IS NULL OR v_b.id IS NULL THEN
    RAISE EXCEPTION 'Queue entry not found';
  END IF;

  IF v_a.status <> 'searching' OR v_b.status <> 'searching' THEN
    RAISE EXCEPTION 'Both players must be searching';
  END IF;

  IF v_a.user_id = v_b.user_id THEN
    RAISE EXCEPTION 'A player cannot be matched with themselves';
  END IF;

  IF v_user_id <> v_a.user_id AND v_user_id <> v_b.user_id THEN
    RAISE EXCEPTION 'You are not part of this match';
  END IF;

  IF v_a.time_control <> v_b.time_control
     OR v_a.initial_time_seconds <> v_b.initial_time_seconds
     OR v_a.increment_seconds <> v_b.increment_seconds THEN
    RAISE EXCEPTION 'Players have incompatible time controls';
  END IF;

  IF (v_a.min_rating IS NOT NULL AND v_b.rating < v_a.min_rating)
     OR (v_a.max_rating IS NOT NULL AND v_b.rating > v_a.max_rating)
     OR (v_b.min_rating IS NOT NULL AND v_a.rating < v_b.min_rating)
     OR (v_b.max_rating IS NOT NULL AND v_a.rating > v_b.max_rating) THEN
    RAISE EXCEPTION 'Players are outside the allowed rating range';
  END IF;

  IF pg_catalog.random() < 0.5 THEN
    v_white_user := v_a.user_id;
    v_black_user := v_b.user_id;
  ELSE
    v_white_user := v_b.user_id;
    v_black_user := v_a.user_id;
  END IF;

  INSERT INTO public.games (
    game_type,
    status,
    time_control,
    initial_time_seconds,
    increment_seconds,
    white_player_id,
    black_player_id,
    current_fen,
    current_turn,
    white_time_ms,
    black_time_ms,
    started_at
  )
  VALUES (
    'online_random',
    'active',
    v_a.time_control,
    v_a.initial_time_seconds,
    v_a.increment_seconds,
    v_white_user,
    v_black_user,
    'startpos',
    'white',
    v_a.initial_time_seconds::bigint * 1000,
    v_a.initial_time_seconds::bigint * 1000,
    pg_catalog.now()
  )
  RETURNING id INTO v_game_id;

  INSERT INTO public.game_players (game_id, user_id, color)
  VALUES
    (v_game_id, v_white_user, 'white'),
    (v_game_id, v_black_user, 'black');

  UPDATE public.matchmaking_queue
  SET
    status = 'matched',
    matched_game_id = v_game_id,
    updated_at = pg_catalog.now()
  WHERE id IN (p_queue_a, p_queue_b);

  INSERT INTO public.player_presence (
    user_id,
    status,
    current_game_id,
    last_seen_at,
    updated_at
  )
  VALUES
    (v_white_user, 'playing', v_game_id, pg_catalog.now(), pg_catalog.now()),
    (v_black_user, 'playing', v_game_id, pg_catalog.now(), pg_catalog.now())
  ON CONFLICT (user_id)
  DO UPDATE SET
    status = 'playing',
    current_game_id = EXCLUDED.current_game_id,
    last_seen_at = EXCLUDED.last_seen_at,
    updated_at = EXCLUDED.updated_at;

  RETURN v_game_id;
END;
$$;


-- =========================================================
-- 4. EXPIRE OLD QUEUE ENTRIES
-- Intended for trusted backend or scheduled execution.
-- =========================================================

CREATE OR REPLACE FUNCTION public.expire_matchmaking_queue()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_count integer;
BEGIN
  UPDATE public.matchmaking_queue
  SET
    status = 'expired',
    updated_at = pg_catalog.now()
  WHERE status = 'searching'
    AND expires_at <= pg_catalog.now();

  GET DIAGNOSTICS v_count = ROW_COUNT;

  RETURN v_count;
END;
$$;


-- =========================================================
-- 5. FUNCTION EXECUTION PERMISSIONS
-- =========================================================

REVOKE ALL ON FUNCTION public.join_matchmaking(text, integer, integer, integer)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.join_matchmaking(text, integer, integer, integer)
TO authenticated;


REVOKE ALL ON FUNCTION public.leave_matchmaking()
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.leave_matchmaking()
TO authenticated;


REVOKE ALL ON FUNCTION public.create_matched_game(uuid, uuid)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.create_matched_game(uuid, uuid)
TO authenticated;


REVOKE ALL ON FUNCTION public.expire_matchmaking_queue()
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.expire_matchmaking_queue()
TO service_role;
