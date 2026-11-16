-- Friends, friend requests, and direct friend game invitations.

CREATE TABLE IF NOT EXISTS public.friend_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  addressee_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  CHECK (requester_id <> addressee_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS friend_requests_pair_idx
  ON public.friend_requests (LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id));
CREATE INDEX IF NOT EXISTS friend_requests_addressee_status_idx
  ON public.friend_requests (addressee_id, status);
CREATE INDEX IF NOT EXISTS friend_requests_requester_status_idx
  ON public.friend_requests (requester_id, status);

ALTER TABLE public.friend_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their friend requests"
ON public.friend_requests;
CREATE POLICY "Users can view their friend requests"
ON public.friend_requests FOR SELECT TO authenticated
USING (requester_id = auth.uid() OR addressee_id = auth.uid());

DROP POLICY IF EXISTS "Users can create friend requests"
ON public.friend_requests;
CREATE POLICY "Users can create friend requests"
ON public.friend_requests FOR INSERT TO authenticated
WITH CHECK (requester_id = auth.uid() AND requester_id <> addressee_id);

CREATE OR REPLACE FUNCTION public.send_friend_request(p_username text)
RETURNS public.friend_requests
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_target_id uuid;
  v_request public.friend_requests;
BEGIN
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  SELECT id INTO v_target_id FROM public.profiles
  WHERE lower(username) = lower(trim(p_username));
  IF v_target_id IS NULL THEN RAISE EXCEPTION 'Player not found'; END IF;
  IF v_target_id = v_user_id THEN RAISE EXCEPTION 'You cannot add yourself'; END IF;

  INSERT INTO public.friend_requests (requester_id, addressee_id, status)
  VALUES (v_user_id, v_target_id, 'pending')
  ON CONFLICT ((LEAST(requester_id, addressee_id)), (GREATEST(requester_id, addressee_id)))
  DO UPDATE SET status = CASE
    WHEN public.friend_requests.status = 'declined' THEN 'pending'
    ELSE public.friend_requests.status
  END, updated_at = pg_catalog.now()
  RETURNING * INTO v_request;
  RETURN v_request;
END;
$$;

CREATE OR REPLACE FUNCTION public.respond_friend_request(
  p_request_id uuid,
  p_accept boolean
)
RETURNS public.friend_requests
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_request public.friend_requests;
BEGIN
  SELECT * INTO v_request FROM public.friend_requests
  WHERE id = p_request_id AND addressee_id = auth.uid() AND status = 'pending'
  FOR UPDATE;
  IF v_request.id IS NULL THEN RAISE EXCEPTION 'Friend request not found'; END IF;
  UPDATE public.friend_requests
  SET status = CASE WHEN p_accept THEN 'accepted' ELSE 'declined' END,
      updated_at = pg_catalog.now()
  WHERE id = p_request_id
  RETURNING * INTO v_request;
  RETURN v_request;
END;
$$;

CREATE OR REPLACE FUNCTION public.remove_friend(p_friend_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  DELETE FROM public.friend_requests
  WHERE status = 'accepted'
    AND ((requester_id = auth.uid() AND addressee_id = p_friend_id)
      OR (requester_id = p_friend_id AND addressee_id = auth.uid()));
END;
$$;

ALTER TABLE public.games ADD COLUMN IF NOT EXISTS invited_player_id uuid
  REFERENCES auth.users(id) ON DELETE SET NULL;

DROP POLICY IF EXISTS "Players can view their games" ON public.games;
CREATE POLICY "Players can view their games"
ON public.games FOR SELECT TO authenticated
USING (
  auth.uid() = white_player_id
  OR auth.uid() = black_player_id
  OR auth.uid() = invited_player_id
);

DROP FUNCTION IF EXISTS public.create_friend_game(text, integer, integer);

CREATE OR REPLACE FUNCTION public.create_friend_game(
  p_time_control text DEFAULT '10+0',
  p_initial_time_seconds integer DEFAULT 600,
  p_increment_seconds integer DEFAULT 0,
  p_opponent_id uuid DEFAULT NULL
)
RETURNS public.games
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_game public.games;
BEGIN
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  IF p_time_control <> '10+0' OR p_initial_time_seconds <> 600 OR p_increment_seconds <> 0
    THEN RAISE EXCEPTION 'Unsupported time control'; END IF;
  IF p_opponent_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.friend_requests
    WHERE status = 'accepted'
      AND ((requester_id = v_user_id AND addressee_id = p_opponent_id)
        OR (requester_id = p_opponent_id AND addressee_id = v_user_id))
  ) THEN RAISE EXCEPTION 'You can only challenge an accepted friend'; END IF;

  INSERT INTO public.games (
    game_type, status, time_control, initial_time_seconds, increment_seconds,
    white_player_id, black_player_id, invited_player_id, current_fen, current_turn,
    white_time_ms, black_time_ms
  )
  VALUES (
    'online_friend', 'pending', p_time_control, p_initial_time_seconds, p_increment_seconds,
    v_user_id, NULL, p_opponent_id, 'startpos', 'white',
    p_initial_time_seconds::bigint * 1000, p_initial_time_seconds::bigint * 1000
  )
  RETURNING * INTO v_game;
  INSERT INTO public.game_players (game_id, user_id, color)
  VALUES (v_game.id, v_user_id, 'white');
  RETURN v_game;
END;
$$;

CREATE OR REPLACE FUNCTION public.join_friend_game(p_game_id uuid)
RETURNS public.games
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_game public.games;
BEGIN
  SELECT * INTO v_game FROM public.games WHERE id = p_game_id FOR UPDATE;
  IF v_game.id IS NULL OR v_game.game_type <> 'online_friend' OR v_game.status <> 'pending'
    THEN RAISE EXCEPTION 'This friend game is no longer available'; END IF;
  IF v_game.invited_player_id IS NOT NULL AND v_game.invited_player_id <> v_user_id
    THEN RAISE EXCEPTION 'This game was invited to another player'; END IF;
  IF v_game.white_player_id = v_user_id THEN RAISE EXCEPTION 'You cannot join your own game'; END IF;
  UPDATE public.games SET black_player_id = v_user_id, status = 'active',
    started_at = pg_catalog.now(), state_version = state_version + 1,
    updated_at = pg_catalog.now() WHERE id = p_game_id RETURNING * INTO v_game;
  INSERT INTO public.game_players (game_id, user_id, color)
  VALUES (p_game_id, v_user_id, 'black');
  RETURN v_game;
END;
$$;

REVOKE ALL ON FUNCTION public.send_friend_request(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.send_friend_request(text) TO authenticated;
REVOKE ALL ON FUNCTION public.respond_friend_request(uuid, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.respond_friend_request(uuid, boolean) TO authenticated;
REVOKE ALL ON FUNCTION public.remove_friend(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.remove_friend(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.create_friend_game(text, integer, integer, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_friend_game(text, integer, integer, uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.join_friend_game(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.join_friend_game(uuid) TO authenticated;
