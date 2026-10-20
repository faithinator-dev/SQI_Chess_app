-- Admin-managed community pages. Review and apply only on disposable local
-- or explicitly approved staging Supabase; this migration is not auto-applied.

CREATE TABLE IF NOT EXISTS public.community_pages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL CHECK (length(trim(title)) BETWEEN 2 AND 80),
  description text NOT NULL DEFAULT '' CHECK (length(description) <= 500),
  created_by uuid REFERENCES auth.users(id) ON DELETE RESTRICT,
  is_published boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS community_pages_published_created_idx
  ON public.community_pages(is_published, created_at DESC);


ALTER TABLE public.community_pages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read published community pages"
ON public.community_pages FOR SELECT TO authenticated
USING (
  is_published
  OR EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  )
);

CREATE POLICY "Admins can create community pages"
ON public.community_pages FOR INSERT TO authenticated
WITH CHECK (
  created_by = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  )
);

CREATE POLICY "Admins can update community pages"
ON public.community_pages FOR UPDATE TO authenticated
USING (EXISTS (
  SELECT 1 FROM public.profiles p
  WHERE p.id = auth.uid() AND p.role = 'admin'
))
WITH CHECK (EXISTS (
  SELECT 1 FROM public.profiles p
  WHERE p.id = auth.uid() AND p.role = 'admin'
));

ALTER TABLE public.community_posts
  ADD COLUMN IF NOT EXISTS page_id uuid
  REFERENCES public.community_pages(id) ON DELETE SET NULL;

-- Existing deployments created this column as required; allow system-owned
-- starter pages to have no human creator.
ALTER TABLE public.community_pages
  ALTER COLUMN created_by DROP NOT NULL;

CREATE INDEX IF NOT EXISTS community_posts_page_created_idx
  ON public.community_posts(page_id, created_at DESC);

INSERT INTO public.community_pages (title, description, created_by)
SELECT defaults.title, defaults.description, NULL
FROM (VALUES
  ('General', 'Introductions, chess chat, and club conversation.', NULL::uuid),
  ('Announcements', 'Official SQI Checkmate updates and club notices.', NULL::uuid),
  ('Study & Tactics', 'Share puzzles, positions, and ideas for improving.', NULL::uuid)
) AS defaults(title, description, created_by)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.community_pages existing
  WHERE lower(existing.title) = lower(defaults.title)
);

GRANT SELECT, INSERT, UPDATE ON public.community_pages TO authenticated;

-- Announcements are visible to everyone but may only be posted by admins.
DROP POLICY IF EXISTS "Users can create their own posts" ON public.community_posts;
CREATE POLICY "Authenticated users can create community posts"
ON public.community_posts FOR INSERT TO authenticated
WITH CHECK (
  auth.uid() IS NOT NULL
  AND user_id = auth.uid()
  AND (
    page_id IS NULL
    OR lower((SELECT cp.title FROM public.community_pages cp WHERE cp.id = page_id)) <> 'announcements'
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
  )
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'community_pages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.community_pages;
  END IF;
END;
$$;
