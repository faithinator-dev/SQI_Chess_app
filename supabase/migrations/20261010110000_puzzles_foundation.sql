-- Reviewable puzzle foundation. No production puzzle catalogue is inserted.

CREATE TABLE IF NOT EXISTS public.puzzles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL CHECK (length(trim(title)) BETWEEN 3 AND 120),
  category text NOT NULL CHECK (length(trim(category)) > 0),
  difficulty text NOT NULL
    CHECK (difficulty IN ('Beginner', 'Intermediate', 'Advanced', 'Expert')),
  fen text NOT NULL CHECK (length(trim(fen)) > 0),
  solution_uci text[] NOT NULL CHECK (cardinality(solution_uci) > 0),
  instruction text NOT NULL DEFAULT '',
  is_published boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS puzzles_published_idx
  ON public.puzzles(is_published, difficulty, category);

ALTER TABLE public.puzzles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view published puzzles"
ON public.puzzles FOR SELECT TO authenticated
USING (is_published = true);

-- Progress is intentionally not writable by the client yet. A trusted
-- validation operation must be added before completion can affect durable
-- player records.
