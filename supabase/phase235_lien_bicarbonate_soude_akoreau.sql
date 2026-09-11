-- ============================================================
-- AkoraHub - Patch Phase 235 : relie "Bicarbonate de soude" (grade
-- technique, Akora Pro) à Akor'Eau — demande explicite de la
-- propriétaire le 11/09/2026.
--
-- Contexte : le bicarbonate de sodium (NaHCO₃) est une seule molécule,
-- déjà présente au catalogue sous 3 fiches distinctes selon le grade :
--   - "Bicarbonate de soude" (technique, Akora Pro/Acides & Bases) —
--     abrasif léger/désodorisant, entretien ménager.
--   - "Bicarbonate de soude alimentaire" (Akora Pro) — DÉJÀ relié à
--     Akora NutriLab (phase205, catégorie "Additifs alimentaires").
--   - "Bicarbonate de sodium NaHCO₃ (E500ii)" (Akora Pro) — DÉJÀ relié
--     à Akora NutriLab (phase208, catégorie "Additifs alimentaires").
--
-- Il ne manquait que le grade technique pour le traitement de l'eau /
-- piscine (augmentation de l'alcalinité, stabilisation du pH) —
-- aucune nouvelle fiche créée, on relie le produit technique existant
-- à Akor'Eau, catégorie "Correction du pH" (déjà utilisée pour Chaux
-- eteinte et Bisulfate de sodium).
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do update).
-- ============================================================

do $$
declare
  v_akoreau_id uuid;
  v_product_id uuid;
begin
  select id into v_akoreau_id from public.business_units where slug = 'akor-eau';
  if v_akoreau_id is null then
    raise exception 'Aucun pilier avec le slug "akor-eau" trouvé — arrêt.';
  end if;

  select id into v_product_id from public.products where name = 'Bicarbonate de soude';
  if v_product_id is not null then
    insert into public.product_extra_business_units (product_id, business_unit_id, category)
    values (v_product_id, v_akoreau_id, 'Correction du pH')
    on conflict (product_id, business_unit_id) do update set category = excluded.category;
  else
    raise notice '"Bicarbonate de soude" introuvable dans products (pas encore de fiche vendable pour ce produit) — rien relié.';
  end if;
end $$;

-- Vérification :
-- select p.name, peb.category from public.product_extra_business_units peb
-- join public.products p on p.id = peb.product_id
-- where peb.business_unit_id = (select id from public.business_units where slug = 'akor-eau')
-- and p.name = 'Bicarbonate de soude';
