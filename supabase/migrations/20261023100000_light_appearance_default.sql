-- Make Light the default appearance for new and existing accounts.
ALTER TABLE public.user_settings
  ALTER COLUMN appearance SET DEFAULT 'Light';

UPDATE public.user_settings
SET appearance = 'Light'
WHERE appearance = 'Dark';
