-- ============================================================
-- AkoraHub - Patch Phase 119 : fiches Académie pour le lot 2 (8
-- huiles spécialisées cosmétiques) des nouveaux produits "Huiles &
-- Beurres Cosmétiques" — contenu DeepSeek, vérifié par l'utilisatrice.
--
-- Lot 2/5 : Huile de coco fractionnée, Huile de pépin de raisin,
-- Huile d'avocat, Huile de sésame, Huile de noisette, Huile de
-- macadamia, Huile de noyau d'abricot, Huile de chanvre.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Huile de coco fractionnée (caprylic/capric triglyceride)
  -- ------------------------------------------------------------
  v_material_id := '17bd0a19-ce40-4961-9fcd-a65400098f6b'::uuid;

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
    'Triglycérides caprylique/caprique (esters d''acides caprylique C8 et caprique C10)',
    'Caprylic/Capric Triglyceride, MCT Oil, huile de coco fractionnée, triglycérides à chaîne moyenne',
    'Cosmétique, Alimentaire',
    'Liquide incolore, très fluide, inodore, toucher sec et soyeux',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, miscible à toutes les huiles, soluble dans l''alcool et les solvants organiques',
    0.94, 180.0,
    'Composition : 55-65 % acide caprylique (C8), 30-40 % acide caprique (C10), sans acide laurique. Indice de saponification 325-345. Ne rancit pas, ne se solidifie pas, pénètre instantanément sans laisser de film gras. Excellent solvant pour les huiles essentielles.',
    'Contrairement à l''huile de coco vierge, elle reste liquide à toute température et ne contient pas d''acide laurique, ce qui la rend non moussante en savon mais bien plus légère. Comparée à l''huile de jojoba, elle a un toucher encore plus sec et un indice de saponification très élevé.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts.',
    'Récipient hermétique, à température ambiante. Extrêmement stable, ne rancit pas.',
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
  (v_academie_id, 'Sérum visage et huile de massage légère',
   'Appliquer quelques gouttes pures ou en mélange (10-50 %) sur la peau. Absorption instantanée sans toucher gras.',
   'plage', 10, 50, '% de la formule', 'Ambiante', 'Immédiat', false, 0),
  (v_academie_id, 'Dilution d''huiles essentielles pour cosmétiques',
   'Mélanger 1 à 5 % d''huile essentielle dans l''huile de coco fractionnée. Excellent support neutre qui ne masque pas les parfums.',
   'plage', 1, 5, '% d''huile essentielle dans l''huile support', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Huile de pépin de raisin
  -- ------------------------------------------------------------
  v_material_id := 'f368f68a-04bd-48cd-9569-377e9fe48f24'::uuid;

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
    'Triglycérides d''acides gras majoritairement linoléique (Vitis vinifera)',
    'Vitis Vinifera Seed Oil, Grapeseed Oil, huile de pépins de raisin',
    'Cosmétique, Alimentaire',
    'Liquide jaune-vert pâle, fluide, odeur très légèrement végétale',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.92, 230.0,
    'Composition acides gras : 60-75 % acide linoléique (oméga-6), 15-20 % acide oléique, 5-10 % acide palmitique, riche en vitamine E et proanthocyanidines antioxydantes. Indice de saponification 188-194. Huile très légère, pénétrante, légèrement astringente.',
    'Par rapport à l''huile de tournesol, elle est plus riche en linoléique, plus légère et plus rapidement absorbée. Comparée à l''huile d''amande douce, elle est moins nourrissante mais plus adaptée aux peaux grasses. Excellente huile de base économique.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts, chaleur prolongée.',
    'Récipient hermétique, au frais, à l''abri de la lumière pour éviter le rancissement.',
    5, 25, false, true, 12, 'a_valider'
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
  (v_academie_id, 'Savon saponifié à froid (agent de conditionnement)',
   'Incorporer 5 à 25 % du poids des huiles. Apporte légèreté et un toucher soyeux. À utiliser en association avec des huiles plus stables.',
   'plage', 5, 25, '% du poids des huiles', '35-45°C', 'Trace en 15-20 min', false, 0),
  (v_academie_id, 'Huile de massage pour peaux grasses',
   'Appliquer pure ou en mélange (50-100 %). Excellente glisse, pénétration rapide, fini non gras.',
   'plage', 50, 100, '% de la formule', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Huile d'avocat
  -- ------------------------------------------------------------
  v_material_id := '15096619-bb4b-4349-952e-8f6e6bdf89ed'::uuid;

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
    'Triglycérides d''acides gras majoritairement oléique (Persea gratissima)',
    'Persea Gratissima Oil, Avocado Oil, huile d''avocat',
    'Cosmétique, Alimentaire',
    'Liquide épais, vert foncé à brun-vert, odeur légèrement fruitée et grasse',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.91, 200.0,
    'Composition acides gras : 55-70 % acide oléique, 10-20 % acide palmitique, 8-15 % acide linoléique, très riche en insaponifiables (2-6 %) : phytostérols, vitamine A, D, E, caroténoïdes. Indice de saponification 175-195. Exceptionnellement nourrissante et pénétrante.',
    'Par rapport à l''huile d''olive, elle est plus riche en insaponifiables et plus pénétrante. Comparée à l''huile de macadamia, elle est plus épaisse et plus nourrissante. Sa couleur verte intense peut colorer les savons en beige-vert.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger (alimentaire).',
    'Oxydants forts.',
    'Récipient hermétique, au frais, à l''abri de la lumière pour préserver les insaponifiables.',
    10, 25, false, true, 18, 'a_valider'
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
  (v_academie_id, 'Savon saponifié à froid (surgras nourrissant)',
   'Incorporer 10 à 30 % du poids des huiles ou ajouter à la trace comme surgras (5-10 %). Apporte un toucher riche et réparateur.',
   'plage', 10, 30, '% du poids des huiles', '35-45°C', 'Trace en 10-20 min', false, 0),
  (v_academie_id, 'Soin intensif pour peaux sèches et cheveux abîmés',
   'Appliquer pure ou en masque (20-50 %) sur la peau ou les pointes. Laisser poser 30 min avant de rincer si nécessaire.',
   'plage', 20, 100, '% de la formule', 'Ambiante', '30 min', false, 1);

  -- ------------------------------------------------------------
  -- Huile de sésame
  -- ------------------------------------------------------------
  v_material_id := 'a26f50f5-ffbc-4db7-93c2-ad11e93f2be4'::uuid;

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
    'Triglycérides d''acides gras oléique et linoléique (Sesamum indicum)',
    'Sesamum Indicum Seed Oil, Sesame Oil, huile de sésame',
    'Cosmétique, Alimentaire',
    'Liquide jaune doré à brun clair, odeur caractéristique de sésame grillé (vierge) ou neutre (raffinée)',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.92, 230.0,
    'Composition acides gras : 35-45 % acide oléique, 35-45 % acide linoléique, 8-12 % acide palmitique, riche en vitamine E, sésamoline, sésamine (antioxydants naturels). Indice de saponification 186-195. Excellente résistance à l''oxydation grâce aux antioxydants naturels.',
    'Par rapport à l''huile de tournesol, elle est mieux équilibrée en acides gras et se conserve mieux grâce à ses antioxydants. Comparée à l''huile d''amande douce, elle a une odeur plus prononcée (version vierge) et est souvent utilisée en Ayurveda.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger (alimentaire).',
    'Oxydants forts.',
    'Récipient hermétique, au frais, à l''abri de la lumière.',
    10, 25, false, true, 18, 'a_valider'
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
  (v_academie_id, 'Savon saponifié à froid (agent de conditionnement équilibré)',
   'Incorporer 10 à 30 % du poids des huiles. Apporte un toucher doux, une mousse onctueuse et une bonne conservation.',
   'plage', 10, 30, '% du poids des huiles', '35-45°C', 'Trace en 15-20 min', false, 0),
  (v_academie_id, 'Huile de massage ayurvédique',
   'Chauffer légèrement l''huile vierge, appliquer en massage du corps. Excellente glisse et propriétés chauffantes.',
   'valeur_unique', 100, null, 'pure', '35-40°C', '15-30 min de massage', false, 1);

  -- ------------------------------------------------------------
  -- Huile de noisette
  -- ------------------------------------------------------------
  v_material_id := '33659e99-3dce-40b7-bfb0-a509399bb021'::uuid;

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
    'Triglycérides d''acides gras majoritairement oléique (Corylus avellana)',
    'Corylus Avellana Seed Oil, Hazelnut Oil, huile de noisette',
    'Cosmétique, Alimentaire',
    'Liquide jaune doré clair, fluide, odeur légère et agréable de noisette',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.92, 220.0,
    'Composition acides gras : 65-80 % acide oléique, 10-15 % acide linoléique, 5-8 % acide palmitique, riche en vitamine E et phytostérols. Indice de saponification 185-195. Pénètre rapidement, toucher sec, non comédogène, idéale pour les peaux grasses.',
    'Par rapport à l''huile d''amande douce, elle est moins grasse et plus pénétrante. Comparée à l''huile de macadamia, elle est moins riche en acide palmitoléique mais partage un toucher sec similaire. Excellente pour les soins du visage.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Peut provoquer une réaction allergique chez les personnes sensibilisées aux fruits à coque.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger (alimentaire).',
    'Oxydants forts.',
    'Récipient hermétique, au frais, à l''abri de la lumière.',
    5, 25, false, true, 12, 'a_valider'
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
  (v_academie_id, 'Sérum visage pour peaux grasses et mixtes',
   'Appliquer quelques gouttes pures ou en mélange (20-50 %) sur la peau. Régule le sébum et resserre les pores.',
   'plage', 20, 100, '% de la formule', 'Ambiante', 'Immédiat', false, 0),
  (v_academie_id, 'Savon saponifié à froid (agent de douceur non gras)',
   'Incorporer 10 à 25 % du poids des huiles. Apporte un toucher doux sans effet gras, mousse fine.',
   'plage', 10, 25, '% du poids des huiles', '35-45°C', 'Trace en 15-20 min', false, 1);

  -- ------------------------------------------------------------
  -- Huile de macadamia
  -- ------------------------------------------------------------
  v_material_id := '4bea6026-d252-4a31-a00c-dc772539da3e'::uuid;

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
    'Triglycérides d''acides gras majoritairement palmitoléique et oléique (Macadamia integrifolia)',
    'Macadamia Integrifolia Seed Oil, Macadamia Oil, huile de macadamia',
    'Cosmétique',
    'Liquide jaune pâle, fluide, toucher soyeux et pénétrant, odeur très discrète',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.91, 200.0,
    'Composition acides gras : 55-65 % acide oléique, 18-25 % acide palmitoléique (oméga-7 rare), 2-5 % acide linoléique, riche en insaponifiables. Indice de saponification 193-198. Très pénétrante, toucher sec et soyeux, proche du sébum humain grâce à l''acide palmitoléique.',
    'Par rapport à l''huile de noisette, elle contient de l''acide palmitoléique unique qui lui donne un toucher encore plus soyeux. Comparée à l''huile d''argan, elle est plus fluide et moins odorante. Excellente alternative à l''huile de vison (animale).',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts.',
    'Récipient hermétique, au frais, à l''abri de la lumière.',
    10, 25, false, true, 18, 'a_valider'
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
  (v_academie_id, 'Sérum et soin anti-âge visage haut de gamme',
   'Appliquer quelques gouttes pures sur le visage. Pénètre instantanément, régénère et assouplit la peau.',
   'plage', 10, 100, '% de la formule', 'Ambiante', 'Immédiat', false, 0),
  (v_academie_id, 'Savon saponifié à froid (surgras soyeux)',
   'Ajouter 5 à 15 % à la trace comme surgras pour un toucher soyeux et un savon très doux.',
   'plage', 5, 15, '% du poids total (surgras)', 'Trace (30-40°C)', 'Ajout juste avant coulage', false, 1);

  -- ------------------------------------------------------------
  -- Huile de noyau d'abricot
  -- ------------------------------------------------------------
  v_material_id := '6e395f89-77f6-4af8-9caf-19f054f9a84a'::uuid;

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
    'Triglycérides d''acides gras majoritairement oléique et linoléique (Prunus armeniaca)',
    'Prunus Armeniaca Kernel Oil, Apricot Kernel Oil, huile de noyau d''abricot',
    'Cosmétique, Alimentaire',
    'Liquide jaune pâle à doré, fluide, odeur très légère d''amande',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.92, 220.0,
    'Composition acides gras : 55-65 % acide oléique, 25-30 % acide linoléique, 4-8 % acide palmitique, riche en vitamine A et E. Indice de saponification 185-195. Pénètre rapidement, toucher doux et non gras, idéale pour les peaux sensibles et les bébés.',
    'Par rapport à l''huile d''amande douce, elle est plus riche en linoléique et pénètre encore plus vite. Comparée à l''huile de pépin de raisin, elle est plus nourrissante grâce à sa teneur plus élevée en oléique. C''est une huile très polyvalente et douce.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger (alimentaire).',
    'Oxydants forts.',
    'Récipient hermétique, au frais, à l''abri de la lumière.',
    5, 25, false, true, 12, 'a_valider'
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
  (v_academie_id, 'Savon saponifié à froid (agent de douceur universel)',
   'Incorporer 10 à 30 % du poids des huiles. Apporte douceur, toucher soyeux et convient aux peaux les plus sensibles et aux savons bébé.',
   'plage', 10, 30, '% du poids des huiles', '35-45°C', 'Trace en 15-20 min', false, 0),
  (v_academie_id, 'Huile de massage pour bébés et peaux sensibles',
   'Appliquer pure ou mélangée à 50-100 %. Excellente glisse, très douce, bonne absorption.',
   'plage', 50, 100, '% de la formule', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Huile de chanvre
  -- ------------------------------------------------------------
  v_material_id := '0af36325-3efa-4783-bcbb-8da587c4814c'::uuid;

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
    'Triglycérides d''acides gras polyinsaturés oméga-3 et oméga-6 (Cannabis sativa)',
    'Cannabis Sativa Seed Oil, Hemp Seed Oil, huile de chanvre, huile de graines de chanvre',
    'Cosmétique, Alimentaire',
    'Liquide vert foncé à brun-vert, fluide, odeur herbacée prononcée et caractéristique',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.93, 220.0,
    'Composition acides gras : 45-55 % acide linoléique (oméga-6), 15-25 % acide alpha-linolénique (oméga-3), 10-15 % acide oléique, ratio oméga-6/oméga-3 idéal de 3:1. Indice de saponification 185-195. Extrêmement nourrissante, anti-inflammatoire, mais très oxydative.',
    'Par rapport à l''huile de lin, elle a un meilleur équilibre oméga-3/oméga-6 et une odeur plus agréable. Comparée à l''huile d''avocat, elle est plus pénétrante et moins grasse, mais elle rancit très vite. Sa couleur verte intense colore les savons en vert-brun.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger (alimentaire).',
    'Oxydants forts, chaleur, lumière (rancissement très rapide).',
    'Récipient hermétique, impérativement au réfrigérateur après ouverture, à l''abri de la lumière. Huile très fragile, à utiliser rapidement.',
    2, 8, false, true, 6, 'a_valider'
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
  (v_academie_id, 'Savon saponifié à froid (surgras nutritif)',
   'Ajouter 5 à 10 % à la trace comme surgras pour préserver ses qualités. Donne un savon vert-brun très doux et nourrissant.',
   'plage', 5, 10, '% du poids total (surgras)', 'Trace (30-40°C)', 'Ajout avant coulage', false, 0),
  (v_academie_id, 'Sérum visage réparateur anti-inflammatoire',
   'Appliquer quelques gouttes pures sur les zones irritées ou en mélange (5-20 %). Conserver le flacon au réfrigérateur.',
   'plage', 5, 20, '% de la formule', 'Ambiante', 'Immédiat', false, 1);
end $$;
