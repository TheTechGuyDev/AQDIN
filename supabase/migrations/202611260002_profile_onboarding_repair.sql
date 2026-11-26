-- AQDIN profile onboarding repair. Safe to run more than once.
-- The original initial migration is already in GitHub, but GitHub commits do
-- not execute SQL against the hosted Supabase project.

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

alter table public.user_profiles enable row level security;
drop policy if exists "profiles_select_visible_members" on public.user_profiles;
create policy "profiles_select_visible_members" on public.user_profiles
for select to authenticated
using (id = (select auth.uid()) or profile_visibility = 'members');
drop policy if exists "profiles_insert_own" on public.user_profiles;
create policy "profiles_insert_own" on public.user_profiles
for insert to authenticated with check (id = (select auth.uid()));
drop policy if exists "profiles_update_own" on public.user_profiles;
create policy "profiles_update_own" on public.user_profiles
for update to authenticated using (id = (select auth.uid()))
with check (id = (select auth.uid()));
grant select, insert, update on public.user_profiles to authenticated;
notify pgrst, 'reload schema';
