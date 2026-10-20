-- Client-facing access controls for the profile/settings/history surfaces.
-- This migration is intentionally conditional so it can be applied alongside
-- an existing project schema without creating demo tables or records.

do $$
begin
  if to_regclass('public.profiles') is not null then
    alter table public.profiles enable row level security;
    if not exists (
      select 1 from pg_policies
      where schemaname = 'public' and tablename = 'profiles'
        and policyname = 'profiles_read_own_or_public'
    ) then
      create policy profiles_read_own_or_public
        on public.profiles for select
        using (id = auth.uid() or coalesce(public_profile, false));
    end if;
  end if;

  if to_regclass('public.user_settings') is not null then
    alter table public.user_settings enable row level security;
    if not exists (
      select 1 from pg_policies
      where schemaname = 'public' and tablename = 'user_settings'
        and policyname = 'user_settings_owner_access'
    ) then
      create policy user_settings_owner_access
        on public.user_settings for all
        using (user_id = auth.uid())
        with check (user_id = auth.uid());
    end if;
  end if;

  if to_regclass('public.games') is not null then
    alter table public.games enable row level security;
    if not exists (
      select 1 from pg_policies
      where schemaname = 'public' and tablename = 'games'
        and policyname = 'games_participant_read'
    ) then
      create policy games_participant_read
        on public.games for select
        using (white_player_id = auth.uid() or black_player_id = auth.uid());
    end if;
  end if;

  if to_regclass('public.game_moves') is not null then
    alter table public.game_moves enable row level security;
    if not exists (
      select 1 from pg_policies
      where schemaname = 'public' and tablename = 'game_moves'
        and policyname = 'game_moves_participant_read'
    ) then
      create policy game_moves_participant_read
        on public.game_moves for select
        using (
          exists (
            select 1 from public.games
            where games.id = game_moves.game_id
              and (games.white_player_id = auth.uid()
                or games.black_player_id = auth.uid())
          )
        );
    end if;
  end if;
end
$$;
