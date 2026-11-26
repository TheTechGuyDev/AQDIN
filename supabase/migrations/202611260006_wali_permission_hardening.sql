-- Tighten Wali permissions: the member controls shared permissions; the invited Wali may only accept or decline.
drop policy if exists "wali_participants_update" on public.wali_relationships;
revoke update on public.wali_relationships from authenticated;

create or replace function public.respond_to_wali_invitation(relationship_uuid uuid, decision text)
returns void language plpgsql security definer set search_path=public
as $$
begin
  if auth.uid() is null or decision not in ('active','declined') then raise exception 'Invalid invitation response'; end if;
  update public.wali_relationships
    set status=decision, responded_at=now()
    where id=relationship_uuid and wali_user_id=auth.uid() and status='pending';
  if not found then raise exception 'Invitation not found or already answered'; end if;
end $$;

create or replace function public.update_wali_permissions(relationship_uuid uuid, new_permissions jsonb)
returns void language plpgsql security definer set search_path=public
as $$
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  if jsonb_typeof(new_permissions) <> 'object' then raise exception 'Invalid permissions'; end if;
  update public.wali_relationships
    set permissions=jsonb_build_object(
      'view_profile', coalesce((new_permissions->>'view_profile')::boolean,false),
      'view_matches', coalesce((new_permissions->>'view_matches')::boolean,false),
      'view_messages', false
    )
    where id=relationship_uuid and member_user_id=auth.uid() and status='active';
  if not found then raise exception 'Active Wali relationship not found'; end if;
end $$;

create or replace function public.revoke_wali_relationship(relationship_uuid uuid)
returns void language plpgsql security definer set search_path=public
as $$
begin
  update public.wali_relationships set status='revoked',revoked_at=now()
    where id=relationship_uuid and member_user_id=auth.uid();
  if not found then raise exception 'Wali relationship not found'; end if;
end $$;

revoke all on function public.respond_to_wali_invitation(uuid,text) from public;
revoke all on function public.update_wali_permissions(uuid,jsonb) from public;
revoke all on function public.revoke_wali_relationship(uuid) from public;
grant execute on function public.respond_to_wali_invitation(uuid,text) to authenticated;
grant execute on function public.update_wali_permissions(uuid,jsonb) to authenticated;
grant execute on function public.revoke_wali_relationship(uuid) to authenticated;
