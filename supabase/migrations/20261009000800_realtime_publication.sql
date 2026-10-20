
-- SQI CHECKMATE ARENA
-- Migration 8: Realtime publication membership

DO $$
DECLARE
  v_table text;
BEGIN
  FOREACH v_table IN ARRAY ARRAY[
    'community_comments',
    'community_post_likes',
    'community_posts',
    'game_moves',
    'games',
    'matchmaking_queue',
    'notifications',
    'player_presence'
  ]
  LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM pg_catalog.pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = v_table
    ) THEN
      EXECUTE pg_catalog.format(
        'ALTER PUBLICATION supabase_realtime ADD TABLE public.%I',
        v_table
      );
    END IF;
  END LOOP;
END;
$$;