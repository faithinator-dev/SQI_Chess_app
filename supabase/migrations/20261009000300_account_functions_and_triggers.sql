
-- SQI CHECKMATE ARENA
-- Migration 3: Account functions and timestamp triggers
-- Intended for a fresh Supabase database.

-- =========================================================
-- 1. AUTOMATIC UPDATED_AT HANDLER
-- =========================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at := timezone('utc', now());
  RETURN NEW;
END;
$$;


-- =========================================================
-- 2. CREATE A PROFILE WHEN A USER SIGNS UP
-- =========================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_username text;
  v_full_name text;
BEGIN
  v_username := COALESCE(
    NULLIF(
      lower(
        regexp_replace(
          COALESCE(NEW.raw_user_meta_data ->> 'username', ''),
          '[^a-zA-Z0-9_]',
          '',
          'g'
        )
      ),
      ''
    ),
    'player_' || substr(replace(NEW.id::text, '-', ''), 1, 8)
  );

  v_full_name := COALESCE(
    NULLIF(trim(NEW.raw_user_meta_data ->> 'full_name'), ''),
    'SQI Player'
  );

  INSERT INTO public.profiles (
    id,
    username,
    full_name,
    phone,
    skill_level,
    preferred_time_control,
    play_style,
    bio,
    sqi_status,
    department,
    level,
    campus,
    role
  )
  VALUES (
    NEW.id,
    v_username,
    v_full_name,
    NEW.phone,
    'Beginner',
    'Rapid',
    'Both',
    NEW.raw_user_meta_data ->> 'bio',
    COALESCE(
      NULLIF(NEW.raw_user_meta_data ->> 'sqi_status', ''),
      'Student'
    ),
    NEW.raw_user_meta_data ->> 'department',
    NEW.raw_user_meta_data ->> 'level',
    NEW.raw_user_meta_data ->> 'campus',
    'player'
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;


-- =========================================================
-- 3. CREATE DEFAULT SETTINGS WHEN A USER SIGNS UP
-- =========================================================

CREATE OR REPLACE FUNCTION public.handle_new_user_settings()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;


-- =========================================================
-- 4. ATTACH AUTH SIGNUP TRIGGERS
-- =========================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();


DROP TRIGGER IF EXISTS on_auth_user_created_settings ON auth.users;

CREATE TRIGGER on_auth_user_created_settings
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user_settings();


-- =========================================================
-- 5. UPDATED_AT TRIGGERS
-- Create one trigger per table, avoiding the duplicate
-- games trigger found in the existing database.
-- =========================================================

DROP TRIGGER IF EXISTS games_set_updated_at ON public.games;
DROP TRIGGER IF EXISTS games_updated_at ON public.games;

CREATE TRIGGER games_updated_at
BEFORE UPDATE ON public.games
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();


DROP TRIGGER IF EXISTS matchmaking_queue_updated_at
ON public.matchmaking_queue;

CREATE TRIGGER matchmaking_queue_updated_at
BEFORE UPDATE ON public.matchmaking_queue
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();


DROP TRIGGER IF EXISTS player_presence_updated_at
ON public.player_presence;

CREATE TRIGGER player_presence_updated_at
BEFORE UPDATE ON public.player_presence
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();


-- =========================================================
-- 6. FUNCTION EXECUTION PERMISSIONS
-- Trigger functions are intended to be invoked by triggers,
-- not called directly by client applications.
-- =========================================================

REVOKE ALL ON FUNCTION public.set_updated_at()
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.handle_new_user()
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.handle_new_user_settings()
FROM PUBLIC, anon, authenticated;