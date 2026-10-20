-- Add one official welcome post when an administrator profile already exists.
-- The guard keeps this safe to run more than once.
CREATE TABLE IF NOT EXISTS public.community_pages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL DEFAULT '',
  created_by uuid REFERENCES auth.users(id) ON DELETE RESTRICT,
  is_published boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

ALTER TABLE public.community_pages
  ALTER COLUMN created_by DROP NOT NULL;

ALTER TABLE public.community_posts
  ADD COLUMN IF NOT EXISTS page_id uuid
  REFERENCES public.community_pages(id) ON DELETE SET NULL;

INSERT INTO public.community_pages (title, description, created_by)
SELECT 'General', 'Introductions, chess chat, and club conversation.', NULL
WHERE NOT EXISTS (
  SELECT 1
  FROM public.community_pages
  WHERE lower(title) = 'general'
);

INSERT INTO public.community_posts (user_id, content, page_id)
SELECT
  admin_profile.id,
  'Welcome to the SQI Chess Club community! This is the place to share chess ideas, celebrate progress, and stay updated with club activities. We are glad to have you here.',
  general_page.id
FROM (
  SELECT id
  FROM public.profiles
  WHERE role = 'admin'
  ORDER BY created_at
  LIMIT 1
) AS admin_profile
LEFT JOIN public.community_pages AS general_page
  ON lower(general_page.title) = 'general'
WHERE NOT EXISTS (
  SELECT 1
  FROM public.community_posts
  WHERE content = 'Welcome to the SQI Chess Club community! This is the place to share chess ideas, celebrate progress, and stay updated with club activities. We are glad to have you here.'
);
