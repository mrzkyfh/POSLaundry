create or replace function public.create_order(
  target_outlet_id uuid,
  target_customer_id uuid,
  order_items jsonb,
  completion_at timestamptz default null,
  order_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := (select auth.uid());
  target_organization_id uuid;
  new_order_id uuid;
  new_order_number text;
  item jsonb;
  selected_service public.services%rowtype;
  selected_price numeric(18,2);
  selected_quantity numeric(14,3);
  calculated_subtotal numeric(18,2) := 0;
begin
  if current_user_id is null then raise exception 'authentication_required'; end if;
  select organization_id into target_organization_id from public.outlets where id = target_outlet_id and status = 'active';
  if target_organization_id is null then raise exception 'invalid_outlet'; end if;
  if not public.has_organization_role(target_organization_id, array['owner','admin','cashier']) then raise exception 'permission_denied'; end if;
  if target_customer_id is not null and not exists (select 1 from public.customers where id = target_customer_id and organization_id = target_organization_id and status = 'active') then raise exception 'invalid_customer'; end if;
  if jsonb_typeof(order_items) <> 'array' or jsonb_array_length(order_items) = 0 then raise exception 'items_required'; end if;

  new_order_number := 'LDY-' || to_char(clock_timestamp(), 'YYMMDD-HH24MISS') || '-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 4));
  insert into public.orders(organization_id, outlet_id, customer_id, order_number, estimated_completion_at, notes, created_by)
  values(target_organization_id, target_outlet_id, target_customer_id, new_order_number, completion_at, nullif(trim(order_notes), ''), current_user_id)
  returning id into new_order_id;

  for item in select * from jsonb_array_elements(order_items)
  loop
    selected_quantity := (item->>'quantity')::numeric;
    if selected_quantity <= 0 then raise exception 'invalid_quantity'; end if;
    select * into selected_service from public.services where id = (item->>'service_id')::uuid and organization_id = target_organization_id and status = 'active';
    if selected_service.id is null then raise exception 'invalid_service'; end if;
    select price into selected_price from public.service_prices
      where organization_id = target_organization_id and service_id = selected_service.id
        and (outlet_id = target_outlet_id or outlet_id is null)
        and speed_type = coalesce(nullif(item->>'speed_type', ''), 'regular')
        and effective_from <= now() and (effective_until is null or effective_until > now())
      order by (outlet_id is not null) desc, effective_from desc limit 1;
    if selected_price is null then raise exception 'price_not_found_for_service_%', selected_service.code; end if;
    insert into public.order_items(organization_id, order_id, service_id, service_name_snapshot, unit, quantity, unit_price)
    values(target_organization_id, new_order_id, selected_service.id, selected_service.name, selected_service.unit, selected_quantity, selected_price);
    calculated_subtotal := calculated_subtotal + (selected_quantity * selected_price);
  end loop;

  update public.orders set subtotal = calculated_subtotal, grand_total = calculated_subtotal where id = new_order_id;
  return jsonb_build_object('id', new_order_id, 'order_number', new_order_number, 'grand_total', calculated_subtotal);
end;
$$;

revoke all on function public.create_order(uuid, uuid, jsonb, timestamptz, text) from public;
grant execute on function public.create_order(uuid, uuid, jsonb, timestamptz, text) to authenticated;
