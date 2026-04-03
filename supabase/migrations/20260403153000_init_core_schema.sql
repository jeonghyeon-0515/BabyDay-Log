-- BabyDay-Log initial core schema
-- Assumption: Supabase project with auth schema available

begin;

create extension if not exists pgcrypto;

-- =========================================================
-- ENUMS
-- =========================================================

do $$
begin
  if not exists (select 1 from pg_type where typname = 'membership_role') then
    create type public.membership_role as enum ('owner', 'admin', 'editor', 'viewer');
  end if;

  if not exists (select 1 from pg_type where typname = 'membership_status') then
    create type public.membership_status as enum ('invited', 'active', 'disabled', 'left');
  end if;

  if not exists (select 1 from pg_type where typname = 'invite_status') then
    create type public.invite_status as enum ('active', 'expired', 'revoked', 'consumed');
  end if;

  if not exists (select 1 from pg_type where typname = 'baby_sex') then
    create type public.baby_sex as enum ('male', 'female', 'other', 'unknown');
  end if;

  if not exists (select 1 from pg_type where typname = 'event_status') then
    create type public.event_status as enum ('draft', 'running', 'completed', 'cancelled');
  end if;

  if not exists (select 1 from pg_type where typname = 'event_source') then
    create type public.event_source as enum ('app', 'widget', 'watch', 'shortcut', 'import', 'system');
  end if;

  if not exists (select 1 from pg_type where typname = 'diary_visibility') then
    create type public.diary_visibility as enum ('private', 'household', 'public_pending', 'public');
  end if;

  if not exists (select 1 from pg_type where typname = 'community_post_status') then
    create type public.community_post_status as enum ('visible', 'hidden', 'flagged', 'removed');
  end if;

  if not exists (select 1 from pg_type where typname = 'reminder_rule_type') then
    create type public.reminder_rule_type as enum ('feeding', 'sleep', 'diaper', 'medication');
  end if;
end
$$;

-- =========================================================
-- COMMON FUNCTIONS
-- =========================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, locale, timezone, created_at, updated_at)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1), 'new-user'),
    coalesce(new.raw_user_meta_data ->> 'locale', 'ko'),
    coalesce(new.raw_user_meta_data ->> 'timezone', 'Asia/Seoul'),
    timezone('utc', now()),
    timezone('utc', now())
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create or replace function public.is_household_member(target_household_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.household_memberships hm
    where hm.household_id = target_household_id
      and hm.user_id = auth.uid()
      and hm.status = 'active'
  );
$$;

create or replace function public.has_household_role(
  target_household_id uuid,
  allowed_roles public.membership_role[]
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.household_memberships hm
    where hm.household_id = target_household_id
      and hm.user_id = auth.uid()
      and hm.status = 'active'
      and hm.role = any (allowed_roles)
  );
$$;

create or replace function public.handle_household_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.household_memberships (
    id,
    household_id,
    user_id,
    role,
    status,
    invited_by_user_id,
    joined_at,
    created_at,
    updated_at
  )
  values (
    gen_random_uuid(),
    new.id,
    new.created_by_user_id,
    'owner',
    'active',
    new.created_by_user_id,
    timezone('utc', now()),
    timezone('utc', now()),
    timezone('utc', now())
  )
  on conflict (household_id, user_id) do nothing;

  return new;
end;
$$;

-- =========================================================
-- TABLES
-- =========================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  avatar_path text,
  locale text not null default 'ko',
  timezone text not null default 'Asia/Seoul',
  onboarding_completed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  locale text not null default 'ko',
  timezone text not null default 'Asia/Seoul',
  growth_chart_standard text not null default 'kr_2017',
  created_by_user_id uuid not null references public.profiles(id) on delete restrict,
  archived_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.household_memberships (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.membership_role not null default 'viewer',
  status public.membership_status not null default 'invited',
  invited_by_user_id uuid references public.profiles(id) on delete set null,
  joined_at timestamptz,
  last_active_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (household_id, user_id)
);

