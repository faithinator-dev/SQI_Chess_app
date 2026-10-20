-- SQI CHECKMATE ARENA
-- Phase 2: secure draw offers and idempotent rated-game completion.
-- Review and apply only to a disposable local/staging database first.

CREATE TABLE public.game_draw_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id uuid NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
  offered_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  offered_to uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  state_version bigint NOT NULL CHECK (state_version >= 0),
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  responded_at timestamptz,
  CHECK (offered_by <> offered_to)
);

CREATE UNIQUE INDEX game_draw_offers_one_pending_per_game_idx
  ON public.game_draw_offers (game_id)
  WHERE status = 'pending';

CREATE INDEX game_draw_offers_recipient_idx
  ON public.game_draw_offers (offered_to, status, created_at DESC);

CREATE TABLE public.game_completions (
  game_id uuid PRIMARY KEY REFERENCES public.games(id) ON DELETE CASCADE,
  result text NOT NULL CHECK (result IN ('white', 'black', 'draw')),
  termination_reason text NOT NULL,
  white_rating_before integer,
  black_rating_before integer,
  white_rating_delta integer NOT NULL DEFAULT 0,
  black_rating_delta integer NOT NULL DEFAULT 0,
  applied_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

ALTER TABLE public.game_draw_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_completions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Players can view draw offers from their games"
ON public.game_draw_offers
FOR SELECT
TO authenticated
USING (offered_by = auth.uid() OR offered_to = auth.uid());

CREATE POLICY "Players can view completions from their games"
ON public.game_completions
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.games AS g
    WHERE g.id = game_completions.game_id
      AND (g.white_player_id = auth.uid() OR g.black_player_id = auth.uid())
  )
);

GRANT SELECT ON public.game_draw_offers, public.game_completions
TO authenticated;

