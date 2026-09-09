-- ONE WAY Grass 4s — Supabase setup
-- Run this entire file once in Supabase SQL Editor.

create table if not exists public.teams (
  id integer primary key,
  name text not null,
  pool text not null,
  court integer not null,
  paid boolean not null default false,
  checked_in boolean not null default false,
  updated_at timestamptz not null default now()
);

create table if not exists public.pool_matches (
  id text primary key,
  round integer not null,
  time_label text not null,
  court integer not null,
  pool text not null,
  team_a integer not null references public.teams(id),
  team_b integer not null references public.teams(id),
  score_a integer not null default 0,
  score_b integer not null default 0,
  final boolean not null default false,
  locked boolean not null default false,
  updated_at timestamptz not null default now()
);

create table if not exists public.bracket_matches (
  id text primary key,
  round_name text not null,
  time_label text not null,
  court integer not null,
  key_a text,
  key_b text,
  from_a text,
  from_b text,
  sets jsonb not null default '[]'::jsonb,
  current_a integer not null default 0,
  current_b integer not null default 0,
  final boolean not null default false,
  locked boolean not null default false,
  updated_at timestamptz not null default now()
);

insert into public.teams (id,name,pool,court,paid,checked_in) values
(1, 'Team 1', 'A', 1, false, false),
(2, 'Team 2', 'A', 1, false, false),
(3, 'Team 3', 'A', 1, false, false),
(4, 'Team 4', 'A', 1, false, false),
(5, 'Team 5', 'B', 2, false, false),
(6, 'Team 6', 'B', 2, false, false),
(7, 'Team 7', 'B', 2, false, false),
(8, 'Team 8', 'B', 2, false, false),
(9, 'Team 9', 'C', 3, false, false),
(10, 'Team 10', 'C', 3, false, false),
(11, 'Team 11', 'C', 3, false, false),
(12, 'Team 12', 'C', 3, false, false),
(13, 'Team 13', 'D', 4, false, false),
(14, 'Team 14', 'D', 4, false, false),
(15, 'Team 15', 'D', 4, false, false),
(16, 'Team 16', 'D', 4, false, false)
on conflict (id) do nothing;

insert into public.pool_matches
(id,round,time_label,court,pool,team_a,team_b,score_a,score_b,final,locked) values
('P1', 1, '9:00 AM', 1, 'A', 1, 2, 0, 0, false, false),
('P2', 1, '9:00 AM', 2, 'B', 5, 6, 0, 0, false, false),
('P3', 1, '9:00 AM', 3, 'C', 9, 10, 0, 0, false, false),
('P4', 1, '9:00 AM', 4, 'D', 13, 14, 0, 0, false, false),
('P5', 2, '9:30 AM', 1, 'A', 3, 4, 0, 0, false, false),
('P6', 2, '9:30 AM', 2, 'B', 7, 8, 0, 0, false, false),
('P7', 2, '9:30 AM', 3, 'C', 11, 12, 0, 0, false, false),
('P8', 2, '9:30 AM', 4, 'D', 15, 16, 0, 0, false, false),
('P9', 3, '10:00 AM', 1, 'A', 1, 3, 0, 0, false, false),
('P10', 3, '10:00 AM', 2, 'B', 5, 7, 0, 0, false, false),
('P11', 3, '10:00 AM', 3, 'C', 9, 11, 0, 0, false, false),
('P12', 3, '10:00 AM', 4, 'D', 13, 15, 0, 0, false, false),
('P13', 4, '10:30 AM', 1, 'A', 2, 4, 0, 0, false, false),
('P14', 4, '10:30 AM', 2, 'B', 6, 8, 0, 0, false, false),
('P15', 4, '10:30 AM', 3, 'C', 10, 12, 0, 0, false, false),
('P16', 4, '10:30 AM', 4, 'D', 14, 16, 0, 0, false, false),
('P17', 5, '11:00 AM', 1, 'A', 1, 4, 0, 0, false, false),
('P18', 5, '11:00 AM', 2, 'B', 5, 8, 0, 0, false, false),
('P19', 5, '11:00 AM', 3, 'C', 9, 12, 0, 0, false, false),
('P20', 5, '11:00 AM', 4, 'D', 13, 16, 0, 0, false, false),
('P21', 6, '11:30 AM', 1, 'A', 2, 3, 0, 0, false, false),
('P22', 6, '11:30 AM', 2, 'B', 6, 7, 0, 0, false, false),
('P23', 6, '11:30 AM', 3, 'C', 10, 11, 0, 0, false, false),
('P24', 6, '11:30 AM', 4, 'D', 14, 15, 0, 0, false, false)
on conflict (id) do nothing;

