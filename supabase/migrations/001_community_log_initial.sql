create extension if not exists "pgcrypto";

create table if not exists public.facilities (
  facility_id uuid primary key default gen_random_uuid(),
  facility_name text not null,
  shared_password_hash text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.staff (
  staff_id uuid primary key default gen_random_uuid(),
  facility_id uuid not null references public.facilities(facility_id) on delete cascade,
  staff_name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.goals (
  goal_id uuid primary key default gen_random_uuid(),
  facility_id uuid not null references public.facilities(facility_id) on delete cascade,
  title text not null,
  description text not null default '',
  category text not null default '',
  icon text not null default 'star',
  color text not null default 'green',
  is_active boolean not null default true,
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.daily_logs (
  log_id uuid primary key default gen_random_uuid(),
  facility_id uuid not null references public.facilities(facility_id) on delete cascade,
  staff_id uuid not null references public.staff(staff_id) on delete cascade,
  goal_id uuid not null references public.goals(goal_id) on delete cascade,
  score integer not null check (score between 1 and 5),
  comment text not null default '',
  log_date date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (facility_id, staff_id, goal_id, log_date)
);

create index if not exists staff_facility_id_idx on public.staff(facility_id);
create index if not exists goals_facility_id_idx on public.goals(facility_id);
create index if not exists daily_logs_facility_date_idx on public.daily_logs(facility_id, log_date);
create index if not exists daily_logs_staff_id_idx on public.daily_logs(staff_id);
create index if not exists daily_logs_goal_id_idx on public.daily_logs(goal_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists facilities_set_updated_at on public.facilities;
create trigger facilities_set_updated_at
before update on public.facilities
for each row execute function public.set_updated_at();

drop trigger if exists staff_set_updated_at on public.staff;
create trigger staff_set_updated_at
before update on public.staff
for each row execute function public.set_updated_at();

drop trigger if exists goals_set_updated_at on public.goals;
create trigger goals_set_updated_at
before update on public.goals
for each row execute function public.set_updated_at();

drop trigger if exists daily_logs_set_updated_at on public.daily_logs;
create trigger daily_logs_set_updated_at
before update on public.daily_logs
for each row execute function public.set_updated_at();

alter table public.facilities enable row level security;
alter table public.staff enable row level security;
alter table public.goals enable row level security;
alter table public.daily_logs enable row level security;
