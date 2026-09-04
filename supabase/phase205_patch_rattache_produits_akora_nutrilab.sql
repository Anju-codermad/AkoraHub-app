-- ============================================================
-- AkoraHub - Patch Phase 205 : rattache au pilier "Akora NutriLab"
-- les produits déjà au catalogue (sous Akora Pro) qui correspondent
-- à des ingrédients/matières premières agroalimentaire — demande
-- explicite de la propriétaire le 04/09/2026, suite au diagnostic
-- fait en session (recherche par nom/catégorie + fiches Académie
-- mentionnant "grade alimentaire"/"agroalimentaire").
--
-- Deux traitements différents, décidés produit par produit avec la
-- propriétaire :
--
-- A) BASCULE complète (business_unit_id + category) : produits dont
--    l'usage alimentaire est la vocation principale (nom explicite
--    "alimentaire", numéro E, ingrédient dédié). Ils quittent Akora
--    Pro pour Akora NutriLab et sont classés dans l'une des 7
--    catégories créées en phase 204.
--
-- B) LIEN SUPPLÉMENTAIRE (product_extra_business_units, cf. phase202) :
--    produits chimiques polyvalents dont l'agroalimentaire n'est
--    qu'un usage parmi d'autres (industriel, cosmétique...). Ils
--    restent principalement sous Akora Pro mais apparaissent aussi
--    dans Akora NutriLab, sans dupliquer leur fiche.
--
-- Volontairement laissés de côté (ni A ni B) : désinfectants
-- industriels (Acide peracétique, Chlorure de benzalkonium, Dioxyde
-- de chlore, PHMB — pas des "ingrédients"), adjuvants de filtration
-- multi-industrie (Diatomite, Perlite expansée), résines/huiles à
-- vocation principalement parfumerie (Huiles essentielles, Myrrhe,
-- Oliban, Benjoin), et Sulfate d'aluminium (usage principal :
-- traitement de l'eau, l'agroalimentaire n'étant qu'une mention
-- parmi 6 domaines d'application).
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (mise à jour par nom exact ; on conflict do nothing
-- pour les liens supplémentaires).
-- ============================================================

do $$
declare
  v_nutrilab_id uuid;
  v_moved_count int;
  v_linked_count int;
begin
  select id into v_nutrilab_id from public.business_units where slug = 'akora-nutrilab';
  if v_nutrilab_id is null then
    raise exception 'Pilier Akora NutriLab introuvable — exécuter d''abord la phase 203.';
  end if;

  -- ------------------------------------------------------------
  -- A) Bascule pilier + catégorie
  -- ------------------------------------------------------------
  update public.products p
  set business_unit_id = v_nutrilab_id,
      category = m.new_category
  from (values
    -- Additifs alimentaires
    ('Acide acétique / Vinaigre blanc (E260)', 'Additifs alimentaires'),
    ('Acide citrique alimentaire', 'Additifs alimentaires'),
    ('Acide citrique anhydre (E330)', 'Additifs alimentaires'),
    ('Acide citrique monohydraté (E330)', 'Additifs alimentaires'),
    ('Acide phosphorique H₃PO₄ (E338)', 'Additifs alimentaires'),
    ('Acide phosphorique H₃PO₄ alimentaire (E338)', 'Additifs alimentaires'),
    ('Sel alimentaire raffine', 'Additifs alimentaires'),
    ('Sel de table / Chlorure de sodium alimentaire (NaCl)', 'Additifs alimentaires'),
    ('Silice colloïdale / Dioxyde de silicium (E551)', 'Additifs alimentaires'),
    ('Charbon Actif Alimentaire – Grade Alimentaire', 'Additifs alimentaires'),
    ('Peroxyde d''hydrogène alimentaire (H₂O₂) — grade stérilisation emballage', 'Additifs alimentaires'),
    ('Vinaigre blanc / Acide acétique (acidification conserves)', 'Additifs alimentaires'),
    ('Bicarbonate de soude alimentaire', 'Additifs alimentaires'),
    ('Dioxyde de carbone CO₂ alimentaire', 'Additifs alimentaires'),

    -- Arômes & parfums alimentaires
    ('Aromes alimentaires', 'Arômes & parfums alimentaires'),
    ('Épices alimentaires (cannelle, muscade, gingembre, clou de girofle)', 'Arômes & parfums alimentaires'),

    -- Colorants alimentaires
    ('Bétacarotène (E160a)', 'Colorants alimentaires'),
    ('Carmin / Cochenille (E120)', 'Colorants alimentaires'),
    ('Lutéine, extrait de tagète (E161b)', 'Colorants alimentaires'),
    ('Rouge de betterave / bétanine (E162)', 'Colorants alimentaires'),
    ('Colorants alimentaires certifies', 'Colorants alimentaires'),
    ('Caramel alimentaire (E150a — classe I)', 'Colorants alimentaires'),

    -- Épaississants, gélifiants et stabilisants
    ('Chlorure de calcium CaCl₂ (texturation conserves)', 'Épaississants, gélifiants et stabilisants'),
    ('Chlorure de calcium CaCl₂ alimentaire', 'Épaississants, gélifiants et stabilisants'),
    ('Tylose CMC (Pâtisserie décorative)', 'Épaississants, gélifiants et stabilisants'),
    ('Gélatine alimentaire en poudre (200 Bloom)', 'Épaississants, gélifiants et stabilisants'),
    ('Glycérine / Glycérol alimentaire (E422)', 'Épaississants, gélifiants et stabilisants'),
    ('Plasmal (mélange phosphates alimentaires)', 'Épaississants, gélifiants et stabilisants'),

    -- Édulcorants
    ('Glucose / Dextrose monohydraté', 'Édulcorants')
  ) as m(product_name, new_category)
  where p.name = m.product_name;
  get diagnostics v_moved_count = row_count;
  raise notice '% produit(s) basculé(s) vers Akora NutriLab.', v_moved_count;

  -- ------------------------------------------------------------
  -- B) Lien supplémentaire (pilier principal inchangé)
  -- ------------------------------------------------------------
  insert into public.product_extra_business_units (product_id, business_unit_id)
  select p.id, v_nutrilab_id
  from public.products p
  where p.name in (
    'Acide acetique',
    'Acide benzoique',
    'Acide citrique',
    'Acide lactique',
    'Acide phosphorique',
    'Caféine (anhydre)',
    'Caféine anhydre',
    'Taurine',
    'Inositol / Myo-inositol (Vitamine B8)',
    'Vitamines B3, B6, B12 (niacine, pyridoxine, cobalamine)',
    'Polysorbate 80',
    'Propylene glycol',
    'Soude caustique NaOH (grade alimentaire)',
    'Acide sorbique (E200)',
    'Sorbate de potassium',
    'Ethanol (alcool ethylique)',
    'L-cystéine (E920)'
  )
  on conflict (product_id, business_unit_id) do nothing;
  get diagnostics v_linked_count = row_count;
  raise notice '% produit(s) lié(s) en plus à Akora NutriLab.', v_linked_count;
end $$;

-- Vérification : produits maintenant sous Akora NutriLab (pilier principal)
select name as produit, category as categorie
from public.products
where business_unit_id = (select id from public.business_units where slug = 'akora-nutrilab')
order by category, name;

-- Vérification : produits liés en plus (pilier principal inchangé)
select p.name as produit, bu.name as pilier_principal
from public.product_extra_business_units peb
join public.products p on p.id = peb.product_id
join public.business_units bu on bu.id = p.business_unit_id
where peb.business_unit_id = (select id from public.business_units where slug = 'akora-nutrilab')
order by p.name;
