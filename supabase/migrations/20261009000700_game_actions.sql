
-- SQI CHECKMATE ARENA
-- Migration 7: Game actions and atomic move commit

CREATE OR REPLACE FUNCTION public.resign_game(
  p_game_id uuid
)
RETURNS public.games
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_game public.games;
  v_result text;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT *
  INTO v_game
  FROM public.games
  WHERE id = p_game_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Game not found';
  END IF;

  IF v_game.status <> 'active' THEN
    RAISE EXCEPTION 'Game is not active';
  END IF;

  IF v_game.white_player_id = v_user_id THEN
    v_result := 'black';
  ELSIF v_game.black_player_id = v_user_id THEN
    v_result := 'white';
  ELSE
    RAISE EXCEPTION 'You are not a player in this game';
  END IF;

  UPDATE public.games
  SET
    status = 'completed',
    result = v_result,
    termination_reason = 'resignation',
    ended_at = pg_catalog.now(),
    updated_at = pg_catalog.now()
  WHERE id = p_game_id
  RETURNING * INTO v_game;

  UPDATE public.player_presence
  SET
    status = 'online',
    current_game_id = NULL,
    last_seen_at = pg_catalog.now(),
    updated_at = pg_catalog.now()
  WHERE user_id IN (
    v_game.white_player_id,
    v_game.black_player_id
  );

  RETURN v_game;
END;
$$;


CREATE OR REPLACE FUNCTION public.commit_validated_move(
  p_game_id uuid,
  p_user_id uuid,
  p_expected_state_version bigint,
  p_expected_fen text,
  p_expected_turn text,
  p_uci text,
  p_san text,
  p_fen_after text,
  p_color text,
  p_move_number integer,
  p_ply integer,
  p_remaining_time_ms bigint,
  p_result text,
  p_termination_reason text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_game public.games;
  v_move public.game_moves;
  v_next_turn text;
  v_next_status text;
BEGIN
  IF p_game_id IS NULL OR p_user_id IS NULL
     OR p_expected_state_version IS NULL
     OR p_expected_fen IS NULL OR p_expected_turn IS NULL
     OR p_uci IS NULL OR p_san IS NULL OR p_fen_after IS NULL
     OR p_color IS NULL OR p_move_number IS NULL OR p_ply IS NULL THEN
    RAISE EXCEPTION 'Required move fields are missing';
  END IF;

  IF p_color NOT IN ('white', 'black')
     OR p_expected_turn NOT IN ('white', 'black') THEN
    RAISE EXCEPTION 'Invalid player color';
  END IF;

  IF p_result IS NOT NULL
     AND p_result NOT IN ('white', 'black', 'draw') THEN
    RAISE EXCEPTION 'Invalid game result';
  END IF;

  IF p_move_number <= 0 OR p_ply <= 0 THEN
    RAISE EXCEPTION 'Invalid move number';
  END IF;

  SELECT *
  INTO v_game
  FROM public.games
  WHERE id = p_game_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Game not found';
  END IF;

  IF v_game.status <> 'active' THEN
    RAISE EXCEPTION 'Game is not active';
  END IF;

  IF NOT (
    (p_color = 'white' AND v_game.white_player_id = p_user_id)
    OR
    (p_color = 'black' AND v_game.black_player_id = p_user_id)
  ) THEN
    RAISE EXCEPTION 'Player does not match game color';
  END IF;

  IF v_game.state_version <> p_expected_state_version
     OR v_game.current_fen IS DISTINCT FROM p_expected_fen
     OR v_game.current_turn IS DISTINCT FROM p_expected_turn THEN
    RAISE EXCEPTION 'Game state is stale; reload and retry';
  END IF;

  IF v_game.current_turn <> p_color THEN
    RAISE EXCEPTION 'It is not this player''s turn';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.game_moves
    WHERE game_id = p_game_id
      AND ply = p_ply
  ) THEN
    RAISE EXCEPTION 'Move already committed';
  END IF;

  INSERT INTO public.game_moves (
    game_id,
    move_number,
    ply,
    color,
    san,
    uci,
    fen_after,
    remaining_time_ms
  )
  VALUES (
    p_game_id,
    p_move_number,
    p_ply,
    p_color,
    p_san,
    p_uci,
    p_fen_after,
    p_remaining_time_ms
  )
  RETURNING * INTO v_move;

  v_next_turn := CASE p_color
    WHEN 'white' THEN 'black'
    ELSE 'white'
  END;

  v_next_status := CASE
    WHEN p_result IS NOT NULL THEN 'completed'
    ELSE 'active'
  END;

  UPDATE public.games
  SET
    current_fen = p_fen_after,
    current_turn = CASE
      WHEN p_result IS NOT NULL THEN current_turn
      ELSE v_next_turn
    END,
    white_time_ms = CASE
      WHEN p_color = 'white'
           AND p_remaining_time_ms IS NOT NULL
      THEN p_remaining_time_ms
      ELSE white_time_ms
    END,
    black_time_ms = CASE
      WHEN p_color = 'black'
           AND p_remaining_time_ms IS NOT NULL
      THEN p_remaining_time_ms
      ELSE black_time_ms
    END,
    result = p_result,
    termination_reason = p_termination_reason,
    status = v_next_status,
    ended_at = CASE
      WHEN p_result IS NOT NULL THEN pg_catalog.now()
      ELSE ended_at
    END,
    state_version = state_version + 1,
    updated_at = pg_catalog.now()
  WHERE id = p_game_id;

  RETURN pg_catalog.jsonb_build_object(
    'move', pg_catalog.to_jsonb(v_move),
    'state_version', p_expected_state_version + 1,
    'status', v_next_status
  );
END;
$$;


REVOKE ALL ON FUNCTION public.resign_game(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.resign_game(uuid)
TO authenticated;


REVOKE ALL ON FUNCTION public.commit_validated_move(
  uuid, uuid, bigint, text, text, text, text, text, text,
  integer, integer, bigint, text, text
)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.commit_validated_move(
  uuid, uuid, bigint, text, text, text, text, text, text,
  integer, integer, bigint, text, text
)
TO service_role;