create table if not exists public.caregiver_invites (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  invited_role public.membership_role not null default 'viewer',
  code_hash text not null unique,
  expires_at timestamptz not null,
  max_uses integer not null default 1 check (max_uses > 0),
  accepted_count integer not null default 0 check (accepted_count >= 0),
  status public.invite_status not null default 'active',
  invited_by_user_id uuid not null references public.profiles(id) on delete restrict,
  accepted_by_user_id uuid references public.profiles(id) on delete set null,
  accepted_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.babies (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null,
  birth_at timestamptz,
  birth_date date not null,
  sex public.baby_sex default 'unknown',
  due_date date,
  is_preterm boolean not null default false,
  avatar_path text,
  note text,
  archived_at timestamptz,
  created_by_user_id uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.event_types (
  slug text primary key,
  category text not null,
  display_name text not null,
  is_timer_supported boolean not null default false,
  is_quantity_supported boolean not null default false,
  is_enabled boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.activity_events (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  baby_id uuid not null references public.babies(id) on delete cascade,
  actor_user_id uuid not null references public.profiles(id) on delete restrict,
  event_type_slug text not null references public.event_types(slug) on delete restrict,
  status public.event_status not null default 'completed',
  source public.event_source not null default 'app',
  started_at timestamptz,
  ended_at timestamptz,
  recorded_at timestamptz not null,
  note text,
  metadata jsonb not null default '{}'::jsonb,
  client_uid uuid,
  deleted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint activity_events_time_check check (ended_at is null or started_at is null or ended_at >= started_at),
  constraint activity_events_running_check check ((status <> 'running') or ended_at is null)
);

create unique index if not exists idx_activity_events_client_uid_unique
  on public.activity_events (client_uid)
  where client_uid is not null;
create index if not exists idx_activity_events_baby_recorded_at
  on public.activity_events (baby_id, recorded_at desc);
create index if not exists idx_activity_events_household_created_at
  on public.activity_events (household_id, created_at desc);
create index if not exists idx_activity_events_type_recorded_at
  on public.activity_events (event_type_slug, recorded_at desc);

create table if not exists public.feeding_event_details (
  event_id uuid primary key references public.activity_events(id) on delete cascade,
  feeding_mode text not null,
  breast_side text,
  left_duration_sec integer check (left_duration_sec is null or left_duration_sec >= 0),
  right_duration_sec integer check (right_duration_sec is null or right_duration_sec >= 0),
  amount_value numeric,
  amount_unit text,
  content_type text,
  spit_up_level smallint check (spit_up_level is null or spit_up_level between 0 and 3),
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists public.sleep_event_details (
  event_id uuid primary key references public.activity_events(id) on delete cascade,
  sleep_type text not null,
  location text,
  fell_asleep_at timestamptz,
  woke_up_at timestamptz,
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists public.diaper_event_details (
  event_id uuid primary key references public.activity_events(id) on delete cascade,
  diaper_type text not null,
  stool_color text,
  stool_texture text,
  rash_observed boolean not null default false,
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists public.pump_event_details (
  event_id uuid primary key references public.activity_events(id) on delete cascade,
  left_amount_ml numeric,
  right_amount_ml numeric,
  left_duration_sec integer check (left_duration_sec is null or left_duration_sec >= 0),
  right_duration_sec integer check (right_duration_sec is null or right_duration_sec >= 0),
  total_amount_ml numeric,
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists public.health_event_details (
  event_id uuid primary key references public.activity_events(id) on delete cascade,
  health_type text not null,
  temperature_c numeric,
  medication_name text,
  dosage_value numeric,
  dosage_unit text,
  symptom_summary text,
  clinic_name text,
  diagnosis text,
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists public.care_event_details (
  event_id uuid primary key references public.activity_events(id) on delete cascade,
  care_type text not null,
  duration_sec integer check (duration_sec is null or duration_sec >= 0),
  quantity_value numeric,
  quantity_unit text,
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists public.activity_attachments (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.activity_events(id) on delete cascade,
  storage_bucket text not null,
  storage_path text not null,
  mime_type text not null,
  size_bytes bigint not null check (size_bytes >= 0),
  width integer,
  height integer,
  created_by_user_id uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now())
);
create index if not exists idx_activity_attachments_event_id on public.activity_attachments(event_id);

create table if not exists public.growth_entries (
  id uuid primary key default gen_random_uuid(),
  baby_id uuid not null references public.babies(id) on delete cascade,
  actor_user_id uuid not null references public.profiles(id) on delete restrict,
  measured_at timestamptz not null,
  weight_kg numeric,
  height_cm numeric,
  head_circumference_cm numeric,
  percentile_source text,
  note text,
  deleted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint growth_entries_measurement_present check (
    weight_kg is not null or height_cm is not null or head_circumference_cm is not null
  )
);
create index if not exists idx_growth_entries_baby_measured_at on public.growth_entries(baby_id, measured_at desc);

create table if not exists public.development_milestone_catalog (
  id uuid primary key default gen_random_uuid(),
  milestone_group text not null,
  min_month integer not null check (min_month >= 0),
  max_month integer not null check (max_month >= min_month),
  title text not null,
  description text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.development_checks (
  id uuid primary key default gen_random_uuid(),
  baby_id uuid not null references public.babies(id) on delete cascade,
  milestone_id uuid not null references public.development_milestone_catalog(id) on delete cascade,
  checked_by_user_id uuid not null references public.profiles(id) on delete restrict,
  checked_at timestamptz not null,
  status text not null,
  note text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (baby_id, milestone_id)
);

create table if not exists public.diary_entries (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  baby_id uuid not null references public.babies(id) on delete cascade,
  author_user_id uuid not null references public.profiles(id) on delete restrict,
  title text,
  body text not null,
  visibility public.diary_visibility not null default 'private',
  event_date date,
  published_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);
create index if not exists idx_diary_entries_baby_event_date on public.diary_entries(baby_id, event_date desc);

create table if not exists public.diary_attachments (
  id uuid primary key default gen_random_uuid(),
  diary_entry_id uuid not null references public.diary_entries(id) on delete cascade,
  storage_bucket text not null,
  storage_path text not null,
  mime_type text not null,
  size_bytes bigint not null check (size_bytes >= 0),
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now())
);
create index if not exists idx_diary_attachments_diary_entry_id on public.diary_attachments(diary_entry_id);

create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  diary_entry_id uuid not null unique references public.diary_entries(id) on delete cascade,
  author_user_id uuid not null references public.profiles(id) on delete restrict,
  household_id uuid not null references public.households(id) on delete cascade,
  baby_age_days integer not null check (baby_age_days >= 0),
  status public.community_post_status not null default 'visible',
  published_at timestamptz not null default timezone('utc', now()),
  moderated_at timestamptz,
  moderation_reason text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);
create index if not exists idx_community_posts_status_published_at on public.community_posts(status, published_at desc);

create table if not exists public.reminder_rules (
  id uuid primary key default gen_random_uuid(),
  baby_id uuid not null references public.babies(id) on delete cascade,
  household_id uuid not null references public.households(id) on delete cascade,
  rule_type public.reminder_rule_type not null,
  is_enabled boolean not null default true,
  threshold_minutes integer not null check (threshold_minutes > 0),
  quiet_hours_json jsonb not null default '{}'::jsonb,
  created_by_user_id uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.device_installations (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null,
  push_token text,
  locale text not null default 'ko',
  timezone text not null default 'Asia/Seoul',
  app_version text,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);
create unique index if not exists idx_device_installations_user_push_token
  on public.device_installations(user_id, push_token)
  where push_token is not null;

create table if not exists public.notification_logs (
  id uuid primary key default gen_random_uuid(),
  reminder_rule_id uuid references public.reminder_rules(id) on delete set null,
  device_installation_id uuid not null references public.device_installations(id) on delete cascade,
  notification_type text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'queued',
  sent_at timestamptz,
  opened_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);
create index if not exists idx_notification_logs_device_created_at on public.notification_logs(device_installation_id, created_at desc);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  actor_user_id uuid references public.profiles(id) on delete set null,
  entity_type text not null,
  entity_id uuid not null,
  action text not null,
  before_json jsonb,
  after_json jsonb,
  created_at timestamptz not null default timezone('utc', now())
);
create index if not exists idx_audit_logs_household_created_at on public.audit_logs(household_id, created_at desc);

-- =========================================================
-- UPDATED_AT TRIGGERS
-- =========================================================

drop trigger if exists trg_profiles_set_updated_at on public.profiles;
create trigger trg_profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_households_set_updated_at on public.households;
create trigger trg_households_set_updated_at
before update on public.households
for each row execute function public.set_updated_at();

drop trigger if exists trg_household_memberships_set_updated_at on public.household_memberships;
create trigger trg_household_memberships_set_updated_at
before update on public.household_memberships
for each row execute function public.set_updated_at();

drop trigger if exists trg_caregiver_invites_set_updated_at on public.caregiver_invites;
create trigger trg_caregiver_invites_set_updated_at
before update on public.caregiver_invites
for each row execute function public.set_updated_at();

drop trigger if exists trg_babies_set_updated_at on public.babies;
create trigger trg_babies_set_updated_at
before update on public.babies
for each row execute function public.set_updated_at();

drop trigger if exists trg_event_types_set_updated_at on public.event_types;
create trigger trg_event_types_set_updated_at
before update on public.event_types
for each row execute function public.set_updated_at();

drop trigger if exists trg_activity_events_set_updated_at on public.activity_events;
create trigger trg_activity_events_set_updated_at
before update on public.activity_events
for each row execute function public.set_updated_at();

drop trigger if exists trg_growth_entries_set_updated_at on public.growth_entries;
create trigger trg_growth_entries_set_updated_at
before update on public.growth_entries
for each row execute function public.set_updated_at();

drop trigger if exists trg_development_milestone_catalog_set_updated_at on public.development_milestone_catalog;
create trigger trg_development_milestone_catalog_set_updated_at
before update on public.development_milestone_catalog
for each row execute function public.set_updated_at();

drop trigger if exists trg_development_checks_set_updated_at on public.development_checks;
create trigger trg_development_checks_set_updated_at
before update on public.development_checks
for each row execute function public.set_updated_at();

drop trigger if exists trg_diary_entries_set_updated_at on public.diary_entries;
create trigger trg_diary_entries_set_updated_at
before update on public.diary_entries
for each row execute function public.set_updated_at();

drop trigger if exists trg_community_posts_set_updated_at on public.community_posts;
create trigger trg_community_posts_set_updated_at
before update on public.community_posts
for each row execute function public.set_updated_at();

drop trigger if exists trg_reminder_rules_set_updated_at on public.reminder_rules;
create trigger trg_reminder_rules_set_updated_at
before update on public.reminder_rules
for each row execute function public.set_updated_at();

drop trigger if exists trg_device_installations_set_updated_at on public.device_installations;
create trigger trg_device_installations_set_updated_at
before update on public.device_installations
for each row execute function public.set_updated_at();

-- =========================================================
-- AUTH / HOUSEHOLD TRIGGERS
-- =========================================================

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

drop trigger if exists trg_household_created_owner_membership on public.households;
create trigger trg_household_created_owner_membership
  after insert on public.households
  for each row execute function public.handle_household_created();

-- =========================================================
-- RLS
-- =========================================================

alter table public.profiles enable row level security;
alter table public.households enable row level security;
alter table public.household_memberships enable row level security;
alter table public.caregiver_invites enable row level security;
alter table public.babies enable row level security;
alter table public.event_types enable row level security;
alter table public.activity_events enable row level security;
alter table public.feeding_event_details enable row level security;
alter table public.sleep_event_details enable row level security;
alter table public.diaper_event_details enable row level security;
alter table public.pump_event_details enable row level security;
alter table public.health_event_details enable row level security;
alter table public.care_event_details enable row level security;
alter table public.activity_attachments enable row level security;
alter table public.growth_entries enable row level security;
alter table public.development_milestone_catalog enable row level security;
alter table public.development_checks enable row level security;
alter table public.diary_entries enable row level security;
alter table public.diary_attachments enable row level security;
alter table public.community_posts enable row level security;
alter table public.reminder_rules enable row level security;
alter table public.device_installations enable row level security;
alter table public.notification_logs enable row level security;
alter table public.audit_logs enable row level security;

-- profiles

drop policy if exists profiles_select_self on public.profiles;
create policy profiles_select_self on public.profiles
for select using (id = auth.uid());

drop policy if exists profiles_insert_self on public.profiles;
create policy profiles_insert_self on public.profiles
for insert with check (id = auth.uid());

drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles
for update using (id = auth.uid())
with check (id = auth.uid());

-- households

drop policy if exists households_select_member on public.households;
create policy households_select_member on public.households
for select using (public.is_household_member(id));

drop policy if exists households_insert_authenticated on public.households;
create policy households_insert_authenticated on public.households
for insert to authenticated
with check (created_by_user_id = auth.uid());

drop policy if exists households_update_admin on public.households;
create policy households_update_admin on public.households
for update using (public.has_household_role(id, array['owner', 'admin']::public.membership_role[]))
with check (public.has_household_role(id, array['owner', 'admin']::public.membership_role[]));

-- household_memberships

drop policy if exists household_memberships_select_member on public.household_memberships;
create policy household_memberships_select_member on public.household_memberships
for select using (
  user_id = auth.uid() or public.is_household_member(household_id)
);

drop policy if exists household_memberships_insert_admin on public.household_memberships;
create policy household_memberships_insert_admin on public.household_memberships
for insert with check (
  public.has_household_role(household_id, array['owner', 'admin']::public.membership_role[])
);

drop policy if exists household_memberships_update_admin on public.household_memberships;
create policy household_memberships_update_admin on public.household_memberships
for update using (
  public.has_household_role(household_id, array['owner', 'admin']::public.membership_role[])
)
with check (
  public.has_household_role(household_id, array['owner', 'admin']::public.membership_role[])
);

-- caregiver_invites

drop policy if exists caregiver_invites_select_member on public.caregiver_invites;
create policy caregiver_invites_select_member on public.caregiver_invites
for select using (public.is_household_member(household_id));

drop policy if exists caregiver_invites_manage_admin on public.caregiver_invites;
create policy caregiver_invites_manage_admin on public.caregiver_invites
for all using (public.has_household_role(household_id, array['owner', 'admin']::public.membership_role[]))
with check (public.has_household_role(household_id, array['owner', 'admin']::public.membership_role[]));

-- babies

drop policy if exists babies_select_member on public.babies;
create policy babies_select_member on public.babies
for select using (public.is_household_member(household_id));

drop policy if exists babies_insert_editor on public.babies;
create policy babies_insert_editor on public.babies
for insert with check (
  public.has_household_role(household_id, array['owner', 'admin', 'editor']::public.membership_role[])
  and created_by_user_id = auth.uid()
);

drop policy if exists babies_update_editor on public.babies;
create policy babies_update_editor on public.babies
for update using (
  public.has_household_role(household_id, array['owner', 'admin', 'editor']::public.membership_role[])
)
with check (
  public.has_household_role(household_id, array['owner', 'admin', 'editor']::public.membership_role[])
);

-- event_types

drop policy if exists event_types_select_authenticated on public.event_types;
create policy event_types_select_authenticated on public.event_types
for select to authenticated using (is_enabled = true);

-- activity_events

drop policy if exists activity_events_select_member on public.activity_events;
create policy activity_events_select_member on public.activity_events
for select using (public.is_household_member(household_id));

drop policy if exists activity_events_insert_editor on public.activity_events;
create policy activity_events_insert_editor on public.activity_events
for insert with check (
  public.has_household_role(household_id, array['owner', 'admin', 'editor']::public.membership_role[])
  and actor_user_id = auth.uid()
);

drop policy if exists activity_events_update_editor on public.activity_events;
create policy activity_events_update_editor on public.activity_events
for update using (
  public.has_household_role(household_id, array['owner', 'admin', 'editor']::public.membership_role[])
)
with check (
  public.has_household_role(household_id, array['owner', 'admin', 'editor']::public.membership_role[])
);

-- detail tables share event-based policy

drop policy if exists feeding_event_details_select_member on public.feeding_event_details;
create policy feeding_event_details_select_member on public.feeding_event_details
for select using (exists (
  select 1 from public.activity_events ae
  where ae.id = feeding_event_details.event_id
    and public.is_household_member(ae.household_id)
));

drop policy if exists feeding_event_details_modify_editor on public.feeding_event_details;
create policy feeding_event_details_modify_editor on public.feeding_event_details
for all using (exists (
  select 1 from public.activity_events ae
  where ae.id = feeding_event_details.event_id
    and public.has_household_role(ae.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
))
with check (exists (
  select 1 from public.activity_events ae
  where ae.id = feeding_event_details.event_id
    and public.has_household_role(ae.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
));

drop policy if exists sleep_event_details_select_member on public.sleep_event_details;
create policy sleep_event_details_select_member on public.sleep_event_details
for select using (exists (
  select 1 from public.activity_events ae
  where ae.id = sleep_event_details.event_id
    and public.is_household_member(ae.household_id)
));

drop policy if exists sleep_event_details_modify_editor on public.sleep_event_details;
create policy sleep_event_details_modify_editor on public.sleep_event_details
for all using (exists (
  select 1 from public.activity_events ae
  where ae.id = sleep_event_details.event_id
    and public.has_household_role(ae.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
))
with check (exists (
  select 1 from public.activity_events ae
  where ae.id = sleep_event_details.event_id
    and public.has_household_role(ae.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
));

drop policy if exists diaper_event_details_select_member on public.diaper_event_details;
create policy diaper_event_details_select_member on public.diaper_event_details
for select using (exists (
  select 1 from public.activity_events ae
  where ae.id = diaper_event_details.event_id
    and public.is_household_member(ae.household_id)
));

drop policy if exists diaper_event_details_modify_editor on public.diaper_event_details;
create policy diaper_event_details_modify_editor on public.diaper_event_details
for all using (exists (
  select 1 from public.activity_events ae
  where ae.id = diaper_event_details.event_id
    and public.has_household_role(ae.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
))
with check (exists (
  select 1 from public.activity_events ae
  where ae.id = diaper_event_details.event_id
    and public.has_household_role(ae.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
));

drop policy if exists pump_event_details_select_member on public.pump_event_details;
create policy pump_event_details_select_member on public.pump_event_details
for select using (exists (
  select 1 from public.activity_events ae
  where ae.id = pump_event_details.event_id
    and public.is_household_member(ae.household_id)
));

drop policy if exists pump_event_details_modify_editor on public.pump_event_details;
create policy pump_event_details_modify_editor on public.pump_event_details
for all using (exists (
  select 1 from public.activity_events ae
  where ae.id = pump_event_details.event_id
    and public.has_household_role(ae.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
))
with check (exists (
  select 1 from public.activity_events ae
  where ae.id = pump_event_details.event_id
    and public.has_household_role(ae.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
));

drop policy if exists health_event_details_select_member on public.health_event_details;
create policy health_event_details_select_member on public.health_event_details
for select using (exists (
  select 1 from public.activity_events ae
  where ae.id = health_event_details.event_id
    and public.is_household_member(ae.household_id)
));

drop policy if exists health_event_details_modify_editor on public.health_event_details;
create policy health_event_details_modify_editor on public.health_event_details
for all using (exists (
  select 1 from public.activity_events ae
  where ae.id = health_event_details.event_id
    and public.has_household_role(ae.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
))
with check (exists (
  select 1 from public.activity_events ae
  where ae.id = health_event_details.event_id
    and public.has_household_role(ae.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
));

drop policy if exists care_event_details_select_member on public.care_event_details;
create policy care_event_details_select_member on public.care_event_details
for select using (exists (
  select 1 from public.activity_events ae
  where ae.id = care_event_details.event_id
    and public.is_household_member(ae.household_id)
));

drop policy if exists care_event_details_modify_editor on public.care_event_details;
create policy care_event_details_modify_editor on public.care_event_details
for all using (exists (
  select 1 from public.activity_events ae
  where ae.id = care_event_details.event_id
    and public.has_household_role(ae.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
))
with check (exists (
  select 1 from public.activity_events ae
  where ae.id = care_event_details.event_id
    and public.has_household_role(ae.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
));

-- attachments

drop policy if exists activity_attachments_select_member on public.activity_attachments;
create policy activity_attachments_select_member on public.activity_attachments
for select using (exists (
  select 1 from public.activity_events ae
  where ae.id = activity_attachments.event_id
    and public.is_household_member(ae.household_id)
));

drop policy if exists activity_attachments_modify_editor on public.activity_attachments;
create policy activity_attachments_modify_editor on public.activity_attachments
for all using (exists (
  select 1 from public.activity_events ae
  where ae.id = activity_attachments.event_id
    and public.has_household_role(ae.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
))
with check (exists (
  select 1 from public.activity_events ae
  where ae.id = activity_attachments.event_id
    and public.has_household_role(ae.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
));

-- growth

drop policy if exists growth_entries_select_member on public.growth_entries;
create policy growth_entries_select_member on public.growth_entries
for select using (exists (
  select 1 from public.babies b
  where b.id = growth_entries.baby_id
    and public.is_household_member(b.household_id)
));

drop policy if exists growth_entries_modify_editor on public.growth_entries;
create policy growth_entries_modify_editor on public.growth_entries
for all using (exists (
  select 1 from public.babies b
  where b.id = growth_entries.baby_id
    and public.has_household_role(b.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
))
with check (exists (
  select 1 from public.babies b
  where b.id = growth_entries.baby_id
    and public.has_household_role(b.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
));

-- milestone catalog (read only to authenticated)

drop policy if exists development_milestone_catalog_select_authenticated on public.development_milestone_catalog;
create policy development_milestone_catalog_select_authenticated on public.development_milestone_catalog
for select to authenticated using (is_active = true);

-- development checks

drop policy if exists development_checks_select_member on public.development_checks;
create policy development_checks_select_member on public.development_checks
for select using (exists (
  select 1 from public.babies b
  where b.id = development_checks.baby_id
    and public.is_household_member(b.household_id)
));

drop policy if exists development_checks_modify_editor on public.development_checks;
create policy development_checks_modify_editor on public.development_checks
for all using (exists (
  select 1 from public.babies b
  where b.id = development_checks.baby_id
    and public.has_household_role(b.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
))
with check (exists (
  select 1 from public.babies b
  where b.id = development_checks.baby_id
    and public.has_household_role(b.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
));

-- diary entries

drop policy if exists diary_entries_select_visibility on public.diary_entries;
create policy diary_entries_select_visibility on public.diary_entries
for select using (
  public.is_household_member(household_id)
  or visibility = 'public'
);

drop policy if exists diary_entries_modify_editor on public.diary_entries;
create policy diary_entries_modify_editor on public.diary_entries
for all using (
  public.has_household_role(household_id, array['owner', 'admin', 'editor']::public.membership_role[])
)
with check (
  public.has_household_role(household_id, array['owner', 'admin', 'editor']::public.membership_role[])
  and author_user_id = auth.uid()
);

-- diary attachments

drop policy if exists diary_attachments_select_visibility on public.diary_attachments;
create policy diary_attachments_select_visibility on public.diary_attachments
for select using (exists (
  select 1 from public.diary_entries de
  where de.id = diary_attachments.diary_entry_id
    and (public.is_household_member(de.household_id) or de.visibility = 'public')
));

drop policy if exists diary_attachments_modify_editor on public.diary_attachments;
create policy diary_attachments_modify_editor on public.diary_attachments
for all using (exists (
  select 1 from public.diary_entries de
  where de.id = diary_attachments.diary_entry_id
    and public.has_household_role(de.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
))
with check (exists (
  select 1 from public.diary_entries de
  where de.id = diary_attachments.diary_entry_id
    and public.has_household_role(de.household_id, array['owner', 'admin', 'editor']::public.membership_role[])
));

-- community posts

drop policy if exists community_posts_select_visible on public.community_posts;
create policy community_posts_select_visible on public.community_posts
for select using (status = 'visible');

-- reminder rules

drop policy if exists reminder_rules_select_member on public.reminder_rules;
create policy reminder_rules_select_member on public.reminder_rules
for select using (public.is_household_member(household_id));

drop policy if exists reminder_rules_modify_editor on public.reminder_rules;
create policy reminder_rules_modify_editor on public.reminder_rules
for all using (
  public.has_household_role(household_id, array['owner', 'admin', 'editor']::public.membership_role[])
)
with check (
  public.has_household_role(household_id, array['owner', 'admin', 'editor']::public.membership_role[])
);

-- device installations

drop policy if exists device_installations_select_self on public.device_installations;
create policy device_installations_select_self on public.device_installations
for select using (user_id = auth.uid());

drop policy if exists device_installations_insert_self on public.device_installations;
create policy device_installations_insert_self on public.device_installations
for insert with check (
  user_id = auth.uid()
  and public.is_household_member(household_id)
);

drop policy if exists device_installations_update_self on public.device_installations;
create policy device_installations_update_self on public.device_installations
for update using (user_id = auth.uid())
with check (user_id = auth.uid());

-- notification_logs / audit_logs are service-role oriented; no client policies by default

-- =========================================================
-- SEED DATA
-- =========================================================

insert into public.event_types (slug, category, display_name, is_timer_supported, is_quantity_supported, is_enabled, sort_order)
values
  ('breastfeeding', 'feeding', '모유수유', true, false, true, 10),
  ('bottle_feeding', 'feeding', '젖병/분유', false, true, true, 20),
  ('solid_food', 'feeding', '이유식', false, true, true, 30),
  ('sleep', 'sleep', '수면', true, false, true, 40),
  ('diaper', 'diaper', '기저귀', false, false, true, 50),
  ('pumping', 'pump', '유축', true, true, true, 60),
  ('temperature', 'health', '체온', false, true, true, 70),
  ('medication', 'health', '약 복용', false, true, true, 80),
  ('symptom', 'health', '증상', false, false, true, 90),
  ('doctor_visit', 'health', '병원 방문', false, false, true, 100),
  ('bath', 'care', '목욕', false, false, true, 110),
  ('tummy_time', 'care', '터미타임', true, false, true, 120),
  ('custom_care', 'care', '기타 육아 활동', false, true, true, 130)
on conflict (slug) do update
set
  category = excluded.category,
  display_name = excluded.display_name,
  is_timer_supported = excluded.is_timer_supported,
  is_quantity_supported = excluded.is_quantity_supported,
  is_enabled = excluded.is_enabled,
  sort_order = excluded.sort_order,
  updated_at = timezone('utc', now());

commit;
