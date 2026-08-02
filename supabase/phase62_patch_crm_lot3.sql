-- ============================================================
-- AkoraHub - Patch Phase 62 : CRM Lot 3/5 — statut VIP,
-- avantages accordés, note moyenne (avis), signalements liés au client
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- ⚠️ "Note moyenne + nombre d'avis" ne nécessite aucun changement SQL :
-- déjà calculable depuis `product_reviews` (lu depuis la Phase 60/61).
--
-- ⚠️ "Signalements liés au client" réutilise `post_reports` (Phase 47)
-- tel quel : cette table n'a pas de colonne "personne signalée", donc
-- on affiche côté app (1) les signalements déposés PAR ce client et
-- (2) les signalements reçus sur les publications de ce client — les
-- deux se déduisent de `post_reports` + `posts.author_id` sans
-- nouvelle colonne ni nouvelle table.
--
-- ⚠️ Comme pour `profiles.tags` (Phase 61), `is_vip` est modifiable
-- par la policy générique `profiles_update_own_or_staff` (pas de
-- policy dédiée par colonne dans ce schéma) — seule l'app UI réserve
-- ce bouton au staff.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Statut VIP — simple étiquette booléenne, activable/désactivable
-- par le staff depuis la fiche client.
-- ------------------------------------------------------------
alter table public.profiles
  add column if not exists is_vip boolean not null default false;

-- ------------------------------------------------------------
-- 2) Avantages accordés — historique manuel (remise exceptionnelle,
-- cadeau, livraison offerte, etc.). Il n'existe aujourd'hui aucun
-- système de coupons/promos automatisé dans le schéma ; ceci est donc
-- un simple journal que le staff remplit à la main, jamais visible du
-- client (même politique que `customer_notes`, Phase 61).
-- ------------------------------------------------------------
create table if not exists public.customer_benefits (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  granted_by uuid references public.profiles(id),
  description text not null,
  created_at timestamptz not null default now()
);

create index if not exists customer_benefits_customer_idx
  on public.customer_benefits (customer_id, created_at desc);

alter table public.customer_benefits enable row level security;

drop policy if exists "customer_benefits_staff_only" on public.customer_benefits;
create policy "customer_benefits_staff_only" on public.customer_benefits
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());
