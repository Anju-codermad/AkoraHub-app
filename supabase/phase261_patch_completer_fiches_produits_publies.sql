-- ============================================================
-- AkoraHub - Patch Phase 261 : complète les fiches de produits DÉJÀ
-- PUBLIÉS (visibility = true) dont la description ou la liste
-- d'usages était manquante/trop courte — demande explicite de la
-- propriétaire (12/10) : "chaque produit [publié] à des informations
-- complètes et liste des usages complet".
--
-- Identifié par audit (2 requêtes de diagnostic lancées par la
-- propriétaire dans Supabase SQL Editor le 12/10, sur les 70 produits
-- publiés) : 1 sans description, 4 sans aucun usage, 20 avec un seul
-- usage. Liste exhaustive des 25 produits concernés ci-dessous.
--
-- Contenu non inventé : les usages ajoutés sont des applications
-- plausibles et génériques pour la famille de produit (cohérentes
-- avec la description déjà en base), pas des garanties techniques —
-- même règle que pour tous les brouillons ajoutés cette session.
--
-- Chaque UPDATE est gardé par le nom exact du produit + la condition
-- "toujours incomplet" (pour ne jamais écraser une correction que la
-- propriétaire aurait déjà faite elle-même depuis l'Admin entre temps)
-- — script rejouable sans risque.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

-- ------------------------------------------------------------
-- Akor'Eau
-- ------------------------------------------------------------

update public.products
set use_cases = array[
  'Adoucissement de l''eau de chaudière',
  'Adoucissement de l''eau domestique',
  'Adoucissement de l''eau industrielle',
  'Prétraitement avant osmose inverse'
]
where name = 'Résine échangeuse de cations (adoucissement)'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

update public.products
set use_cases = array[
  'Anti-tartre pour circuits d''eau',
  'Séquestrant de calcium, magnésium et fer',
  'Dispersant en traitement de l''eau industrielle'
]
where name = 'Hexamétaphosphate de sodium (SHMP)'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

update public.products
set use_cases = array[
  'Coagulation des eaux usées',
  'Élimination du phosphore',
  'Clarification de l''eau potable',
  'Déshydratation des boues'
]
where name = 'Chlorure ferrique (FeCl₃)'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

update public.products
set use_cases = array[
  'Coagulation de l''eau potable',
  'Traitement des eaux industrielles',
  'Traitement des eaux usées'
]
where name = 'PAC (Polychlorure d''aluminium)'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

update public.products
set use_cases = array[
  'Coagulation et clarification de l''eau',
  'Traitement des eaux usées',
  'Élimination du phosphore'
]
where name = 'Sulfate ferrique (Fe₂(SO₄)₃)'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

update public.products
set use_cases = array[
  'Réduction du pH de l''eau de piscine',
  'Correction du pH en traitement de l''eau',
  'Nettoyants acides pour sanitaires'
]
where name = 'Bisulfate de sodium (NaHSO₄)'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

update public.products
set use_cases = array[
  'Remontée du pH de l''eau (chaulage)',
  'Traitement des eaux usées',
  'Désinfection de l''eau'
]
where name = 'Chaux eteinte'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

update public.products
set use_cases = array[
  'Floculation après coagulation (eau potable)',
  'Traitement des eaux usées',
  'Déshydratation des boues'
]
where name = 'Polyacrylamide (PAM)'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

update public.products
set use_cases = array[
  'Clarification des eaux de surface',
  'Traitement des eaux usées',
  'Déshydratation des boues (stations d''épuration)'
]
where name = 'Polymeres floculants'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

-- ------------------------------------------------------------
-- Akora Coatings (pilier déjà existant en base sous un slug non
-- identifié avec certitude — mise à jour par nom de produit, pas par
-- slug, pour ne pas dépendre de cette inconnue). Catégorie vide
-- complétée au passage.
-- ------------------------------------------------------------

update public.products
set category = coalesce(nullif(trim(category), ''), 'Résines et polymères'),
    use_cases = array[
      'Fabrication de peintures',
      'Fabrication de vernis',
      'Revêtements pour bois et métaux',
      'Finitions brillantes ou satinées'
    ]
where name = 'Résine Alkyde'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

-- ------------------------------------------------------------
-- Akora Lab — catégorie vide complétée au passage.
-- ------------------------------------------------------------

update public.products
set category = coalesce(nullif(trim(category), ''), 'Consommables de laboratoire'),
    use_cases = array[
      'Filtration en laboratoire',
      'Clarification de liquides',
      'Filtration industrielle'
    ]
where name = 'Papier filtre standard lisse grande 600'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

-- ------------------------------------------------------------
-- Akora NutriSource
-- ------------------------------------------------------------

update public.products
set use_cases = array[
  'Acidifiant pour boissons et confiseries',
  'Conservateur et antioxydant alimentaire',
  'Régulateur de pH',
  'Détartrant écologique'
]
where name = 'Acide citrique monohydraté (E330)'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

-- ------------------------------------------------------------
-- Akora Packaging
-- ------------------------------------------------------------

update public.products
set use_cases = array[
  'Flacons de gel douche et shampoing',
  'Flacons de produits d''entretien liquides',
  'Bidons de détergent liquide'
]
where name = 'Bouchon push-pull'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

-- ------------------------------------------------------------
-- Akora Pro — Acides & Bases
-- ------------------------------------------------------------

update public.products
set use_cases = array[
  'Insecticide (fourmis, blattes)',
  'Antifongique pour traitement du bois',
  'Nettoyant désinfectant'
]
where name = 'Acide borique'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

update public.products
set use_cases = array[
  'Décapage des métaux',
  'Passivation de l''inox',
  'Réactif de laboratoire et d''analyse'
]
where name = 'Acide nitrique (HNO₃) 68 %,'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

update public.products
set use_cases = array[
  'Détergent et nettoyant alcalin',
  'Adjuvant anti-redéposition dans les lessives',
  'Fabrication de savons et détergents'
]
where name = 'Silicate de sodium'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

-- ------------------------------------------------------------
-- Akora Pro — Conservateurs & Antioxydants
-- ------------------------------------------------------------

update public.products
set use_cases = array[
  'Conservateur alimentaire (fromages, pâtisseries, boissons, conserves)',
  'Stabilisation des vins moelleux (œnologie)',
  'Conservateur en cosmétique (crèmes, lotions)'
]
where name = 'Sorbate de potassium (E202)'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

-- ------------------------------------------------------------
-- Akora Pro — Épaississants
-- ------------------------------------------------------------

update public.products
set use_cases = array[
  'Stabilisant pour boissons et sauces',
  'Épaississant pour dentifrices et cosmétiques',
  'Agent de texture en boulangerie-pâtisserie',
  'Stabilisant pour glaces et sorbets'
]
where name = 'CMC / Carboxyméthylcellulose (E466) — Tylose'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

-- ------------------------------------------------------------
-- Akora Pro — Tensioactifs
-- ------------------------------------------------------------

update public.products
set use_cases = array[
  'Shampoings et gels douche',
  'Bains moussants',
  'Nettoyants visage',
  'Produits pour bébés'
]
where name = 'CAPB 45%'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

update public.products
set use_cases = array[
  'Shampoings et gels douche très doux',
  'Produits pour bébé',
  'Lingettes nettoyantes'
]
where name = 'Coco Glucoside'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

update public.products
set use_cases = array[
  'Épaississant pour shampoings',
  'Épaississant pour gels douche',
  'Stabilisant de mousse pour bains moussants'
]
where name = 'Comperlan / Cocamide DEA 85%'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

update public.products
set use_cases = array[
  'Shampoings et gels douche doux',
  'Nettoyants pour peau sensible et bébé',
  'Formulations cosmétiques bio/Ecocert'
]
where name = 'Decyl Glucoside'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

update public.products
set description = coalesce(
  nullif(trim(description), ''),
  'Tensioactif anionique de base, très moussant et nettoyant, utilisé comme pilier de la plupart des formulations de lessives liquides, shampoings et gels douche. Concentration commerciale 70 %, origine Corée du Sud. Généralement associé à des tensioactifs secondaires (amphotères, non ioniques) pour adoucir la formule finale.'
)
where name = 'SLES 70% (Made in Korea)'
  and visibility = true
  and (description is null or trim(description) = '');

-- ------------------------------------------------------------
-- Akora Foods — Miel
-- ------------------------------------------------------------

update public.products
set use_cases = array[
  'Consommation directe',
  'Petit-déjeuner (tartines, yaourts)',
  'Boissons chaudes (thé, tisane)'
]
where name = 'Miel de niaouli'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

update public.products
set use_cases = array[
  'Consommation directe',
  'Petit-déjeuner (tartines, yaourts)',
  'Pâtisserie et cuisine'
]
where name = 'Miel polyfloral'
  and visibility = true
  and (use_cases is null or coalesce(array_length(use_cases,1),0) < 2);

-- Vérification : relancer après exécution, devrait renvoyer 0 lignes
-- (sauf produits corrigés manuellement entre-temps avec un contenu
-- toujours jugé insuffisant par ce même filtre) :
-- select bu.name as pilier, p.category, p.name, p.description,
--        array_length(p.use_cases,1) as nb_usages
-- from public.products p
-- join public.business_units bu on bu.id = p.business_unit_id
-- where p.visibility = true
--   and (p.description is null or trim(p.description) = ''
--        or p.use_cases is null or coalesce(array_length(p.use_cases,1),0) < 2)
-- order by bu.name, p.category, p.name;
