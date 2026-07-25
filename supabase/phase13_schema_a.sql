-- ============================================================
-- Akora Fanadiovana / AkoraHub - Schéma Phase 13, Partie A (obligatoire)
-- Commande récurrente automatique : le client configure un panier type +
-- une fréquence, une vraie commande est recréée automatiquement à chaque
-- échéance (via la fonction ci-dessous, appelée par pg_cron si disponible
-- — voir Partie B — sinon exécutable manuellement par un Admin).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

create table if not exists public.recurring_orders (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  frequency_days integer not null default 30,
  next_run_date date not null default current_date,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.recurring_order_items (
  id uuid primary key default gen_random_uuid(),
  recurring_order_id uuid not null references public.recurring_orders(id) on delete cascade,
  product_id uuid references public.products(id),
  product_name text not null,
  quantity numeric not null,
  unit_price numeric not null
);

alter table public.recurring_orders enable row level security;
alter table public.recurring_order_items enable row level security;

drop policy if exists "recurring_orders_select_own_or_staff" on public.recurring_orders;
create policy "recurring_orders_select_own_or_staff" on public.recurring_orders
  for select using (customer_id = auth.uid() or public.current_role_is_staff());

drop policy if exists "recurring_orders_insert_own" on public.recurring_orders;
create policy "recurring_orders_insert_own" on public.recurring_orders
  for insert with check (customer_id = auth.uid());

drop policy if exists "recurring_orders_update_own_or_staff" on public.recurring_orders;
create policy "recurring_orders_update_own_or_staff" on public.recurring_orders
  for update using (customer_id = auth.uid() or public.current_role_is_staff());

drop policy if exists "recurring_orders_delete_own" on public.recurring_orders;
create policy "recurring_orders_delete_own" on public.recurring_orders
  for delete using (customer_id = auth.uid());

drop policy if exists "recurring_order_items_select_related" on public.recurring_order_items;
create policy "recurring_order_items_select_related" on public.recurring_order_items
  for select using (
    exists (select 1 from public.recurring_orders r where r.id = recurring_order_id
            and (r.customer_id = auth.uid() or public.current_role_is_staff()))
  );

drop policy if exists "recurring_order_items_insert_related" on public.recurring_order_items;
create policy "recurring_order_items_insert_related" on public.recurring_order_items
  for insert with check (
    exists (select 1 from public.recurring_orders r where r.id = recurring_order_id
            and r.customer_id = auth.uid())
  );

drop policy if exists "recurring_order_items_delete_related" on public.recurring_order_items;
create policy "recurring_order_items_delete_related" on public.recurring_order_items
  for delete using (
    exists (select 1 from public.recurring_orders r where r.id = recurring_order_id
            and r.customer_id = auth.uid())
  );

-- Fonction principale : parcourt les commandes récurrentes échues et
-- recrée une vraie commande (orders + order_items) pour chacune, puis
-- avance next_run_date à la prochaine échéance.
create or replace function public.process_recurring_orders()
returns integer as $$
declare
  rec record;
  new_order_id uuid;
  new_order_number text;
  total numeric;
begin
  for rec in
    select * from public.recurring_orders
    where active = true and next_run_date <= current_date
  loop
    select coalesce(sum(quantity * unit_price), 0) into total
    from public.recurring_order_items
    where recurring_order_id = rec.id;

    new_order_number := 'CMD-REC-' || to_char(now(), 'YYYYMMDDHH24MISS');

    insert into public.orders (order_number, customer_id, total_amount)
    values (new_order_number, rec.customer_id, total)
    returning id into new_order_id;

    insert into public.order_items
      (order_id, product_id, product_name, quantity, unit_price)
    select new_order_id, product_id, product_name, quantity, unit_price
    from public.recurring_order_items
    where recurring_order_id = rec.id;

    update public.recurring_orders
    set next_run_date = current_date + (rec.frequency_days || ' days')::interval
    where id = rec.id;
  end loop;

  return 1;
end;
$$ language plpgsql security definer;
