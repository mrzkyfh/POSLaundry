create or replace function public.create_service_with_price(
  service_code text,
  service_name text,
  service_unit text,
  service_price numeric,
  target_outlet_id uuid default null,
  service_speed text default 'regular'
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_organization_id uuid;
  new_service_id uuid;
begin
  select organization_id into target_organization_id
  from public.organization_memberships
  where user_id = (select auth.uid()) and status = 'active'
  limit 1;
  if target_organization_id is null then raise exception 'membership_required'; end if;
  if not public.has_organization_role(target_organization_id, array['owner','admin']) then raise exception 'permission_denied'; end if;
  if length(trim(service_code)) < 2 or length(trim(service_name)) < 2 then raise exception 'invalid_service'; end if;
  if service_unit not in ('kg','pcs') or service_speed not in ('regular','express') or service_price < 0 then raise exception 'invalid_price_configuration'; end if;
  if target_outlet_id is not null and not exists(select 1 from public.outlets where id = target_outlet_id and organization_id = target_organization_id) then raise exception 'invalid_outlet'; end if;
  insert into public.services(organization_id, code, name, unit)
  values(target_organization_id, upper(trim(service_code)), trim(service_name), service_unit)
  returning id into new_service_id;
  insert into public.service_prices(organization_id, service_id, outlet_id, speed_type, price)
  values(target_organization_id, new_service_id, target_outlet_id, service_speed, service_price);
  return jsonb_build_object('id', new_service_id);
end;
$$;

revoke all on function public.create_service_with_price(text, text, text, numeric, uuid, text) from public;
grant execute on function public.create_service_with_price(text, text, text, numeric, uuid, text) to authenticated;
