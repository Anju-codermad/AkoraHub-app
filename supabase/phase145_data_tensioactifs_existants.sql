-- ============================================================
-- AkoraHub - Patch Phase 145 : fiches Académie pour les 14 produits
-- "Tensioactifs" déjà présents au catalogue mais non documentés —
-- contenu DeepSeek, vérifié par l'utilisatrice.
-- SLES/SLS documentés avec avertissement irritation à haute
-- concentration ; SLES avec avertissement 1,4-dioxane (éthoxylé).
-- LABSA (acide libre) documenté Corrosif, distinct du LAS (sel
-- neutralisé, Modéré). Cocamide DEA documenté avec note sur le
-- risque de nitrosamines (N-nitrosodiéthanolamine) et recommandation
-- de préférer MEA/MIPA — reste un produit légal, non gaté. Alkyl
-- polyglucosides (Decyl/Lauryl/Coco Glucoside) documentés comme
-- très doux, biodégradables, non éthoxylés.
-- Clôture la catégorie "Tensioactifs" (51/51) et la campagne
-- complète des 12 catégories Académie.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Sodium Laureth Sulfate (SLES)
  -- ------------------------------------------------------------
  v_material_id := 'f1e0b36d-e359-468b-870c-904be36befa6'::uuid;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Sodium laureth sulfate (mélange de sels de sodium de sulfates d''alcools lauriques éthoxylés, degré d''éthoxylation moyen 1-3)',
    'SLES, Sodium lauryl ether sulfate, Texapon N70, Sulfate de laureth de sodium',
    'Cosmétique',
    'Liquide visqueux incolore à jaune pâle, odeur caractéristique faible',
    '7,0 - 8,5 (solution à 1 %)',
    'Soluble dans l''eau en toutes proportions',
    1.05, null,
    'Tensioactif anionique éthoxylé, très utilisé pour son excellent rapport qualité/prix. Mousse abondante et dense. Moins irritant que le SLS grâce au groupe éthoxylé. En raison du procédé d''éthoxylation, le produit peut contenir des traces résiduelles de 1,4-dioxane (cancérogène possible) ; il est impératif d''exiger du fournisseur un certificat d''analyse garantissant une teneur inférieure aux seuils réglementaires (généralement < 10 ppm).',
    'Comparé au Sodium Lauryl Sulfate (SLS), le SLES est nettement moins irritant pour la peau et les yeux, tout en conservant un fort pouvoir moussant. Il est plus facile à épaissir avec du sel ou des amphotères.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en nitrile ou en caoutchouc, lunettes de sécurité. Éviter le contact prolongé avec la peau et les projections oculaires.',
    'Yeux : rincer abondamment à l''eau pendant 15 minutes. Peau : laver à l''eau et au savon. Inhalation : air frais. Ingestion : rincer la bouche, boire de l''eau, consulter un médecin si symptômes.',
    'Tensioactifs cationiques (précipitation), oxydants forts, acides concentrés.',
    'Récipient hermétique en PEHD, dans un endroit frais et ventilé. Éviter le gel (cristallisation possible) et les températures supérieures à 40°C.',
    5, 35, false, false, 24, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280', 'P305+P351+P338', 'P337+P313')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Shampoings, gels douche, bains moussants, savons liquides',
   'Incorporer dans la phase aqueuse sous agitation douce. Pour ajuster la viscosité, ajouter du sel (NaCl) ou une bétaïne après dilution. Peut être mélangé à froid.',
   'plage', 5, 25, '% du produit fini', '20 - 40 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Sodium Lauryl Sulfate (SLS)
  -- ------------------------------------------------------------
  v_material_id := '9720a675-ce09-49b0-8e9e-4c9f08eff3ba'::uuid;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Sodium lauryl sulfate (mélange de sels de sodium de sulfates d''alcools lauriques C12-C14)',
    'SLS, Sodium dodecyl sulfate, Sulfate de lauryle de sodium, SDS',
    'Cosmétique',
    'Poudre blanche à blanc cassé (aiguilles, poudre ou granulés), odeur neutre à légèrement grasse',
    '7,0 - 9,5 (solution à 1 %)',
    'Soluble dans l''eau (jusqu''à 30 % environ), partiellement soluble dans l''alcool',
    0.55, null,
    'Tensioactif anionique non éthoxylé, extrêmement détergent et dégraissant. Produit une mousse très abondante et stable. À l''état pur ou à des concentrations élevées (> 5 % dans le produit fini), il est irritant pour la peau et les muqueuses, et peut provoquer un dessèchement cutané. Ne contient pas de risque 1,4-dioxane.',
    'Comparé au SLES, le SLS est plus irritant et détergent, mais il ne présente aucun risque de contamination par le 1,4-dioxane. Il est moins cher mais nécessite un bon conditionnement (agents adoucissants) pour un usage quotidien.',
    'Modéré',
    array['gants','lunettes','masque'],
    'Gants en nitrile, lunettes de sécurité. La poudre étant volatile, porter un masque anti-poussière (type FFP2) pour éviter l''inhalation.',
    'Yeux : rincer abondamment à l''eau pendant 15 minutes, consulter un médecin. Peau : laver à l''eau savonneuse. Inhalation : air frais, consulter si gêne. Ingestion : rincer la bouche, boire de l''eau, ne pas faire vomir, consulter un médecin.',
    'Tensioactifs cationiques, acides forts (hydrolyse), oxydants forts.',
    'Récipient étanche, au sec, à l''abri de l''humidité pour éviter la prise en masse. Température ambiante.',
    5, 35, true, false, 36, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H315', 'H318', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P280', 'P305+P351+P338', 'P301+P312')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Dentifrices, shampoings, gels douche, nettoyants ménagers',
   'Dissoudre la poudre dans l''eau tiède (30-40°C) sous agitation. Ajuster le pH si nécessaire (acide citrique). Ajouter les autres ingrédients après refroidissement.',
   'plage', 2, 15, '% du produit fini', '20 - 50 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Sodium Lauryl Sulfoacetate (SLSA)
  -- ------------------------------------------------------------
  v_material_id := 'd69552e4-bf4c-4984-898e-5bd924db9175'::uuid;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Sodium lauryl sulfoacetate',
    'SLSA, Sulfoacétate de lauryle de sodium, tensioactif solide doux',
    'Cosmétique',
    'Poudre blanche fine à granulés, odeur neutre à légèrement vinaigrée',
    '5,0 - 7,0 (solution à 1 %)',
    'Soluble dans l''eau chaude, se disperse dans l''eau froide',
    0.60, null,
    'Tensioactif anionique non éthoxylé, réputé pour sa grande douceur. Mousse crémeuse, stable et onctueuse. pH proche de la neutralité. Très bien toléré par la peau, même sensible. Exempt de sulfates agressifs et de 1,4-dioxane. Particulièrement adapté aux formulations solides (syndets, shampoings solides, bombes de bain).',
    'Comparé au SLS, le SLSA est beaucoup moins irritant et ne déshydrate pas la peau. Il est le tensioactif de référence pour les produits "sans sulfates" et pour peaux délicates, bien que son pouvoir moussant soit légèrement inférieur.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour la manipulation de la poudre. Éviter l''inhalation.',
    'Yeux : rincer à l''eau. Peau : laver à l''eau. Inhalation : air frais. Ingestion : rincer la bouche, boire de l''eau.',
    'Oxydants forts, acides concentrés (hydrolyse).',
    'Récipient étanche, au sec, à température ambiante. Éviter l''humidité (prise en masse).',
    5, 35, true, false, 36, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Savons solides sans savon (syndets), shampoings solides, bombes de bain moussantes',
   'Faire fondre avec un peu d''eau ou de glycérine à feu doux (70-80°C) ou incorporer directement en poudre dans un mélange pâteux. Ne pas dépasser 80°C pour éviter la dégradation.',
   'plage', 10, 70, '% du produit fini', '40 - 80 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Sodium Coco-Sulfate (SCS)
  -- ------------------------------------------------------------
  v_material_id := 'f8b605d0-8a9d-46c5-a8f1-772c2c6eda1e'::uuid;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Sodium coco-sulfate (mélange de sels de sodium de sulfates d''alcools de noix de coco C8-C18)',
    'SCS, Sodium coco sulfate, Cocosulfate de sodium, tensioactif solide',
    'Cosmétique',
    'Poudre ou granulés blancs à jaune pâle, odeur faible de noix de coco',
    '8,0 - 10,0 (solution à 1 %)',
    'Soluble dans l''eau chaude, se gélifie à haute concentration',
    0.65, null,
    'Tensioactif anionique non éthoxylé, issu de la sulfatation des alcools de noix de coco. Il combine les propriétés moussantes du SLS avec une certaine douceur apportée par les chaînes grasses longues (C14-C18). Exempt de 1,4-dioxane. Idéal pour les shampoings et savons solides. Peut laisser un léger film sur les cheveux si utilisé seul.',
    'Comparé au SLS (laurique pur), le SCS a une distribution de chaînes plus large, ce qui le rend un peu moins irritant et moins décapant, tout en maintenant un très bon niveau de mousse. Il est souvent considéré comme un bon compromis entre performance et tolérance.',
    'Modéré',
    array['gants','lunettes','masque'],
    'Gants en nitrile, lunettes de sécurité, masque anti-poussière. Éviter le contact avec les yeux.',
    'Yeux : rincer abondamment 15 minutes. Peau : laver à l''eau. Inhalation : air frais. Ingestion : rincer la bouche, boire de l''eau, consulter un médecin.',
    'Tensioactifs cationiques, acides forts, oxydants forts.',
    'Récipient étanche, au sec, à température ambiante.',
    5, 35, true, false, 36, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Shampoings solides, savons solides, poudres de bain moussantes',
   'Incorporer la poudre ou les granulés directement dans la formule chaude (70-80°C) en agitant jusqu''à dissolution. Pour les produits solides, mélanger à sec puis ajouter un liant.',
   'plage', 10, 60, '% du produit fini', '40 - 80 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- LAS
  -- ------------------------------------------------------------
  v_material_id := '7678d680-5be7-4f45-b6fe-851f749e045e'::uuid;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Alkylbenzène sulfonate de sodium linéaire (chaîne alkyle C10-C13)',
    'LAS, Sulfonate d''alkylbenzène linéaire, Alkylbenzène sulfonate de sodium',
    'Technique',
    'Poudre blanche à jaune pâle, ou pâte épaisse, odeur caractéristique de détergent',
    '7,0 - 9,0 (solution à 1 %)',
    'Soluble dans l''eau, partiellement soluble dans l''alcool',
    1.00, null,
    'Tensioactif anionique de synthèse le plus produit au monde, principalement utilisé dans les lessives et produits de nettoyage. Excellente détergence, bon rapport qualité/prix. Mousse abondante en eau douce. Biodégradable en aérobiose. Non éthoxylé, sans risque 1,4-dioxane. Sous sa forme de sel (neutralisé), il est moins irritant que l''acide correspondant (LABSA).',
    'Comparé au LABSA (acide libre), le LAS est un sel déjà neutralisé, prêt à l''emploi et beaucoup moins dangereux à manipuler. Il offre une détergence puissante, comparable aux sulfates d''alcool gras, mais son profil biodégradable anaérobie est moins bon.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en caoutchouc, lunettes de sécurité. Éviter le contact cutané prolongé.',
    'Yeux : rincer abondamment. Peau : laver à l''eau et au savon. Inhalation : air frais. Ingestion : rincer la bouche, boire de l''eau.',
    'Tensioactifs cationiques, acides forts (reformation de LABSA insoluble), oxydants forts.',
    'Sacs étanches ou bidons, au sec, à l''abri de l''humidité. Éviter les températures extrêmes.',
    5, 40, true, false, 24, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Lessives liquides et en poudre, liquides vaisselle, nettoyants multi-usages',
   'Dissoudre dans l''eau chaude (40-50°C) sous agitation. Neutraliser si nécessaire (si l''on part de LABSA, utiliser de la soude). Ajouter les autres composants après clarification.',
   'plage', 5, 25, '% du produit fini', '20 - 60 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- LABSA (Acide Sulfonique Lineaire)
  -- ------------------------------------------------------------
  v_material_id := '1e373a68-1591-4acf-9943-c9d00c8161c8'::uuid;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Acide alkylbenzène sulfonique linéaire (chaîne alkyle C10-C13)',
    'LABSA, Acide sulfonique linéaire, Alkylbenzène sulfonique acide, Dodecylbenzene sulfonic acid',
    'Technique',
    'Liquide visqueux brun foncé à ambré, odeur âcre et piquante caractéristique',
    'Fortement acide (pH < 1 à l''état pur)',
    'Soluble dans l''eau (réaction exothermique), soluble dans de nombreux solvants organiques',
    1.06, 180.0,
    'Acide fort, précurseur de tous les sulfonates d''alkylbenzène (LAS). Il doit être neutralisé par une base (soude, potasse, ammoniaque) avant utilisation comme tensioactif. Extrêmement corrosif à l''état pur pour la peau, les yeux et les métaux. Produit non éthoxylé, sans risque 1,4-dioxane.',
    'Contrairement au LAS (sel), le LABSA est l''acide libre : il est donc beaucoup plus agressif et requiert des précautions de manipulation sévères. Il permet de formuler des détergents avec un choix libre du contre-ion (sodium, potassium, ammonium).',
    'Corrosif',
    array['gants','lunettes','tablier','ventilation','bottes'],
    'Gants en caoutchouc butyle ou nitrile épais, lunettes de sécurité étanches ou écran facial, tablier anti-acide, chaussures de sécurité fermées. Manipuler sous hotte ou avec une ventilation forcée.',
    'Peau : rincer immédiatement et abondamment à l''eau pendant au moins 20 minutes, retirer les vêtements contaminés. Yeux : rincer à grande eau en écartant les paupières pendant 20 minutes, consulter un ophtalmologue en urgence. Ingestion : rincer la bouche, ne pas faire vomir, appeler immédiatement un centre antipoison. Inhalation : air frais, consulter.',
    'Bases fortes (réaction violente avec dégagement de chaleur), métaux, oxydants puissants.',
    'Récipient en acier inoxydable ou plastique résistant aux acides (PEHD). Local frais, sec, ventilé, à l''écart des bases et des matières combustibles. Mettre en rétention.',
    10, 35, false, false, 24, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H314', 'H318', 'H335', 'H315')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P280', 'P301+P330+P331', 'P303+P361+P353', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Fabrication de détergents (lessives, liquides vaisselle) après neutralisation par une base',
   'Diluer lentement dans l''eau (jamais l''inverse) en refroidissant si nécessaire. Neutraliser progressivement avec une solution de soude caustique (ou de potasse) jusqu''à pH 7-8. Le sel formé (LAS) est alors le tensioactif actif.',
   'plage', 5, 20, '% d''acide pur avant neutralisation dans la formule finale', '20 - 50 °C (contrôler l''exothermie)', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- CAPB
  -- ------------------------------------------------------------
  v_material_id := 'c250cb28-c06e-452e-a01b-c36d196ee54f'::uuid;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Cocamidopropyl bétaïne (mélange d''amido-alkyl bétaïnes dérivées de l''huile de coco)',
    'CAPB, Cocoamidopropyl bétaïne, Tego Betaine L7, Dehyton K, tensioactif amphotère',
    'Cosmétique',
    'Liquide visqueux incolore à jaune pâle, odeur neutre',
    '5,0 - 7,0 (solution à 1 %)',
    'Soluble dans l''eau en toutes proportions',
    1.05, null,
    'Tensioactif amphotère à dominante douce. Épaississant et booster de mousse lorsqu''il est associé aux anioniques (SLES, SLS). Réduit l''irritation des formules lavantes. Non éthoxylé, sans risque 1,4-dioxane. Très bonne tolérance cutanée et oculaire. Stable sur une large plage de pH.',
    'Comparé à la Cocamidopropyl Hydroxysultaine, la CAPB est légèrement moins performante en milieu très alcalin ou en présence de fortes concentrations de sels, mais elle est généralement plus économique.',
    'Faible',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité. Éviter le contact avec les yeux à l''état pur.',
    'Yeux : rincer à l''eau. Peau : laver à l''eau. Ingestion : rincer la bouche, boire de l''eau.',
    'Agents oxydants forts.',
    'Bidon hermétique en PEHD, à température ambiante. Éviter le gel (cristallisation possible) et les températures > 40°C.',
    5, 35, false, false, 24, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Shampoings, gels douche, bains moussants, nettoyants visage, produits pour bébés',
   'Incorporer directement dans la phase aqueuse après les tensioactifs principaux. Utiliser 1 à 5 % comme co-tensioactif doux ou jusqu''à 10 % comme tensioactif principal. Ajuster le pH entre 4,5 et 6,5.',
   'plage', 3, 10, '% du produit fini', '20 - 40 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Cocamidopropyl Hydroxysultaine
  -- ------------------------------------------------------------
  v_material_id := 'de39c0a1-cb34-452a-90ed-cbf223c1c49b'::uuid;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Cocamidopropyl hydroxysultaine (mélange d''amido-alkyl sultaines dérivées de l''huile de coco)',
    'CAHS, Cocamidopropyl hydroxysultaine, Sulfobétaïne de coco, Mackam CBS-50',
    'Cosmétique',
    'Liquide visqueux incolore à jaune pâle, odeur neutre',
    '5,5 - 7,0 (solution à 1 %)',
    'Soluble dans l''eau en toutes proportions',
    1.05, null,
    'Tensioactif amphotère de la famille des sultaines. Excellente stabilité en milieux acides et alcalins, et en présence d''électrolytes (sel). Très bon booster de mousse et de viscosité. Mousse dense et crémeuse. Non éthoxylé, sans 1,4-dioxane. Encore plus doux que la CAPB.',
    'Comparée à la Cocamidopropyl Betaine (CAPB), l''hydroxysultaine offre une meilleure tolérance aux fortes concentrations en sel et aux pH extrêmes, ce qui la rend idéale pour les formules techniques ou les produits contenant des actifs acides (AHA).',
    'Faible',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité.',
    'Yeux : rincer à l''eau. Peau : laver. Ingestion : rincer la bouche, boire de l''eau.',
    'Agents oxydants très forts.',
    'Bidon hermétique en PEHD, à température ambiante. Protéger du gel.',
    5, 35, false, false, 24, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Shampoings, produits nettoyants acides (gommages AHA), produits pour bébés, gels douche',
   'Ajouter dans la phase aqueuse, seule ou en association avec des anioniques. Dosage optimal comme booster entre 2 et 6 %. Compatible avec les pH acides.',
   'plage', 2, 8, '% du produit fini', '20 - 40 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Sodium Lauroyl Sarcosinate
  -- ------------------------------------------------------------
  v_material_id := '3aa1d0ec-0d86-40d6-9a61-77e4c40f4773'::uuid;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Sodium lauroyl sarcosinate',
    'Sodium lauroyl sarcosinate, Sarcosinate de lauryle de sodium, Crodasinic LS30, Medialan LD',
    'Cosmétique',
    'Liquide incolore à jaune très pâle, légèrement visqueux, odeur neutre',
    '7,0 - 8,5 (solution à 1 %)',
    'Soluble dans l''eau',
    1.02, null,
    'Tensioactif anionique doux, dérivé d''acide aminé (sarcosine) et d''acide laurique. Mousse fine et crémeuse, même en eau dure. Excellent pour les formulations "sans sulfates". Non éthoxylé, sans risque 1,4-dioxane. Compatible avec les agents cationiques, ce qui est rare pour un anionique.',
    'Comparé au SLS, le lauroyl sarcosinate est infiniment plus doux, mais son pouvoir moussant est modéré. Il est souvent utilisé en synergie avec des amphotères pour les nettoyants visage doux.',
    'Faible',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité.',
    'Yeux : rincer. Peau : laver. Ingestion : rincer la bouche, boire de l''eau.',
    'Acides forts (hydrolyse), oxydants forts.',
    'Bidon hermétique, à température ambiante. Protéger du gel.',
    5, 35, false, false, 24, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Nettoyants visage doux, gels douche "sans sulfates", dentifrices, produits pour bébés',
   'Incorporer dans la phase aqueuse à froid ou tiède. Peut être utilisé seul (5-15%) ou en combinaison avec des amphotères.',
   'plage', 5, 15, '% du produit fini', '20 - 40 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Comperlan / Cocamide DEA
  -- ------------------------------------------------------------
  v_material_id := '7e4b34f9-a71e-451c-a3d3-a5b71ab6a8db'::uuid;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Diéthanolamide d''acide gras de noix de coco',
    'Cocamide DEA, Comperlan, Diéthanolamide de coco, Ninol',
    'Cosmétique',
    'Liquide visqueux ambré à brun, ou pâte molle, odeur caractéristique d''amide',
    '9,0 - 10,5 (solution à 1 %)',
    'Dispersible dans l''eau, soluble dans les tensioactifs et les alcools gras',
    1.00, null,
    'Alcanolamide non ionique utilisé comme épaississant et stabilisateur de mousse. Excellent pour augmenter la viscosité des formules à base de SLES. En raison de sa teneur résiduelle possible en diéthanolamine (DEA), il peut former des nitrosamines (N-nitrosodiéthanolamine) suspectées cancérogènes en présence d''agents nitrosants. Ce risque est maîtrisé dans les produits de qualité cosmétique mais doit être connu. Privilégier le Cocamide MEA/MIPA quand cela est possible. L''usage reste légal.',
    'Comparé au Cocamide MEA, le DEA est un meilleur épaississant et donne une mousse plus stable, mais il est moins sûr sur le plan toxicologique. Il est de plus en plus remplacé dans les formulations grand public.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes. Éviter le contact prolongé avec la peau et l''inhalation des vapeurs lors de la manipulation à chaud.',
    'Yeux : rincer. Peau : laver à l''eau et au savon. Ingestion : rincer la bouche, boire de l''eau, consulter un médecin si symptômes.',
    'Agents nitrosants (nitrites, acide nitreux), oxydants forts.',
    'Récipient hermétique, au sec, à l''abri de la chaleur et des agents nitrosants. Conserver dans un endroit ventilé.',
    10, 30, false, false, 24, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Épaississant pour shampoings, gels douche, bains moussants',
   'Incorporer 1 à 5 % dans la phase tensioactive chaude (40-50°C). Agiter jusqu''à homogénéité. Refroidir sous agitation.',
   'plage', 1, 5, '% du produit fini', '30 - 50 °C', 'Refroidissement lent', false, 0);

  -- ------------------------------------------------------------
  -- Decyl Glucoside
  -- ------------------------------------------------------------
  v_material_id := '4cd03d1c-6432-4b01-b29f-851d79219170'::uuid;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Decyl glucoside (mélange de glucosides d''alcools décyliques C10)',
    'Decyl glucoside, APG décylique, Plantacare 2000 UP, Tensioactif végétal non ionique',
    'Cosmétique',
    'Liquide visqueux incolore à jaune pâle, odeur neutre à légèrement sucrée',
    '11,5 - 12,5 (solution commerciale à 50 % de matière active)',
    'Soluble dans l''eau, partiellement soluble dans les alcools',
    1.15, null,
    'Tensioactif non ionique issu de matières premières renouvelables (glucose de maïs et alcool gras de coco/palme). Extrêmement doux, biodégradable, non éthoxylé (sans 1,4-dioxane). Mousse stable, résistante aux graisses. pH alcalin à l''état pur qui s''abaisse après dilution et ajout d''acide. Certifiable Ecocert/Cosmos.',
    'Comparé au Lauryl Glucoside (C12), le Decyl Glucoside (C10) a un pouvoir moussant légèrement plus faible mais une meilleure solubilité dans l''eau froide. Il est encore plus doux et convient aux produits pour bébés.',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes recommandés car le pH alcalin du concentré peut irriter. Ne pas laisser à la portée des enfants à l''état pur.',
    'Yeux : rincer abondamment. Peau : laver à l''eau. Ingestion : boire de l''eau.',
    'Acides forts (neutralisation exothermique), oxydants forts.',
    'Bidon en PEHD, à température ambiante. Éviter le gel. Le produit peut cristalliser à basse température ; réchauffer doucement pour homogénéiser.',
    5, 35, false, false, 24, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Nettoyants visage doux, gels douche bio, shampoings pour bébés, liquides vaisselle écologiques',
   'Incorporer dans la phase aqueuse après ajustement du pH. Ramener le pH final à 5-6 avec de l''acide citrique. Compatible avec les autres tensioactifs.',
   'plage', 5, 20, '% du produit fini', '20 - 40 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Lauryl Glucoside
  -- ------------------------------------------------------------
  v_material_id := '58b60ad2-ea81-418f-9ee8-4365074fc615'::uuid;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Lauryl glucoside (mélange de glucosides d''alcools lauriques C12)',
    'Lauryl glucoside, APG laurylique, Plantacare 1200 UP',
    'Cosmétique',
    'Liquide visqueux jaune pâle à incolore, odeur neutre',
    '11,5 - 12,5 (solution commerciale à 50 % de matière active)',
    'Soluble dans l''eau',
    1.15, null,
    'Tensioactif non ionique d''origine végétale, biodégradable, non éthoxylé. Mousse abondante et stable pour un non ionique. Très doux, il remplace avantageusement les sulfates dans les formules "sans SLES". Légèrement plus détergent que le Decyl Glucoside.',
    'Comparé au Decyl Glucoside, le Lauryl Glucoside (C12) produit une mousse plus riche et plus stable. Il est un peu moins doux mais reste bien toléré. Il est le choix standard pour les shampoings doux.',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes (pH alcalin du concentré).',
    'Yeux : rincer abondamment. Peau : laver. Ingestion : boire de l''eau.',
    'Acides forts, oxydants forts.',
    'Bidon en PEHD, à température ambiante. Éviter le gel. Réchauffer doucement en cas de cristallisation.',
    5, 35, false, false, 24, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Shampoings doux, gels douche, nettoyants ménagers écologiques',
   'Incorporer dans l''eau, ajuster le pH à 5-6 avec de l''acide citrique. Mousse stable en eau dure.',
   'plage', 5, 20, '% du produit fini', '20 - 40 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Coco Glucoside
  -- ------------------------------------------------------------
  v_material_id := '98924dd6-420c-4402-8d15-48510e98df4a'::uuid;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Coco glucoside (mélange de glucosides d''alcools de noix de coco C8-C16)',
    'Coco glucoside, APG de coco, Plantacare 818 UP, Tensioactif végétal non ionique',
    'Cosmétique',
    'Liquide visqueux jaune pâle, odeur neutre à légèrement fruitée',
    '11,5 - 12,5 (solution commerciale à 50 % de matière active)',
    'Soluble dans l''eau',
    1.15, null,
    'Tensioactif non ionique ultra-doux issu du glucose et de l''huile de coco. Biodégradable, non éthoxylé, certifié bio. Excellente tolérance cutanée. Mousse fine et onctueuse. Souvent utilisé en combinaison avec d''autres APG ou des amphotères pour un nettoyage très doux.',
    'Comparé au Lauryl Glucoside, le Coco Glucoside a une distribution de chaînes grasses plus large, ce qui lui confère un pouvoir moussant légèrement inférieur mais une douceur accrue. Il est souvent le choix de base pour les produits "ultra-doux".',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes (pH alcalin du concentré).',
    'Yeux : rincer abondamment. Peau : laver. Ingestion : boire de l''eau.',
    'Acides forts, oxydants forts.',
    'Bidon en PEHD, à température ambiante. Éviter le gel. Réchauffer doucement en cas de cristallisation.',
    5, 35, false, false, 24, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Shampoings et gels douche très doux, produits pour bébé, lingettes nettoyantes',
   'Incorporer dans la phase aqueuse, ajuster le pH à 5-6. Peut être utilisé seul (10-20 %) ou comme co-tensioactif.',
   'plage', 5, 20, '% du produit fini', '20 - 40 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- AOS (Sodium C14-16 Olefin Sulfonate)
  -- ------------------------------------------------------------
  v_material_id := '1a2956d6-9fd7-4aca-8f5e-a98e898284df'::uuid;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Sulfonate de sodium d''alpha-oléfines C14-C16 (mélange d''hydroxyalcanesulfonates et d''alcènesulfonates)',
    'AOS, Alpha Olefin Sulfonate, Sulfonate d''oléfine, Bio-Terge AS-40',
    'Cosmétique',
    'Liquide visqueux jaune pâle à incolore, ou poudre blanche, odeur caractéristique',
    '6,5 - 8,0 (solution à 1 %)',
    'Très soluble dans l''eau, bonne solubilité dans les solutions salines',
    1.05, null,
    'Tensioactif anionique non éthoxylé, très résistant à l''eau dure et aux électrolytes. Mousse abondante, stable, onctueuse. Pouvoir détergent élevé. Excellente stabilité en milieu acide ou alcalin. Biodégradable, sans risque 1,4-dioxane. Utilisé comme alternative au SLS/SLES dans les formulations techniques et cosmétiques.',
    'Comparé au SLES, l''AOS est plus stable à pH extrêmes et forme une mousse plus résistante en présence de sébum ou de salissures. Il est légèrement moins doux que le SLES mais reste bien toléré.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité. Éviter le contact avec les yeux à l''état pur.',
    'Yeux : rincer abondamment. Peau : laver à l''eau. Ingestion : rincer la bouche, boire de l''eau.',
    'Agents cationiques à forte dose, oxydants forts.',
    'Bidon hermétique en PEHD, à température ambiante. Éviter le gel.',
    5, 35, false, false, 24, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, point_eclair = excluded.point_eclair,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    temperature_stockage_min = excluded.temperature_stockage_min,
    temperature_stockage_max = excluded.temperature_stockage_max,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Shampoings, gels douche, liquides vaisselle, nettoyants industriels',
   'Ajouter directement dans la phase aqueuse. Compatible avec une large gamme de pH (3-12). Peut être utilisé seul ou en synergie avec d''autres tensioactifs.',
   'plage', 5, 25, '% du produit fini', '20 - 50 °C', 'Immédiat', false, 0);
end $$;
