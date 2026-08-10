-- ============================================================
-- AkoraHub - Patch Phase 156 : gamme "Softberry" (5 cosmétiques,
-- agréés Food & Drugs Control Administration - Gujarat, license
-- GC/1484) dans le pilier Akora Fanadiovana, catégorie "Soins du
-- Corps & Cosmétiques".
--
-- Contexte (10/08, demande explicite) : l'utilisatrice a fourni les 5
-- certificats d'agrément produit (composition INCI complète) et a
-- demandé de créer les fiches avec description/usages/mode d'emploi
-- à partir des noms officiels des documents. Mêmes conventions que
-- phase148 : produits créés en Brouillon (visibility = false), prix
-- et stock à 0 en attendant que l'utilisatrice ajoute photo + prix
-- réels puis publie depuis l'admin (product_management_real.dart).
-- Non destructif et rejouable : chaque insert est gardé par un
-- `where not exists` sur (name, category).
-- ============================================================

insert into public.products (
  business_unit_id, category, name, description, use_cases,
  price_detail, price_gros, gros_threshold_qty, stock_quantity, visibility
)
select
  (select id from public.business_units where name ilike 'Akora Fanadiovana' limit 1),
  'Soins du Corps & Cosmétiques',
  v.name,
  v.description,
  v.use_cases,
  0, 0, 10, 0, false
from (values
  (
    'Softberry Orange Face Wash',
    'Gel nettoyant visage à l''orange, à la mousse onctueuse. Il nettoie la peau en douceur, élimine l''excès de sébum, les impuretés et les résidus de maquillage, tout en respectant l''équilibre naturel de la peau. Parfum orange frais et agréable à chaque utilisation.' || E'\n\n' ||
    'Usages : visage, peau.' || E'\n\n' ||
    'Mode d''emploi : appliquer une petite quantité sur le visage humidifié, masser délicatement en mouvements circulaires en évitant le contour des yeux, puis rincer abondamment à l''eau tiède. À utiliser matin et/ou soir.' || E'\n\n' ||
    'Ingrédients clés : agents nettoyants doux, agent conditionneur, parfum orange.',
    array['Visage','Peau']
  ),
  (
    'Softberry Coffee Face And Body Scrub',
    'Gommage exfoliant visage & corps au café, à base de poudre de coquille de noix pour une exfoliation mécanique douce. Il aide à éliminer les cellules mortes en surface et laisse la peau plus lisse et plus douce.' || E'\n\n' ||
    'Usages : corps, visage, peau.' || E'\n\n' ||
    'Mode d''emploi : appliquer sur peau humide, masser en mouvements circulaires sur les zones à exfolier (au visage, éviter le contour des yeux) pendant 1 à 2 minutes, puis rincer abondamment à l''eau tiède. Usage conseillé 1 à 2 fois par semaine.' || E'\n\n' ||
    'Ingrédients clés : poudre de coquille de noix (exfoliant), extrait de café, huiles émollientes.',
    array['Corps','Visage','Peau']
  ),
  (
    'Softberry Shea Butter Moisturizer',
    'Crème hydratante au beurre de karité, à la texture onctueuse qui pénètre facilement. Elle nourrit et adoucit la peau en profondeur, laissant une sensation de confort et de douceur durable.' || E'\n\n' ||
    'Usages : visage, corps, hydratation, peau.' || E'\n\n' ||
    'Mode d''emploi : appliquer une noisette de crème sur peau propre, matin et/ou soir, en massant jusqu''à absorption complète. Convient au visage comme au corps.' || E'\n\n' ||
    'Ingrédients clés : beurre de karité, glycérine (agent hydratant), agents émollients.',
    array['Visage','Corps','Hydratation','Peau']
  ),
  (
    'Softberry Rose Honey Milk Moisturizer',
    'Crème hydratante au miel, au lait et à l''eau de rose. Sa formule enrichie en glycérine aide à maintenir l''hydratation de la peau tout en lui apportant douceur et confort.' || E'\n\n' ||
    'Usages : visage, corps, hydratation, peau.' || E'\n\n' ||
    'Mode d''emploi : appliquer quotidiennement sur peau propre, matin et/ou soir, en effectuant un léger massage circulaire jusqu''à absorption complète.' || E'\n\n' ||
    'Ingrédients clés : miel, lait, eau de rose, glycérine.',
    array['Visage','Corps','Hydratation','Peau']
  ),
  (
    'Softberry Red Wine Face And Body Scrub',
    'Gommage exfoliant visage & corps au vin rouge et extrait de raisin, enrichi en huiles végétales (coco, olive, amande). Il élimine en douceur les cellules mortes tout en préservant le confort de la peau.' || E'\n\n' ||
    'Usages : corps, visage, peau.' || E'\n\n' ||
    'Mode d''emploi : appliquer sur peau humide, masser en mouvements circulaires pendant 1 à 2 minutes, puis rincer abondamment à l''eau tiède. Usage conseillé 1 à 2 fois par semaine.' || E'\n\n' ||
    'Ingrédients clés : extrait de raisin, huiles végétales (coco, olive, amande), poudre de noix exfoliante.',
    array['Corps','Visage','Peau']
  )
) as v(name, description, use_cases)
where not exists (
  select 1 from public.products p
  where p.name = v.name and p.category = 'Soins du Corps & Cosmétiques'
);
