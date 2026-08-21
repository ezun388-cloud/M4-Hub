-- M4 Hub v2 shared-data setup for Supabase
-- Run this once in Supabase -> SQL Editor -> New query.

create extension if not exists pgcrypto;

create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'M4',
  invite_code text unique not null,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.household_members (
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null,
  joined_at timestamptz not null default now(),
  primary key (household_id,user_id)
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  text text not null,
  person text not null default 'Anyone',
  done boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists public.shopping (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  text text not null,
  done boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists public.board_messages (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  person text not null,
  text text not null,
  created_at timestamptz not null default now()
);
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  date date not null,
  time time,
  text text not null,
  person text not null default 'Family',
  created_at timestamptz not null default now()
);

alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.tasks enable row level security;
alter table public.shopping enable row level security;
alter table public.board_messages enable row level security;
alter table public.events enable row level security;

create or replace function public.is_household_member(hid uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.household_members m where m.household_id=hid and m.user_id=auth.uid()); $$;

drop policy if exists "members read households" on public.households;
create policy "members read households" on public.households for select using (public.is_household_member(id));

drop policy if exists "members read membership" on public.household_members;
create policy "members read membership" on public.household_members for select using (user_id=auth.uid() or public.is_household_member(household_id));

do $$
declare t text;
begin
  foreach t in array array['tasks','shopping','board_messages','events']
  loop
    execute format('drop policy if exists "family select" on public.%I',t);
    execute format('drop policy if exists "family insert" on public.%I',t);
    execute format('drop policy if exists "family update" on public.%I',t);
    execute format('drop policy if exists "family delete" on public.%I',t);
    execute format('create policy "family select" on public.%I for select using (public.is_household_member(household_id))',t);
    execute format('create policy "family insert" on public.%I for insert with check (public.is_household_member(household_id))',t);
    execute format('create policy "family update" on public.%I for update using (public.is_household_member(household_id)) with check (public.is_household_member(household_id))',t);
    execute format('create policy "family delete" on public.%I for delete using (public.is_household_member(household_id))',t);
  end loop;
end $$;

create or replace function public.create_m4_household(p_name text, p_display_name text)
returns table(household_id uuid, invite_code text)
language plpgsql security definer set search_path=public
as $$
declare hid uuid; code text;
begin
  if auth.uid() is null then raise exception 'Not signed in'; end if;
  code := upper(substr(encode(gen_random_bytes(6),'hex'),1,8));
  insert into public.households(name,invite_code,created_by) values(coalesce(p_name,'M4'),code,auth.uid()) returning id into hid;
  insert into public.household_members(household_id,user_id,display_name) values(hid,auth.uid(),p_display_name);
  return query select hid,code;
end $$;

create or replace function public.join_m4_household(p_invite_code text, p_display_name text)
returns uuid
language plpgsql security definer set search_path=public
as $$
declare hid uuid;
begin
  if auth.uid() is null then raise exception 'Not signed in'; end if;
  select id into hid from public.households where invite_code=upper(trim(p_invite_code));
  if hid is null then raise exception 'Invite code not found'; end if;
  insert into public.household_members(household_id,user_id,display_name)
  values(hid,auth.uid(),p_display_name)
  on conflict(household_id,user_id) do update set display_name=excluded.display_name;
  return hid;
end $$;

grant execute on function public.create_m4_household(text,text) to authenticated;
grant execute on function public.join_m4_household(text,text) to authenticated;
grant execute on function public.is_household_member(uuid) to authenticated;

-- Enable Realtime for the four shared tables.
alter publication supabase_realtime add table public.tasks;
alter publication supabase_realtime add table public.shopping;
alter publication supabase_realtime add table public.board_messages;
alter publication supabase_realtime add table public.events;
