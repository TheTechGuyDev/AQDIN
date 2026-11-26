-- Private photo storage for member profiles. Additive and safe to rerun.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('profile-photos','profile-photos',false,8388608,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=false,file_size_limit=8388608,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists "member_upload_own_profile_photos" on storage.objects;
create policy "member_upload_own_profile_photos" on storage.objects
for insert to authenticated with check(
  bucket_id='profile-photos' and (storage.foldername(name))[1]=auth.uid()::text
);

drop policy if exists "member_read_visible_profile_photos" on storage.objects;
create policy "member_read_visible_profile_photos" on storage.objects
for select to authenticated using(
  bucket_id='profile-photos' and (
    (storage.foldername(name))[1]=auth.uid()::text
    or exists(
      select 1 from public.profile_photos ph
      join public.user_profiles p on p.id=ph.user_id
      where ph.storage_path=name and ph.moderation_status='approved'
        and p.profile_visibility='members'
    )
  )
);

drop policy if exists "member_delete_own_profile_photos" on storage.objects;
create policy "member_delete_own_profile_photos" on storage.objects
for delete to authenticated using(
  bucket_id='profile-photos' and (storage.foldername(name))[1]=auth.uid()::text
);
