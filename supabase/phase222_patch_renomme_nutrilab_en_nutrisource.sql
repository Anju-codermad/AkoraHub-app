-- ============================================================
-- AkoraHub - Patch Phase 222 : renomme le pilier "Akora NutriLab" en
-- "Akora NutriSource" et affine ses catégories — demande explicite de
-- la propriétaire (nouvelle branche "Akora Agro" du site, avec des
-- catégories plus précises que celles créées en phase 204).
--
-- Le pilier "Akora NutriLab" (phase 203) contient déjà ~150 produits
-- réels (29 basculés directement en phase 205, ~118 liés en plus
-- depuis Akora Pro via product_extra_business_units — phases
-- 205/206/208) répartis sur 7 catégories (phase 204). La nouvelle
-- liste souhaitée en compte 13, plus fines. Ce script :
--
--   1. Renomme le pilier (business_units) — id inchangé, tout ce qui
--      référence business_unit_id reste valide.
--   2. Renomme en place 3 catégories qui deviennent le "reliquat"
--      d'une scission, et crée les nouvelles catégories qui en sont
--      issues :
--        - "Épaississants, gélifiants et stabilisants" (25 produits)
--          -> renommée "Épaississants & stabilisants alimentaires"
--             (reliquat : cellulose/phosphates/CaCl₂/glycérine),
--             + nouvelles "Gélifiants alimentaires" (agar-agar,
--             alginate de sodium, carraghénanes, pectine, gélatine),
--             "Gommes alimentaires" (les 8 "Gomme ..."),
--             "Amidon & dérivés" (amidon modifié).
--        - "Additifs alimentaires" (58 produits)
--          -> renommée "Additifs et auxiliaires technologiques
--             alimentaires" (reliquat : sels, agents de charge,
--             gaz/auxiliaires de fabrication, exhausteurs de goût),
--             + nouvelles "Conservateurs alimentaires" (antioxydants
--             E3xx, sulfites, nitrites, propionates, benzoate...) et
--             "Acidifiants alimentaires" (acides organiques, citrates,
--             tartrates).
--        - "Arômes & parfums alimentaires" -> renommée "Arômes
--          alimentaires" (simple renommage, pas de scission).
--   3. Ajoute "Conservateurs alimentaires", "Fibres alimentaires" (pas
--      encore de produit dessus — à peupler plus tard).
--   4. Reclasse chaque produit concerné (products.category pour les 20
--      produits basculés, product_extra_business_units.category pour
--      les 63 produits liés en plus) selon la nouvelle catégorie —
--      classement fait par familles chimiques/fonctionnelles connues
--      (ex. gommes végétales -> "Gommes alimentaires", agents
--      gélifiants classiques -> "Gélifiants alimentaires", dérivés de
--      cellulose/phosphates -> restent "Épaississants & stabilisants").
--      À VÉRIFIER par la propriétaire — même principe que les
--      corrections passées (phases 206/207/209) : un correctif de
--      détail est simple à écrire si un produit est mal classé.
--
-- "Édulcorants", "Émulsifiants", "Colorants alimentaires" et
-- "Ingrédients nutritionnels" ne changent pas (déjà alignées avec la
-- nouvelle liste).
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (renommages par nom exact ; on conflict do nothing
-- pour les nouvelles catégories).
-- ============================================================

do $$
declare
  v_nutrisource_id uuid;
