create table public.order_status_history (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  order_id uuid not null,
  status text not null check (status in ('received','sorting','washing','drying','ironing','quality_control','ready','completed','cancelled')),
  changed_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  foreign key (organization_id, order_id) references public.orders(organization_id, id) on delete cascade
);
create index idx_order_status_history_order on public.order_status_history(order_id, created_at);
alter table public.order_status_history enable row level security;
create policy "members read order status history" on public.order_status_history for select to authenticated using ((select public.is_organization_member(organization_id)));
create policy "staff manage order status history" on public.order_status_history for all to authenticated using ((select public.has_organization_role(organization_id, array['owner','admin','cashier','production']))) with check ((select public.has_organization_role(organization_id, array['owner','admin','cashier','production'])));
grant select, insert on public.order_status_history to authenticated;

create or replace function public.capture_initial_order_status()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.order_status_history(organization_id, order_id, status, changed_by)
  values(new.organization_id, new.id, new.production_status, new.created_by);
  return new;
end;
$$;
create trigger orders_capture_initial_status after insert on public.orders for each row execute function public.capture_initial_order_status();

create or replace function public.update_order_status(target_order_id uuid, next_status text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare target_order public.orders%rowtype;
begin
  select * into target_order from public.orders where id = target_order_id for update;
  if target_order.id is null then raise exception 'order_not_found'; end if;
  if not public.has_organization_role(target_order.organization_id, array['owner','admin','cashier','production']) then raise exception 'permission_denied'; end if;
  if next_status not in ('received','sorting','washing','drying','ironing','quality_control','ready','completed','cancelled') then raise exception 'invalid_status'; end if;
  if target_order.production_status = next_status then return jsonb_build_object('status', next_status); end if;
  update public.orders set production_status = next_status, pickup_status = case when next_status = 'ready' then 'ready' when next_status = 'completed' then 'picked_up' else pickup_status end, updated_at = now() where id = target_order_id;
  insert into public.order_status_history(organization_id, order_id, status, changed_by) values(target_order.organization_id, target_order.id, next_status, (select auth.uid()));
  return jsonb_build_object('status', next_status);
end;
$$;
revoke all on function public.update_order_status(uuid, text) from public;
grant execute on function public.update_order_status(uuid, text) to authenticated;

create or replace function public.record_order_payment(target_order_id uuid, payment_amount numeric, payment_method text, payment_key text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare target_order public.orders%rowtype; paid_total numeric(18,2); new_payment_id uuid; new_status text;
begin
  select * into target_order from public.orders where id = target_order_id for update;
  if target_order.id is null then raise exception 'order_not_found'; end if;
  if not public.has_organization_role(target_order.organization_id, array['owner','admin','cashier','finance']) then raise exception 'permission_denied'; end if;
  if payment_method not in ('cash','transfer','qris','card','other') or payment_amount <= 0 then raise exception 'invalid_payment'; end if;
  select coalesce(sum(pa.amount),0) into paid_total from public.payment_allocations pa join public.payments p on p.id = pa.payment_id where pa.order_id = target_order_id and p.status = 'succeeded';
  if payment_amount > target_order.grand_total - paid_total then raise exception 'payment_exceeds_remaining_balance'; end if;
  insert into public.payments(organization_id, outlet_id, amount, method, status, paid_at, idempotency_key, created_by)
  values(target_order.organization_id, target_order.outlet_id, payment_amount, payment_method, 'succeeded', now(), payment_key, (select auth.uid())) returning id into new_payment_id;
  insert into public.payment_allocations(organization_id, payment_id, order_id, amount) values(target_order.organization_id, new_payment_id, target_order.id, payment_amount);
  paid_total := paid_total + payment_amount;
  new_status := case when paid_total >= target_order.grand_total then 'paid' when paid_total > 0 then 'partially_paid' else 'unpaid' end;
  update public.orders set payment_status = new_status, updated_at = now() where id = target_order_id;
  return jsonb_build_object('payment_id', new_payment_id, 'paid_total', paid_total, 'payment_status', new_status);
end;
$$;
revoke all on function public.record_order_payment(uuid, numeric, text, text) from public;
grant execute on function public.record_order_payment(uuid, numeric, text, text) to authenticated;
