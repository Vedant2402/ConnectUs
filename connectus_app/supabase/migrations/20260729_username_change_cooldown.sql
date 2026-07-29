alter table public.profiles
add column if not exists username_changed_at timestamptz;

create or replace function public.enforce_username_change_cooldown()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.username is distinct from old.username then
    if old.username_changed_at is not null
       and old.username_changed_at > now() - interval '7 days' then
      raise exception
        'Username can only be changed once every 7 days. Try again after %.',
        old.username_changed_at + interval '7 days';
    end if;

    new.username_changed_at = now();
  else
    new.username_changed_at = old.username_changed_at;
  end if;

  return new;
end;
$$;

drop trigger if exists enforce_username_change_cooldown
on public.profiles;

create trigger enforce_username_change_cooldown
before update on public.profiles
for each row
execute function public.enforce_username_change_cooldown();

notify pgrst, 'reload schema';