begin
  -- 1) Renomme le pilier
  update public.business_units
  set name = 'Akora NutriSource', slug = 'akora-nutrisource'
  where slug = 'akora-nutrilab';

  select id into v_nutrisource_id from public.business_units where slug = 'akora-nutrisource';
  if v_nutrisource_id is null then
    raise exception 'Pilier Akora NutriSource introuvable après renommage — vérifier qu''Akora NutriLab existait bien (phase 203).';
  end if;

  -- 2) Renomme en place les 3 catégories "reliquat"
  update public.categories set name = 'Épaississants & stabilisants alimentaires'
  where business_unit_id = v_nutrisource_id and name = 'Épaississants, gélifiants et stabilisants';

  update public.categories set name = 'Additifs et auxiliaires technologiques alimentaires'
  where business_unit_id = v_nutrisource_id and name = 'Additifs alimentaires';

  update public.categories set name = 'Arômes alimentaires'
  where business_unit_id = v_nutrisource_id and name = 'Arômes & parfums alimentaires';

  -- 3) Crée les nouvelles catégories (celles issues d'une scission +
  --    les entièrement nouvelles/vides)
  insert into public.categories (business_unit_id, name)
  select v_nutrisource_id, c.name
  from (values
    ('Gélifiants alimentaires'),
    ('Gommes alimentaires'),
    ('Amidon & dérivés'),
    ('Conservateurs alimentaires'),
    ('Acidifiants alimentaires'),
    ('Fibres alimentaires')
  ) as c(name)
  on conflict (business_unit_id, name) do nothing;

  -- 4a) Reclasse les produits basculés (products.category)
  update public.products p
  set category = m.new_category
  from (values
    -- -> Épaississants & stabilisants alimentaires (reliquat)
    ('Chlorure de calcium CaCl₂ (texturation conserves)', 'Épaississants & stabilisants alimentaires'),
    ('Chlorure de calcium CaCl₂ alimentaire', 'Épaississants & stabilisants alimentaires'),
    ('Tylose CMC (Pâtisserie décorative)', 'Épaississants & stabilisants alimentaires'),
    ('Glycérine / Glycérol alimentaire (E422)', 'Épaississants & stabilisants alimentaires'),
    ('Plasmal (mélange phosphates alimentaires)', 'Épaississants & stabilisants alimentaires'),
    -- -> Gélifiants alimentaires
    ('Gélatine alimentaire en poudre (200 Bloom)', 'Gélifiants alimentaires'),
    -- -> Acidifiants alimentaires
    ('Acide acétique / Vinaigre blanc (E260)', 'Acidifiants alimentaires'),
    ('Acide citrique alimentaire', 'Acidifiants alimentaires'),
    ('Acide citrique anhydre (E330)', 'Acidifiants alimentaires'),
    ('Acide citrique monohydraté (E330)', 'Acidifiants alimentaires'),
    ('Acide phosphorique H₃PO₄ (E338)', 'Acidifiants alimentaires'),
    ('Acide phosphorique H₃PO₄ alimentaire (E338)', 'Acidifiants alimentaires'),
    ('Vinaigre blanc / Acide acétique (acidification conserves)', 'Acidifiants alimentaires'),
    -- -> Additifs et auxiliaires technologiques alimentaires (reliquat)
    ('Sel alimentaire raffine', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Sel de table / Chlorure de sodium alimentaire (NaCl)', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Silice colloïdale / Dioxyde de silicium (E551)', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Charbon Actif Alimentaire – Grade Alimentaire', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Peroxyde d''hydrogène alimentaire (H₂O₂) — grade stérilisation emballage', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Bicarbonate de soude alimentaire', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Dioxyde de carbone CO₂ alimentaire', 'Additifs et auxiliaires technologiques alimentaires')
  ) as m(product_name, new_category)
  where p.business_unit_id = v_nutrisource_id and p.name = m.product_name;

  -- 4b) Reclasse les produits liés en plus (product_extra_business_units.category)
  update public.product_extra_business_units peb
  set category = m.new_category
  from public.products p,
  (values
    -- -> Épaississants & stabilisants alimentaires (reliquat)
    ('Alginate de propylène glycol (PGA, E405)', 'Épaississants & stabilisants alimentaires'),
    ('CMC / Carboxyméthylcellulose (E466) — Tylose', 'Épaississants & stabilisants alimentaires'),
    ('Éthylcellulose (E462)', 'Épaississants & stabilisants alimentaires'),
    ('HPMC (hydroxypropylméthylcellulose, E464)', 'Épaississants & stabilisants alimentaires'),
    ('Méthylcellulose (E461)', 'Épaississants & stabilisants alimentaires'),
    ('Tripolyphosphate de sodium STPP (E451)', 'Épaississants & stabilisants alimentaires'),
    -- -> Gélifiants alimentaires
    ('Agar-Agar (E406)', 'Gélifiants alimentaires'),
    ('Alginate de sodium (E401)', 'Gélifiants alimentaires'),
    ('Carraghénanes (E407)', 'Gélifiants alimentaires'),
    ('Pectine HM (E440i)', 'Gélifiants alimentaires'),
    -- -> Gommes alimentaires
    ('Gomme adragante (E413)', 'Gommes alimentaires'),
    ('Gomme arabique (E414)', 'Gommes alimentaires'),
    ('Gomme de caroube (LBG, E410)', 'Gommes alimentaires'),
    ('Gomme de konjac (E425)', 'Gommes alimentaires'),
    ('Gomme gellane (E418)', 'Gommes alimentaires'),
    ('Gomme guar (E412)', 'Gommes alimentaires'),
    ('Gomme karaya (E416)', 'Gommes alimentaires'),
    ('Gomme Tara (E417)', 'Gommes alimentaires'),
    -- -> Amidon & dérivés
    ('Amidon modifié (E1400–E1452)', 'Amidon & dérivés'),
    -- -> Conservateurs alimentaires
    ('Acide ascorbique / Ascorbate Na (E300/E301)', 'Conservateurs alimentaires'),
    ('Acide benzoïque (E210)', 'Conservateurs alimentaires'),
    ('Acide propionique (E280)', 'Conservateurs alimentaires'),
    ('Ascorbate de calcium (E302)', 'Conservateurs alimentaires'),
    ('Ascorbate de sodium (E301)', 'Conservateurs alimentaires'),
    ('BHA (Butylhydroxyanisole, E320)', 'Conservateurs alimentaires'),
    ('BHT (Butylhydroxytoluène, E321)', 'Conservateurs alimentaires'),
    ('Dicarbonate de diméthyle (DMDC, E242)', 'Conservateurs alimentaires'),
    ('Gallate d''octyle (E311)', 'Conservateurs alimentaires'),
    ('Gallate de dodécyle (E312)', 'Conservateurs alimentaires'),
    ('Gallate de propyle (E310)', 'Conservateurs alimentaires'),
    ('Hexaméthylènetétramine (E239)', 'Conservateurs alimentaires'),
    ('Lysozyme (E1105)', 'Conservateurs alimentaires'),
    ('Métabisulfite de potassium (E224) — ''Meta K''', 'Conservateurs alimentaires'),
    ('Natamycine (E235)', 'Conservateurs alimentaires'),
    ('Nisine (E234)', 'Conservateurs alimentaires'),
    ('Nitrite de sodium / Sel nitrité (E250)', 'Conservateurs alimentaires'),
    ('Palmitate d''ascorbyle (E304)', 'Conservateurs alimentaires'),
    ('Propionate de calcium (E282)', 'Conservateurs alimentaires'),
    ('Propionate de sodium (E281)', 'Conservateurs alimentaires'),
    ('Salpêtre (Nitrate de potassium KNO₃ E252)', 'Conservateurs alimentaires'),
    ('Salpêtre / Nitrate de potassium (E252)', 'Conservateurs alimentaires'),
    ('Sulfite de sodium / Métabisulfite de sodium (E221/E223)', 'Conservateurs alimentaires'),
    ('Acide phytique (E391)', 'Conservateurs alimentaires'),
    -- -> Acidifiants alimentaires
    ('Acide fumarique (E297)', 'Acidifiants alimentaires'),
    ('Acide malique DL (E296)', 'Acidifiants alimentaires'),
    ('Acide tartrique L(+) (E334)', 'Acidifiants alimentaires'),
    ('Citrate de sodium (E331)', 'Acidifiants alimentaires'),
    ('Citrate de sodium / Citrate de potassium (E331/E332)', 'Acidifiants alimentaires'),
    ('Crème de tartre (Tartrate acide de potassium E336)', 'Acidifiants alimentaires'),
    ('Gluconate de sodium (E576)', 'Acidifiants alimentaires'),
    ('Tartrate de sodium (E335)', 'Acidifiants alimentaires'),
    -- -> Additifs et auxiliaires technologiques alimentaires (reliquat)
    ('Bicarbonate de sodium NaHCO₃ (E500ii)', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Carbonate acide d''ammonium / Bicarbonate d''ammonium (E503)', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Carbonate de calcium CaCO₃ (E170)', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Alun de potassium (E522)', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Chlorure de magnésium (E511)', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Chlorure de potassium (E508)', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Éthylmaltol (E637)', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Guanylate disodique / Acide guanylique (E626/E627)', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Inosinate disodique / Acide inosinique (E630/E631)', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Maltol (E636)', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Glutamate monosodique MSG (E621)', 'Additifs et auxiliaires technologiques alimentaires'),
    ('Azodicarbonamide (E927a)', 'Additifs et auxiliaires technologiques alimentaires')
  ) as m(product_name, new_category)
  where peb.product_id = p.id
    and peb.business_unit_id = v_nutrisource_id
    and p.name = m.product_name;

  raise notice 'Phase 222 terminée pour le pilier %', v_nutrisource_id;
