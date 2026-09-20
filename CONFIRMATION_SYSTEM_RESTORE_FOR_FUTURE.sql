-- FUTURE TOURNAMENT ONLY — restore public player-confirmation frontend support
--
-- ONE WAY v42 intentionally hides registration_players from anonymous reads.
-- The original confirmation RPCs/tables remain in the database.
-- If you build a DIFFERENT tournament that uses the old confirmation-enabled
-- v41 frontend pattern, run this on that tournament's Supabase project.

grant select on table public.registration_players to anon;

drop policy if exists "public read registration players"
on public.registration_players;

create policy "public read registration players"
on public.registration_players
for select
to anon
using (true);

-- The original confirmation functions are intentionally unchanged:
--   public.register_team(...)
--   public.registration_confirmation_view(uuid)
--   public.confirm_registration_player(uuid,uuid)
--
-- For a new tournament, use its own database/project and review privacy needs
-- before exposing player names publicly.
