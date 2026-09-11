-- ============================================================
-- AkoraHub - Patch Phase 239 : resynchronise products.use_cases pour
-- "Bicarbonate de soude" après l'ajout des 2 nouveaux usages
-- (détergents industriels, agriculture) en phase238 — même décalage
-- que la phase237 : le trigger sync_product_from_raw_material ne
-- remplit use_cases qu'à la création du produit.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (recalcule toujours la valeur exacte attendue).
-- ============================================================

do $$
declare
  v_academie_id uuid;
  v_usages text[];
begin
  select a.id into v_academie_id
    from public.matieres_premieres_academie a
    join public.raw_materials rm on rm.id = a.matiere_premiere_id
    where rm.name = 'Bicarbonate de sodium technique';

  if v_academie_id is null then
    raise exception 'Fiche Académie introuvable pour "Bicarbonate de sodium technique" — exécuter d''abord la phase 236.';
  end if;

  select array_agg(distinct u.domaine_application order by u.domaine_application)
    into v_usages
    from public.matieres_premieres_usages u
    where u.academie_id = v_academie_id;

  update public.products
  set use_cases = coalesce(v_usages, '{}')
  where raw_material_id = (
    select matiere_premiere_id from public.matieres_premieres_academie where id = v_academie_id
  );
end $$;

-- Vérification :
-- select name, use_cases from public.products where name = 'Bicarbonate de sodium technique';
