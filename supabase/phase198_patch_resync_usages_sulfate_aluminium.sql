-- ============================================================
-- AkoraHub - Patch Phase 198 : recopie tous les usages de la fiche
-- Académie du "Sulfate d'aluminium (Alun)" vers products.use_cases —
-- corrige un décalage constaté après la phase 197.
--
-- Cause : le trigger sync_product_from_raw_material (phase159) ne
-- remplit products.use_cases qu'à la création du produit (à partir des
-- usages déjà présents à ce moment précis dans
-- matieres_premieres_usages). Ajouter des usages plus tard à une fiche
-- Académie existante (comme la phase 197 vient de le faire, 2 -> 9
-- usages) ne re-déclenche PAS cette recopie — d'où le décalage observé
-- dans l'écran Admin "Modifier le produit" : seuls les 2 usages
-- présents à la création du produit apparaissaient cochés.
--
-- Ce script recalcule use_cases pour CE produit précisément à partir
-- de sa fiche Académie actuelle (même logique que le trigger), sans
-- toucher aux autres produits.
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
    where rm.name = 'Sulfate d''aluminium (Alun)';

  if v_academie_id is null then
    raise exception 'Fiche Académie introuvable pour "Sulfate d''aluminium (Alun)" — arrêt.';
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
-- select name, use_cases from public.products where name = 'Sulfate d''aluminium (Alun)';