CREATE OR REPLACE FUNCTION public.apply_game_completion(
  p_game_id uuid,
  p_result text,
  p_termination_reason text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_game public.games;
  v_white_rating integer;
  v_black_rating integer;
  v_white_delta integer := 0;
  v_black_delta integer := 0;
  v_expected_white numeric;
  v_expected_black numeric;
BEGIN
  IF p_result NOT IN ('white', 'black', 'draw')
     OR p_termination_reason IS NULL
     OR length(pg_catalog.btrim(p_termination_reason)) = 0 THEN
    RAISE EXCEPTION 'Invalid completion data';
  END IF;

  SELECT *
  INTO v_game
  FROM public.games
  WHERE id = p_game_id
  FOR UPDATE;

  IF NOT FOUND OR v_game.status <> 'completed'
     OR v_game.result IS DISTINCT FROM p_result THEN
    RAISE EXCEPTION 'Game completion state is invalid';
  END IF;

  INSERT INTO public.game_completions (
    game_id,
    result,
    termination_reason,
    white_rating_before,
    black_rating_before
  )
  VALUES (
    p_game_id,
    p_result,
    p_termination_reason,
    NULL,
    NULL
  )
  ON CONFLICT (game_id) DO NOTHING;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  IF v_game.game_type IN ('online_random', 'online_friend')
     AND v_game.white_player_id IS NOT NULL
     AND v_game.black_player_id IS NOT NULL THEN
    PERFORM 1
    FROM public.profiles
    WHERE id IN (v_game.white_player_id, v_game.black_player_id)
    ORDER BY id
    FOR UPDATE;

    SELECT chess_rating
    INTO v_white_rating
    FROM public.profiles
    WHERE id = v_game.white_player_id;

    SELECT chess_rating
    INTO v_black_rating
    FROM public.profiles
    WHERE id = v_game.black_player_id;

    IF v_white_rating IS NULL OR v_black_rating IS NULL THEN
      RAISE EXCEPTION 'Player profiles are required for rated completion';
    END IF;

    v_expected_white :=
      1 / (1 + pg_catalog.power(10, (v_black_rating - v_white_rating) / 400.0));
    v_expected_black := 1 - v_expected_white;

    v_white_delta := pg_catalog.round(
      32 * ((CASE WHEN p_result = 'white' THEN 1
                  WHEN p_result = 'draw' THEN 0.5
                  ELSE 0 END) - v_expected_white)
    );
    v_black_delta := pg_catalog.round(
      32 * ((CASE WHEN p_result = 'black' THEN 1
                  WHEN p_result = 'draw' THEN 0.5
                  ELSE 0 END) - v_expected_black)
    );

    UPDATE public.profiles
    SET
      chess_rating = pg_catalog.greatest(0, chess_rating + v_white_delta),
      games_played = games_played + 1,
      wins = wins + CASE WHEN p_result = 'white' THEN 1 ELSE 0 END,
      losses = losses + CASE WHEN p_result = 'black' THEN 1 ELSE 0 END,
      draws = draws + CASE WHEN p_result = 'draw' THEN 1 ELSE 0 END,
      current_streak = CASE
        WHEN p_result = 'white' THEN current_streak + 1
        ELSE 0
      END,
      updated_at = pg_catalog.now()
    WHERE id = v_game.white_player_id;

    UPDATE public.profiles
    SET
      chess_rating = pg_catalog.greatest(0, chess_rating + v_black_delta),
      games_played = games_played + 1,
      wins = wins + CASE WHEN p_result = 'black' THEN 1 ELSE 0 END,
      losses = losses + CASE WHEN p_result = 'white' THEN 1 ELSE 0 END,
      draws = draws + CASE WHEN p_result = 'draw' THEN 1 ELSE 0 END,
      current_streak = CASE
        WHEN p_result = 'black' THEN current_streak + 1
        ELSE 0
      END,
      updated_at = pg_catalog.now()
    WHERE id = v_game.black_player_id;

    UPDATE public.game_completions
    SET
      white_rating_before = v_white_rating,
      black_rating_before = v_black_rating,
      white_rating_delta = v_white_delta,
      black_rating_delta = v_black_delta
    WHERE game_id = p_game_id;
  END IF;

  UPDATE public.player_presence
  SET
    status = 'online',
    current_game_id = NULL,
    last_seen_at = pg_catalog.now(),
    updated_at = pg_catalog.now()
  WHERE user_id IN (v_game.white_player_id, v_game.black_player_id);

  UPDATE public.game_draw_offers
  SET
    status = 'declined',
    responded_at = pg_catalog.now()
  WHERE game_id = p_game_id
    AND status = 'pending';
END;
$$;

CREATE OR REPLACE FUNCTION public.offer_draw(p_game_id uuid)
RETURNS public.game_draw_offers
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_game public.games;
  v_offer public.game_draw_offers;
  v_recipient uuid;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT * INTO v_game
  FROM public.games
  WHERE id = p_game_id
  FOR UPDATE;

  IF NOT FOUND OR v_game.status <> 'active' THEN
    RAISE EXCEPTION 'Game is not active';
  END IF;

  IF v_game.white_player_id = v_user_id THEN
    v_recipient := v_game.black_player_id;
  ELSIF v_game.black_player_id = v_user_id THEN
    v_recipient := v_game.white_player_id;
  ELSE
    RAISE EXCEPTION 'You are not a player in this game';
  END IF;

  IF v_recipient IS NULL THEN
    RAISE EXCEPTION 'A human opponent is required';
  END IF;

  INSERT INTO public.game_draw_offers (
    game_id, offered_by, offered_to, state_version
  )
  VALUES (p_game_id, v_user_id, v_recipient, v_game.state_version)
  RETURNING * INTO v_offer;

  RETURN v_offer;
END;
$$;

CREATE OR REPLACE FUNCTION public.respond_draw_offer(
  p_offer_id uuid,
  p_accept boolean
)
RETURNS public.games
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_offer public.game_draw_offers;
  v_game public.games;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT * INTO v_offer
  FROM public.game_draw_offers
  WHERE id = p_offer_id
  FOR UPDATE;

  IF NOT FOUND OR v_offer.offered_to <> v_user_id
     OR v_offer.status <> 'pending' THEN
    RAISE EXCEPTION 'Draw offer is not available';
  END IF;

  SELECT * INTO v_game
  FROM public.games
  WHERE id = v_offer.game_id
  FOR UPDATE;

  IF v_game.status <> 'active'
     OR v_game.state_version <> v_offer.state_version THEN
    RAISE EXCEPTION 'Draw offer is stale';
  END IF;

  IF NOT p_accept THEN
    UPDATE public.game_draw_offers
    SET status = 'declined', responded_at = pg_catalog.now()
    WHERE id = p_offer_id
    RETURNING * INTO v_offer;
    RETURN v_game;
  END IF;

  UPDATE public.games
  SET
    status = 'completed',
    result = 'draw',
    termination_reason = 'agreement',
    ended_at = pg_catalog.now(),
    state_version = state_version + 1,
    updated_at = pg_catalog.now()
  WHERE id = v_game.id
  RETURNING * INTO v_game;

  UPDATE public.game_draw_offers
  SET status = 'accepted', responded_at = pg_catalog.now()
  WHERE id = p_offer_id;

  PERFORM public.apply_game_completion(
    v_game.id, 'draw', 'agreement'
  );

  RETURN v_game;
END;
$$;

CREATE OR REPLACE FUNCTION public.expire_game_on_timeout(p_game_id uuid)
RETURNS public.games
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_game public.games;
  v_elapsed bigint;
  v_remaining bigint;
  v_result text;
BEGIN
  SELECT * INTO v_game
  FROM public.games
  WHERE id = p_game_id
  FOR UPDATE;

  IF NOT FOUND OR v_game.status <> 'active' THEN
    RAISE EXCEPTION 'Game is not active';
  END IF;

  IF v_user_id IS NULL
     OR (v_user_id <> v_game.white_player_id
         AND v_user_id <> v_game.black_player_id) THEN
    RAISE EXCEPTION 'You are not a player in this game';
  END IF;

  v_elapsed := pg_catalog.greatest(
    0,
    floor(extract(epoch FROM (pg_catalog.now() - v_game.updated_at)) * 1000)
  );
  v_remaining := CASE
    WHEN v_game.current_turn = 'white'
      THEN pg_catalog.greatest(0, v_game.white_time_ms - v_elapsed)
    ELSE pg_catalog.greatest(0, v_game.black_time_ms - v_elapsed)
  END;

  IF v_remaining > 0 THEN
    RAISE EXCEPTION 'Game clock has not expired';
  END IF;

  v_result := CASE
    WHEN v_game.current_turn = 'white' THEN 'black'
    ELSE 'white'
  END;

  UPDATE public.games
  SET
    status = 'completed',
    result = v_result,
    termination_reason = 'timeout',
    ended_at = pg_catalog.now(),
    state_version = state_version + 1,
    updated_at = pg_catalog.now()
  WHERE id = p_game_id
  RETURNING * INTO v_game;

  PERFORM public.apply_game_completion(v_game.id, v_result, 'timeout');
  RETURN v_game;
END;
$$;

REVOKE ALL ON FUNCTION public.apply_game_completion(uuid, text, text)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.offer_draw(uuid)
TO authenticated;

GRANT EXECUTE ON FUNCTION public.respond_draw_offer(uuid, boolean)
TO authenticated;

GRANT EXECUTE ON FUNCTION public.expire_game_on_timeout(uuid)
TO authenticated;

-- Replace resignation so all authenticated online completions use the ledger.
CREATE OR REPLACE FUNCTION public.resign_game(p_game_id uuid)
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

  SELECT * INTO v_game
  FROM public.games
  WHERE id = p_game_id
  FOR UPDATE;

  IF NOT FOUND OR v_game.status <> 'active' THEN
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
    state_version = state_version + 1,
    updated_at = pg_catalog.now()
  WHERE id = p_game_id
  RETURNING * INTO v_game;

  PERFORM public.apply_game_completion(v_game.id, v_result, 'resignation');

  RETURN v_game;
END;
$$;

GRANT EXECUTE ON FUNCTION public.resign_game(uuid)
TO authenticated;

-- Replace the validated move commit so checkmate and supported chess draws
-- enter the same completion ledger as resignation and agreed draws.
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

  SELECT * INTO v_game
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
    OR (p_color = 'black' AND v_game.black_player_id = p_user_id)
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
    SELECT 1 FROM public.game_moves
    WHERE game_id = p_game_id AND ply = p_ply
  ) THEN
    RAISE EXCEPTION 'Move already committed';
  END IF;

  INSERT INTO public.game_moves (
    game_id, move_number, ply, color, san, uci, fen_after, remaining_time_ms
  )
  VALUES (
    p_game_id, p_move_number, p_ply, p_color, p_san, p_uci,
    p_fen_after, p_remaining_time_ms
  )
  RETURNING * INTO v_move;

  v_next_turn := CASE p_color WHEN 'white' THEN 'black' ELSE 'white' END;
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
      WHEN p_color = 'white' AND p_remaining_time_ms IS NOT NULL
      THEN p_remaining_time_ms ELSE white_time_ms END,
    black_time_ms = CASE
      WHEN p_color = 'black' AND p_remaining_time_ms IS NOT NULL
      THEN p_remaining_time_ms ELSE black_time_ms END,
    result = p_result,
    termination_reason = p_termination_reason,
    status = v_next_status,
    ended_at = CASE
      WHEN p_result IS NOT NULL THEN pg_catalog.now()
      ELSE ended_at END,
    state_version = state_version + 1,
    updated_at = pg_catalog.now()
  WHERE id = p_game_id
  RETURNING * INTO v_game;

  UPDATE public.game_draw_offers
  SET
    status = 'declined',
    responded_at = pg_catalog.now()
  WHERE game_id = p_game_id
    AND status = 'pending';

  IF p_result IS NOT NULL THEN
    PERFORM public.apply_game_completion(
      p_game_id, p_result, p_termination_reason
    );
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'move', pg_catalog.to_jsonb(v_move),
    'state_version', p_expected_state_version + 1,
    'status', v_next_status
  );
END;
$$;

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

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'game_draw_offers'
  ) THEN
    EXECUTE
      'ALTER PUBLICATION supabase_realtime ADD TABLE public.game_draw_offers';
  END IF;
END;
$$;
