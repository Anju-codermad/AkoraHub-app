-- ============================================================
-- AkoraHub - Patch Phase 199 : resynchronise products.use_cases pour
-- TOUS les produits du pilier Akor'Eau, pas seulement le Sulfate
-- d'aluminium (Phase 198) — même cause : le trigger
-- sync_product_from_raw_material (phase159) ne remplit use_cases qu'à
-- la création du produit, qui a souvent lieu (via le trigger, à
-- l'INSERT sur raw_materials) AVANT que les usages ne soient insérés
-- juste après dans le même script (phases 190, 195...) — le produit
-- se retrouve donc parfois créé avec use_cases vide ou incomplet.
--
-- Recalcule use_cases pour chaque produit du pilier Akor'Eau ayant une
-- fiche Académie liée, à partir de ses usages actuels — même logique
-- que la Phase 198, appliquée à tout le pilier en une fois.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (recalcule toujours la valeur exacte attendue).
-- ============================================================

do $$
declare
  v_akoreau_id uuid;
  v_row record;
  v_usages text[];
  v_fixed_count int := 0;
begin
  select id into v_akoreau_id from public.business_units where slug = 'akor-eau';
  if v_akoreau_id is null then
    raise exception 'Aucun pilier avec le slug "akor-eau" trouvé — arrêt.';
  end if;

  for v_row in
    select p.id as product_id, a.id as academie_id, p.name
    from public.products p
    join public.matieres_premieres_academie a on a.matiere_premiere_id = p.raw_material_id
    where p.business_unit_id = v_akoreau_id
  loop
    select array_agg(distinct u.domaine_application order by u.domaine_application)
      into v_usages
      from public.matieres_premieres_usages u
      where u.academie_id = v_row.academie_id;

    update public.products
    set use_cases = coalesce(v_usages, '{}')
    where id = v_row.product_id;

    v_fixed_count := v_fixed_count + 1;
  end loop;

  raise notice '% produit(s) Akor''Eau resynchronisé(s).', v_fixed_count;
end $$;

-- Vérification :
-- select name, use_cases from public.products
-- where business_unit_id = (select id from public.business_units where slug = 'akor-eau')
-- order by name;
