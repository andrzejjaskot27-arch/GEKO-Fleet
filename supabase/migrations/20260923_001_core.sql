-- GEKO Fleet: users, vehicles, daily vehicle selection and faults
create extension if not exists pgcrypto;

create type public.user_role as enum ('courier','coordinator','admin');
create type public.vehicle_status as enum ('active','service','inactive');
create type public.fault_status as enum ('new','in_review','resolved');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role public.user_role not null default 'courier',
  created_at timestamptz not null default now()
);

create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  registration text not null unique,
  name text not null,
  mileage integer not null default 0 check (mileage >= 0),
  status public.vehicle_status not null default 'active',
  created_at timestamptz not null default now()
);

create table public.vehicle_sessions (
  id uuid primary key default gen_random_uuid(),
  courier_id uuid not null references public.profiles(id) on delete cascade,
  vehicle_id uuid not null references public.vehicles(id) on delete restrict,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  check (ended_at is null or ended_at >= started_at)
);
create unique index one_open_vehicle_session_per_courier
  on public.vehicle_sessions(courier_id) where ended_at is null;

create table public.faults (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles(id) on delete restrict,
  reported_by uuid not null references public.profiles(id) on delete restrict,
  title text not null check (char_length(trim(title)) between 2 and 120),
  description text not null check (char_length(trim(description)) between 2 and 3000),
  status public.fault_status not null default 'new',
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles(id,full_name)
  values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''))
  on conflict(id) do nothing;
  return new;
end $$;

create trigger on_auth_user_created
after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role in ('coordinator','admin'));
$$;

alter table public.profiles enable row level security;
alter table public.vehicles enable row level security;
alter table public.vehicle_sessions enable row level security;
alter table public.faults enable row level security;

create policy "profiles self or staff read" on public.profiles for select to authenticated
using (id=auth.uid() or public.is_staff());
create policy "vehicles authenticated read" on public.vehicles for select to authenticated using (true);
create policy "vehicles staff manage" on public.vehicles for all to authenticated
using (public.is_staff()) with check (public.is_staff());

create policy "sessions own or staff read" on public.vehicle_sessions for select to authenticated
using (courier_id=auth.uid() or public.is_staff());
create policy "courier starts own session" on public.vehicle_sessions for insert to authenticated
with check (courier_id=auth.uid());
create policy "courier ends own session" on public.vehicle_sessions for update to authenticated
using (courier_id=auth.uid() or public.is_staff())
with check (courier_id=auth.uid() or public.is_staff());

create policy "faults own or staff read" on public.faults for select to authenticated
using (reported_by=auth.uid() or public.is_staff());
create policy "courier reports fault" on public.faults for insert to authenticated
with check (reported_by=auth.uid());
create policy "staff updates faults" on public.faults for update to authenticated
using (public.is_staff()) with check (public.is_staff());

create index vehicle_sessions_vehicle_idx on public.vehicle_sessions(vehicle_id,started_at desc);
create index faults_vehicle_idx on public.faults(vehicle_id,created_at desc);
create index faults_reporter_idx on public.faults(reported_by,created_at desc);

-- Example vehicles: replace these with your real fleet.
insert into public.vehicles(registration,name,mileage) values
('DW 4GEKO','Renault Master 2.3',351240),
('DW 7GEKO','Ford Transit',228500),
('DW 2GEKO','Opel Movano',194820)
on conflict(registration) do nothing;
