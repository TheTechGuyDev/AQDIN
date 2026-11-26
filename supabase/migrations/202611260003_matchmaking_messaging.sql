-- AQDIN core matchmaking and communication schema
-- Additive migration; existing profile tables remain compatible.
create extension if not exists pgcrypto;

create table if not exists public.profile_interests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  interest text not null,
  created_at timestamptz not null default now(),
  unique(user_id, interest)
);
create table if not exists public.compatibility_answers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  question_key text not null,
  answer jsonb not null,
  visibility text not null default 'matches' check (visibility in ('private','matches','members')),
  updated_at timestamptz not null default now(),
  unique(user_id, question_key)
);
create table if not exists public.profile_actions (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid not null references auth.users(id) on delete cascade,
  target_user_id uuid not null references auth.users(id) on delete cascade,
  action text not null check (action in ('like','pass','save','intro')),
  created_at timestamptz not null default now(),
  unique(actor_user_id, target_user_id, action),
  check(actor_user_id <> target_user_id)
);
create index if not exists profile_actions_target_idx on public.profile_actions(target_user_id, action);
create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  user_one uuid not null references auth.users(id) on delete cascade,
  user_two uuid not null references auth.users(id) on delete cascade,
  status text not null default 'active' check(status in ('active','closed','blocked')),
  created_at timestamptz not null default now(),
  check(user_one < user_two),
  unique(user_one,user_two)
);
create table if not exists public.introduction_requests (
  id uuid primary key default gen_random_uuid(),
  sender_user_id uuid not null references auth.users(id) on delete cascade,
  recipient_user_id uuid not null references auth.users(id) on delete cascade,
  message text,
  status text not null default 'pending' check(status in ('pending','accepted','declined','withdrawn')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check(sender_user_id <> recipient_user_id)
);
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  match_id uuid references public.matches(id) on delete set null,
  created_at timestamptz not null default now(),
  unique(match_id)
);
create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key(conversation_id,user_id)
);
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_user_id uuid not null references auth.users(id) on delete cascade,
  body text not null check(length(trim(body)) between 1 and 5000),
  message_type text not null default 'text' check(message_type in ('text','system')),
  created_at timestamptz not null default now(),
  edited_at timestamptz,
  deleted_at timestamptz
);
create index if not exists messages_conversation_created_idx on public.messages(conversation_id,created_at desc);
create table if not exists public.user_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null,
  title text not null,
  body text,
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists user_notifications_user_idx on public.user_notifications(user_id,created_at desc);
create table if not exists public.user_presence (
  user_id uuid primary key references auth.users(id) on delete cascade,
  last_seen_at timestamptz not null default now(),
  show_online boolean not null default true
);

alter table public.profile_interests enable row level security;
alter table public.compatibility_answers enable row level security;
alter table public.profile_actions enable row level security;
alter table public.matches enable row level security;
alter table public.introduction_requests enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.user_notifications enable row level security;
alter table public.user_presence enable row level security;

-- Interests can be managed by their owner and read on visible member profiles.
create policy "interests_read_visible" on public.profile_interests for select to authenticated
using (user_id = auth.uid() or exists(select 1 from public.user_profiles p where p.id=user_id and p.profile_visibility='members'));
create policy "interests_manage_own" on public.profile_interests for all to authenticated
using(user_id=auth.uid()) with check(user_id=auth.uid());

-- Compatibility answers are private by default; owner can read/write their own answers.
create policy "answers_owner_all" on public.compatibility_answers for all to authenticated
using(user_id=auth.uid()) with check(user_id=auth.uid());

-- Actions are private to the actor. Clients cannot forge actions as another user.
create policy "actions_actor_read" on public.profile_actions for select to authenticated using(actor_user_id=auth.uid());
create policy "actions_actor_insert" on public.profile_actions for insert to authenticated with check(actor_user_id=auth.uid());
create policy "actions_actor_delete" on public.profile_actions for delete to authenticated using(actor_user_id=auth.uid());

-- Matches visible only to their two members.
create policy "matches_participants_read" on public.matches for select to authenticated
using(auth.uid() in (user_one,user_two));
-- Matches are created by the database trigger below, not directly by clients.

