create or replace function public.has_organization_role(target_organization_id uuid, allowed_roles text[])
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
      and m.role = any(allowed_roles)
  );
$$;

revoke all on function public.has_organization_role(uuid, text[]) from public;
grant execute on function public.has_organization_role(uuid, text[]) to authenticated;

create or replace function public.bootstrap_owner(organization_name text, outlet_name text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := (select auth.uid());
  new_organization_id uuid;
  new_outlet_id uuid;
  new_membership_id uuid;
begin
  if current_user_id is null then
    raise exception 'authentication_required';
  end if;
  if exists (select 1 from public.organization_memberships where user_id = current_user_id) then
    raise exception 'membership_already_exists';
  end if;
  if length(trim(organization_name)) < 2 or length(trim(outlet_name)) < 2 then
    raise exception 'invalid_name';
  end if;

  insert into public.organizations(name) values (trim(organization_name)) returning id into new_organization_id;
  insert into public.outlets(organization_id, code, name)
    values (new_organization_id, 'MAIN', trim(outlet_name)) returning id into new_outlet_id;
  insert into public.organization_memberships(organization_id, user_id, role)
    values (new_organization_id, current_user_id, 'owner') returning id into new_membership_id;
  insert into public.membership_outlets(membership_id, outlet_id) values (new_membership_id, new_outlet_id);

  return jsonb_build_object('organization_id', new_organization_id, 'outlet_id', new_outlet_id);
end;
$$;

revoke all on function public.bootstrap_owner(text, text) from public;
grant execute on function public.bootstrap_owner(text, text) to authenticated;

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  name text not null,
  phone text,
  email text,
  notes text,
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, id)
);

create table public.services (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  code text not null,
  name text not null,
  unit text not null check (unit in ('kg', 'pcs')),
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now(),
  unique (organization_id, code),
  unique (organization_id, id)
);

create table public.service_prices (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  service_id uuid not null,
  outlet_id uuid,
  speed_type text not null default 'regular' check (speed_type in ('regular', 'express')),
  price numeric(18,2) not null check (price >= 0),
  effective_from timestamptz not null default now(),
  effective_until timestamptz,
  foreign key (organization_id, service_id) references public.services(organization_id, id),
  foreign key (organization_id, outlet_id) references public.outlets(organization_id, id),
  check (effective_until is null or effective_until > effective_from)
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  outlet_id uuid not null,
  customer_id uuid,
  order_number text not null,
  subtotal numeric(18,2) not null default 0 check (subtotal >= 0),
  discount_total numeric(18,2) not null default 0 check (discount_total >= 0),
  tax_total numeric(18,2) not null default 0 check (tax_total >= 0),
  grand_total numeric(18,2) not null default 0 check (grand_total >= 0),
  production_status text not null default 'received' check (production_status in ('received','sorting','washing','drying','ironing','quality_control','ready','completed','cancelled')),
  payment_status text not null default 'unpaid' check (payment_status in ('unpaid','partially_paid','paid','refunded')),
  pickup_status text not null default 'pending' check (pickup_status in ('pending','ready','picked_up','delivered')),
  estimated_completion_at timestamptz,
  notes text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (outlet_id, order_number),
  unique (organization_id, id),
  foreign key (organization_id, outlet_id) references public.outlets(organization_id, id),
  foreign key (organization_id, customer_id) references public.customers(organization_id, id)
);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  order_id uuid not null,
  service_id uuid not null,
  service_name_snapshot text not null,
  unit text not null check (unit in ('kg', 'pcs')),
  quantity numeric(14,3) not null check (quantity > 0),
  unit_price numeric(18,2) not null check (unit_price >= 0),
  line_total numeric(18,2) generated always as (quantity * unit_price) stored,
  foreign key (organization_id, order_id) references public.orders(organization_id, id) on delete cascade,
  foreign key (organization_id, service_id) references public.services(organization_id, id)
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  outlet_id uuid not null,
  amount numeric(18,2) not null check (amount > 0),
  method text not null check (method in ('cash','transfer','qris','card','other')),
  status text not null default 'succeeded' check (status in ('pending','succeeded','failed','reversed')),
  paid_at timestamptz,
  idempotency_key text not null,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique (organization_id, idempotency_key),
  unique (organization_id, id),
  foreign key (organization_id, outlet_id) references public.outlets(organization_id, id)
);

