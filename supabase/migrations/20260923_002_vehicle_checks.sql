-- GEKO Fleet: kontrola pojazdu przed wyjazdem
create table if not exists public.vehicle_checks (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  courier_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid references public.vehicle_sessions(id) on delete set null,
  engine_oil_ok boolean not null,
  coolant_ok boolean not null,
  washer_fluid_ok boolean not null,
  tires_ok boolean not null,
  lights_ok boolean not null,
  body_ok boolean not null,
  dashboard_ok boolean not null,
  note text,
  created_at timestamptz not null default now()
);

alter table public.vehicle_checks enable row level security;

drop policy if exists "courier insert own checks" on public.vehicle_checks;
create policy "courier insert own checks"
on public.vehicle_checks for insert to authenticated
with check (courier_id = auth.uid());

drop policy if exists "courier read own checks" on public.vehicle_checks;
create policy "courier read own checks"
on public.vehicle_checks for select to authenticated
using (courier_id = auth.uid() or public.is_staff());

create index if not exists vehicle_checks_vehicle_idx on public.vehicle_checks(vehicle_id);
create index if not exists vehicle_checks_courier_idx on public.vehicle_checks(courier_id);
create index if not exists vehicle_checks_created_idx on public.vehicle_checks(created_at desc);
