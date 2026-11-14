create table public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  outlet_id uuid,
  sku text not null,
  name text not null,
  category text,
  unit text not null,
  current_stock numeric(18,3) not null default 0 check (current_stock >= 0),
  minimum_stock numeric(18,3) not null default 0 check (minimum_stock >= 0),
  unit_cost numeric(18,2) not null default 0 check (unit_cost >= 0),
  status text not null default 'active' check (status in ('active','inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(organization_id, sku),
  unique(organization_id, id),
  foreign key(organization_id, outlet_id) references public.outlets(organization_id, id)
);
create table public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  inventory_item_id uuid not null,
  movement_type text not null check (movement_type in ('purchase','usage','adjustment_in','adjustment_out','return')),
  quantity numeric(18,3) not null check (quantity > 0),
  balance_after numeric(18,3) not null check (balance_after >= 0),
  reference text,
  notes text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  foreign key(organization_id, inventory_item_id) references public.inventory_items(organization_id, id) on delete restrict
);
create index idx_inventory_items_org on public.inventory_items(organization_id,status);
create index idx_stock_movements_item on public.stock_movements(inventory_item_id,created_at desc);
alter table public.inventory_items enable row level security;
alter table public.stock_movements enable row level security;
create policy "members read inventory" on public.inventory_items for select to authenticated using ((select public.is_organization_member(organization_id)));
create policy "inventory managers manage items" on public.inventory_items for all to authenticated using ((select public.has_organization_role(organization_id,array['owner','admin','inventory']))) with check ((select public.has_organization_role(organization_id,array['owner','admin','inventory'])));
create policy "members read stock movements" on public.stock_movements for select to authenticated using ((select public.is_organization_member(organization_id)));
create policy "inventory staff create movements" on public.stock_movements for insert to authenticated with check ((select public.has_organization_role(organization_id,array['owner','admin','inventory','production'])));
grant select,insert,update on public.inventory_items to authenticated;
grant select,insert on public.stock_movements to authenticated;

create or replace function public.create_inventory_item(item_sku text,item_name text,item_unit text,opening_stock numeric,minimum_level numeric,item_unit_cost numeric,target_outlet_id uuid default null,item_category text default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare org_id uuid;new_id uuid;
begin
  select organization_id into org_id from public.organization_memberships where user_id=(select auth.uid()) and status='active' limit 1;
  if org_id is null or not public.has_organization_role(org_id,array['owner','admin','inventory']) then raise exception 'permission_denied'; end if;
  if length(trim(item_sku))<2 or length(trim(item_name))<2 or length(trim(item_unit))<1 or opening_stock<0 or minimum_level<0 or item_unit_cost<0 then raise exception 'invalid_inventory_item'; end if;
  if target_outlet_id is not null and not exists(select 1 from public.outlets where id=target_outlet_id and organization_id=org_id) then raise exception 'invalid_outlet'; end if;
  insert into public.inventory_items(organization_id,outlet_id,sku,name,category,unit,current_stock,minimum_stock,unit_cost)
  values(org_id,target_outlet_id,upper(trim(item_sku)),trim(item_name),nullif(trim(item_category),''),trim(item_unit),opening_stock,minimum_level,item_unit_cost) returning id into new_id;
  if opening_stock>0 then insert into public.stock_movements(organization_id,inventory_item_id,movement_type,quantity,balance_after,reference,created_by) values(org_id,new_id,'adjustment_in',opening_stock,opening_stock,'OPENING',(select auth.uid())); end if;
  return jsonb_build_object('id',new_id);
end;$$;
revoke all on function public.create_inventory_item(text,text,text,numeric,numeric,numeric,uuid,text) from public;
grant execute on function public.create_inventory_item(text,text,text,numeric,numeric,numeric,uuid,text) to authenticated;

create or replace function public.record_stock_movement(target_item_id uuid,movement_kind text,movement_quantity numeric,movement_reference text default null,movement_notes text default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare item public.inventory_items%rowtype;new_balance numeric(18,3);direction integer;
begin
  select * into item from public.inventory_items where id=target_item_id for update;
  if item.id is null then raise exception 'inventory_item_not_found'; end if;
  if not public.has_organization_role(item.organization_id,array['owner','admin','inventory','production']) then raise exception 'permission_denied'; end if;
  if movement_kind not in ('purchase','usage','adjustment_in','adjustment_out','return') or movement_quantity<=0 then raise exception 'invalid_movement'; end if;
  direction:=case when movement_kind in ('purchase','adjustment_in','return') then 1 else -1 end;
  new_balance:=item.current_stock+(movement_quantity*direction);
  if new_balance<0 then raise exception 'insufficient_stock'; end if;
  update public.inventory_items set current_stock=new_balance,updated_at=now() where id=item.id;
  insert into public.stock_movements(organization_id,inventory_item_id,movement_type,quantity,balance_after,reference,notes,created_by) values(item.organization_id,item.id,movement_kind,movement_quantity,new_balance,nullif(trim(movement_reference),''),nullif(trim(movement_notes),''),(select auth.uid()));
  return jsonb_build_object('balance',new_balance);
end;$$;
revoke all on function public.record_stock_movement(uuid,text,numeric,text,text) from public;
grant execute on function public.record_stock_movement(uuid,text,numeric,text,text) to authenticated;
