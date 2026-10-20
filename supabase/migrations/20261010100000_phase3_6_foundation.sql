-- Phase 3-6 foundation: competitions and public spectator access.
-- Review and apply only in a disposable local or approved staging database.

ALTER TABLE public.games
  ADD COLUMN IF NOT EXISTS visibility text NOT NULL DEFAULT 'private'
  CHECK (visibility IN ('private', 'unlisted', 'public'));

CREATE TABLE IF NOT EXISTS public.competitions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  title text NOT NULL CHECK (length(trim(title)) BETWEEN 3 AND 120),
  description text NOT NULL DEFAULT '' CHECK (length(description) <= 5000),
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN (
      'draft', 'published', 'registration_open', 'registration_closed',
      'in_progress', 'completed', 'cancelled'
    )),
  format text NOT NULL CHECK (format IN ('round_robin', 'single_elimination')),
  time_control text NOT NULL CHECK (length(trim(time_control)) > 0),
  rated boolean NOT NULL DEFAULT false,
  capacity integer CHECK (capacity IS NULL OR capacity BETWEEN 2 AND 10000),
  registration_deadline timestamptz,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  CHECK (ends_at IS NULL OR starts_at IS NULL OR ends_at >= starts_at),
  CHECK (
    registration_deadline IS NULL
    OR starts_at IS NULL
    OR registration_deadline <= starts_at
  )
);

CREATE TABLE IF NOT EXISTS public.competition_registrations (
  competition_id uuid NOT NULL REFERENCES public.competitions(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'registered'
    CHECK (status IN ('registered', 'withdrawn', 'eliminated', 'completed')),
  registered_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  PRIMARY KEY (competition_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.competition_rounds (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  competition_id uuid NOT NULL REFERENCES public.competitions(id) ON DELETE CASCADE,
  round_number integer NOT NULL CHECK (round_number > 0),
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'open', 'completed')),
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  UNIQUE (competition_id, round_number)
);

CREATE TABLE IF NOT EXISTS public.competition_pairings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  round_id uuid NOT NULL REFERENCES public.competition_rounds(id) ON DELETE CASCADE,
  white_player_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  black_player_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  game_id uuid UNIQUE REFERENCES public.games(id) ON DELETE SET NULL,
  result text CHECK (result IS NULL OR result IN ('white', 'black', 'draw', 'bye')),
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  CHECK (
    white_player_id IS NULL
    OR black_player_id IS NULL
    OR white_player_id <> black_player_id
  ),
  CHECK (white_player_id IS NOT NULL OR black_player_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS competitions_status_starts_at_idx
  ON public.competitions(status, starts_at);
CREATE INDEX IF NOT EXISTS competition_registrations_user_idx
  ON public.competition_registrations(user_id, registered_at DESC);
CREATE INDEX IF NOT EXISTS competition_pairings_players_idx
  ON public.competition_pairings(white_player_id, black_player_id);

ALTER TABLE public.competitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.competition_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.competition_rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.competition_pairings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view published competitions"
ON public.competitions FOR SELECT TO authenticated
USING (status <> 'draft' OR organizer_id = auth.uid());

CREATE POLICY "Users can view competition registrations"
ON public.competition_registrations FOR SELECT TO authenticated
USING (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.competitions c
    WHERE c.id = competition_id AND c.status <> 'draft'
  )
);

CREATE POLICY "Users can view published competition rounds"
ON public.competition_rounds FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.competitions c
    WHERE c.id = competition_id AND c.status <> 'draft'
  )
);

CREATE POLICY "Users can view published competition pairings"
ON public.competition_pairings FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.competition_rounds r
    JOIN public.competitions c ON c.id = r.competition_id
    WHERE r.id = round_id AND c.status <> 'draft'
  )
);

CREATE OR REPLACE FUNCTION public.register_for_competition(p_competition_id uuid)
RETURNS public.competition_registrations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  competition_row public.competitions;
  registration_row public.competition_registrations;
BEGIN
  SELECT * INTO competition_row
  FROM public.competitions
  WHERE id = p_competition_id
  FOR UPDATE;

  IF competition_row.id IS NULL
     OR competition_row.status <> 'registration_open'
     OR (
       competition_row.registration_deadline IS NOT NULL
       AND competition_row.registration_deadline <= timezone('utc', now())
     ) THEN
    RAISE EXCEPTION 'Competition is not open for registration';
  END IF;

  IF competition_row.capacity IS NOT NULL
     AND (
       SELECT count(*)
       FROM public.competition_registrations
       WHERE competition_id = p_competition_id
         AND status = 'registered'
     ) >= competition_row.capacity THEN
    RAISE EXCEPTION 'Competition is full';
  END IF;

  INSERT INTO public.competition_registrations (competition_id, user_id)
  VALUES (p_competition_id, auth.uid())
  ON CONFLICT (competition_id, user_id)
  DO UPDATE SET status = 'registered', registered_at = timezone('utc', now())
  RETURNING * INTO registration_row;

  RETURN registration_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.withdraw_from_competition(p_competition_id uuid)
RETURNS public.competition_registrations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  registration_row public.competition_registrations;
BEGIN
  UPDATE public.competition_registrations
  SET status = 'withdrawn'
  WHERE competition_id = p_competition_id
    AND user_id = auth.uid()
    AND status = 'registered'
  RETURNING * INTO registration_row;

  IF registration_row.competition_id IS NULL THEN
    RAISE EXCEPTION 'Active registration not found';
  END IF;

  RETURN registration_row;
END;
$$;

REVOKE ALL ON FUNCTION public.register_for_competition(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.withdraw_from_competition(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.register_for_competition(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.withdraw_from_competition(uuid) TO authenticated;

CREATE POLICY "Authenticated users can view public games"
ON public.games FOR SELECT TO authenticated
USING (
  visibility = 'public'
  AND status IN ('active', 'completed')
);

CREATE POLICY "Authenticated users can view moves from public games"
ON public.game_moves FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.games g
    WHERE g.id = game_moves.game_id
      AND g.visibility = 'public'
      AND g.status IN ('active', 'completed')
  )
);