end $$;

-- ------------------------------------------------------------
-- Vérification 1 : les 13 catégories du pilier, avec nombre de
-- produits (basculés + liés en plus) dans chacune.
-- ------------------------------------------------------------
select
  cat.name as categorie,
  (select count(*) from public.products p
    where p.business_unit_id = bu.id and p.category = cat.name) as produits_basculés,
  (select count(*) from public.product_extra_business_units peb
    where peb.business_unit_id = bu.id and peb.category = cat.name) as produits_liés_en_plus
from public.categories cat
join public.business_units bu on bu.id = cat.business_unit_id
where bu.slug = 'akora-nutrisource'
order by cat.name;

-- ------------------------------------------------------------
-- Vérification 2 : détail produit par produit, à relire pour
-- confirmer chaque classement (corriger via un phase223 dédié si un
-- produit est mal placé — même principe que les phases 206/207/209).
-- ------------------------------------------------------------
select p.name as produit, p.category as categorie, 'basculé' as type
from public.products p
where p.business_unit_id = (select id from public.business_units where slug = 'akora-nutrisource')
union all
select p.name as produit, peb.category as categorie, 'lié en plus' as type
from public.product_extra_business_units peb
join public.products p on p.id = peb.product_id
where peb.business_unit_id = (select id from public.business_units where slug = 'akora-nutrisource')
order by categorie, produit;
