-- Conversation participants may see participant IDs for conversations they belong to.
-- This is needed to render the other matched member in the inbox; it grants no Wali access.
drop policy if exists "conversation_members_read" on public.conversation_members;
create policy "conversation_members_read" on public.conversation_members
for select to authenticated
using (exists(
  select 1 from public.conversation_members mine
  where mine.conversation_id=conversation_members.conversation_id
    and mine.user_id=auth.uid()
));
