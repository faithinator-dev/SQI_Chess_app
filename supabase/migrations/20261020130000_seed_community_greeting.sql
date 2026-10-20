-- Add one official welcome post when an administrator profile already exists.
-- The guard keeps this safe to run more than once.
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