create policy "intro_participants_read" on public.introduction_requests for select to authenticated
using(auth.uid() in (sender_user_id,recipient_user_id));
create policy "intro_sender_insert" on public.introduction_requests for insert to authenticated
with check(sender_user_id=auth.uid());
create policy "intro_recipient_update" on public.introduction_requests for update to authenticated
using(recipient_user_id=auth.uid()) with check(recipient_user_id=auth.uid());

create policy "conversation_members_read" on public.conversation_members for select to authenticated using(user_id=auth.uid());
create policy "conversation_read_members" on public.conversations for select to authenticated
using(exists(select 1 from public.conversation_members cm where cm.conversation_id=id and cm.user_id=auth.uid()));
create policy "messages_read_members" on public.messages for select to authenticated
using(exists(select 1 from public.conversation_members cm where cm.conversation_id=conversation_id and cm.user_id=auth.uid()));
create policy "messages_send_members" on public.messages for insert to authenticated
with check(sender_user_id=auth.uid() and exists(select 1 from public.conversation_members cm where cm.conversation_id=conversation_id and cm.user_id=auth.uid()));
create policy "messages_edit_own" on public.messages for update to authenticated
using(sender_user_id=auth.uid()) with check(sender_user_id=auth.uid());

create policy "notifications_owner_all" on public.user_notifications for all to authenticated
using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "presence_read_visible" on public.user_presence for select to authenticated
using(user_id=auth.uid() or (show_online and exists(select 1 from public.user_profiles p where p.id=user_id and p.profile_visibility='members')));
create policy "presence_owner_all" on public.user_presence for all to authenticated
using(user_id=auth.uid()) with check(user_id=auth.uid());

-- A mutual like creates a match and a private conversation. The function runs
-- with definer privileges but derives the actor from auth.uid().
create or replace function public.process_profile_like(target uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  actor uuid := auth.uid();
  low_id uuid;
  high_id uuid;
  match_uuid uuid;
  conversation_uuid uuid;
begin
  if actor is null or target is null or actor=target then
    raise exception 'Invalid profile action';
  end if;
  if exists(select 1 from public.user_blocks b where
      (b.blocker_user_id=actor and b.blocked_user_id=target) or
      (b.blocker_user_id=target and b.blocked_user_id=actor)) then
    raise exception 'This profile is unavailable';
  end if;
  insert into public.profile_actions(actor_user_id,target_user_id,action)
  values(actor,target,'like')
  on conflict(actor_user_id,target_user_id,action) do nothing;

  if exists(select 1 from public.profile_actions
            where actor_user_id=target and target_user_id=actor and action='like') then
    low_id := least(actor,target);
    high_id := greatest(actor,target);
    insert into public.matches(user_one,user_two)
    values(low_id,high_id)
    on conflict(user_one,user_two) do update set status='active'
    returning id into match_uuid;

    insert into public.conversations(match_id) values(match_uuid)
    on conflict(match_id) do update set match_id=excluded.match_id
    returning id into conversation_uuid;

    insert into public.conversation_members(conversation_id,user_id)
    values(conversation_uuid,actor),(conversation_uuid,target)
    on conflict do nothing;

    insert into public.user_notifications(user_id,kind,title,body,payload)
    values(actor,'match','It’s a match','You have a mutual introduction.',jsonb_build_object('match_id',match_uuid)),
          (target,'match','It’s a match','You have a mutual introduction.',jsonb_build_object('match_id',match_uuid));
    return match_uuid;
  end if;
  return null;
end;
$$;
revoke all on function public.process_profile_like(uuid) from public;
grant execute on function public.process_profile_like(uuid) to authenticated;

grant select,insert,delete on public.profile_interests to authenticated;
grant select,insert,update,delete on public.compatibility_answers to authenticated;
grant select,insert,delete on public.profile_actions to authenticated;
grant select on public.matches, public.conversations, public.conversation_members, public.messages to authenticated;
grant insert,update on public.messages to authenticated;
grant select,insert,update on public.introduction_requests to authenticated;
grant select,insert,update,delete on public.user_notifications to authenticated;
grant select,insert,update on public.user_presence to authenticated;
notify pgrst, 'reload schema';
