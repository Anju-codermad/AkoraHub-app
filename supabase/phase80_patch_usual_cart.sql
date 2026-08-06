-- ============================================================
-- AkoraHub - Patch Phase 80 : "Mon panier habituel"
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : sur demande ("Mon panier habituel", liste "praticable" du
-- 06/08) — une liste de produits + quantités que le client compose une
-- fois (icône sur la fiche produit) et recharge en un clic depuis
-- l'écran dédié, sans repasser par tout le catalogue. Distinct de :
-- - `favorites` (simple étoile, pas de quantité) ;
-- - `recurring_orders` (recommande AUTOMATIQUEMENT à intervalle fixe) —
--   "Mon panier habituel" n'a rien d'automatique, juste un raccourci
--   manuel.
-- ============================================================

create table if not exists public.usual_cart_items (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  quantity int not null default 1,
  created_at timestamptz not null default now(),
  unique (customer_id, product_id)
);

alter table public.usual_cart_items enable row level security;

drop policy if exists "usual_cart_items_own_select" on public.usual_cart_items;
create policy "usual_cart_items_own_select" on public.usual_cart_items
  for select using (auth.uid() = customer_id);

drop policy if exists "usual_cart_items_own_insert" on public.usual_cart_items;
create policy "usual_cart_items_own_insert" on public.usual_cart_items
  for insert with check (auth.uid() = customer_id);

drop policy if exists "usual_cart_items_own_update" on public.usual_cart_items;
create policy "usual_cart_items_own_update" on public.usual_cart_items
  for update using (auth.uid() = customer_id);

drop policy if exists "usual_cart_items_own_delete" on public.usual_cart_items;
create policy "usual_cart_items_own_delete" on public.usual_cart_items
  for delete using (auth.uid() = customer_id);
