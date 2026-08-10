-- ============================================================
-- AkoraHub - Patch Phase 148 : compléter automatiquement le catalogue
-- "Akora Pro" à partir des données déjà saisies dans l'Académie
-- (matières premières + fiches techniques)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (09/08, demande explicite) : chaque produit devrait avoir
-- sa description automatiquement, et l'utilisatrice veut que TOUTE la
-- liste de produits du catalogue soit complétée pour n'avoir plus
-- qu'à ajouter photo + prix ensuite. Trois étapes, toutes non
-- destructives (aucune ligne existante n'est écrasée si elle a déjà
-- une valeur) :
--
-- 1) Relie les produits déjà existants (ex. "Soude Caustique (NaOH)",
--    "Decyl Glucoside") à leur fiche Académie par correspondance
--    exacte nom + catégorie, uniquement là où `raw_material_id` est
--    encore vide.
-- 2) Complète la description des produits dont la description est
--    vide, à partir de la fiche Académie liée (`particularite`, ou
--    `raw_materials.description` en repli).
-- 3) Crée un produit "Brouillon" (invisible côté client, voir
--    phase147/product_management_real.dart) pour chaque matière
--    première Académie qui n'a encore AUCUN produit correspondant —
--    nom, catégorie, pilier, description et usages généraux
--    pré-remplis ; prix à 0 et stock à 0 (valeurs par défaut) en
--    attendant que l'utilisatrice ajoute photo + prix et publie.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Lier les produits existants non encore liés
-- ------------------------------------------------------------
update public.products p
set raw_material_id = rm.id
from public.raw_materials rm
where p.raw_material_id is null
  and p.name = rm.name
  and p.category = rm.category_name;

-- ------------------------------------------------------------
-- 2) Compléter les descriptions vides des produits déjà liés
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
-- 3) Créer les produits manquants (brouillon) pour les matières
-- premières Académie qui n'ont encore aucun produit correspondant.
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
