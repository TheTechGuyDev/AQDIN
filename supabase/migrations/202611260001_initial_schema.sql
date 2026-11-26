-- AQDIN initial schema
-- Apply through Supabase SQL Editor. Review before production deployment.

create extension if not exists pgcrypto;

create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  date_of_birth date,
  country_code text,
  city text,
  bio text,
  gender text check (gender in ('woman','man','self_described')),
  marital_status text check (marital_status in ('never_married','divorced','widowed')),
  profile_visibility text not null default 'members' check (profile_visibility in ('members','hidden')),
  onboarding_complete boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profile_photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null,
  sort_order integer not null default 0,
  is_primary boolean not null default false,
  moderation_status text not null default 'pending'
    check (moderation_status in ('pending','approved','rejected')),
  created_at timestamptz not null default now(),
  unique (user_id, storage_path)
);

create table if not exists public.marriage_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  min_age integer check (min_age between 18 and 100),
  max_age integer check (max_age between 18 and 100),
  preferred_countries text[] not null default '{}',
  open_to_relocation boolean not null default false,
  marital_status_preferences text[] not null default '{}',
  wants_children text,
  polygyny_expectation text,
  marriage_timeline text,
  updated_at timestamptz not null default now(),
  check (min_age is null or max_age is null or min_age <= max_age)
);

create table if not exists public.wali_relationships (
  id uuid primary key default gen_random_uuid(),
  member_user_id uuid not null references auth.users(id) on delete cascade,
  wali_user_id uuid not null references auth.users(id) on delete cascade,
  relationship_label text,
  status text not null default 'pending'
    check (status in ('pending','active','revoked','declined')),
  permissions jsonb not null default '{"view_profile": true, "view_matches": false, "view_messages": false}'::jsonb,
  invited_at timestamptz not null default now(),
  responded_at timestamptz,
  revoked_at timestamptz,
  check (member_user_id <> wali_user_id),
  unique (member_user_id, wali_user_id)
);

create table if not exists public.user_blocks (
  blocker_user_id uuid not null references auth.users(id) on delete cascade,
  blocked_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_user_id, blocked_user_id),
  check (blocker_user_id <> blocked_user_id)
);

create table if not exists public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_user_id uuid not null references auth.users(id) on delete cascade,
  reported_user_id uuid not null references auth.users(id) on delete cascade,
  category text not null,
  description text,
  status text not null default 'open'
    check (status in ('open','reviewing','resolved','dismissed')),
  created_at timestamptz not null default now(),
  check (reporter_user_id <> reported_user_id)
);

create index if not exists profile_photos_user_order_idx
  on public.profile_photos(user_id, sort_order);
create index if not exists wali_relationships_wali_idx
  on public.wali_relationships(wali_user_id, status);
create index if not exists user_reports_status_idx
  on public.user_reports(status, created_at);

alter table public.user_profiles enable row level security;
alter table public.profile_photos enable row level security;
alter table public.marriage_preferences enable row level security;
alter table public.wali_relationships enable row level security;
alter table public.user_blocks enable row level security;
alter table public.user_reports enable row level security;

-- Profiles: owners can create and edit their own profile.
create policy "profiles_select_visible_members"
on public.user_profiles for select to authenticated
using (
  id = (select auth.uid())
  or profile_visibility = 'members'
);

create policy "profiles_insert_own"
on public.user_profiles for insert to authenticated
with check (id = (select auth.uid()));

create policy "profiles_update_own"
on public.user_profiles for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

-- Photos: users manage their own photo records. Public discovery of approved
-- photo records is limited to visible member profiles; storage stays private.
create policy "photos_select_own_or_approved_visible"
on public.profile_photos for select to authenticated
using (
  user_id = (select auth.uid())
  or (
    moderation_status = 'approved'
    and exists (
      select 1 from public.user_profiles p
      where p.id = profile_photos.user_id
        and p.profile_visibility = 'members'
    )
  )
);

create policy "photos_insert_own"
on public.profile_photos for insert to authenticated
with check (user_id = (select auth.uid()));

create policy "photos_update_own"
on public.profile_photos for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy "photos_delete_own"
on public.profile_photos for delete to authenticated
using (user_id = (select auth.uid()));

-- Preferences are private to their owner.
create policy "preferences_select_own"
on public.marriage_preferences for select to authenticated
using (user_id = (select auth.uid()));

create policy "preferences_insert_own"
on public.marriage_preferences for insert to authenticated
with check (user_id = (select auth.uid()));

create policy "preferences_update_own"
on public.marriage_preferences for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy "preferences_delete_own"
on public.marriage_preferences for delete to authenticated
using (user_id = (select auth.uid()));

-- Wali rows are visible only to the two participants. A member creates an
-- invitation; the invited Wali may accept/decline; the member may revoke.
create policy "wali_select_participants"
on public.wali_relationships for select to authenticated
using (
  member_user_id = (select auth.uid())
  or wali_user_id = (select auth.uid())
);

create policy "wali_member_invites"
on public.wali_relationships for insert to authenticated
with check (
  member_user_id = (select auth.uid())
  and status = 'pending'
);

create policy "wali_participants_update"
on public.wali_relationships for update to authenticated
using (
  member_user_id = (select auth.uid())
  or wali_user_id = (select auth.uid())
)
with check (
  member_user_id = (select auth.uid())
  or wali_user_id = (select auth.uid())
);

create policy "wali_member_revoke_delete"
on public.wali_relationships for delete to authenticated
using (member_user_id = (select auth.uid()));

-- Blocks are private to the person who created them.
create policy "blocks_select_own"
on public.user_blocks for select to authenticated
using (blocker_user_id = (select auth.uid()));

create policy "blocks_insert_own"
on public.user_blocks for insert to authenticated
with check (blocker_user_id = (select auth.uid()));

create policy "blocks_delete_own"
on public.user_blocks for delete to authenticated
using (blocker_user_id = (select auth.uid()));

-- Reports: reporters can create and view their own reports. Status changes
-- are reserved for trusted server-side moderation workflows.
create policy "reports_select_own"
on public.user_reports for select to authenticated
using (reporter_user_id = (select auth.uid()));

create policy "reports_insert_own"
on public.user_reports for insert to authenticated
with check (reporter_user_id = (select auth.uid()));
