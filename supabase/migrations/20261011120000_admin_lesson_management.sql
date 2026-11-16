-- Admin lesson authoring against the existing public.lessons contract.
-- Review and apply only to disposable local or approved staging Supabase.

GRANT SELECT, INSERT, UPDATE ON public.lessons TO authenticated;

-- Use the non-recursive SECURITY DEFINER role check from the role management
-- migration so lesson policies cannot recurse through profiles RLS.
DO $$
BEGIN
  IF to_regprocedure('public.current_user_is_admin()') IS NULL THEN
    RAISE EXCEPTION 'Apply 20261011110000_admin_role_management.sql first';
  END IF;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'lessons'
      AND policyname = 'Admins can view all lessons'
  ) THEN
    CREATE POLICY "Admins can view all lessons"
      ON public.lessons FOR SELECT TO authenticated
      USING (public.current_user_is_admin());
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'lessons'
      AND policyname = 'Admins can create lessons'
  ) THEN
    CREATE POLICY "Admins can create lessons"
      ON public.lessons FOR INSERT TO authenticated
      WITH CHECK (public.current_user_is_admin());
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'lessons'
      AND policyname = 'Admins can update lessons'
  ) THEN
    CREATE POLICY "Admins can update lessons"
      ON public.lessons FOR UPDATE TO authenticated
      USING (public.current_user_is_admin())
      WITH CHECK (public.current_user_is_admin());
  END IF;
END;
$$;
