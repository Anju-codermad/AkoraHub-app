-- ============================================================
-- AkoraHub - Patch Phase 211 : consolide "Charbon actif" et "STPP" en
-- un seul produit chacun, relié aux deux piliers (Akora Pro + Akor'Eau)
-- via le système multi-pilier (phase202) — demande explicite de la
-- propriétaire le 05/09/2026 : "Relié le produit même nom dans l'Akora
-- Pro et dans l'Akor'Eau [...] Je ne veux pas le rajouter encore."
--
-- La phase 195 avait créé deux fiches SÉPARÉES pour ces produits
-- ("Charbon actif granulaire (GAC)", "STPP — grade traitement de
-- l'eau") au lieu de relier les fiches déjà existantes sous Akora Pro
-- ("Charbon actif (vrac)", "Tripolyphosphate de sodium STPP (E451)")
-- — avant que le multi-pilier (phase202) n'existe. Corrigé ici :
--
--   1) Relie les 2 produits EXISTANTS d'Akora Pro à Akor'Eau (comme
--      Hypochlorite de calcium 70%, phase202).
--   2) Supprime complètement les 2 fiches dupliquées de la phase 195
--      (raw_materials + academie + usages + phrases H/P + products) —
--      jamais publiées côté client (visibility=false), aucune perte
--      de données réelle (stock/prix à 0 depuis leur création).
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do nothing / delete conditionnels).
-- ============================================================

do $$
declare
  v_akora_pro_id uuid;
  v_akoreau_id uuid;
  v_charbon_id uuid;
  v_stpp_id uuid;
  v_dup_material_id uuid;
  v_dup_academie_id uuid;
begin
  select id into v_akora_pro_id from public.business_units where slug = 'matieres-premieres';
  select id into v_akoreau_id from public.business_units where slug = 'akor-eau';
  if v_akora_pro_id is null then
    raise exception 'Aucun pilier avec le slug "matieres-premieres" trouvé — arrêt.';
  end if;
  if v_akoreau_id is null then
    raise exception 'Aucun pilier avec le slug "akor-eau" trouvé — arrêt.';
  end if;

  -- ============================================================
  -- 1) Relie les produits existants d'Akora Pro à Akor'Eau
  -- ============================================================
  select id into v_charbon_id from public.products
    where business_unit_id = v_akora_pro_id and name = 'Charbon actif (vrac)';
  if v_charbon_id is not null then
    insert into public.product_extra_business_units (product_id, business_unit_id)
    values (v_charbon_id, v_akoreau_id)
    on conflict (product_id, business_unit_id) do nothing;
  else
    raise notice 'Produit "Charbon actif (vrac)" introuvable sous Akora Pro — rien relié.';
  end if;

  select id into v_stpp_id from public.products
    where business_unit_id = v_akora_pro_id and name = 'Tripolyphosphate de sodium STPP (E451)';
  if v_stpp_id is not null then
    insert into public.product_extra_business_units (product_id, business_unit_id)
    values (v_stpp_id, v_akoreau_id)
    on conflict (product_id, business_unit_id) do nothing;
  else
    raise notice 'Produit "Tripolyphosphate de sodium STPP (E451)" introuvable sous Akora Pro — rien relié.';
  end if;

  -- ============================================================
  -- 2) Supprime les fiches dupliquées créées par la phase 195
  -- ============================================================

  -- 2a. Charbon actif granulaire (GAC)
  select id into v_dup_material_id from public.raw_materials
    where business_unit_id = v_akora_pro_id and name = 'Charbon actif granulaire (GAC)';
  if v_dup_material_id is not null then
    select id into v_dup_academie_id from public.matieres_premieres_academie
      where matiere_premiere_id = v_dup_material_id;
    if v_dup_academie_id is not null then
      delete from public.matieres_premieres_usages where academie_id = v_dup_academie_id;
      delete from public.academie_phrases_h where academie_id = v_dup_academie_id;
      delete from public.academie_phrases_p where academie_id = v_dup_academie_id;
      delete from public.matieres_premieres_academie where id = v_dup_academie_id;
    end if;
    delete from public.products where raw_material_id = v_dup_material_id;
    delete from public.raw_materials where id = v_dup_material_id;
  end if;

  -- 2b. STPP — grade traitement de l'eau (anti-tartre)
  select id into v_dup_material_id from public.raw_materials
    where business_unit_id = v_akora_pro_id and name = 'STPP — grade traitement de l''eau (anti-tartre)';
  if v_dup_material_id is not null then
    select id into v_dup_academie_id from public.matieres_premieres_academie
      where matiere_premiere_id = v_dup_material_id;
    if v_dup_academie_id is not null then
      delete from public.matieres_premieres_usages where academie_id = v_dup_academie_id;
      delete from public.academie_phrases_h where academie_id = v_dup_academie_id;
      delete from public.academie_phrases_p where academie_id = v_dup_academie_id;
      delete from public.matieres_premieres_academie where id = v_dup_academie_id;
    end if;
    delete from public.products where raw_material_id = v_dup_material_id;
    delete from public.raw_materials where id = v_dup_material_id;
  end if;
end $$;

-- Vérification :
-- select p.name, bu.name as pilier_principal,
--        array_agg(bu_extra.name) filter (where bu_extra.name is not null) as piliers_supplementaires
-- from public.products p
-- join public.business_units bu on bu.id = p.business_unit_id
-- left join public.product_extra_business_units peb on peb.product_id = p.id
-- left join public.business_units bu_extra on bu_extra.id = peb.business_unit_id
-- where p.name in ('Charbon actif (vrac)', 'Tripolyphosphate de sodium STPP (E451)')
-- group by p.name, bu.name;
--
-- select name from public.products
-- where name in ('Charbon actif granulaire (GAC)', 'STPP — grade traitement de l''eau (anti-tartre)');
-- (doit renvoyer 0 ligne)
