-- ONE WAY v53 — TOURNAMENT HARDENING
-- Run this entire block ONCE in Supabase SQL Editor.
-- Non-destructive: does NOT delete registrations, teams, pools, schedules, brackets, or scores.

begin;
create extension if not exists pgcrypto with schema extensions;

-- Admin correction hardening: clear stale locks and bump revisions.
create or replace function public.admin_unlock_match(
  p_code text,
  p_match_type text,
  p_match_id text
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_sets jsonb;
  v_len integer;
  v_last jsonb;
begin
  if encode(digest(coalesce(p_code,''),'sha256'),'hex')
     <> '18642fa8fb69ca94183ef39f93692a597872125a8b7d607afab643dfd89569a8'
  then raise exception 'Unauthorized'; end if;

  perform pg_advisory_xact_lock(1462026);

  if p_match_type='pool' then
    if not exists(select 1 from public.pool_matches where id=p_match_id) then
      raise exception 'Pool match not found';
    end if;

    delete from public.match_score_locks where match_id is not null;

    update public.pool_matches
    set final=false,
        locked=false,
        score_revision=score_revision+1,
        score_last_operation_id=null,
        updated_at=now()
    where id=p_match_id;

    update public.bracket_matches
    set sets='[]'::jsonb,
        current_a=0,
        current_b=0,
        final=false,
        locked=false,
        score_revision=score_revision+1,
        score_last_operation_id=null,
        updated_at=now()
    where id is not null;

  elsif p_match_type='bracket' then
    select coalesce(sets,'[]'::jsonb)
    into v_sets
    from public.bracket_matches
    where id=p_match_id
    for update;
    if not found then raise exception 'Bracket match not found'; end if;

    delete from public.match_score_locks
    where match_type='bracket' and match_id=p_match_id;

    v_len:=jsonb_array_length(v_sets);
    if v_len>0 then
      v_last:=v_sets->(v_len-1);
      update public.bracket_matches
      set sets=case when v_len=1 then '[]'::jsonb else v_sets-(v_len-1) end,
          current_a=coalesce((v_last->>'a')::integer,0),
          current_b=coalesce((v_last->>'b')::integer,0),
          final=false,
          locked=false,
          score_revision=score_revision+1,
          score_last_operation_id=null,
          updated_at=now()
      where id=p_match_id;
    else
      update public.bracket_matches
      set final=false,
          locked=false,
          score_revision=score_revision+1,
          score_last_operation_id=null,
          updated_at=now()
      where id=p_match_id;
    end if;

    if p_match_id in ('QF1','QF2') then
      delete from public.match_score_locks
      where match_type='bracket' and match_id in ('SF1','FINAL');
      update public.bracket_matches
      set sets='[]'::jsonb,current_a=0,current_b=0,final=false,locked=false,
          score_revision=score_revision+1,score_last_operation_id=null,updated_at=now()
      where id in ('SF1','FINAL');
    elsif p_match_id in ('QF3','QF4') then
      delete from public.match_score_locks
      where match_type='bracket' and match_id in ('SF2','FINAL');
      update public.bracket_matches
      set sets='[]'::jsonb,current_a=0,current_b=0,final=false,locked=false,
          score_revision=score_revision+1,score_last_operation_id=null,updated_at=now()
      where id in ('SF2','FINAL');
    elsif p_match_id in ('SF1','SF2') then
      delete from public.match_score_locks
      where match_type='bracket' and match_id='FINAL';
      update public.bracket_matches
      set sets='[]'::jsonb,current_a=0,current_b=0,final=false,locked=false,
          score_revision=score_revision+1,score_last_operation_id=null,updated_at=now()
      where id='FINAL';
    elsif p_match_id='FINAL' then
      null;
    else
      raise exception 'Invalid bracket match ID';
    end if;
  else
    raise exception 'Invalid match type';
  end if;
end;
$$;
grant execute on function public.admin_unlock_match(text,text,text) to anon;

-- Reopening registration explicitly clears every scorer lock.
create or replace function public.admin_reopen_registration(p_code text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if encode(digest(coalesce(p_code,''),'sha256'),'hex')
     <> '18642fa8fb69ca94183ef39f93692a597872125a8b7d607afab643dfd89569a8'
  then raise exception 'Unauthorized'; end if;
  perform pg_advisory_xact_lock(1462026);
  delete from public.match_score_locks where match_id is not null;
  update public.tournament_settings
  set registration_open=true,pools_finalized=false,finalized_at=null
  where id=1;
end;
$$;
grant execute on function public.admin_reopen_registration(text) to anon;

-- Stronger scoring health check: presence + permissions + required schema.
create or replace function public.score_backend_status()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare v_ready boolean;
begin
  v_ready :=
    to_regclass('public.match_score_locks') is not null
    and exists(select 1 from information_schema.columns where table_schema='public' and table_name='pool_matches' and column_name='score_revision')
    and exists(select 1 from information_schema.columns where table_schema='public' and table_name='bracket_matches' and column_name='score_revision')
    and to_regprocedure('public.score_acquire_match_lock(text,text,text)') is not null
    and to_regprocedure('public.score_match_heartbeat(text,text,text)') is not null
    and to_regprocedure('public.score_release_match_lock(text,text,text)') is not null
    and to_regprocedure('public.score_save_match_state(text,text,text,text,integer,jsonb)') is not null
    and to_regprocedure('public.score_confirm_set_state(text,text,text,text)') is not null
    and has_function_privilege('anon',to_regprocedure('public.score_acquire_match_lock(text,text,text)'),'EXECUTE')
    and has_function_privilege('anon',to_regprocedure('public.score_match_heartbeat(text,text,text)'),'EXECUTE')
    and has_function_privilege('anon',to_regprocedure('public.score_release_match_lock(text,text,text)'),'EXECUTE')
    and has_function_privilege('anon',to_regprocedure('public.score_save_match_state(text,text,text,text,integer,jsonb)'),'EXECUTE')
    and has_function_privilege('anon',to_regprocedure('public.score_confirm_set_state(text,text,text,text)'),'EXECUTE');
  return jsonb_build_object('ready',v_ready,'backend_version','v53');
end;
$$;
grant execute on function public.score_backend_status() to anon, authenticated;

notify pgrst, 'reload schema';
commit;