insert into public.bracket_matches
(id,round_name,time_label,court,key_a,key_b,from_a,from_b,sets,current_a,current_b,final,locked) values
('QF1','Quarterfinal','12:30 PM',1,'A-1','B-2',null,null,'[]'::jsonb,0,0,false,false),
('QF2','Quarterfinal','12:30 PM',2,'B-1','A-2',null,null,'[]'::jsonb,0,0,false,false),
('QF3','Quarterfinal','12:30 PM',3,'C-1','D-2',null,null,'[]'::jsonb,0,0,false,false),
('QF4','Quarterfinal','12:30 PM',4,'D-1','C-2',null,null,'[]'::jsonb,0,0,false,false),
('SF1','Semifinal','1:30 PM',1,null,null,'QF1','QF3','[]'::jsonb,0,0,false,false),
('SF2','Semifinal','1:30 PM',2,null,null,'QF2','QF4','[]'::jsonb,0,0,false,false),
('FINAL','Championship','2:30 PM',1,null,null,'SF1','SF2','[]'::jsonb,0,0,false,false)
on conflict (id) do nothing;

alter table public.teams enable row level security;
alter table public.pool_matches enable row level security;
alter table public.bracket_matches enable row level security;

drop policy if exists "public read teams" on public.teams;
drop policy if exists "public update teams" on public.teams;
drop policy if exists "public read pool" on public.pool_matches;
drop policy if exists "public update pool" on public.pool_matches;
drop policy if exists "public read bracket" on public.bracket_matches;
drop policy if exists "public update bracket" on public.bracket_matches;

create policy "public read teams" on public.teams for select to anon using (true);
create policy "public update teams" on public.teams for update to anon using (true) with check (true);

create policy "public read pool" on public.pool_matches for select to anon using (true);
create policy "public update pool" on public.pool_matches for update to anon using (true) with check (true);

create policy "public read bracket" on public.bracket_matches for select to anon using (true);
create policy "public update bracket" on public.bracket_matches for update to anon using (true) with check (true);

-- Enable realtime for the three tournament tables.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='teams'
  ) then
    alter publication supabase_realtime add table public.teams;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='pool_matches'
  ) then
    alter publication supabase_realtime add table public.pool_matches;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='bracket_matches'
  ) then
    alter publication supabase_realtime add table public.bracket_matches;
  end if;
end $$;


-- ONE WAY Grass 4s — Registration + Admin Security Upgrade
-- Run this entire file ONCE in Supabase SQL Editor.

create extension if not exists pgcrypto;

alter table public.teams add column if not exists registration_id uuid;

create table if not exists public.team_registrations (
  id uuid primary key default gen_random_uuid(),
  team_name text not null,
  status text not null default 'pending'
    check (status in ('pending','registered','waitlisted','cancelled')),
  reserved_slot integer check (reserved_slot between 1 and 16),
  created_at timestamptz not null default now(),
  confirmed_at timestamptz
);

create table if not exists public.registration_players (
  id uuid primary key default gen_random_uuid(),
  registration_id uuid not null references public.team_registrations(id) on delete cascade,
  player_number integer not null check (player_number between 1 and 4),
  full_name text not null,
  confirmed boolean not null default false,
  confirmed_at timestamptz,
  unique(registration_id, player_number)
);

create table if not exists public.registration_contacts (
  registration_id uuid primary key references public.team_registrations(id) on delete cascade,
  captain_name text not null,
  captain_phone text not null,
  captain_email text not null
);

create table if not exists public.registration_secrets (
  registration_id uuid primary key references public.team_registrations(id) on delete cascade,
  confirmation_token uuid not null default gen_random_uuid() unique
);

create unique index if not exists one_active_registration_per_slot
on public.team_registrations(reserved_slot)
where reserved_slot is not null and status in ('pending','registered');

alter table public.team_registrations enable row level security;
alter table public.registration_players enable row level security;
alter table public.registration_contacts enable row level security;
alter table public.registration_secrets enable row level security;

drop policy if exists "public read registrations" on public.team_registrations;
drop policy if exists "public read registration players" on public.registration_players;
create policy "public read registrations" on public.team_registrations
for select to anon using (true);
create policy "public read registration players" on public.registration_players
for select to anon using (true);

-- Remove anonymous direct team edits. Admin changes go through the protected RPC below.
drop policy if exists "public update teams" on public.teams;

