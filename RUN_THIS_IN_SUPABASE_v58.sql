-- ONE WAY v58 — MIN 6 TEAMS + POOL 15 + 25/25/15 BRACKET + SEMIS/FINAL
-- Run this once before deploying v56.
--
-- This resets MATCH SCORES because the scoring format changed.
-- It preserves registrations, teams, pool assignments, check-in/payment,
-- captain info, prize settings and editable rule settings.

begin;

delete from public.match_score_locks
where match_id is not null;

update public.pool_matches
set score_a=0,score_b=0,final=false,locked=false,
    score_revision=score_revision+1,
    score_last_operation_id=null,
    updated_at=now()
where id is not null;

delete from public.bracket_matches
where id is not null;

create or replace function public.admin_finalize_pools(
  p_code text,
  p_assignments jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_team_count integer;
  v_pool_count integer;
  v_payment_enabled boolean;

  v_size_a integer:=0;
  v_size_b integer:=0;
  v_size_c integer:=0;
  v_size_d integer:=0;

  v_pool_idx integer;
  v_pool text;
  v_ids integer[];
  v_round integer;
  v_team_a integer;
  v_team_b integer;

  v_times text[]:=array[
    'Sat Oct 3 • 1:00 PM',
    'Sat Oct 3 • 1:40 PM',
    'Sat Oct 3 • 2:20 PM',
    'Sat Oct 3 • 3:00 PM',
    'Sat Oct 3 • 3:40 PM',
    'Sat Oct 3 • 4:20 PM'
  ];
begin
  if encode(digest(coalesce(p_code,''),'sha256'),'hex')
     <> '18642fa8fb69ca94183ef39f93692a597872125a8b7d607afab643dfd89569a8'
  then
    raise exception 'Unauthorized';
  end if;

  perform pg_advisory_xact_lock(1462026);

  select coalesce(payment_enabled,true) into v_payment_enabled from public.tournament_settings where id=1;

  select count(*)
  into v_team_count
  from public.team_registrations
  where status='registered'
    and (not v_payment_enabled or coalesce(paid,false)=true)
    and coalesce(checked_in,false)=true;

  if v_team_count<6 then
    if v_payment_enabled then
      raise exception 'At least 6 registered, paid, and checked-in teams are required';
    else
      raise exception 'At least 6 registered and checked-in teams are required';
    end if;
  end if;

  if v_team_count>16 then
    raise exception 'Maximum tournament size is 16 teams';
  end if;

  if v_team_count=6 then
    v_pool_count:=2;
    v_size_a:=3;
    v_size_b:=3;

  elsif v_team_count=7 then
    v_pool_count:=2;
    v_size_a:=4;
    v_size_b:=3;

  elsif v_team_count=8 then
    v_pool_count:=2;
    v_size_a:=4;
    v_size_b:=4;

  elsif v_team_count=9 then
    v_pool_count:=3;
    v_size_a:=3;
    v_size_b:=3;
    v_size_c:=3;

  elsif v_team_count=10 then
    v_pool_count:=3;
    v_size_a:=4;
    v_size_b:=3;
    v_size_c:=3;

  elsif v_team_count=11 then
    v_pool_count:=3;
    v_size_a:=4;
    v_size_b:=4;
    v_size_c:=3;

  elsif v_team_count=12 then
    v_pool_count:=4;
    v_size_a:=3;
    v_size_b:=3;
    v_size_c:=3;
    v_size_d:=3;

  elsif v_team_count=13 then
    v_pool_count:=4;
    v_size_a:=4;
    v_size_b:=3;
    v_size_c:=3;
    v_size_d:=3;

  elsif v_team_count=14 then
    v_pool_count:=4;
    v_size_a:=4;
    v_size_b:=4;
    v_size_c:=3;
    v_size_d:=3;

  elsif v_team_count=15 then
    v_pool_count:=4;
    v_size_a:=4;
    v_size_b:=4;
    v_size_c:=4;
    v_size_d:=3;

  else
    v_pool_count:=4;
    v_size_a:=4;
    v_size_b:=4;
    v_size_c:=4;
    v_size_d:=4;
  end if;

  drop table if exists tmp_pool_assignments;

  create temporary table tmp_pool_assignments(
    registration_id uuid,
    pool text,
    seed_order integer
  )
  on commit drop;

  insert into tmp_pool_assignments(
    registration_id,
    pool,
    seed_order
  )
  select
    registration_id,
    pool,
    seed_order
  from jsonb_to_recordset(p_assignments)
    as x(
      registration_id uuid,
      pool text,
      seed_order integer
    );

  if (
    select count(*)
    from tmp_pool_assignments
  ) <> v_team_count
  then
    raise exception
      'Assignments must include every pool-eligible team exactly once';
  end if;

  if (
    select count(distinct registration_id)
    from tmp_pool_assignments
  ) <> v_team_count
  then
    raise exception 'Duplicate team assignment detected';
  end if;

  if exists(
    select 1
    from tmp_pool_assignments a
    left join public.team_registrations r
      on r.id=a.registration_id
    where r.id is null
       or r.status<>'registered'
       or (v_payment_enabled and coalesce(r.paid,false)=false)
       or coalesce(r.checked_in,false)=false
  )
  then
    if v_payment_enabled then
      raise exception 'Only registered, paid, and checked-in teams may be assigned';
    else
      raise exception 'Only registered and checked-in teams may be assigned';
    end if;
  end if;

  if exists(
    select 1
    from tmp_pool_assignments
    where pool not in ('A','B','C','D')
       or (v_pool_count=2 and pool not in ('A','B'))
       or (v_pool_count=3 and pool not in ('A','B','C'))
  )
  then
    raise exception 'Invalid pool assignment';
  end if;

  if (
    select count(*) from tmp_pool_assignments where pool='A'
  ) <> v_size_a

  or (
    select count(*) from tmp_pool_assignments where pool='B'
  ) <> v_size_b

  or (
    select count(*) from tmp_pool_assignments where pool='C'
  ) <> v_size_c

  or (
    select count(*) from tmp_pool_assignments where pool='D'
  ) <> v_size_d
  then
    raise exception
      'Pool sizes do not match the required tournament format';
  end if;

  -- Close incomplete teams out of the locked field.
  -- Their registration history and player confirmations remain intact.
  update public.team_registrations
  set
    status='waitlisted',
    reserved_slot=null
  where status='pending';

  -- Final transactional safety check: every previewed team must STILL
  -- be fully registered, paid, and checked in at the moment pools are locked.
  if exists(
    select 1
    from tmp_pool_assignments a
    join public.team_registrations r
      on r.id=a.registration_id
    where r.status<>'registered'
       or (v_payment_enabled and coalesce(r.paid,false)=false)
       or coalesce(r.checked_in,false)=false
  )
  then
    raise exception
      'Pool eligibility changed. Refresh the pool preview before finalizing.';
  end if;

  update public.teams
  set
    name='',
    paid=false,
    checked_in=false,
    registration_id=null,
    updated_at=now()
  where id is not null;

  drop table if exists tmp_slotmap;

  create temporary table tmp_slotmap
  on commit drop
  as
  select
    row_number() over(
      order by
        case a.pool
          when 'A' then 1
          when 'B' then 2
          when 'C' then 3
          else 4
        end,
        -- Neutral randomized registration UUID order.
        -- This avoids allowing skill level / preview order to act
        -- as an invisible standings tiebreak.
        md5(a.registration_id::text)
    )::integer as slot_id,

    a.registration_id,
    a.pool

  from tmp_pool_assignments a;

  update public.teams t
  set
    name=r.team_name,
    pool=s.pool,

    court=
      case s.pool
        when 'A' then 1
        when 'B' then 2
        when 'C' then 3
        else 4
      end,

    registration_id=s.registration_id,
    paid=coalesce(r.paid,false),
    checked_in=coalesce(r.checked_in,false),
    updated_at=now()

  from tmp_slotmap s

  join public.team_registrations r
    on r.id=s.registration_id

  where t.id=s.slot_id;

  -- Delete every old pool/bracket row. Realtime clients in v16
  -- now process DELETE events correctly.
  delete from public.pool_matches
  where id is not null;

  for v_pool_idx in 1..v_pool_count loop
    v_pool:=chr(64+v_pool_idx);

    select array_agg(id order by id)
    into v_ids
    from public.teams
    where registration_id is not null
      and pool=v_pool;

    for v_round in 1..6 loop
      if array_length(v_ids,1)=4 then
        case v_round
          when 1 then
            v_team_a:=v_ids[1]; v_team_b:=v_ids[2];
          when 2 then
            v_team_a:=v_ids[3]; v_team_b:=v_ids[4];
          when 3 then
            v_team_a:=v_ids[1]; v_team_b:=v_ids[3];
          when 4 then
            v_team_a:=v_ids[2]; v_team_b:=v_ids[4];
          when 5 then
            v_team_a:=v_ids[1]; v_team_b:=v_ids[4];
          when 6 then
            v_team_a:=v_ids[2]; v_team_b:=v_ids[3];
        end case;

      elsif array_length(v_ids,1)=3 then
        case v_round
          when 1 then
            v_team_a:=v_ids[1]; v_team_b:=v_ids[2];
          when 2 then
            v_team_a:=v_ids[2]; v_team_b:=v_ids[3];
          when 3 then
            v_team_a:=v_ids[1]; v_team_b:=v_ids[3];
          when 4 then
            v_team_a:=v_ids[2]; v_team_b:=v_ids[1];
          when 5 then
            v_team_a:=v_ids[3]; v_team_b:=v_ids[2];
          when 6 then
            v_team_a:=v_ids[3]; v_team_b:=v_ids[1];
        end case;

      else
        raise exception 'Pool % has an invalid team count',v_pool;
      end if;

      insert into public.pool_matches(
        id,
        round,
        time_label,
        court,
        pool,
        team_a,
        team_b,
        score_a,
        score_b,
        final,
        locked
      )
      values(
        'P'||v_pool||v_round,
        v_round,
        v_times[v_round],
        v_pool_idx,
        v_pool,
        v_team_a,
        v_team_b,
        0,
        0,
        false,
        false
      );
    end loop;
  end loop;

  delete from public.bracket_matches
  where id is not null;

  insert into public.bracket_matches(
    id,round_name,time_label,court,key_a,key_b,from_a,from_b,
    sets,current_a,current_b,final,locked
  )
  values
    ('SF1','Semifinal','Sun Oct 4 • 3:15 PM',1,'S-1','S-4',null,null,'[]'::jsonb,0,0,false,false),
    ('SF2','Semifinal','Sun Oct 4 • 3:15 PM',2,'S-2','S-3',null,null,'[]'::jsonb,0,0,false,false),
    ('FINAL','Championship','Sun Oct 4 • 4:15 PM',1,null,null,'SF1','SF2','[]'::jsonb,0,0,false,false);

  update public.tournament_settings
  set
    registration_open=false,
    pools_finalized=true,
    pool_count=v_pool_count,
    team_count=v_team_count,
    finalized_at=now()
  where id=1;

  return jsonb_build_object(
    'team_count',v_team_count,
    'pool_count',v_pool_count
  );
end;
$$;

grant execute on function public.admin_finalize_pools(text,jsonb) to anon;

create or replace function public.score_save_match_state(
  p_match_type text,
  p_match_id text,
  p_lock_token text,
  p_operation_id text,
  p_expected_revision integer,
  p_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_hash text;
  v_revision integer;
  v_last_op text;
  v_existing_locked boolean;

  v_score_a integer;
  v_score_b integer;
  v_final boolean;
  v_locked boolean;

  v_sets jsonb;
  v_current_a integer;
  v_current_b integer;
  v_a_wins integer:=0;
  v_b_wins integer:=0;
  v_set jsonb;
begin
  if p_match_type not in ('pool','bracket') then
    raise exception 'Invalid match type';
  end if;

  if nullif(btrim(coalesce(p_operation_id,'')),'') is null then
    raise exception 'Operation ID is required';
  end if;

  if p_expected_revision is null
     or p_expected_revision < 0
  then
    raise exception 'Invalid score revision';
  end if;

  if not coalesce(
    (
      select pools_finalized
      from public.tournament_settings
      where id=1
    ),
    false
  ) then
    raise exception 'TOURNAMENT_FROZEN';
  end if;

  v_hash:=encode(
    digest(coalesce(p_lock_token,''),'sha256'),
    'hex'
  );

  if not exists(
    select 1
    from public.match_score_locks
    where match_type=p_match_type
      and match_id=p_match_id
      and lock_hash=v_hash
      and expires_at>=now()
  ) then
    raise exception 'MATCH_LOCK_REQUIRED';
  end if;

  if p_match_type='pool' then

    select
      score_revision,
      score_last_operation_id,
      locked
    into
      v_revision,
      v_last_op,
      v_existing_locked
    from public.pool_matches
    where id=p_match_id
    for update;

    if not found then
      raise exception 'Match not found';
    end if;

    if v_last_op=p_operation_id then
      return jsonb_build_object(
        'ok',true,
        'score_revision',v_revision,
        'duplicate_retry',true
      );
    end if;

    if v_existing_locked then
      raise exception 'MATCH_ALREADY_LOCKED';
    end if;

    if v_revision<>p_expected_revision then
      raise exception 'SCORE_REVISION_CONFLICT';
    end if;

    v_score_a:=coalesce(
      (p_payload->>'score_a')::integer,
      0
    );

    v_score_b:=coalesce(
      (p_payload->>'score_b')::integer,
      0
    );

    v_final:=coalesce(
      (p_payload->>'final')::boolean,
      false
    );

    v_locked:=coalesce(
      (p_payload->>'locked')::boolean,
      false
    );

    if v_score_a<0
       or v_score_a>15
       or v_score_b<0
       or v_score_b>15
    then
      raise exception 'Invalid pool score';
    end if;

    if v_final then

      if not v_locked then
        raise exception 'Final pool match must be locked';
      end if;

      if not (
        (v_score_a=15 and v_score_b<=14)
        or
        (v_score_b=15 and v_score_a<=14)
      ) then
        raise exception 'Invalid final pool score';
      end if;

    end if;

    update public.pool_matches
    set
      score_a=v_score_a,
      score_b=v_score_b,
      final=v_final,
      locked=v_locked,
      score_revision=score_revision+1,
      score_last_operation_id=p_operation_id,
      updated_at=now()
    where id=p_match_id
    returning score_revision
    into v_revision;

  else

    select
      score_revision,
      score_last_operation_id,
      locked
    into
      v_revision,
      v_last_op,
      v_existing_locked
    from public.bracket_matches
    where id=p_match_id
    for update;

    if not found then
      raise exception 'Match not found';
    end if;

    if v_last_op=p_operation_id then
      return jsonb_build_object(
        'ok',true,
        'score_revision',v_revision,
        'duplicate_retry',true
      );
    end if;

    if v_existing_locked then
      raise exception 'MATCH_ALREADY_LOCKED';
    end if;

    if v_revision<>p_expected_revision then
      raise exception 'SCORE_REVISION_CONFLICT';
    end if;

    v_sets:=coalesce(
      p_payload->'sets',
      '[]'::jsonb
    );

    v_current_a:=coalesce(
      (p_payload->>'current_a')::integer,
      0
    );

    v_current_b:=coalesce(
      (p_payload->>'current_b')::integer,
      0
    );

    v_final:=coalesce(
      (p_payload->>'final')::boolean,
      false
    );

    v_locked:=coalesce(
      (p_payload->>'locked')::boolean,
      false
    );

    if jsonb_typeof(v_sets)<>'array'
       or jsonb_array_length(v_sets)>3
    then
      raise exception 'Invalid bracket sets';
    end if;

    if v_current_a<0
       or v_current_b<0
       or v_current_a>99
       or v_current_b>99
    then
      raise exception 'Invalid bracket score';
    end if;

    for v_set in
      select value
      from jsonb_array_elements(v_sets)
    loop

      if coalesce(
           (v_set->>'a')::integer,
           0
         )
         >
         coalesce(
           (v_set->>'b')::integer,
           0
         )
      then
        v_a_wins:=v_a_wins+1;
      else
        v_b_wins:=v_b_wins+1;
      end if;

    end loop;

    if v_final then

      if not v_locked then
        raise exception 'Final bracket match must be locked';
      end if;

      if greatest(v_a_wins,v_b_wins)<2 then
        raise exception
          'Bracket match cannot be final before two set wins';
      end if;

    end if;

    update public.bracket_matches
    set
      sets=v_sets,
      current_a=v_current_a,
      current_b=v_current_b,
      final=v_final,
      locked=v_locked,
      score_revision=score_revision+1,
      score_last_operation_id=p_operation_id,
      updated_at=now()
    where id=p_match_id
    returning score_revision
    into v_revision;

  end if;

  -- Successful write renews the phone's lock.
  update public.match_score_locks
  set
    expires_at=now()+interval '90 seconds',
    updated_at=now()
  where match_type=p_match_type
    and match_id=p_match_id
    and lock_hash=v_hash;

  return jsonb_build_object(
    'ok',true,
    'score_revision',v_revision,
    'duplicate_retry',false
  );
end;
$$;

grant execute on function public.score_save_match_state(text,text,text,text,integer,jsonb)
to anon,authenticated;

create or replace function public.score_confirm_set_state(
  p_match_type text,
  p_match_id text,
  p_lock_token text,
  p_operation_id text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_hash text;

  v_revision integer;
  v_last_op text;
  v_locked boolean;
  v_final boolean;

  v_score_a integer;
  v_score_b integer;

  v_sets jsonb;
  v_current_a integer;
  v_current_b integer;
  v_set_number integer;
  v_target integer;
  v_a_wins integer:=0;
  v_b_wins integer:=0;
  v_set jsonb;
begin
  if p_match_type not in ('pool','bracket') then
    raise exception 'Invalid match type';
  end if;

  if nullif(btrim(coalesce(p_match_id,'')),'') is null then
    raise exception 'Match ID is required';
  end if;

  if nullif(btrim(coalesce(p_operation_id,'')),'') is null then
    raise exception 'Operation ID is required';
  end if;

  if char_length(coalesce(p_lock_token,'')) < 12 then
    raise exception 'Invalid lock token';
  end if;

  if not coalesce(
    (
      select pools_finalized
      from public.tournament_settings
      where id=1
    ),
    false
  ) then
    raise exception 'TOURNAMENT_FROZEN';
  end if;

  v_hash:=encode(
    digest(p_lock_token,'sha256'),
    'hex'
  );

  if not exists(
    select 1
    from public.match_score_locks
    where match_type=p_match_type
      and match_id=p_match_id
      and lock_hash=v_hash
      and expires_at>=now()
  ) then
    raise exception 'MATCH_LOCK_REQUIRED';
  end if;

  -- ==========================================================
  -- POOL PLAY: finalize the CURRENT saved server score.
  -- ==========================================================
  if p_match_type='pool' then

    select
      score_revision,
      score_last_operation_id,
      locked,
      final,
      score_a,
      score_b
    into
      v_revision,
      v_last_op,
      v_locked,
      v_final,
      v_score_a,
      v_score_b
    from public.pool_matches
    where id=p_match_id
    for update;

    if not found then
      raise exception 'Match not found';
    end if;

    -- Idempotent retry.
    if v_last_op=p_operation_id then
      return jsonb_build_object(
        'ok',true,
        'duplicate_retry',true,
        'score_revision',v_revision,
        'score_a',v_score_a,
        'score_b',v_score_b,
        'final',v_final,
        'locked',v_locked
      );
    end if;

    -- Already final is safe to return.
    if v_final and v_locked then
      return jsonb_build_object(
        'ok',true,
        'already_final',true,
        'score_revision',v_revision,
        'score_a',v_score_a,
        'score_b',v_score_b,
        'final',true,
        'locked',true
      );
    end if;

    -- Pool play is first to 15 with a hard cap.
    if not (
      (v_score_a=15 and v_score_b between 0 and 14)
      or
      (v_score_b=15 and v_score_a between 0 and 14)
    ) then
      raise exception 'SCORE_NOT_READY';
    end if;

    update public.pool_matches
    set
      final=true,
      locked=true,
      score_revision=score_revision+1,
      score_last_operation_id=p_operation_id,
      updated_at=now()
    where id=p_match_id
    returning
      score_revision,
      score_a,
      score_b,
      final,
      locked
    into
      v_revision,
      v_score_a,
      v_score_b,
      v_final,
      v_locked;

    return jsonb_build_object(
      'ok',true,
      'duplicate_retry',false,
      'score_revision',v_revision,
      'score_a',v_score_a,
      'score_b',v_score_b,
      'final',v_final,
      'locked',v_locked
    );

  end if;

  -- ==========================================================
  -- BRACKET: confirm the CURRENT saved set atomically.
  -- ==========================================================
  select
    score_revision,
    score_last_operation_id,
    locked,
    final,
    coalesce(sets,'[]'::jsonb),
    coalesce(current_a,0),
    coalesce(current_b,0)
  into
    v_revision,
    v_last_op,
    v_locked,
    v_final,
    v_sets,
    v_current_a,
    v_current_b
  from public.bracket_matches
  where id=p_match_id
  for update;

  if not found then
    raise exception 'Match not found';
  end if;

  -- Idempotent retry.
  if v_last_op=p_operation_id then
    return jsonb_build_object(
      'ok',true,
      'duplicate_retry',true,
      'score_revision',v_revision,
      'sets',v_sets,
      'current_a',v_current_a,
      'current_b',v_current_b,
      'final',v_final,
      'locked',v_locked
    );
  end if;

  if v_final and v_locked then
    return jsonb_build_object(
      'ok',true,
      'already_final',true,
      'score_revision',v_revision,
      'sets',v_sets,
      'current_a',v_current_a,
      'current_b',v_current_b,
      'final',true,
      'locked',true
    );
  end if;

  v_set_number:=jsonb_array_length(v_sets)+1;

  if v_set_number>3 then
    raise exception 'Too many bracket sets';
  end if;

  v_target:=
    case
      when v_set_number=3 then 15
      else 25
    end;

  if not (
    (v_current_a>=v_target or v_current_b>=v_target)
    and abs(v_current_a-v_current_b)>=2
  ) then
    raise exception 'SCORE_NOT_READY';
  end if;

  v_sets:=
    v_sets ||
    jsonb_build_array(
      jsonb_build_object(
        'a',v_current_a,
        'b',v_current_b
      )
    );

  for v_set in
    select value
    from jsonb_array_elements(v_sets)
  loop
    if coalesce((v_set->>'a')::integer,0)
       >
       coalesce((v_set->>'b')::integer,0)
    then
      v_a_wins:=v_a_wins+1;
    else
      v_b_wins:=v_b_wins+1;
    end if;
  end loop;

  v_final:=(v_a_wins>=2 or v_b_wins>=2);
  v_locked:=v_final;

  update public.bracket_matches
  set
    sets=v_sets,
    current_a=0,
    current_b=0,
    final=v_final,
    locked=v_locked,
    score_revision=score_revision+1,
    score_last_operation_id=p_operation_id,
    updated_at=now()
  where id=p_match_id
  returning
    score_revision,
    sets,
    current_a,
    current_b,
    final,
    locked
  into
    v_revision,
    v_sets,
    v_current_a,
    v_current_b,
    v_final,
    v_locked;

  -- If the match is not over yet, renew the same iPad's scoring lock.
  if not v_final then
    update public.match_score_locks
    set
      expires_at=now()+interval '90 seconds',
      updated_at=now()
    where match_type=p_match_type
      and match_id=p_match_id
      and lock_hash=v_hash;
  end if;

  return jsonb_build_object(
    'ok',true,
    'duplicate_retry',false,
    'score_revision',v_revision,
    'sets',v_sets,
    'current_a',v_current_a,
    'current_b',v_current_b,
    'final',v_final,
    'locked',v_locked
  );
end;
$$;

grant execute on function public.score_confirm_set_state(text,text,text,text)
to anon,authenticated;

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

    if p_match_id in ('SF1','SF2') then
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

create or replace function public.oneway_backend_status()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'ready',
      to_regprocedure('public.register_team_oneway(text,text,text,text,text,text[])') is not null
      and to_regprocedure('public.admin_finalize_pools(text,jsonb)') is not null
      and to_regprocedure('public.score_acquire_match_lock(text,text,text)') is not null
      and to_regprocedure('public.score_save_match_state(text,text,text,text,integer,jsonb)') is not null
      and to_regprocedure('public.admin_reset_tournament_v55(text,text)') is not null,
    'backend_version','v58'
  );
$$;

grant execute on function public.oneway_backend_status() to anon,authenticated;

do $$
declare
  v_finalized boolean;
begin
  select coalesce(pools_finalized,false)
  into v_finalized
  from public.tournament_settings
  where id=1;

  if v_finalized then
    insert into public.bracket_matches(
      id,round_name,time_label,court,key_a,key_b,from_a,from_b,
      sets,current_a,current_b,final,locked
    )
    values
      ('SF1','Semifinal','Sun Oct 4 • 3:15 PM',1,'S-1','S-4',null,null,'[]'::jsonb,0,0,false,false),
      ('SF2','Semifinal','Sun Oct 4 • 3:15 PM',2,'S-2','S-3',null,null,'[]'::jsonb,0,0,false,false),
      ('FINAL','Championship','Sun Oct 4 • 4:15 PM',1,null,null,'SF1','SF2','[]'::jsonb,0,0,false,false);
  end if;
end;
$$;

notify pgrst,'reload schema';

commit;

select 'ONE WAY v58 FORMAT INSTALLED — SUCCESS' as status,
       'Min 6 teams | Pool 15 | Bracket 25/25/15 | 2 SF + Final' as format;
