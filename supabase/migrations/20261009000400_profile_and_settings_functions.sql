
-- SQI CHECKMATE ARENA
-- Migration 4: Profile and settings functions

-- =========================================================
-- 1. UPDATE THE SIGNED-IN PLAYER'S PROFILE
-- =========================================================

CREATE OR REPLACE FUNCTION public.update_my_profile(
  p_full_name text,
  p_username text,
  p_bio text
)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid;
  v_profile public.profiles;
  v_username text;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_full_name IS NULL OR length(trim(p_full_name)) = 0 THEN
    RAISE EXCEPTION 'Full name is required';
  END IF;

  IF p_username IS NULL THEN
    RAISE EXCEPTION 'Username is required';
  END IF;

  v_username := lower(trim(p_username));

  IF length(v_username) < 3 OR length(v_username) > 30 THEN
    RAISE EXCEPTION 'Username must be between 3 and 30 characters';
  END IF;

  IF v_username !~ '^[a-zA-Z0-9_]+$' THEN
    RAISE EXCEPTION 'Username may contain only letters, numbers, and underscores';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.profiles AS p
    WHERE lower(p.username) = v_username
      AND p.id <> v_user_id
  ) THEN
    RAISE EXCEPTION 'Username is already taken';
  END IF;

  UPDATE public.profiles
  SET
    full_name = trim(p_full_name),
    username = v_username,
    bio = p_bio,
    updated_at = pg_catalog.now()
  WHERE id = v_user_id
  RETURNING * INTO v_profile;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Player profile not found';
  END IF;

  RETURN v_profile;
END;
$$;


-- =========================================================
-- 2. UPDATE PROFILE VISIBILITY
-- =========================================================

CREATE OR REPLACE FUNCTION public.update_my_profile_visibility(
  p_public_profile boolean
)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid;
  v_profile public.profiles;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_public_profile IS NULL THEN
    RAISE EXCEPTION 'Profile visibility value is required';
  END IF;

  UPDATE public.profiles
  SET
    public_profile = p_public_profile,
    updated_at = pg_catalog.now()
  WHERE id = v_user_id
  RETURNING * INTO v_profile;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Player profile not found';
  END IF;

  RETURN v_profile;
END;
$$;


-- =========================================================
-- 3. UPDATE THE SIGNED-IN PLAYER'S SETTINGS
-- =========================================================

CREATE OR REPLACE FUNCTION public.update_my_settings(
  p_notifications boolean,
  p_email_notifications boolean,
  p_push_notifications boolean,
  p_match_invites boolean,
  p_community_mentions boolean,
  p_game_sounds boolean,
  p_vibration boolean,
  p_board_coordinates boolean,
  p_confirm_resignation boolean,
  p_public_profile boolean,
  p_reduce_motion boolean,
  p_appearance text,
  p_language text,
  p_timezone text
)
RETURNS public.user_settings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid;
  v_settings public.user_settings;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_appearance IS NULL
     OR p_appearance NOT IN ('Dark', 'Light', 'System') THEN
    RAISE EXCEPTION 'Invalid appearance setting';
  END IF;

  IF p_language IS NULL OR length(trim(p_language)) = 0 THEN
    RAISE EXCEPTION 'Language is required';
  END IF;

  IF p_timezone IS NULL OR length(trim(p_timezone)) = 0 THEN
    RAISE EXCEPTION 'Timezone is required';
  END IF;

  INSERT INTO public.user_settings (
    user_id,
    notifications,
    email_notifications,
    push_notifications,
    match_invites,
    community_mentions,
    game_sounds,
    vibration,
    board_coordinates,
    confirm_resignation,
    reduce_motion,
    appearance,
    language,
    timezone,
    updated_at
  )
  VALUES (
    v_user_id,
    p_notifications,
    p_email_notifications,
    p_push_notifications,
    p_match_invites,
    p_community_mentions,
    p_game_sounds,
    p_vibration,
    p_board_coordinates,
    p_confirm_resignation,
    p_reduce_motion,
    p_appearance,
    trim(p_language),
    trim(p_timezone),
    pg_catalog.now()
  )
  ON CONFLICT (user_id)
  DO UPDATE SET
    notifications = EXCLUDED.notifications,
    email_notifications = EXCLUDED.email_notifications,
    push_notifications = EXCLUDED.push_notifications,
    match_invites = EXCLUDED.match_invites,
    community_mentions = EXCLUDED.community_mentions,
    game_sounds = EXCLUDED.game_sounds,
    vibration = EXCLUDED.vibration,
    board_coordinates = EXCLUDED.board_coordinates,
    confirm_resignation = EXCLUDED.confirm_resignation,
    reduce_motion = EXCLUDED.reduce_motion,
    appearance = EXCLUDED.appearance,
    language = EXCLUDED.language,
    timezone = EXCLUDED.timezone,
    updated_at = pg_catalog.now()
  RETURNING * INTO v_settings;

  UPDATE public.profiles
  SET
    public_profile = p_public_profile,
    updated_at = pg_catalog.now()
  WHERE id = v_user_id;

  RETURN v_settings;
END;
$$;


-- =========================================================
-- 4. RESTRICT RPC EXECUTION TO AUTHENTICATED USERS
-- =========================================================

REVOKE ALL ON FUNCTION public.update_my_profile(text, text, text)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.update_my_profile(text, text, text)
TO authenticated;


REVOKE ALL ON FUNCTION public.update_my_profile_visibility(boolean)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.update_my_profile_visibility(boolean)
TO authenticated;


REVOKE ALL ON FUNCTION public.update_my_settings(
  boolean, boolean, boolean, boolean, boolean, boolean,
  boolean, boolean, boolean, boolean, boolean, text, text, text
)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.update_my_settings(
  boolean, boolean, boolean, boolean, boolean, boolean,
  boolean, boolean, boolean, boolean, boolean, text, text, text
)
TO authenticated;