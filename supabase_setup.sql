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
