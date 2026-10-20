
-- SQI CHECKMATE ARENA
-- Migration 6: Notifications and player presence

CREATE OR REPLACE FUNCTION public.mark_notification_read(
  p_notification_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  UPDATE public.notifications
  SET read_at = pg_catalog.now()
  WHERE id = p_notification_id
    AND user_id = v_user_id
    AND read_at IS NULL;
END;
$$;


CREATE OR REPLACE FUNCTION public.mark_all_notifications_read()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  UPDATE public.notifications
  SET read_at = pg_catalog.now()
  WHERE user_id = v_user_id
    AND read_at IS NULL;
END;
$$;


CREATE OR REPLACE FUNCTION public.set_player_presence(
  p_status text
)
RETURNS public.player_presence
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_presence public.player_presence;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_status IS NULL
     OR p_status NOT IN ('online', 'away', 'playing', 'offline') THEN
    RAISE EXCEPTION 'Invalid presence status';
  END IF;

  INSERT INTO public.player_presence (
    user_id, status, last_seen_at, updated_at
  )
  VALUES (
    v_user_id, p_status, pg_catalog.now(), pg_catalog.now()
  )
  ON CONFLICT (user_id)
  DO UPDATE SET
    status = EXCLUDED.status,
    last_seen_at = EXCLUDED.last_seen_at,
    updated_at = EXCLUDED.updated_at
  RETURNING * INTO v_presence;

  RETURN v_presence;
END;
$$;


REVOKE ALL ON FUNCTION public.mark_notification_read(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.mark_notification_read(uuid)
TO authenticated;


REVOKE ALL ON FUNCTION public.mark_all_notifications_read()
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.mark_all_notifications_read()
TO authenticated;


REVOKE ALL ON FUNCTION public.set_player_presence(text)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.set_player_presence(text)
TO authenticated;