-- ============================================================
-- AkoraHub - Patch Phase 115 : fiches Académie pour les 26 nouveaux
-- colorants ajoutés en phase 114 — contenu DeepSeek, vérifié par
-- l'utilisatrice.
--
-- Ne couvre pas encore les 14 produits déjà présents avant cette
-- campagne (10 colorants spécifiques + 4 entrées génériques de
-- famille : Colorants alimentaires certifiés, Colorants cosmétiques,
-- Colorants industriels, Pigments oxydes de fer/TiO2).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Bleu de méthylène
  -- ------------------------------------------------------------
  v_material_id := '26c529c5-f76b-44d4-be1a-f035ce115d9d'::uuid;

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
    'Chlorure de 3,7-bis(diméthylamino)phénothiazin-5-ium (C₁₆H₁₈ClN₃S)',
    'Bleu de méthylène, CI 52015, Basic Blue 9',
    'Technique',
    'Cristaux bleu foncé à reflets verts, ou poudre, inodore',
    'Soluble',
    'Soluble dans l''eau et l''alcool',
    0.90, null,
    'Colorant cationique bleu intense. Utilisé comme antiseptique doux (aquariophilie), en laboratoire (colorant histologique) et comme traceur. Tache fortement.',
    'Par rapport au bleu de toluidine, il est plus foncé et plus courant. Tache la peau et les vêtements de façon tenace.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en nitrile, éviter le contact avec la peau (taches). Ne pas ingérer.',
    'Yeux : rincer 15 min. Peau : laver à l''eau. Ingestion : rincer la bouche, boire de l''eau, consulter si gêne.',
    'Agents réducteurs forts, alcalis.',
    'Récipient étanche, au sec, à l''abri de la lumière.',
    5, 35, false, true, 48, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H315', 'H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280', 'P305+P351+P338', 'P301+P312')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Traitement de l''eau en aquariophilie (antiseptique doux)',
   'Préparer une solution mère à 1% et doser 1-2 gouttes par litre d''eau. Ne pas surdoser.',
   'plage', 0.5, 1, 'mg/L (ppm) d''eau d''aquarium', '20-25°C', '30 min, puis filtration sur charbon actif si nécessaire', false, 0),
  (v_academie_id, 'Traceur coloré et colorant de laboratoire',
   'Dissoudre 0,1-1% dans l''eau ou l''alcool pour les colorations.',
   'plage', 0.1, 1, '% dans la solution de travail', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Bleu patenté V (E131)
  -- ------------------------------------------------------------
  v_material_id := 'c16cef53-e28d-4aa3-8ae6-52455c0eb2d1'::uuid;

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
    'Sel de sodium de triarylméthane sulfoné (C₂₇H₃₁N₂NaO₇S₃)',
    'E131, bleu patenté V, CI 42051',
    'Alimentaire',
    'Poudre bleu foncé à violette, inodore',
    'Stable en milieu acide à neutre',
    'Très soluble dans l''eau',
    0.75, null,
    'Colorant triarylméthane bleu violacé. Moins utilisé depuis l''arrivée du bleu brillant FCF (E133). Peut provoquer des allergies rares.',
    'Par rapport au bleu brillant FCF (E133), il tire plus vers le violet. Plus sensible à la chaleur et à la lumière.',
    'Faible',
    array[]::text[],
    'Aucun obligatoire.',
    'Yeux : rincer. Peau : laver.',
    'Agents réducteurs (décoloration), chaleur prolongée.',
    'Récipient étanche, au sec, à température ambiante.',
    5, 35, true, false, 60, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Colorant pour glaces, confiseries, boissons, cosmétiques',
   'Dissoudre dans l''eau.',
   'plage', 0.005, 0.02, '% du produit fini', '20-80°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Brun FK (E154)
  -- ------------------------------------------------------------
  v_material_id := 'd7990997-fcc2-401d-bab3-b74d979fe879'::uuid;

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
    'Mélange de colorants azoïques, dérivés sulfonés de l''acide 1,3-benzènediamine et de l''acide 2,4-diaminobenzènesulfonique (mélange complexe)',
    'E154, brun FK, Food Brown FK, Kipper Brown',
    'Alimentaire',
    'Poudre brune à brun foncé, inodore',
    '6-7 (solution aqueuse à 1%)',
    'Très soluble dans l''eau, légèrement soluble dans l''éthanol',
    0.75, null,
    'Mélange de six colorants azoïques principaux. Usage alimentaire extrêmement restreint en UE : uniquement autorisé pour la coloration des kippers (harengs fumés) au Royaume-Uni et en Irlande. Teinte brune mate imitant le fumage traditionnel.',
    'Par rapport au Brun HT (E155), il est exclusivement réservé aux produits de la pêche fumés. Contrairement au caramel (E150), il ne colore pas en brun-rouge et est un colorant de synthèse. Sa réglementation est la plus restrictive parmi les colorants bruns alimentaires.',
    'Faible',
    array[]::text[],
    'Aucun équipement obligatoire. Éviter l''inhalation de poussières lors de la manipulation de grandes quantités.',
    'Yeux : rincer à l''eau. Peau : laver au savon. Ingestion : boire de l''eau. Aucune toxicité aiguë connue aux doses d''usage.',
    'Agents réducteurs forts (décoloration), oxydants puissants.',
    'Récipient étanche, au sec, à température ambiante, à l''abri de la lumière.',
    5, 35, true, false, 48, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Coloration des kippers (harengs fumés) — usage exclusif autorisé en UE',
   'Préparer une solution aqueuse de Brun FK, appliquer par trempage ou badigeonnage sur les harengs avant ou pendant le fumage à froid. Respecter la dose maximale réglementaire.',
   'valeur_unique', 20, null, 'mg/kg de produit fini (dose maximale légale UE)', 'Fumage à froid (20-30°C)', 'Pendant le processus de fumage (plusieurs heures)', false, 0);

  -- ------------------------------------------------------------
  -- Brun HT (E155)
  -- ------------------------------------------------------------
  v_material_id := 'ecb44b31-1120-4ad9-9bb9-6f63090941fe'::uuid;

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
    'Sel disodique d''un dérivé azoïque de benzènesulfonique (C₂₀H₁₄N₆Na₂O₉S₂)',
    'E155, brun HT, brun chocolat HT, CI 20285',
    'Alimentaire',
    'Poudre brun foncé, inodore',
    'Stable en milieu acide à neutre',
    'Très soluble dans l''eau',
    0.80, null,
    'Colorant azoïque brun chocolat. Principalement utilisé pour les biscuits, gâteaux et snacks. Soumis à restriction de dosage.',
    'Par rapport au caramel (E150d), il donne un brun plus foncé et moins rouge. Plus stable que les colorants naturels bruns (extraits de malt).',
    'Faible',
    array[]::text[],
    'Aucun obligatoire.',
    'Yeux : rincer. Peau : laver.',
    'Réducteurs, oxydants forts.',
    'Récipient étanche, au sec, à l''abri de la lumière.',
    5, 35, true, false, 60, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Coloration de biscuits, gâteaux, snacks apéritifs',
   'Ajouter dissous dans l''eau de la recette.',
   'valeur_unique', 0.02, null, '% du poids de la pâte', 'Jusqu''à 200°C (cuisson)', 'Avant cuisson', false, 0);

  -- ------------------------------------------------------------
  -- Carmin / Cochenille (E120)
  -- ------------------------------------------------------------
  v_material_id := '07384c09-9923-47ed-b7bf-903f0e7dc3ad'::uuid;

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
    'Acide carminique, extrait de cochenille Dactylopius coccus (C₂₂H₂₀O₁₃)',
    'E120, carmin, cochenille, rouge carmin, Natural Red 4',
    'Alimentaire',
    'Poudre rouge foncé à bordeaux, ou solution liquide, inodore',
    'Stable en milieu acide à neutre (pH 3-7)',
    'Soluble dans l''eau et les solutions hydroalcooliques, insoluble dans les huiles',
    0.90, null,
    'Colorant naturel d''origine animale (insectes). Excellente stabilité à la chaleur et à la lumière. Peut précipiter en milieu acide fort ou en présence de cations polyvalents. Non végétalien.',
    'Par rapport au rouge de betterave (E162), il est beaucoup plus stable à la chaleur et à la lumière, mais d''origine animale. Plus résistant que les anthocyanes en pH neutre.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. Éviter l''inhalation de poudre.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Cations métalliques (Al, Fe, Ca) → précipité. Milieux très acides (pH < 2).',
    'Récipient étanche, au frais, à l''abri de la lumière.',
    5, 25, true, true, 36, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Colorant alimentaire pour charcuterie, yaourts, bonbons, boissons',
   'Dissoudre dans l''eau ou la phase aqueuse avant ajout. Résiste à la pasteurisation.',
   'plage', 0.05, 0.5, '% du produit fini', '20-80°C', 'Immédiat', false, 0),
  (v_academie_id, 'Colorant cosmétique (rouges à lèvres, blush, fards)',
   'Disperser dans la phase grasse ou l''alcool, ou utiliser une laque de carmin (fixée sur substrat).',
   'plage', 0.5, 10, '% du produit fini', 'Ambiante à 70°C', 'Pendant le mélange', false, 1);

  -- ------------------------------------------------------------
  -- Chlorophylles et chlorophyllines (E140/E141)
  -- ------------------------------------------------------------
  v_material_id := '6445461c-267f-4adb-9afd-c4947dd1fa07'::uuid;

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
    'Chlorophylle a et b, extrait de plantes vertes (C₅₅H₇₂MgN₄O₅ / C₅₅H₇₀MgN₄O₆)',
    'E140, chlorophylle naturelle, CI 75810 ; forme hydrosoluble E141 (chlorophyllines cuivriques)',
    'Alimentaire',
    'Pâte vert foncé, poudre vert olive, ou liquide huileux, odeur végétale',
    'Stable en milieu neutre à légèrement alcalin',
    'Soluble dans les huiles et solvants organiques (liposoluble, E140). Les chlorophyllines (E141) sont hydrosolubles.',
    0.70, null,
    'Sensible à la chaleur, à la lumière et aux acides (perte du magnésium → brun). La forme liposoluble est E140, la forme hydrosoluble est E141 (chlorophyllines cuivriques).',
    'Par rapport au vert S (E142, synthétique), elle est naturelle mais moins stable. Plus foncée que le vert de spiruline. Les chlorophyllines (E141) sont plus stables et hydrosolubles.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. Protéger les vêtements (taches).',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Acides (démagnésiation → brun), lumière directe prolongée, oxydants.',
    'Récipient étanche, au frais, à l''abri de la lumière.',
    5, 25, true, true, 12, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Colorant vert pour glaces, pâtes, confiseries, chewing-gums',
   'Dissoudre dans la phase grasse chaude ou utiliser la forme E141 hydrosoluble.',
   'plage', 0.05, 0.5, '% du produit fini', 'Selon le procédé', 'Incorporation', false, 0),
  (v_academie_id, 'Colorant vert naturel pour savons et cosmétiques',
   'Ajouter la poudre ou la pâte dans la phase grasse avant saponification ou à la trace.',
   'plage', 0.5, 3, '% du poids des huiles', '30-40°C (trace)', 'Mélange', false, 1);

  -- ------------------------------------------------------------
  -- CI 15850 (rouge lithol, laque de calcium)
  -- ------------------------------------------------------------
  v_material_id := '394d15c3-9fda-4200-8be1-2f4132de7a60'::uuid;

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
    'Laque de calcium de l''acide 3-hydroxy-4-[(4-méthyl-2-sulfophényl)azo]-2-naphtalènecarboxylique (C₁₈H₁₂CaN₂O₆S)',
    'CI 15850, rouge lithol, D&C Red 7, Pigment Red 57',
    'Cosmétique',
    'Poudre rouge intense, inodore',
    'Insoluble (laque), stable dans les huiles',
    'Insoluble dans l''eau, dispersible dans les huiles et les bases grasses',
    0.90, null,
    'Laque de calcium utilisée pour les rouges à lèvres, blushs, vernis à ongles. Excellente stabilité à la lumière et à la chaleur. Non approuvée pour l''alimentaire.',
    'Par rapport au carmin (E120), il est synthétique, plus vif et plus stable. Contrairement aux colorants solubles, il est utilisé sous forme de dispersion.',
    'Faible',
    array[]::text[],
    'Éviter l''inhalation de poudre.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants puissants.',
    'Récipient étanche, au sec, à l''abri de la lumière.',
    5, 35, false, false, 60, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Pigment pour rouges à lèvres, blushs, vernis à ongles',
   'Disperser la poudre dans l''huile de ricin ou autre liant, broyer finement avant incorporation.',
   'plage', 5, 30, '% du produit fini', 'Ambiante à 80°C', 'Pendant le mélange', false, 0);

  -- ------------------------------------------------------------
  -- CI 61570 (vert D&C, laque d'aluminium)
  -- ------------------------------------------------------------
  v_material_id := 'c74efff9-13cf-4ddb-98af-d9b50d79e100'::uuid;

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
    'Sel disodique d''un dérivé anthraquinonique sulfoné (C₂₈H₂₂N₂Na₂O₈S₂)',
    'CI 61570, D&C Green 5, vert acide',
    'Cosmétique',
    'Poudre vert foncé, inodore',
    'Stable',
    'Soluble dans l''eau',
    0.85, null,
    'Colorant anthraquinonique vert pour cosmétiques. Utilisé dans les savons, bains moussants, gels douche.',
    'Moins utilisé que le mélange de colorants jaune et bleu pour faire du vert. Teinte plus pure que le vert S (E142).',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer.',
    'Réducteurs.',
    'Récipient étanche, au sec.',
    5, 35, true, false, 60, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Colorant vert pour savons, gels douche, bains moussants',
   'Dissoudre dans la phase aqueuse.',
   'plage', 0.05, 0.3, '% du produit', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- CI 77007 (outremer bleu)
  -- ------------------------------------------------------------
  v_material_id := '01d7859f-194e-4e41-a477-3bbf8116761f'::uuid;

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
    'Silicate d''aluminium et de sodium soufré (Na₇Al₆Si₆O₂₄S₃)',
    'CI 77007, bleu outremer, ultramarine, pigment bleu 29',
    'Cosmétique',
    'Poudre bleu profond, inodore',
    'Alcalin (8-9 en suspension)',
    'Insoluble, se disperse',
    2.35, null,
    'Pigment minéral bleu traditionnel. Excellent pouvoir couvrant, stable à la chaleur et à la lumière. Utilisé comme azurant optique dans les lessives.',
    'Par rapport aux colorants organiques, il est minéral, plus couvrant mais plus terne. Ne pas confondre avec le bleu de cobalt.',
    'Faible',
    array['masque'],
    'Éviter l''inhalation de poussière fine. Ne pas ingérer.',
    'Inhalation : air frais. Yeux : rincer. Peau : laver.',
    'Acides (dégagement de H₂S).',
    'Récipient étanche, au sec, à l''écart des acides.',
    5, 40, false, false, 120, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Pigment bleu pour fards, savons, eye-liners, lessives',
   'Disperser la poudre dans la phase grasse ou l''eau. Pour les lessives, ajouter comme azurant optique.',
   'plage', 0.5, 10, '% du produit fini', 'Ambiante', 'Mélange', false, 0);

  -- ------------------------------------------------------------
  -- CI 77289 (vert d'oxyde de chrome)
  -- ------------------------------------------------------------
  v_material_id := 'bcb3aaeb-0259-4c2c-85ca-27145b074f01'::uuid;

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
    'Sesquioxyde de chrome, oxyde de chrome(III) (Cr₂O₃)',
    'CI 77289, vert de chrome, Pigment Green 17',
    'Cosmétique',
    'Poudre vert olive à vert foncé, inodore',
    'Insoluble',
    'Insoluble, inerte',
    5.20, null,
    'Pigment minéral vert extrêmement stable. Résiste à la chaleur, à la lumière et aux agents chimiques. Le Cr(III), forme trivalente de ce pigment, est inerte et non toxique — à ne pas confondre avec le chrome hexavalent (Cr VI), toxique et cancérogène, qui n''est pas présent dans ce pigment en usage normal.',
    'Plus stable que les verts organiques. Contrairement au vert d''outremer, il est plus opaque et plus terne.',
    'Faible',
    array['masque'],
    'Éviter l''inhalation de poudre de chrome. Le pigment est du Cr(III) inoffensif, mais ne pas chauffer en présence d''oxydants (risque de formation de Cr(VI)).',
    'Inhalation : air frais. Peau : laver. Yeux : rincer 15 min.',
    'Oxydants forts à haute température (risque de formation de chromates).',
    'Récipient étanche, au sec, à l''écart des oxydants puissants.',
    5, 40, false, false, 120, 'a_valider'
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
  (v_academie_id, 'Pigment vert pour cosmétiques (fards, eye-liners) et savons',
   'Disperser dans la phase grasse ou incorporer à la poudre.',
   'plage', 1, 20, '% du produit fini', 'Ambiante', 'Mélange', false, 0);

  -- ------------------------------------------------------------
  -- CI 77742 (violet de manganèse)
  -- ------------------------------------------------------------
  v_material_id := '44b0cb19-0cf8-45be-8185-c54ddc79ab05'::uuid;

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
    'Pyrophosphate de manganèse(III) ammoniacal (Mn₃(PO₄)₂·3H₂O, approximatif)',
    'CI 77742, violet de manganèse, Pigment Violet 16',
    'Cosmétique',
    'Poudre violette intense, inodore',
    'Insoluble, stable',
    'Insoluble, se disperse',
    3.00, null,
    'Pigment minéral violet. Très bonne stabilité. Utilisé pour les fards, blushs et vernis. Couleur unique difficile à reproduire.',
    'Par rapport aux violets organiques (ex. CI 60725), il est plus stable et moins sensible à la lumière. Teinte moins vive que les laques organiques.',
    'Faible',
    array[]::text[],
    'Éviter l''inhalation de poudre.',
    'Yeux : rincer. Peau : laver.',
    'Acides forts.',
    'Récipient étanche, au sec.',
    5, 40, false, false, 120, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Pigment violet pour fards, blushs, vernis à ongles',
   'Disperser dans la base ou broyer avec un liant.',
   'plage', 1, 15, '% du produit fini', 'Ambiante', 'Mélange', false, 0);

  -- ------------------------------------------------------------
  -- Curcumine, extrait de curcuma (E100)
  -- ------------------------------------------------------------
  v_material_id := '7bce06b1-09c6-4555-94cb-4813be297f65'::uuid;

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
    'Curcumine, extrait de racine de Curcuma longa (C₂₁H₂₀O₆)',
    'E100, curcumine, colorant curcuma, Natural Yellow 3',
    'Alimentaire',
    'Poudre jaune-orange vif, odeur épicée caractéristique',
    'Stable en milieu acide, vire au rouge en milieu alcalin',
    'Insoluble dans l''eau, soluble dans l''alcool et les huiles. Les formes modifiées (curcumine solubilisée) existent.',
    0.70, null,
    'Colorant naturel très sensible à la lumière. Teinte jaune vif en milieu acide, rouge orangé en milieu basique. Peut tacher durablement.',
    'Par rapport à la tartrazine (E102), elle est naturelle mais moins stable à la lumière. Plus orangée que le jaune de quinoléine. Sa couleur dépend fortement du pH.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. Éviter le contact avec les vêtements (taches).',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Milieux alcalins (vire au rouge), lumière directe (décoloration), oxydants forts.',
    'Récipient étanche, au frais, à l''abri de la lumière.',
    5, 25, false, true, 24, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Colorant pour moutarde, curry, bouillons, plats préparés',
   'Dissoudre dans l''huile ou l''alcool avant incorporation, ou utiliser une forme hydrosoluble.',
   'plage', 0.01, 0.1, '% du produit fini', '20-100°C (stable à chaud)', 'Immédiat', false, 0),
  (v_academie_id, 'Colorant jaune naturel pour savons et bains',
   'Dissoudre dans les huiles avant saponification, ou saupoudrer à la trace.',
   'plage', 0.5, 2, '% des huiles', '30-50°C', 'Incorporation', false, 1);

  -- ------------------------------------------------------------
  -- Extrait de paprika / capsanthine (E160c)
  -- ------------------------------------------------------------
  v_material_id := '8348bb5c-2965-41df-a081-70032913673e'::uuid;

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
    'Capsanthine et capsorubine, caroténoïdes extraits de Capsicum annuum (C₄₀H₅₈O₃ / C₄₀H₅₆O₄)',
    'E160c, extrait de paprika, colorant paprika, Natural Orange 5',
    'Alimentaire',
    'Liquide huileux rouge-orange à rouge foncé, ou poudre, odeur caractéristique de paprika',
    'Stable sur une large gamme de pH (2-10)',
    'Liposoluble, insoluble dans l''eau. Disponible aussi sous forme émulsifiée hydrosoluble.',
    0.95, null,
    'Colorant naturel riche en caroténoïdes. Très stable à la chaleur, mais sensible à l''oxydation et à la lumière. Apporte également du goût selon la concentration.',
    'Par rapport au bétacarotène (E160a), il apporte une teinte plus rouge et légèrement plus résistante. Moins onéreux que le lycopène pour les teintes orangées.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. Éviter le contact avec les yeux (irritant léger pour les épices).',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts (décoloration), lumière directe prolongée.',
    'Récipient étanche, au frais, à l''abri de la lumière et de l''air (éviter oxydation).',
    5, 25, false, true, 18, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Colorant pour snacks, sauces, charcuterie, fromages',
   'Disperser dans la matière grasse ou utiliser une forme émulsifiée dans l''eau.',
   'plage', 0.05, 0.5, '% du produit fini', 'Jusqu''à 150°C (extrusion, cuisson)', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Fluorescéine
  -- ------------------------------------------------------------
  v_material_id := 'f8f39e75-9518-413b-bae9-fd7bbfea4412'::uuid;

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
    'Sel de sodium de la fluorescéine, résorcinolphtaléine (C₂₀H₁₂O₅)',
    'Fluorescéine sodique, CI 45350, Acid Yellow 73',
    'Technique',
    'Poudre rouge-orangé à brun, inodore, fluorescence jaune-vert en solution',
    'Soluble en milieu alcalin',
    'Soluble dans l''eau (pH alcalin) et l''alcool',
    0.85, null,
    'Traceur fluorescent très puissant, visible à très faible concentration (ppb). Utilisé pour tracer les flux d''eau, détecter les fuites. Non toxique aux doses d''usage.',
    'Par rapport à la rhodamine B, elle est jaune-vert et moins toxique. Très utilisée en hydrologie.',
    'Faible',
    array[]::text[],
    'Éviter l''inhalation de poudre et le contact avec les yeux (irritant).',
    'Yeux : rincer 15 min. Peau : laver.',
    'Acides forts (précipitation), oxydants.',
    'Récipient étanche, au frais, à l''abri de la lumière.',
    5, 30, true, true, 36, 'a_valider'
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
  (v_academie_id, 'Traceur hydrologique pour détection de fuites et études de flux',
   'Diluer dans l''eau et injecter en amont. Détecter visuellement ou par fluorimètre.',
   'plage', 0.5, 5, 'ppb (µg/L) dans l''eau', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Jaune de quinoléine (E104)
  -- ------------------------------------------------------------
  v_material_id := '099056bd-74f5-4d38-a47a-2257e83ae390'::uuid;

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
    'Sel disodique de l''acide 2-(2-quinolyl)-1,3-indanedione sulfoné (C₁₈H₉NNa₂O₈S₂)',
    'E104, jaune de quinoléine, CI 47005',
    'Alimentaire',
    'Poudre jaune vif, inodore',
    'Stable sur une large gamme de pH',
    'Très soluble dans l''eau',
    0.70, null,
    'Colorant azoïque jaune-vert. Bonne stabilité à la chaleur et à la lumière. Susceptible de provoquer des réactions allergiques chez certaines personnes (étiquetage obligatoire en UE).',
    'Par rapport à la tartrazine (E102), il a une teinte plus verdâtre. Moins stable que la curcumine en milieu réducteur.',
    'Faible',
    array[]::text[],
    'Éviter l''inhalation de poudre. Peut tacher.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Agents réducteurs forts (décoloration), oxydants.',
    'Récipient étanche, au sec, à température ambiante.',
    5, 35, true, false, 60, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Colorant pour confiseries, glaces, sodas, cosmétiques',
   'Dissoudre dans l''eau à n''importe quel stade de la fabrication.',
   'plage', 0.005, 0.05, '% du produit fini', 'Ambiante à 100°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Lutéine, extrait de tagète (E161b)
  -- ------------------------------------------------------------
  v_material_id := 'ac298ad2-e313-4efd-a0fe-1e2143bcf49f'::uuid;

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
    'Lutéine, extrait de fleur de tagète, Tagetes erecta (C₄₀H₅₆O₂)',
    'E161b, lutéine, Natural Yellow 15',
    'Alimentaire',
    'Poudre jaune-orange foncé, ou pâte huileuse, odeur végétale',
    'Stable en milieu acide à neutre',
    'Liposoluble, dispersible dans l''eau sous forme microencapsulée',
    0.80, null,
    'Caroténoïde jaune-orangé présent dans les légumes verts. Utilisé pour la coloration des produits laitiers et compléments alimentaires.',
    'Par rapport à la curcumine (E100), elle est plus stable à la lumière mais plus chère. Moins orangée que l''extrait de paprika (E160c).',
    'Aucun',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants, lumière.',
    'Récipient étanche, au frais, à l''abri de la lumière.',
    5, 20, false, true, 12, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Coloration de boissons, produits laitiers, compléments alimentaires',
   'Ajouter la poudre dispersible ou la forme huileuse dans la phase grasse.',
   'plage', 0.01, 0.1, '% du produit fini', '20-60°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Lycopène, extrait de tomate (E160d)
  -- ------------------------------------------------------------
  v_material_id := '6824b8b2-651d-45e4-9fe0-aa1d17c5df89'::uuid;

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
    'Lycopène, extrait de tomate ou fermenté par Blakeslea trispora (C₄₀H₅₆)',
    'E160d, lycopène, Natural Red 4',
    'Alimentaire',
    'Poudre rouge foncé, ou liquide huileux rouge, inodore',
    'Stable en milieu acide à neutre',
    'Liposoluble, insoluble dans l''eau. Disponible sous forme de poudre micronisée dispersible.',
    0.85, null,
    'Caroténoïde responsable de la couleur rouge des tomates. Puissant antioxydant. Sensible à l''oxydation, à la lumière et à la chaleur prolongée.',
    'Par rapport au bétacarotène (E160a), il est plus rouge et sans activité pro-vitaminique A. Plus cher que l''extrait de paprika (E160c) mais teinte plus pure.',
    'Aucun',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants, lumière prolongée, oxygène (décoloration).',
    'Récipient opaque, sous atmosphère inerte, au frais.',
    5, 20, false, true, 12, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Colorant rouge pour boissons, confiseries, sauces',
   'Utiliser une suspension huileuse ou une poudre dispersible, ajouter en fin de process.',
   'plage', 0.05, 0.2, '% du produit fini', '20-80°C (éviter les hautes températures prolongées)', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Noir brillant BN (E151)
  -- ------------------------------------------------------------
  v_material_id := '6165f8e4-20d9-4943-af39-ceac95ad06ab'::uuid;

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
    'Sel tétrasodique d''un dérivé azoïque disulfonique (C₂₈H₁₇N₅Na₄O₁₄S₄)',
    'E151, noir brillant BN, noir PN, CI 28440',
    'Alimentaire',
    'Poudre noire à reflets violets, inodore',
    'Stable sur une large gamme de pH',
    'Très soluble dans l''eau',
    0.85, null,
    'Colorant azoïque noir intense. Utilisé dans les confiseries et glaces. Remplacé partiellement par le noir végétal (E153) pour les formulations clean label.',
    'Par rapport au noir végétal (E153), il est synthétique, plus facile à disperser sans grumeaux, mais moins accepté en clean label. Plus foncé que le brun FK.',
    'Faible',
    array[]::text[],
    'Aucun obligatoire.',
    'Yeux : rincer. Peau : laver.',
    'Réducteurs forts.',
    'Récipient étanche, au sec.',
    5, 35, true, false, 60, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Coloration de confiseries, glaces, décorations',
   'Dissoudre dans l''eau avant incorporation.',
   'plage', 0.01, 0.1, '% du produit fini', '20-100°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Noir végétal / charbon végétal (E153)
  -- ------------------------------------------------------------
  v_material_id := 'f519f7ec-ed52-4a71-b374-40f1339292c3'::uuid;

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
    'Carbone amorphe purifié, charbon végétal activé (C)',
    'E153, charbon végétal alimentaire, noir végétal',
    'Alimentaire',
    'Poudre noire très fine, inodore',
    'Neutre (suspension)',
    'Insoluble dans l''eau et les solvants, se disperse',
    0.35, null,
    'Colorant noir intense autorisé en alimentaire. Poudre très volatile et tachante. Peut adsorber des arômes et nutriments si surdosé.',
    'Par rapport au charbon actif technique, il est plus pur et garanti sans contaminants. Contrairement au noir brillant BN (E151) qui est synthétique, il est naturel et peut être utilisé en clean label.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière, la poudre est très volatile et tache les vêtements et surfaces.',
    'Inhalation : air frais. Yeux : rincer. Peau : laver à l''eau et au savon.',
    'Oxydants forts (risque d''incendie).',
    'Récipient étanche, au sec, à l''écart des oxydants.',
    5, 35, true, false, 48, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Colorant noir pour glaces, confiseries, décoration de gâteaux',
   'Mélanger la poudre intimement avec un peu de sucre ou de matière grasse pour éviter les grumeaux, puis incorporer à la préparation.',
   'plage', 0.1, 2, '% du produit fini', '20-40°C', 'Immédiat', false, 0),
  (v_academie_id, 'Colorant noir pour cosmétiques (eye-liners, mascaras, savons noirs)',
   'Disperser la poudre dans la phase grasse ou l''alcool.',
   'plage', 1, 10, '% du produit fini', 'Ambiante', 'Mélange', false, 1);

  -- ------------------------------------------------------------
  -- Rocou / Annatto (bixine, norbixine) (E160b)
  -- ------------------------------------------------------------
  v_material_id := '693bc919-6f48-4e55-92b3-84d633d6363a'::uuid;

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
    'Bixine (liposoluble) et norbixine (hydrosoluble), extraits de Bixa orellana (C₂₅H₃₀O₄ / C₂₄H₂₈O₄)',
    'E160b, annatto, rocou, achiote, Natural Orange 4',
    'Alimentaire',
    'Poudre brun-rouge à orange, ou liquide huileux, odeur légèrement épicée',
    'Stable en milieu alcalin, précipite en milieu acide (bixine)',
    'Bixine : liposoluble. Norbixine : hydrosoluble (solution alcaline).',
    0.70, null,
    'Colorant naturel extrait des graines de roucou. Excellente stabilité à la chaleur. Sensible à la lumière. Utilisé pour les teintes jaune à orange foncé selon le pH.',
    'Par rapport à la curcumine, il est plus orangé et plus stable à la chaleur, mais moins sensible au pH que le carmin. Moins cher que le lycopène pour les teintes orangées.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. Peut tacher.',
    'Yeux : rincer. Peau : laver.',
    'Acides (bixine précipite), lumière.',
    'Récipient étanche, au frais, à l''abri de la lumière.',
    5, 25, true, true, 24, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Coloration de fromages, beurre, snacks, boulangerie',
   'Diluer la forme hydrosoluble (norbixine) dans l''eau ou le lait, ou la forme liposoluble (bixine) dans l''huile avant incorporation.',
   'plage', 0.02, 0.5, '% du produit fini', 'Jusqu''à 120°C (cuisson)', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Rouge allura AC (E129)
  -- ------------------------------------------------------------
  v_material_id := '1ce40dc3-8ec2-403d-8d28-a35212dacc63'::uuid;

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
    'Sel disodique d''un dérivé azoïque naphtalènesulfonique (C₁₈H₁₄N₂Na₂O₈S₂)',
    'E129, rouge allura, FD&C Red 40, CI 16035',
    'Alimentaire',
    'Poudre rouge-orangé foncé, inodore',
    'Stable sur une large gamme de pH',
    'Très soluble dans l''eau',
    0.75, null,
    'Colorant azoïque rouge le plus utilisé dans le monde. Excellente stabilité. Mention particulière sur l''étiquetage en UE (peut causer des troubles de l''attention chez les enfants).',
    'Par rapport au rouge ponceau 4R (E124), il est légèrement plus orangé et plus stable. Remplaçant courant du rouge carmoisine (E122) dans de nombreuses applications.',
    'Faible',
    array[]::text[],
    'Aucun obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Agents réducteurs, oxydants forts.',
    'Récipient étanche, au sec, à température ambiante.',
    5, 35, true, false, 60, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Colorant pour confiseries, sirops, snacks, boissons, cosmétiques',
   'Dissoudre dans l''eau à n''importe quel stade.',
   'plage', 0.01, 0.1, '% du produit fini', 'Ambiante à 120°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Rouge carmoisine / Azorubine (E122)
  -- ------------------------------------------------------------
  v_material_id := '4ff6eeb8-b363-4bde-8dda-e7a475d6a701'::uuid;

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
    'Sel disodique d''un dérivé azoïque naphtalènesulfonique (C₂₀H₁₂N₂Na₂O₇S₂)',
    'E122, azorubine, carmoisine, CI 14720',
    'Alimentaire',
    'Poudre rouge à bordeaux, inodore',
    'Stable en milieu acide à neutre',
    'Très soluble dans l''eau',
    0.80, null,
    'Colorant azoïque rouge framboise. Bonne stabilité thermique. Autorisé sous conditions en UE (étiquetage).',
    'Par rapport au rouge ponceau 4R (E124), la teinte est plus bleutée (framboise). Moins orangé que le rouge allura (E129).',
    'Faible',
    array[]::text[],
    'Aucun obligatoire.',
    'Yeux : rincer. Peau : laver.',
    'Agents réducteurs forts.',
    'Récipient étanche, au sec, à l''abri de l''humidité.',
    5, 35, true, false, 60, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Coloration de confitures, yaourts, sirops, produits de boulangerie',
   'Dissoudre dans l''eau avant incorporation.',
   'plage', 0.01, 0.1, '% du produit fini', '20-100°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Rouge de betterave / bétanine (E162)
  -- ------------------------------------------------------------
  v_material_id := 'ba2fbb06-8f1a-4aed-815d-077874c65795'::uuid;

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
    'Bétanine, extrait de Beta vulgaris (C₂₄H₂₆N₂O₁₃)',
    'E162, bétanine, rouge de betterave, betterave rouge',
    'Alimentaire',
    'Poudre rouge-violet à rouge foncé, ou liquide concentré, odeur légèrement terreuse',
    '4-6 (solution aqueuse, couleur stable en milieu acide)',
    'Soluble dans l''eau et les solutions hydroalcooliques, insoluble dans les huiles',
    0.80, null,
    'Colorant naturel sensible à la chaleur, à la lumière et à l''oxygène. Stabilité optimale à pH 3-5. Vire au brun en milieu alcalin ou lors de traitements thermiques prolongés.',
    'Par rapport au carmin (E120), il est végétalien et moins stable à la chaleur. Plus rose que le rouge de radis (anthocyanes). Ne résiste pas aux hautes températures de cuisson comme les colorants azoïques synthétiques.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. Éviter l''inhalation de poussières lors de la manipulation de la poudre.',
    'Yeux : rincer à l''eau. Peau : laver au savon. Ingestion sans danger.',
    'Milieux alcalins (décoloration brune), oxydants forts (dégradation de la couleur).',
    'Récipient étanche, au frais, à l''abri de la lumière, de la chaleur et de l''humidité.',
    5, 20, true, true, 12, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Colorant alimentaire pour confiseries, glaces, yaourts et boissons',
   'Dissoudre dans la phase aqueuse à froid ou en fin de cuisson (<70°C). Ajuster le pH en dessous de 5 pour une teinte rouge vif.',
   'plage', 0.1, 1, '% du produit fini', '20-70°C', 'Incorporation immédiate', false, 0),
  (v_academie_id, 'Colorant cosmétique naturel (savons, bains)',
   'Ajouter à la pâte à savon à la trace, éviter les pH élevés (savons doux). Pour les bains, diluer dans la phase aqueuse.',
   'plage', 0.5, 3, '% du produit', '30-40°C (trace)', 'Incorporation', false, 1);

  -- ------------------------------------------------------------
  -- Rouge érythrosine (E127)
  -- ------------------------------------------------------------
  v_material_id := 'c0d87eea-8c01-4ddc-bd44-2f134d0f0172'::uuid;

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
    'Sel disodique de la 2,4,5,7-tétraiodofluorescéine (C₂₀H₆I₄Na₂O₅)',
    'E127, érythrosine, FD&C Red 3, CI 45430',
    'Alimentaire',
    'Poudre rouge-rose vif, inodore',
    'Stable en milieu acide',
    'Soluble dans l''eau, insoluble dans les huiles',
    0.85, null,
    'Colorant iodé rose vif. Peut se décomposer à la lumière en libérant de l''iode. Usage limité (cerises cocktail, fruits confits).',
    'Par rapport au carmin, il est plus rose et synthétique. Sa teinte est difficile à reproduire avec des colorants naturels stables.',
    'Faible',
    array[]::text[],
    'Aucun obligatoire. Sensible à la lumière.',
    'Yeux : rincer. Peau : laver.',
    'Lumière (décoloration), acides forts, réducteurs.',
    'Récipient étanche, à l''abri de la lumière, au sec.',
    5, 30, false, true, 36, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Coloration de fruits confits, cerises cocktail, décors de pâtisserie',
   'Dissoudre dans le sirop ou la phase aqueuse. Protéger le produit fini de la lumière.',
   'plage', 0.005, 0.03, '% du produit fini', '20-80°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Spiruline, extrait de phycocyanine
  -- ------------------------------------------------------------
  v_material_id := 'b42ce9b3-7275-414d-8c12-e877a9c61ba7'::uuid;

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
    'Phycocyanine, extrait d''Arthrospira platensis (complexe protéique-pigmentaire)',
    'Extrait de spiruline, colorant spiruline bleu, phycocyanine',
    'Alimentaire',
    'Poudre bleu-vert intense, ou liquide bleu, odeur légère d''algue',
    'Stable à pH 4-7, dénaturé au-delà (bleu → incolore)',
    'Hydrosoluble',
    0.75, null,
    'Seul colorant bleu naturel autorisé en Europe (hors bleu patenté V synthétique). Sensible à la chaleur (>60°C) et à la lumière. Goût légèrement algue perceptible à dose élevée.',
    'Par rapport au bleu brillant FCF (E133) synthétique, elle est naturelle mais beaucoup moins stable. Plus verte que le bleu patenté V (E131).',
    'Aucun',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Chaleur (>60°C), pH alcalin ou très acide, alcool fort (dénaturation).',
    'Récipient étanche, au frais, à l''abri de la lumière et de la chaleur.',
    2, 15, true, true, 12, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Colorant bleu naturel pour confiseries, glaces, boissons',
   'Dissoudre dans la phase aqueuse froide (<60°C). Protéger de la lumière après conditionnement.',
   'plage', 0.1, 1, '% du produit fini', '20-55°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Vert S (E142)
  -- ------------------------------------------------------------
  v_material_id := 'b05b91fa-4cac-446c-84fb-0f3f12a7cc98'::uuid;

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
    'Sel de sodium d''un dérivé triarylméthane sulfoné (C₂₇H₂₅N₂NaO₇S₂)',
    'E142, vert S, vert acide brillant, CI 44090',
    'Alimentaire',
    'Poudre vert foncé, inodore',
    'Stable en milieu acide à neutre',
    'Très soluble dans l''eau',
    0.80, null,
    'Colorant triarylméthane vert synthétique. Utilisé pour les petits pois en conserve, glaces, confiseries. Réservé à certaines applications alimentaires.',
    'Par rapport à la chlorophylle (E140), il est synthétique, plus vif et plus stable. Moins utilisé que les mélanges de bleu et jaune pour faire du vert.',
    'Faible',
    array[]::text[],
    'Aucun obligatoire.',
    'Yeux : rincer. Peau : laver.',
    'Réducteurs, oxydants forts.',
    'Récipient étanche, au sec, à l''abri de la lumière.',
    5, 35, true, false, 60, 'a_valider'
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Coloration de glaces, confiseries, petits pois en conserve, cosmétiques',
   'Dissoudre dans l''eau avant ajout.',
   'plage', 0.005, 0.03, '% du produit fini', 'Ambiante à 100°C', 'Immédiat', false, 0);
end $$;
