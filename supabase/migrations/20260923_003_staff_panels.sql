alter table public.vehicles
add column if not exists vin text,
add column if not exists production_year integer,
add column if not exists fuel_type text,
add column if not exists inspection_due date,
add column if not exists insurance_due date;

drop policy if exists "staff read all profiles" on public.profiles;
drop policy if exists "admin update profiles" on public.profiles;
drop policy if exists "staff insert vehicles" on public.vehicles;
drop policy if exists "staff update vehicles" on public.vehicles;
drop policy if exists "staff read sessions" on public.vehicle_sessions;
drop policy if exists "staff read faults" on public.faults;
drop policy if exists "staff update faults" on public.faults;
drop policy if exists "staff read checks" on public.vehicle_checks;

create policy "staff read all profiles" on public.profiles for select to authenticated using (id = auth.uid() or public.is_staff());
create policy "admin update profiles" on public.profiles for update to authenticated using ((select role from public.profiles where id=auth.uid())='admin') with check ((select role from public.profiles where id=auth.uid())='admin');
create policy "staff insert vehicles" on public.vehicles for insert to authenticated with check (public.is_staff());
create policy "staff update vehicles" on public.vehicles for update to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff read sessions" on public.vehicle_sessions for select to authenticated using (courier_id=auth.uid() or public.is_staff());
create policy "staff read faults" on public.faults for select to authenticated using (reported_by=auth.uid() or public.is_staff());
create policy "staff update faults" on public.faults for update to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff read checks" on public.vehicle_checks for select to authenticated using (courier_id=auth.uid() or public.is_staff());