-- AQDIN demo discovery profiles and hardened photo-upload permissions.
-- Additive only: never creates auth.users or modifies existing member accounts.
create extension if not exists pgcrypto;

create table if not exists public.aqdin_demo_profiles (
 id uuid primary key default gen_random_uuid(),
 demo_key text not null unique,
 display_name text not null,
 gender text not null check (gender in ('man','woman')),
 date_of_birth date not null check (date_of_birth <= current_date - interval '18 years'),
 country_code text not null, city text not null, bio text not null, occupation text not null,
 marital_status text not null default 'never_married' check (marital_status in ('never_married','divorced','widowed')),
 interests text[] not null default '{}', image_url text not null,
 is_demo boolean not null default true check (is_demo = true),
 is_active boolean not null default true, created_at timestamptz not null default now()
);
create index if not exists aqdin_demo_profiles_active_gender_idx on public.aqdin_demo_profiles(is_active,gender);
alter table public.aqdin_demo_profiles enable row level security;
drop policy if exists aqdin_demo_profiles_authenticated_read on public.aqdin_demo_profiles;
create policy aqdin_demo_profiles_authenticated_read on public.aqdin_demo_profiles
 for select to authenticated using (is_active=true);
grant select on public.aqdin_demo_profiles to authenticated;

with
male_names as (select array['Adam','Ahmed','Aidan','Ali','Amir','Bilal','Dawud','Elias','Emir','Faris','Hassan','Ibrahim','Idris','Imran','Ismail','Jamal','Karim','Khalid','Malik','Musa']::text[] a),
female_names as (select array['Aaliyah','Aisha','Amara','Amina','Asiya','Aya','Dalia','Farah','Fatima','Hana','Hiba','Iman','Inaya','Jannah','Khadija','Layla','Maryam','Mariam','Noor','Zahra']::text[] a),
surnames as (select array['Abdullah','Ahmed','Ali','Bello','Hassan']::text[] a),
places as (select array['Lagos|NG','Abuja|NG','Ibadan|NG','Kano|NG','Ilorin|NG','London|GB','Birmingham|GB','Toronto|CA','Ottawa|CA','New York|US','Houston|US','Dubai|AE','Abu Dhabi|AE','Doha|QA','Istanbul|TR','Kuala Lumpur|MY','Jakarta|ID','Cairo|EG','Nairobi|KE','Accra|GH']::text[] a),
male_seed as (
 select 'male-'||lpad(g.i::text,3,'0') demo_key,
  mn.a[((g.i-1)%20)+1]||' '||sn.a[((g.i-1)/20)+1] display_name,'man'::text gender,
  make_date(2026-(24+((g.i*7)%16)),1+((g.i*5)%12),1+((g.i*3)%27)) dob,
  split_part(pl.a[((g.i-1)%20)+1],'|',2) country_code,
  split_part(pl.a[((g.i-1)%20)+1],'|',1) city,
  (array['I value faith, kindness and honest communication. I hope to build a peaceful home rooted in mutual respect.','Family, personal growth and service matter to me. I am here with sincere intentions towards marriage.','I enjoy learning, meaningful conversations and spending time with family. Looking for a thoughtful life partner.','I believe marriage is a partnership built on patience, trust, shared values and compassion.','I appreciate simple moments, community and continuous learning. Seeking a serious, respectful introduction.'])[((g.i-1)%5)+1] bio,
  (array['Software developer','Teacher','Civil engineer','Healthcare professional','Business owner','Accountant','Architect','Project manager','Entrepreneur','Researcher'])[((g.i-1)%10)+1] occupation,
  (array['Reading','Travel','Community service','Fitness','Cooking','Technology','Nature','Football'])[((g.i-1)%8)+1] interest,
  'https://randomuser.me/api/portraits/men/'||(g.i-1)::text||'.jpg' image_url
 from generate_series(1,100) g(i) cross join male_names mn cross join surnames sn cross join places pl
),
female_seed as (
 select 'female-'||lpad(g.i::text,3,'0') demo_key,
  fn.a[((g.i-1)%20)+1]||' '||sn.a[((g.i-1)/20)+1] display_name,'woman'::text gender,
  make_date(2026-(23+((g.i*9)%17)),1+((g.i*7)%12),1+((g.i*4)%27)) dob,
  split_part(pl.a[((g.i+6)%20)+1],'|',2) country_code,
  split_part(pl.a[((g.i+6)%20)+1],'|',1) city,
  (array['I value faith, kindness and honest communication. I hope to build a peaceful home rooted in mutual respect.','Family, personal growth and service matter to me. I am here with sincere intentions towards marriage.','I enjoy learning, meaningful conversations and spending time with family. Looking for a thoughtful life partner.','I believe marriage is a partnership built on patience, trust, shared values and compassion.','I appreciate simple moments, community and continuous learning. Seeking a serious, respectful introduction.'])[((g.i-1)%5)+1] bio,
  (array['Teacher','Doctor','UX designer','Business owner','Pharmacist','Accountant','Lawyer','Project manager','Entrepreneur','Researcher'])[((g.i-1)%10)+1] occupation,
  (array['Reading','Travel','Community service','Fitness','Cooking','Technology','Nature','Art'])[((g.i-1)%8)+1] interest,
  'https://randomuser.me/api/portraits/women/'||(g.i-1)::text||'.jpg' image_url
 from generate_series(1,100) g(i) cross join female_names fn cross join surnames sn cross join places pl
),
seed as (select * from male_seed union all select * from female_seed)
insert into public.aqdin_demo_profiles(demo_key,display_name,gender,date_of_birth,country_code,city,bio,occupation,interests,image_url)
select demo_key,display_name,gender,dob,country_code,city,bio,occupation,array[interest,'Family','Personal growth'],image_url from seed
on conflict(demo_key) do update set display_name=excluded.display_name,gender=excluded.gender,date_of_birth=excluded.date_of_birth,
 country_code=excluded.country_code,city=excluded.city,bio=excluded.bio,occupation=excluded.occupation,
 interests=excluded.interests,image_url=excluded.image_url,is_active=true;

