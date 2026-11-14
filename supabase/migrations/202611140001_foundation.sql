create extension if not exists pgcrypto;

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  business_type text not null default 'laundry',
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.outlets (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  code text not null,
  name text not null,
  address text,
  timezone text not null default 'Asia/Jakarta',
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now(),
  unique (organization_id, code),
  unique (organization_id, id)
);

create table if not exists public.organization_memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner', 'admin', 'cashier', 'production', 'payroll', 'finance')),
  status text not null default 'active' check (status in ('active', 'invited', 'suspended')),
  created_at timestamptz not null default now(),
  unique (organization_id, user_id)
);

create table if not exists public.membership_outlets (
  membership_id uuid not null references public.organization_memberships(id) on delete cascade,
  outlet_id uuid not null references public.outlets(id) on delete cascade,
  primary key (membership_id, outlet_id)
);

create index if not exists idx_outlets_organization on public.outlets(organization_id);
create index if not exists idx_memberships_user on public.organization_memberships(user_id);
create index if not exists idx_memberships_organization on public.organization_memberships(organization_id);

alter table public.organizations enable row level security;
alter table public.outlets enable row level security;
alter table public.organization_memberships enable row level security;
alter table public.membership_outlets enable row level security;

create or replace function public.is_organization_member(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.organization_memberships m
    where m.organization_id = target_organization_id
      and m.user_id = (select auth.uid())
      and m.status = 'active'
  );
$$;

revoke all on function public.is_organization_member(uuid) from public;
grant execute on function public.is_organization_member(uuid) to authenticated;

create policy "members can read their organizations"
on public.organizations for select to authenticated
using ((select public.is_organization_member(id)));

create policy "members can read organization outlets"
on public.outlets for select to authenticated
using ((select public.is_organization_member(organization_id)));

create policy "users can read own memberships"
on public.organization_memberships for select to authenticated
using (user_id = (select auth.uid()));

create policy "users can read own outlet scopes"
on public.membership_outlets for select to authenticated
using (exists (
  select 1 from public.organization_memberships m
  where m.id = membership_id and m.user_id = (select auth.uid())
));

revoke all on public.organizations, public.outlets, public.organization_memberships, public.membership_outlets from anon;
grant select on public.organizations, public.outlets, public.organization_memberships, public.membership_outlets to authenticated;
