-- ============================================================
-- AkoraHub - Patch Phase 225 : catégorise les 16 produits liés à
-- Akora NutriSource sans categorie (product_extra_business_units.
-- category resté null depuis les phases 205/206, jamais complété par
-- la phase 208) — demande explicite de la propriétaire.
--
-- 15 produits reçoivent une catégorie NutriSource, classés par
-- fonction :
--   - Acidifiants alimentaires : Acide acetique, Acide citrique,
--     Acide lactique
--   - Conservateurs alimentaires : Acide benzoique, Acide sorbique
--     (E200), Sorbate de potassium (E202)
--   - Ingrédients nutritionnels : Caféine (anhydre), Caféine anhydre,
--     Inositol / Myo-inositol (Vitamine B8), Taurine, Vitamines B3,
--     B6, B12
--   - Additifs et auxiliaires technologiques alimentaires :
--     L-cystéine (E920, agent de traitement de farine), Propylene
--     glycol (auxiliaire/humectant), Soude caustique NaOH (grade
--     alimentaire, auxiliaire de fabrication)
--   - Émulsifiants : Polysorbate 80
--
-- Le 16e, "Ethanol (alcool ethylique)", N'EST PAS catégorisé : il
-- avait été explicitement retiré du lien vers ce pilier par la phase
-- 209 ("par précaution... éviter une confusion pour un client
-- agroalimentaire", statut alimentaire non confirmé), mais réapparaît
-- ici sans catégorie — signe que la phase 209 n'a en réalité jamais
-- été exécutée en base. Ce script réapplique donc la suppression du
-- lien plutôt que de le catégoriser, pour respecter la décision déjà
-- prise.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (update/delete par nom exact).
-- ============================================================

do $$
declare
  v_nutrisource_id uuid;
begin
  select id into v_nutrisource_id from public.business_units where slug = 'akora-nutrisource';
  if v_nutrisource_id is null then
    raise exception 'Pilier Akora NutriSource introuvable — exécuter d''abord la phase 222.';
  end if;

  update public.product_extra_business_units peb
  set category = m.new_category
  from public.products p,
  (values
    ('Acide acetique', 'Acidifiants alimentaires'),
    ('Acide citrique', 'Acidifiants alimentaires'),
    ('Acide lactique', 'Acidifiants alimentaires'),
    ('Acide benzoique', 'Conservateurs alimentaires'),
    ('Acide sorbique (E200)', 'Conservateurs alimentaires'),
    ('Sorbate de potassium (E202)', 'Conservateurs alimentaires'),
    ('Caféine (anhydre)', 'Ingrédients nutritionnels'),
    ('Caféine anhydre', 'Ingrédients nutritionnels'),
    ('Inositol / Myo-inositol (Vitamine B8)', 'Ingrédients nutritionnels'),
    ('Taurine', 'Ingrédients nutritionnels'),
    ('Vitamines B3, B6, B12 (niacine, pyridoxine, cobalamine)', 'Ingrédients nutritionnels'),
    ('L-cystéine (E920)', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Propylene glycol', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Soude caustique NaOH (grade alimentaire)', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Polysorbate 80', 'Émulsifiants')
  ) as m(product_name, new_category)
  where peb.product_id = p.id
    and peb.business_unit_id = v_nutrisource_id
    and p.name = m.product_name;

  -- Réapplique la suppression du lien Ethanol (phase 209, jamais
  -- effectivement exécutée)
  delete from public.product_extra_business_units peb
  using public.products p
  where peb.product_id = p.id
    and peb.business_unit_id = v_nutrisource_id
    and p.name = 'Ethanol (alcool ethylique)';
end $$;

-- Vérification : ne doit plus renvoyer aucune ligne avec categorie null
select p.name as produit, peb.category as categorie
from public.product_extra_business_units peb
join public.products p on p.id = peb.product_id
where peb.business_unit_id = (select id from public.business_units where slug = 'akora-nutrisource')
  and peb.category is null;

-- Vérification : Ethanol ne doit plus apparaître du tout sous NutriSource
select p.name
from public.product_extra_business_units peb
join public.products p on p.id = peb.product_id
where peb.business_unit_id = (select id from public.business_units where slug = 'akora-nutrisource')
  and p.name = 'Ethanol (alcool ethylique)';
