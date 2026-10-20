-- Reviewable administrator role management for authenticated admin clients.
-- Apply only to a disposable local or explicitly approved staging database.

CREATE OR REPLACE FUNCTION public.current_user_is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles AS p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  );
$$;

REVOKE ALL ON FUNCTION public.current_user_is_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.current_user_is_admin() TO authenticated;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'profiles'
      AND policyname = 'Admins can view all profiles'
  ) THEN
    CREATE POLICY "Admins can view all profiles"
      ON public.profiles FOR SELECT TO authenticated
      USING (public.current_user_is_admin());
  END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.admin_role_audit (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  target_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  old_role text NOT NULL CHECK (old_role IN ('player', 'admin')),
  new_role text NOT NULL CHECK (new_role IN ('player', 'admin')),
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS admin_role_audit_created_idx
  ON public.admin_role_audit (created_at DESC);

ALTER TABLE public.admin_role_audit ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'admin_role_audit'
      AND policyname = 'Admins can read role audit'
  ) THEN
    CREATE POLICY "Admins can read role audit"
      ON public.admin_role_audit FOR SELECT TO authenticated
      USING (public.current_user_is_admin());
  END IF;
END;
$$;

GRANT SELECT ON public.admin_role_audit TO authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.admin_role_audit FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.set_player_admin_role(
  p_user_id uuid,
  p_make_admin boolean
)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_actor uuid := auth.uid();
  v_profile public.profiles;
  v_old_role text;
  v_admin_count bigint;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;
  IF NOT public.current_user_is_admin() THEN
    RAISE EXCEPTION 'Administrator role required' USING ERRCODE = '42501';
  END IF;
  IF p_user_id IS NULL OR p_make_admin IS NULL THEN
    RAISE EXCEPTION 'Target and desired role are required' USING ERRCODE = '22023';
  END IF;

  -- Serialize role changes so concurrent requests cannot demote the last admin.
  PERFORM pg_catalog.pg_advisory_xact_lock(741928461);

  SELECT p.role INTO v_old_role
  FROM public.profiles AS p
  WHERE p.id = p_user_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Player profile not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_old_role = 'admin' AND NOT p_make_admin THEN
    SELECT count(*) INTO v_admin_count
    FROM public.profiles AS p
    WHERE p.role = 'admin';
    IF v_admin_count <= 1 THEN
      RAISE EXCEPTION 'Cannot remove the last administrator' USING ERRCODE = '23514';
    END IF;
  END IF;

  UPDATE public.profiles AS p
  SET role = CASE WHEN p_make_admin THEN 'admin' ELSE 'player' END,
      updated_at = timezone('utc', now())
  WHERE p.id = p_user_id
  RETURNING p.* INTO v_profile;

  IF v_old_role <> v_profile.role THEN
    INSERT INTO public.admin_role_audit (actor_id, target_id, old_role, new_role)
    VALUES (v_actor, p_user_id, v_old_role, v_profile.role);
  END IF;
  RETURN v_profile;
END;
$$;

REVOKE ALL ON FUNCTION public.set_player_admin_role(uuid, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_player_admin_role(uuid, boolean) TO authenticated;
