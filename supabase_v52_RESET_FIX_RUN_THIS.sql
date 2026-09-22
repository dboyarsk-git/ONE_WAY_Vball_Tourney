-- ONE WAY v52 — RESET TOURNAMENT DATA FIX
-- Run this entire block ONCE in Supabase SQL Editor.
--
-- Fixes:
--   DELETE requires a WHERE clause
--
-- This keeps the same protected Admin reset behavior, but all destructive
-- deletes now include explicit WHERE clauses.
--
-- Reset clears:
--   - registrations + private registration records (through FK cascades)
--   - team slot names / registration links / paid / checked-in flags
--   - pool matches
--   - bracket matches
--   - active score-device locks
--
-- Reset also:
--   - reopens registration
--   - marks pools as not finalized
--   - resets pool/team counts
--
-- It intentionally DOES NOT erase editable tournament settings such as
-- prize text, payment configuration, rule text, etc.

begin;

create extension if not exists pgcrypto
with schema extensions;

create or replace function public.admin_reset_tournament_v2(
  p_code text,
  p_confirmation text
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if encode(
       digest(coalesce(p_code,''),'sha256'),
       'hex'
     )
     <>
     '18642fa8fb69ca94183ef39f93692a597872125a8b7d607afab643dfd89569a8'
  then
    raise exception 'Unauthorized';
  end if;

  if p_confirmation <> 'RESET ONE WAY' then
    raise exception 'Reset confirmation did not match';
  end if;

  perform pg_advisory_xact_lock(1462026);

  -- Clear active scorer-device locks first.
  delete from public.match_score_locks
  where match_id is not null;

  -- Clear generated tournament matches.
  delete from public.pool_matches
  where id is not null;

  delete from public.bracket_matches
  where id is not null;

  -- Disconnect all fixed team slots from registrations.
  update public.teams
  set
    name='',
    paid=false,
    checked_in=false,
    registration_id=null,
    updated_at=now()
  where id is not null;

  -- Delete registrations.
  -- Child registration tables are expected to cascade from registration_id.
  delete from public.team_registrations
  where id is not null;

  -- Return tournament to pre-pool registration state.
  update public.tournament_settings
  set
    registration_open=true,
    pools_finalized=false,
    pool_count=0,
    team_count=0,
    finalized_at=null
  where id=1;
end;
$$;

grant execute
on function public.admin_reset_tournament_v2(text,text)
to anon;

notify pgrst, 'reload schema';

commit;
