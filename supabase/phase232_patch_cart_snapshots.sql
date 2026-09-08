-- ============================================================
-- AkoraHub - Patch Phase 232 : paniers abandonnés (site web)
--
-- Contexte (08/09) : le panier du site (assets/cart.js) est entièrement
-- côté navigateur (localStorage) — rien côté serveur ne permet de
-- repérer un client qui remplit son panier sans finaliser, pour une
-- relance commerciale (WhatsApp, e-mail).
--
-- Miroir serveur du panier UNIQUEMENT pour un client CONNECTÉ (sans
-- compte, aucun moyen de le recontacter — un instantané anonyme ne
-- serait pas actionnable pour ce cas d'usage). Une seule ligne par
-- client (upsert sur customer_id), écrasée à chaque changement de
-- panier (panier.html), supprimée dès que le panier se vide ou qu'une
-- commande est passée — voir panier.html (syncCartSnapshotDebounced/
-- upsertCartSnapshot/deleteCartSnapshot).
--
-- customer_id référence directement `profiles` (pas `auth.users`),
-- comme `orders.customer_id` (phase1_schema.sql) — permet à PostgREST
-- d'embarquer profiles(full_name,phone) directement dans le SELECT du
-- rapport admin, sans requête séparée.
--
-- "Abandonné" = une ligne dont `updated_at` date de plus de quelques
-- heures — calculé côté rapport (admin-visites.html), pas ici.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New
-- query. Idempotent (create if not exists).
-- ============================================================

create table if not exists public.cart_snapshots (
  customer_id uuid primary key references public.profiles(id) on delete cascade,
  items jsonb not null,
  total_amount numeric not null default 0,
  updated_at timestamptz not null default now()
);

create index if not exists cart_snapshots_updated_at_idx on public.cart_snapshots (updated_at);

alter table public.cart_snapshots enable row level security;

drop policy if exists "cart_snapshots_insert_own" on public.cart_snapshots;
create policy "cart_snapshots_insert_own" on public.cart_snapshots
  for insert with check (auth.uid() = customer_id);

drop policy if exists "cart_snapshots_update_own" on public.cart_snapshots;
create policy "cart_snapshots_update_own" on public.cart_snapshots
  for update using (auth.uid() = customer_id) with check (auth.uid() = customer_id);

drop policy if exists "cart_snapshots_delete_own" on public.cart_snapshots;
create policy "cart_snapshots_delete_own" on public.cart_snapshots
  for delete using (auth.uid() = customer_id);

drop policy if exists "cart_snapshots_select_staff" on public.cart_snapshots;
create policy "cart_snapshots_select_staff" on public.cart_snapshots
  for select using (public.current_role_is_staff());

-- Rafraîchit updated_at à chaque upsert (POST avec on_conflict=customer_id
-- ne déclenche pas le default, seul un vrai INSERT le fait).
create or replace function public.touch_cart_snapshot_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists touch_cart_snapshot_updated_at_trigger on public.cart_snapshots;
create trigger touch_cart_snapshot_updated_at_trigger
  before update on public.cart_snapshots
  for each row execute function public.touch_cart_snapshot_updated_at();

-- Vérification : la table existe, RLS active, 4 policies.
select policyname, cmd from pg_policies where tablename = 'cart_snapshots';
