-- ============================================================
-- AkoraHub - Patch Phase 57 : Profil client — adresses de livraison
-- multiples, gérables (Lot 4).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- ⚠️ Limite assumée : ce script ajoute uniquement le carnet d'adresses
-- (ajouter/modifier/supprimer/définir par défaut) — le checkout
-- (cart_tab.dart) continue d'utiliser son champ de saisie libre actuel,
-- non branché sur cette table dans ce lot (chantier séparé, touche le
-- flux de commande en production, à faire avec plus de prudence).
--
-- ⚠️ Script idempotent : relancer en entier depuis le début est sans
-- risque.
-- ============================================================

create table if not exists public.delivery_addresses (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  label text not null,
  address text not null,
  latitude double precision,
  longitude double precision,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists delivery_addresses_customer_idx
  on public.delivery_addresses (customer_id);

alter table public.delivery_addresses enable row level security;

drop policy if exists "delivery_addresses_select_own" on public.delivery_addresses;
create policy "delivery_addresses_select_own" on public.delivery_addresses
  for select using (customer_id = auth.uid());

drop policy if exists "delivery_addresses_insert_own" on public.delivery_addresses;
create policy "delivery_addresses_insert_own" on public.delivery_addresses
  for insert with check (customer_id = auth.uid());

drop policy if exists "delivery_addresses_update_own" on public.delivery_addresses;
create policy "delivery_addresses_update_own" on public.delivery_addresses
  for update using (customer_id = auth.uid())
  with check (customer_id = auth.uid());

drop policy if exists "delivery_addresses_delete_own" on public.delivery_addresses;
create policy "delivery_addresses_delete_own" on public.delivery_addresses
  for delete using (customer_id = auth.uid());
