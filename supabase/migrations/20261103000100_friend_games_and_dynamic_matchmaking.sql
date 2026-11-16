-- Friend invites and server-side quick-match pairing.

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
  v_user_id uuid := auth.uid();
  v_profile_rating integer;
  v_queue public.matchmaking_queue;
  v_opponent_id uuid;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_time_control IS NULL OR NOT (
    (p_time_control = '10+0' AND p_initial_time_seconds = 600 AND p_increment_seconds = 0)
    OR (p_time_control = '5+0' AND p_initial_time_seconds = 300 AND p_increment_seconds = 0)
    OR (p_time_control = '3+2' AND p_initial_time_seconds = 180 AND p_increment_seconds = 2)
  ) THEN
    RAISE EXCEPTION 'Unsupported time control';
  END IF;

  SELECT chess_rating INTO v_profile_rating
  FROM public.profiles
  WHERE id = v_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Player profile not found';
  END IF;

  UPDATE public.matchmaking_queue
  SET status = 'cancelled', updated_at = pg_catalog.now()
  WHERE user_id = v_user_id AND status = 'searching';

  INSERT INTO public.matchmaking_queue (
    user_id, time_control, initial_time_seconds, increment_seconds,
    rating, min_rating, max_rating, status
  )
  VALUES (
    v_user_id, p_time_control, p_initial_time_seconds, p_increment_seconds,
    v_profile_rating, greatest(0, v_profile_rating - 300),
    v_profile_rating + 300, 'searching'
  )
  RETURNING * INTO v_queue;

  SELECT id INTO v_opponent_id
  FROM public.matchmaking_queue
  WHERE status = 'searching'
    AND user_id <> v_user_id
    AND time_control = v_queue.time_control
    AND initial_time_seconds = v_queue.initial_time_seconds
    AND increment_seconds = v_queue.increment_seconds
    AND (min_rating IS NULL OR v_queue.rating >= min_rating)
    AND (max_rating IS NULL OR v_queue.rating <= max_rating)
    AND (v_queue.min_rating IS NULL OR rating >= v_queue.min_rating)
    AND (v_queue.max_rating IS NULL OR rating <= v_queue.max_rating)
  ORDER BY created_at
  LIMIT 1
  FOR UPDATE SKIP LOCKED;

  IF v_opponent_id IS NOT NULL THEN
    PERFORM public.create_matched_game(v_queue.id, v_opponent_id);
    SELECT * INTO v_queue
    FROM public.matchmaking_queue
    WHERE id = v_queue.id;
  END IF;

  RETURN v_queue;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_friend_game(
  p_time_control text DEFAULT '10+0',
  p_initial_time_seconds integer DEFAULT 600,
  p_increment_seconds integer DEFAULT 0
)
RETURNS public.games
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_game public.games;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_time_control <> '10+0'
     OR p_initial_time_seconds <> 600
     OR p_increment_seconds <> 0 THEN
    RAISE EXCEPTION 'Unsupported time control';
  END IF;

  INSERT INTO public.games (
    game_type, status, time_control, initial_time_seconds,
    increment_seconds, white_player_id, current_fen, current_turn,
    white_time_ms, black_time_ms
  )
  VALUES (
    'online_friend', 'pending', p_time_control, p_initial_time_seconds,
    p_increment_seconds, v_user_id, 'startpos', 'white',
    p_initial_time_seconds::bigint * 1000,
    p_initial_time_seconds::bigint * 1000
  )
  RETURNING * INTO v_game;

  INSERT INTO public.game_players (game_id, user_id, color)
  VALUES (v_game.id, v_user_id, 'white');

  RETURN v_game;
END;
$$;

CREATE OR REPLACE FUNCTION public.join_friend_game(p_game_id uuid)
RETURNS public.games
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_game public.games;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT * INTO v_game
  FROM public.games
  WHERE id = p_game_id
  FOR UPDATE;

  IF v_game.id IS NULL THEN
    RAISE EXCEPTION 'Game not found';
  END IF;
  IF v_game.game_type <> 'online_friend' OR v_game.status <> 'pending' THEN
    RAISE EXCEPTION 'This friend game is no longer available';
  END IF;
  IF v_game.white_player_id = v_user_id THEN
    RAISE EXCEPTION 'You cannot join your own game';
  END IF;

  UPDATE public.games
  SET black_player_id = v_user_id,
      status = 'active',
      started_at = pg_catalog.now(),
      state_version = state_version + 1,
      updated_at = pg_catalog.now()
  WHERE id = p_game_id
  RETURNING * INTO v_game;

  INSERT INTO public.game_players (game_id, user_id, color)
  VALUES (p_game_id, v_user_id, 'black');

  RETURN v_game;
END;
$$;

REVOKE ALL ON FUNCTION public.create_friend_game(text, integer, integer)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_friend_game(text, integer, integer)
TO authenticated;

REVOKE ALL ON FUNCTION public.join_friend_game(uuid)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.join_friend_game(uuid)
TO authenticated;
