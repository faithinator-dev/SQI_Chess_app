-- Admin lesson authoring against the existing public.lessons contract.
-- Review and apply only to disposable local or approved staging Supabase.

GRANT SELECT, INSERT, UPDATE ON public.lessons TO authenticated;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'lessons'
      AND policyname = 'Admins can view all lessons'
  ) THEN
    CREATE POLICY "Admins can view all lessons"
      ON public.lessons FOR SELECT TO authenticated
      USING (EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
      ));
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'lessons'
      AND policyname = 'Admins can create lessons'
  ) THEN
    CREATE POLICY "Admins can create lessons"
      ON public.lessons FOR INSERT TO authenticated
      WITH CHECK (EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
      ));
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'lessons'
      AND policyname = 'Admins can update lessons'
  ) THEN
    CREATE POLICY "Admins can update lessons"
      ON public.lessons FOR UPDATE TO authenticated
      USING (EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
      ))
      WITH CHECK (EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role = 'admin'
      ));
  END IF;
END;
$$;
