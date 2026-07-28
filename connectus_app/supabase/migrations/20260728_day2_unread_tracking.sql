-- Day 2: unread message counts and last-read tracking.

create or replace function public.mark_conversation_as_read(
  requested_conversation_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  newest_message_id uuid;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if not public.is_conversation_member(requested_conversation_id) then
    raise exception 'You are not a member of this conversation';
  end if;

  select message.id
  into newest_message_id
  from public.messages as message
  where message.conversation_id = requested_conversation_id
    and message.deleted_at is null
  order by message.created_at desc, message.id desc
  limit 1;

  update public.conversation_members
  set last_read_message_id = newest_message_id
  where conversation_id = requested_conversation_id
    and user_id = current_user_id;
end;
$$;

grant execute
on function public.mark_conversation_as_read(uuid)
to authenticated;

create or replace function public.get_unread_conversation_counts()
returns table (
  conversation_id uuid,
  unread_count bigint
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    membership.conversation_id,
    count(message.id)::bigint as unread_count
  from public.conversation_members as membership
  left join public.messages as last_read_message
    on last_read_message.id = membership.last_read_message_id
  join public.messages as message
    on message.conversation_id = membership.conversation_id
   and message.sender_id <> membership.user_id
   and message.deleted_at is null
   and (
     membership.last_read_message_id is null
     or message.created_at > last_read_message.created_at
   )
  where membership.user_id = auth.uid()
  group by membership.conversation_id;
$$;

grant execute
on function public.get_unread_conversation_counts()
to authenticated;

drop policy if exists
  "Users can update their own conversation membership"
on public.conversation_members;

create policy "Users can update their own conversation membership"
on public.conversation_members
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

grant update
on public.conversation_members
to authenticated;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'conversation_members'
  ) then
    alter publication supabase_realtime
    add table public.conversation_members;
  end if;
end;
$$;

notify pgrst, 'reload schema';