create or replace function public.admin_update_team(
  p_code text,
  p_id integer,
  p_name text,
  p_paid boolean,
  p_checked_in boolean
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if encode(digest(coalesce(p_code,''), 'sha256'), 'hex') <> '4af3d72d78b405924dc814caebbc90403482aa90f3523047888f51645674e406' then
    raise exception 'Unauthorized';
  end if;

  update public.teams
  set name=coalesce(nullif(trim(p_name),''),name),
      paid=p_paid,
      checked_in=p_checked_in,
      updated_at=now()
  where id=p_id;
end;
$$;

create or replace function public.register_team(
  p_team_name text,
  p_captain_name text,
  p_captain_phone text,
  p_captain_email text,
  p_players text[]
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_token uuid;
  v_slot integer;
  v_status text;
  v_count integer;
  i integer;
begin
  perform pg_advisory_xact_lock(1462026);

  if trim(coalesce(p_team_name,''))='' then raise exception 'Team name is required'; end if;
  if trim(coalesce(p_captain_name,''))='' then raise exception 'Captain name is required'; end if;
  if trim(coalesce(p_captain_phone,''))='' then raise exception 'Captain phone is required'; end if;
  if trim(coalesce(p_captain_email,''))='' then raise exception 'Captain email is required'; end if;
  if array_length(p_players,1)<>4 then raise exception 'Exactly 4 players are required'; end if;

  for i in 1..4 loop
    if trim(coalesce(p_players[i],''))='' then raise exception 'All 4 player names are required'; end if;
  end loop;

  if exists (
    select 1 from public.team_registrations
    where lower(trim(team_name))=lower(trim(p_team_name))
      and status<>'cancelled'
  ) then raise exception 'That team name is already registered'; end if;

  select count(*) into v_count
  from public.team_registrations
  where status in ('pending','registered') and reserved_slot is not null;

  if v_count<16 then
    select s into v_slot
    from generate_series(1,16) s
    where not exists (
      select 1 from public.team_registrations r
      where r.reserved_slot=s and r.status in ('pending','registered')
    )
    order by s limit 1;
    v_status:='pending';
  else
    v_slot:=null;
    v_status:='waitlisted';
  end if;

  insert into public.team_registrations(team_name,status,reserved_slot)
  values(trim(p_team_name),v_status,v_slot)
  returning id into v_id;

  insert into public.registration_contacts(registration_id,captain_name,captain_phone,captain_email)
  values(v_id,trim(p_captain_name),trim(p_captain_phone),trim(p_captain_email));

  insert into public.registration_secrets(registration_id)
  values(v_id) returning confirmation_token into v_token;

  for i in 1..4 loop
    insert into public.registration_players(registration_id,player_number,full_name)
    values(v_id,i,trim(p_players[i]));
  end loop;

  return jsonb_build_object(
    'registration_id',v_id,
    'confirmation_token',v_token,
    'status',v_status,
    'reserved_slot',v_slot
  );
end;
$$;

create or replace function public.registration_confirmation_view(
  p_token uuid
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_registration_id uuid;
  v_result jsonb;
begin
  select registration_id into v_registration_id
  from public.registration_secrets
  where confirmation_token=p_token;

  if v_registration_id is null then raise exception 'Invalid confirmation link'; end if;

  select jsonb_build_object(
    'id',r.id,
    'team_name',r.team_name,
    'status',r.status,
    'players',(
      select jsonb_agg(
        jsonb_build_object(
          'id',p.id,
          'player_number',p.player_number,
          'full_name',p.full_name,
          'confirmed',p.confirmed
        ) order by p.player_number
      )
      from public.registration_players p
      where p.registration_id=r.id
    )
  )
  into v_result
  from public.team_registrations r
  where r.id=v_registration_id;

  return v_result;
end;
$$;

create or replace function public.confirm_registration_player(
  p_token uuid,
  p_player_id uuid
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_registration_id uuid;
  v_confirmed integer;
  v_status text;
  v_slot integer;
  v_team_name text;
begin
  select registration_id into v_registration_id
  from public.registration_secrets
  where confirmation_token=p_token;

  if v_registration_id is null then raise exception 'Invalid confirmation link'; end if;

  update public.registration_players
  set confirmed=true,confirmed_at=coalesce(confirmed_at,now())
  where id=p_player_id and registration_id=v_registration_id;

  if not found then raise exception 'Player not found for this team'; end if;

  select count(*) into v_confirmed
  from public.registration_players
  where registration_id=v_registration_id and confirmed=true;

  select status,reserved_slot,team_name
  into v_status,v_slot,v_team_name
  from public.team_registrations
  where id=v_registration_id
  for update;

  if v_confirmed=4 and v_status='pending' then
    update public.team_registrations
    set status='registered',confirmed_at=now()
    where id=v_registration_id;

    update public.teams
    set name=v_team_name,
        registration_id=v_registration_id,
        updated_at=now()
    where id=v_slot;

    v_status:='registered';
  end if;

  return jsonb_build_object('confirmed_count',v_confirmed,'status',v_status);
end;
$$;

create or replace function public.admin_registration_contacts(
  p_code text
) returns table(
  registration_id uuid,
  team_name text,
  status text,
  captain_name text,
  captain_phone text,
  captain_email text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if encode(digest(coalesce(p_code,''), 'sha256'), 'hex') <> '4af3d72d78b405924dc814caebbc90403482aa90f3523047888f51645674e406' then
    raise exception 'Unauthorized';
  end if;

  return query
  select r.id,r.team_name,r.status,c.captain_name,c.captain_phone,c.captain_email
  from public.team_registrations r
  join public.registration_contacts c on c.registration_id=r.id
  order by r.created_at;
end;
$$;

grant execute on function public.admin_update_team(text,integer,text,boolean,boolean) to anon;
grant execute on function public.register_team(text,text,text,text,text[]) to anon;
grant execute on function public.registration_confirmation_view(uuid) to anon;
grant execute on function public.confirm_registration_player(uuid,uuid) to anon;
grant execute on function public.admin_registration_contacts(text) to anon;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='team_registrations'
  ) then alter publication supabase_realtime add table public.team_registrations; end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='registration_players'
  ) then alter publication supabase_realtime add table public.registration_players; end if;
end $$;
