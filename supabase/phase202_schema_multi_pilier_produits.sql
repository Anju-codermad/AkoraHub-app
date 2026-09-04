-- ============================================================
-- AkoraHub - Patch Phase 202 : un produit peut appartenir à plusieurs
-- piliers (univers) — demande explicite de la propriétaire le
-- 04/09/2026 ("Je veux qu'il s'affiche dans les deux piliers").
--
-- Jusqu'ici `products.business_unit_id` était une colonne unique : un
-- produit n'appartenait qu'à UN SEUL pilier. Rencontré plusieurs fois
-- dans cette session pour des produits chimiques utiles à la fois à
-- Akora Pro (usage général) et à Akor'Eau (traitement de l'eau) — la
-- solution de contournement (fiche technique dupliquée par usage,
-- phases 195 et 201) fonctionne mais oblige à maintenir stock/prix
-- séparément pour un même produit physique.
--
-- Approche additive (ne touche PAS à `products.business_unit_id`, qui
-- reste le pilier PRINCIPAL du produit — utilisé pour la catégorie,
-- la fiche technique liée, etc.) : nouvelle table
-- `product_extra_business_units` listant les piliers SUPPLÉMENTAIRES
-- où un produit doit aussi apparaître. Un produit peut donc être
-- rattaché à N piliers au total (1 principal + ses extras), sans
-- dupliquer sa fiche.
--
-- Même schéma RLS que `categories` (phase6) : lecture publique,
-- écriture réservée au staff.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (create table if not exists, on conflict do nothing).
-- ============================================================

create table if not exists public.product_extra_business_units (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  business_unit_id uuid not null references public.business_units(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (product_id, business_unit_id)
);

create index if not exists idx_product_extra_business_units_product
  on public.product_extra_business_units(product_id);
create index if not exists idx_product_extra_business_units_unit
  on public.product_extra_business_units(business_unit_id);

alter table public.product_extra_business_units enable row level security;

drop policy if exists "product_extra_business_units_select_all" on public.product_extra_business_units;
create policy "product_extra_business_units_select_all" on public.product_extra_business_units
  for select using (true);

drop policy if exists "product_extra_business_units_write_staff" on public.product_extra_business_units;
create policy "product_extra_business_units_write_staff" on public.product_extra_business_units
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- ------------------------------------------------------------
-- Premier cas d'usage : relie "Hypochlorite de calcium 70%" (pilier
-- principal Akora Pro, où reste sa fiche technique) au pilier
-- supplémentaire Akor'Eau, pour qu'il s'affiche des deux côtés.
--
-- La fiche séparée créée par la Phase 201 ("Hypochlorite de calcium —
-- grade traitement de l'eau") est SUPERSÉDÉE par cette approche : ne
-- pas l'exécuter. Si elle l'a déjà été, la garder n'est pas gênant
-- (produit à part, fonctionnel) mais devient redondante — la
-- propriétaire peut la désactiver/supprimer manuellement si besoin.
-- ------------------------------------------------------------
insert into public.product_extra_business_units (product_id, business_unit_id)
select p.id, akoreau.id
from public.products p
join public.business_units akora_pro on akora_pro.id = p.business_unit_id
  and akora_pro.slug = 'matieres-premieres'
join public.business_units akoreau on akoreau.slug = 'akor-eau'
where p.name = 'Hypochlorite de calcium 70%'
on conflict (product_id, business_unit_id) do nothing;

-- Vérification :
-- select p.name, bu_principal.name as pilier_principal,
--        array_agg(bu_extra.name) as piliers_supplementaires
-- from public.products p
-- join public.business_units bu_principal on bu_principal.id = p.business_unit_id
-- left join public.product_extra_business_units peb on peb.product_id = p.id
-- left join public.business_units bu_extra on bu_extra.id = peb.business_unit_id
-- where p.name = 'Hypochlorite de calcium 70%'
-- group by p.name, bu_principal.name;
