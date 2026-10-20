-- Reviewable app release feed. Apply to disposable local or approved staging first.
-- Binary hosting and store listings remain the release team's responsibility.

CREATE TABLE IF NOT EXISTS public.app_updates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  platform text NOT NULL CHECK (
    platform IN ('android', 'ios', 'windows', 'macos', 'linux', 'web', 'all')
  ),
  version_name text NOT NULL CHECK (length(trim(version_name)) > 0),
  build_number integer NOT NULL CHECK (build_number > 0),
  title text NOT NULL CHECK (length(trim(title)) > 0),
  purpose text NOT NULL CHECK (length(trim(purpose)) > 0),
  changes jsonb NOT NULL DEFAULT '[]'::jsonb
    CHECK (jsonb_typeof(changes) = 'array'),
  instructions text NOT NULL CHECK (length(trim(instructions)) > 0),
  download_url text NOT NULL CHECK (download_url ~* '^https://'),
  is_published boolean NOT NULL DEFAULT false,
  created_by uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  published_at timestamptz,
  UNIQUE (platform, build_number)
);

CREATE INDEX IF NOT EXISTS app_updates_published_platform_build_idx
  ON public.app_updates (platform, build_number DESC)
  WHERE is_published;

CREATE OR REPLACE FUNCTION public.set_app_update_published_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.is_published THEN
      NEW.published_at := now();
    END IF;
  ELSIF NEW.is_published AND NOT OLD.is_published THEN
    NEW.published_at := now();
  ELSIF NOT NEW.is_published THEN
    NEW.published_at := NULL;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS app_updates_published_at_trigger
  ON public.app_updates;
CREATE TRIGGER app_updates_published_at_trigger
  BEFORE INSERT OR UPDATE ON public.app_updates
  FOR EACH ROW EXECUTE FUNCTION public.set_app_update_published_at();

ALTER TABLE public.app_updates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view published app updates" ON public.app_updates;
CREATE POLICY "Users can view published app updates"
  ON public.app_updates FOR SELECT TO authenticated
  USING (is_published OR public.current_user_is_admin());

DROP POLICY IF EXISTS "Admins can create app updates" ON public.app_updates;
CREATE POLICY "Admins can create app updates"
  ON public.app_updates FOR INSERT TO authenticated
  WITH CHECK (public.current_user_is_admin() AND created_by = auth.uid());

DROP POLICY IF EXISTS "Admins can update app updates" ON public.app_updates;
CREATE POLICY "Admins can update app updates"
  ON public.app_updates FOR UPDATE TO authenticated
  USING (public.current_user_is_admin())
  WITH CHECK (public.current_user_is_admin());

DROP POLICY IF EXISTS "Admins can delete app updates" ON public.app_updates;
CREATE POLICY "Admins can delete app updates"
  ON public.app_updates FOR DELETE TO authenticated
  USING (public.current_user_is_admin());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.app_updates TO authenticated;
REVOKE ALL ON public.app_updates FROM anon;
REVOKE ALL ON FUNCTION public.set_app_update_published_at() FROM PUBLIC, anon, authenticated;