create table public.payment_allocations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  payment_id uuid not null,
  order_id uuid not null,
  amount numeric(18,2) not null check (amount > 0),
  created_at timestamptz not null default now(),
  unique (payment_id, order_id),
  foreign key (organization_id, payment_id) references public.payments(organization_id, id) on delete cascade,
  foreign key (organization_id, order_id) references public.orders(organization_id, id)
);

create index idx_customers_org_phone on public.customers(organization_id, phone);
create index idx_services_organization on public.services(organization_id);
create index idx_orders_org_created on public.orders(organization_id, created_at desc);
create index idx_orders_outlet_status on public.orders(outlet_id, production_status);
create index idx_order_items_order on public.order_items(order_id);
create index idx_payments_org_paid on public.payments(organization_id, paid_at desc);
create index idx_payment_allocations_order on public.payment_allocations(order_id);

alter table public.customers enable row level security;
alter table public.services enable row level security;
alter table public.service_prices enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.payments enable row level security;
alter table public.payment_allocations enable row level security;

create policy "members read customers" on public.customers for select to authenticated using ((select public.is_organization_member(organization_id)));
create policy "staff manage customers" on public.customers for all to authenticated using ((select public.has_organization_role(organization_id, array['owner','admin','cashier']))) with check ((select public.has_organization_role(organization_id, array['owner','admin','cashier'])));
create policy "members read services" on public.services for select to authenticated using ((select public.is_organization_member(organization_id)));
create policy "admin manage services" on public.services for all to authenticated using ((select public.has_organization_role(organization_id, array['owner','admin']))) with check ((select public.has_organization_role(organization_id, array['owner','admin'])));
create policy "members read prices" on public.service_prices for select to authenticated using ((select public.is_organization_member(organization_id)));
create policy "admin manage prices" on public.service_prices for all to authenticated using ((select public.has_organization_role(organization_id, array['owner','admin']))) with check ((select public.has_organization_role(organization_id, array['owner','admin'])));
create policy "members read orders" on public.orders for select to authenticated using ((select public.is_organization_member(organization_id)));
create policy "staff manage orders" on public.orders for all to authenticated using ((select public.has_organization_role(organization_id, array['owner','admin','cashier','production']))) with check ((select public.has_organization_role(organization_id, array['owner','admin','cashier','production'])));
create policy "members read order items" on public.order_items for select to authenticated using ((select public.is_organization_member(organization_id)));
create policy "cashier manage order items" on public.order_items for all to authenticated using ((select public.has_organization_role(organization_id, array['owner','admin','cashier']))) with check ((select public.has_organization_role(organization_id, array['owner','admin','cashier'])));
create policy "authorized read payments" on public.payments for select to authenticated using ((select public.has_organization_role(organization_id, array['owner','admin','cashier','finance'])));
create policy "authorized manage payments" on public.payments for all to authenticated using ((select public.has_organization_role(organization_id, array['owner','admin','cashier','finance']))) with check ((select public.has_organization_role(organization_id, array['owner','admin','cashier','finance'])));
create policy "authorized read allocations" on public.payment_allocations for select to authenticated using ((select public.has_organization_role(organization_id, array['owner','admin','cashier','finance'])));
create policy "authorized manage allocations" on public.payment_allocations for all to authenticated using ((select public.has_organization_role(organization_id, array['owner','admin','cashier','finance']))) with check ((select public.has_organization_role(organization_id, array['owner','admin','cashier','finance'])));

revoke all on public.customers, public.services, public.service_prices, public.orders, public.order_items, public.payments, public.payment_allocations from anon;
grant select, insert, update on public.customers, public.services, public.service_prices, public.orders, public.order_items, public.payments, public.payment_allocations to authenticated;
