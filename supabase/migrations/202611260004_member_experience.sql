-- AQDIN member experience expansion. Additive only: does not delete or recreate auth users.
-- Existing account UUIDs and profile rows are preserved.
create extension if not exists pgcrypto;

alter table public.user_profiles
  add column if not exists occupation text,
  add column if not exists education_level text,
  add column if not exists languages text[] not null default '{}',
  add column if not exists interests text[] not null default '{}',
  add column if not exists relocation_open boolean not null default false,
  add column if not exists children_status text,
  add column if not exists marriage_timeline text,
  add column if not exists show_online boolean not null default true,
  add column if not exists last_active_at timestamptz,
  add column if not exists profile_completed_at timestamptz;

alter table public.marriage_preferences
  add column if not exists preferred_gender text,
  add column if not exists min_height_cm integer,
  add column if not exists max_height_cm integer,
  add column if not exists education_preferences text[] not null default '{}',
  add column if not exists occupation_preferences text[] not null default '{}',
  add column if not exists relocation_preferences text,
  add column if not exists family_preferences jsonb not null default '{}'::jsonb,
  add column if not exists values_preferences text[] not null default '{}',
  add column if not exists updated_at timestamptz not null default now();

create table if not exists public.verification_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  verification_type text not null check (verification_type in ('email','phone','selfie','identity')),
  provider text,
  status text not null default 'pending' check (status in ('pending','in_review','verified','rejected','expired')),
  provider_reference text,
  result_summary text,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create table if not exists public.user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  notification_preferences jsonb not null default '{"likes":true,"matches":true,"messages":true,"introductions":true}'::jsonb,
  privacy_preferences jsonb not null default '{"show_online":true,"show_distance":false,"allow_intros":true}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.conversation_settings (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  archived boolean not null default false,
  muted boolean not null default false,
  read_at timestamptz,
  primary key(conversation_id,user_id)
);

create table if not exists public.wali_activity (
  id uuid primary key default gen_random_uuid(),
  relationship_id uuid not null references public.wali_relationships(id) on delete cascade,
  actor_user_id uuid not null references auth.users(id) on delete cascade,
  activity_type text not null,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists verification_user_status_idx on public.verification_records(user_id,status);
create index if not exists introduction_recipient_status_idx on public.introduction_requests(recipient_user_id,status,created_at desc);
create index if not exists profile_presence_last_active_idx on public.user_profiles(last_active_at desc);

alter table public.verification_records enable row level security;
alter table public.user_settings enable row level security;
alter table public.conversation_settings enable row level security;
alter table public.wali_activity enable row level security;

drop policy if exists verification_owner_read on public.verification_records;
create policy verification_owner_read on public.verification_records
for select to authenticated using(user_id=auth.uid());
drop policy if exists verification_owner_insert on public.verification_records;
create policy verification_owner_insert on public.verification_records
for insert to authenticated with check(user_id=auth.uid());

drop policy if exists user_settings_owner_all on public.user_settings;
create policy user_settings_owner_all on public.user_settings
for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());

drop policy if exists conversation_settings_owner_all on public.conversation_settings;
create policy conversation_settings_owner_all on public.conversation_settings
for all to authenticated
using(user_id=auth.uid() and exists(select 1 from public.conversation_members cm where cm.conversation_id=conversation_settings.conversation_id and cm.user_id=auth.uid()))
with check(user_id=auth.uid() and exists(select 1 from public.conversation_members cm where cm.conversation_id=conversation_settings.conversation_id and cm.user_id=auth.uid()));

drop policy if exists wali_activity_participant_read on public.wali_activity;
create policy wali_activity_participant_read on public.wali_activity
for select to authenticated using(exists(
  select 1 from public.wali_relationships wr where wr.id=relationship_id
  and auth.uid() in (wr.member_user_id,wr.wali_user_id)
));
drop policy if exists wali_activity_participant_insert on public.wali_activity;
create policy wali_activity_participant_insert on public.wali_activity
for insert to authenticated with check(actor_user_id=auth.uid() and exists(
  select 1 from public.wali_relationships wr where wr.id=relationship_id
  and auth.uid() in (wr.member_user_id,wr.wali_user_id)
));

grant select,insert on public.verification_records to authenticated;
grant select,insert,update on public.user_settings to authenticated;
grant select,insert,update,delete on public.conversation_settings to authenticated;
grant select,insert on public.wali_activity to authenticated;

-- Keep online status and last-active data owner-controlled.
drop policy if exists profile_presence_owner_update on public.user_profiles;
create policy profile_presence_owner_update on public.user_profiles
for update to authenticated using(id=auth.uid()) with check(id=auth.uid());

-- A single server-side action endpoint ensures the actor is always auth.uid().
create or replace function public.process_profile_action(target uuid, action_name text)
returns uuid
language plpgsql security definer set search_path=public
as $$
declare actor uuid := auth.uid(); result_id uuid;
begin
  if actor is null or target is null or actor=target then raise exception 'Invalid profile action'; end if;
  if action_name not in ('like','pass','save','intro') then raise exception 'Unsupported action'; end if;
  if exists(select 1 from public.user_blocks b where
    (b.blocker_user_id=actor and b.blocked_user_id=target) or
    (b.blocker_user_id=target and b.blocked_user_id=actor)) then raise exception 'This profile is unavailable'; end if;
  insert into public.profile_actions(actor_user_id,target_user_id,action)
  values(actor,target,action_name)
  on conflict(actor_user_id,target_user_id,action) do nothing;
  if action_name='like' and exists(select 1 from public.profile_actions
    where actor_user_id=target and target_user_id=actor and action='like') then
    result_id := public.process_profile_like(target);
  end if;
  if action_name='intro' then
    insert into public.introduction_requests(sender_user_id,recipient_user_id)
    values(actor,target) on conflict do nothing;
  end if;
  return result_id;
end $$;
revoke all on function public.process_profile_action(uuid,text) from public;
grant execute on function public.process_profile_action(uuid,text) to authenticated;

-- Users can only accept/decline introductions addressed to them.
drop policy if exists intro_recipient_update on public.introduction_requests;
create policy intro_recipient_update on public.introduction_requests
for update to authenticated using(recipient_user_id=auth.uid())
with check(recipient_user_id=auth.uid());

-- Message membership is required for reads and writes; Wali accounts are not members by default.
notify pgrst,'reload schema';
