-- ============================================================
-- AkoraHub - Patch Phase 158 : rattraper les matières premières
-- Académie ajoutées depuis phase148 (ex. phase149 "Oxydants & Agents
-- de Blanchiment") qui n'ont encore aucun produit correspondant dans
-- le catalogue Akora Pro — même logique que phase148 (générique, pas
-- spécifique à une catégorie), à rejouer chaque fois que de nouvelles
-- matières premières sont ajoutées à l'Académie.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Non destructif et rejouable : chaque étape est gardée par un
-- `where not exists`, aucune ligne existante n'est modifiée.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Lier les produits existants non encore liés (nom + catégorie
-- identiques à une matière première Académie).
-- ------------------------------------------------------------
update public.products p
set raw_material_id = rm.id
from public.raw_materials rm
where p.raw_material_id is null
  and p.name = rm.name
  and p.category = rm.category_name;

-- ------------------------------------------------------------
-- 2) Compléter les descriptions vides des produits déjà liés.
-- ------------------------------------------------------------
update public.products p
set description = coalesce(
  nullif(trim(a.particularite), ''),
  nullif(trim(rm.description), '')
)
from public.raw_materials rm
left join public.matieres_premieres_academie a
  on a.matiere_premiere_id = rm.id
where p.raw_material_id = rm.id
  and (p.description is null or trim(p.description) = '')
  and coalesce(nullif(trim(a.particularite), ''), nullif(trim(rm.description), '')) is not null;

-- ------------------------------------------------------------
-- 3) Créer les produits manquants (brouillon) pour toute matière
-- première Académie qui n'a encore aucun produit correspondant —
-- couvre notamment les 5 matières de phase149 (percarbonate de
-- sodium, perborate de sodium monohydraté, TAED, persulfate de
-- sodium, azurant optique).
-- ------------------------------------------------------------
insert into public.products (
  business_unit_id, category, name, description, use_cases,
  raw_material_id, visibility
)
select
  rm.business_unit_id,
  rm.category_name,
  rm.name,
  coalesce(nullif(trim(a.particularite), ''), nullif(trim(rm.description), '')),
  coalesce(
    (
      select array_agg(distinct u.domaine_application order by u.domaine_application)
      from public.matieres_premieres_usages u
      where u.academie_id = a.id
    ),
    '{}'
  ),
  rm.id,
  false -- brouillon : invisible côté client tant que non publié
from public.raw_materials rm
left join public.matieres_premieres_academie a
  on a.matiere_premiere_id = rm.id
where not exists (
  select 1 from public.products p where p.raw_material_id = rm.id
)
and not exists (
  select 1 from public.products p2
  where p2.name = rm.name and p2.category = rm.category_name
);
