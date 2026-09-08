-- ============================================================
-- AkoraHub - Patch Phase 224 : corrige 2 produits restés sur l'ancien
-- nom de catégorie "Arômes & parfums alimentaires" après le
-- renommage en "Arômes alimentaires" (phase 222) — la catégorie
-- elle-même avait bien été renommée, mais le texte products.category
-- de ces 2 produits (basculés, pas simplement liés) n'avait pas été
-- mis à jour en même temps. Repéré par la propriétaire après
-- vérification du résultat de la phase 222.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (update par nom exact, sans effet si déjà à jour).
-- ============================================================

update public.products p
set category = 'Arômes alimentaires'
where p.business_unit_id = (select id from public.business_units where slug = 'akora-nutrisource')
  and p.category = 'Arômes & parfums alimentaires';

-- Vérification : ne doit plus renvoyer aucune ligne avec l'ancien nom
select name, category
from public.products
where business_unit_id = (select id from public.business_units where slug = 'akora-nutrisource')
  and category = 'Arômes & parfums alimentaires';

-- Vérification : les 2 produits doivent maintenant apparaître ici
select name, category
from public.products
where business_unit_id = (select id from public.business_units where slug = 'akora-nutrisource')
  and category = 'Arômes alimentaires';