-- Recreate the private bucket configuration without making profile photos public.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('profile-photos','profile-photos',false,8388608,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=false,file_size_limit=8388608,allowed_mime_types=excluded.allowed_mime_types;

grant select,insert,update,delete on public.profile_photos to authenticated;
drop policy if exists photos_insert_own on public.profile_photos;
create policy photos_insert_own on public.profile_photos for insert to authenticated
 with check(user_id=(select auth.uid()));
drop policy if exists photos_select_own_or_approved_visible on public.profile_photos;
create policy photos_select_own_or_approved_visible on public.profile_photos for select to authenticated
 using(user_id=(select auth.uid()) or (moderation_status='approved' and exists(
  select 1 from public.user_profiles p where p.id=profile_photos.user_id and p.profile_visibility='members'
 )));

drop policy if exists member_upload_own_profile_photos on storage.objects;
create policy member_upload_own_profile_photos on storage.objects for insert to authenticated
 with check(bucket_id='profile-photos' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists member_read_visible_profile_photos on storage.objects;
create policy member_read_visible_profile_photos on storage.objects for select to authenticated using(
 bucket_id='profile-photos' and ((storage.foldername(name))[1]=(select auth.uid())::text or exists(
  select 1 from public.profile_photos ph join public.user_profiles p on p.id=ph.user_id
  where ph.storage_path=name and ph.moderation_status='approved' and p.profile_visibility='members'
 )));
drop policy if exists member_update_own_profile_photos on storage.objects;
create policy member_update_own_profile_photos on storage.objects for update to authenticated
 using(bucket_id='profile-photos' and (storage.foldername(name))[1]=(select auth.uid())::text)
 with check(bucket_id='profile-photos' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists member_delete_own_profile_photos on storage.objects;
create policy member_delete_own_profile_photos on storage.objects for delete to authenticated
 using(bucket_id='profile-photos' and (storage.foldername(name))[1]=(select auth.uid())::text);

notify pgrst,'reload schema';
