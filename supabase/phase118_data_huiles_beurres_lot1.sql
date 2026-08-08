-- ============================================================
-- AkoraHub - Patch Phase 118 : fiches Académie pour le lot 1 (8
-- huiles de base) des nouveaux produits "Huiles & Beurres
-- Cosmétiques" — contenu DeepSeek, vérifié par l'utilisatrice.
--
-- Lot 1/5 : Huile d'olive, Huile de palme, Huile de palmiste,
-- Huile de tournesol, Huile de ricin, Huile d'amande douce,
-- Huile de jojoba, Huile d'argan.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Huile d'olive
  -- ------------------------------------------------------------
  v_material_id := 'e0230601-595e-4315-87cb-84a071f7beb2'::uuid;

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
    'Triglycérides d''acides gras majoritairement oléique (Olea europaea)',
    'Olea Europaea Fruit Oil, Olive Oil, huile d''olive vierge',
    'Cosmétique, Alimentaire',
    'Liquide jaune verdâtre à doré, odeur fruitée caractéristique',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.91, 225.0,
    'Composition acides gras : 70-80 % acide oléique (oméga-9), 6-15 % acide palmitique, 4-12 % acide linoléique, squalène, vitamine E. Indice de saponification 185-196. Excellente résistance à l''oxydation. Donne un savon dur, doux et crémeux avec une mousse fine.',
    'Par rapport à l''huile de tournesol, elle est beaucoup plus riche en acide oléique et produit un savon plus dur. Comparée à l''huile d''argan, elle est moins riche en insaponifiables mais plus économique. Son savon est plus doux que celui au coco.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer à l''eau. Peau : laver au savon. Ingestion sans danger (alimentaire).',
    'Oxydants forts, bases fortes (saponification exothermique).',
    'Récipient hermétique, au frais, à l''abri de la lumière, de la chaleur et de l''air pour éviter le rancissement.',
    10, 25, false, true, 24, 'a_valider'
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
  (v_academie_id, 'Savon saponifié à froid',
   'Incorporer de 10 à 60 % du poids des huiles dans la formule. Apporte dureté, douceur et un léger pouvoir moussant. Idéal en association avec l''huile de coco.',
   'plage', 10, 60, '% du poids des huiles', '35-45°C', 'Trace en 10-20 min', false, 0),
  (v_academie_id, 'Baume et soin capillaire nourrissant',
   'Appliquer pure ou en mélange (5-50 %) sur les pointes ou le cuir chevelu. Apporte brillance et nutrition.',
   'plage', 5, 50, '% de la formule', 'Ambiante', '15-30 min avant shampoing', false, 1);

  -- ------------------------------------------------------------
  -- Huile de palme
  -- ------------------------------------------------------------
  v_material_id := '959ed2ec-e433-4d7a-98f9-df4a3b3e77ac'::uuid;

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
    'Triglycérides d''acides gras saturés et monoinsaturés (Elaeis guineensis)',
    'Elaeis Guineensis Oil, Palm Oil, huile de palme brute ou raffinée',
    'Cosmétique, Alimentaire',
    'Semi-solide à température ambiante, jaune-orangé, fond vers 35°C, odeur neutre à légèrement grasse',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.92, 230.0,
    'Composition acides gras : 40-48 % acide palmitique, 35-40 % acide oléique, 8-12 % acide linoléique, riche en caroténoïdes (provitamine A) et vitamine E. Indice de saponification 195-205. Apporte dureté et résistance au savon, mousse stable.',
    'Par rapport à l''huile de palmiste, elle est moins riche en acide laurique et donne un savon moins moussant mais plus dur et moins asséchant. Comparée au beurre de karité, elle a un toucher moins gras et un indice de saponification plus élevé.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger (alimentaire).',
    'Oxydants forts, bases fortes.',
    'Récipient fermé, au frais, à l''abri de la lumière. Peut se solidifier partiellement sans altération.',
    20, 35, false, true, 24, 'a_valider'
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
  (v_academie_id, 'Savon saponifié à froid (agent de dureté)',
   'Incorporer 20 à 50 % du poids des huiles pour apporter dureté, résistance et une mousse stable. Faire fondre avant usage.',
   'plage', 20, 50, '% du poids des huiles', '35-45°C', 'Trace en 5-10 min', false, 0);

  -- ------------------------------------------------------------
  -- Huile de palmiste
  -- ------------------------------------------------------------
  v_material_id := 'be3104cf-73f3-4373-9dd3-94a387be2225'::uuid;

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
    'Triglycérides d''acides gras saturés à chaîne courte (Elaeis guineensis, noyau)',
    'Elaeis Guineensis Kernel Oil, Palm Kernel Oil, huile de coprah de palme',
    'Cosmétique, Alimentaire',
    'Semi-solide blanc jaunâtre à température ambiante, fond vers 25-28°C, odeur neutre',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.91, 210.0,
    'Composition acides gras : 45-52 % acide laurique, 14-18 % acide myristique, 12-17 % acide oléique, 6-8 % acide palmitique. Indice de saponification 240-255. Mousse abondante en gros bouillons, très proche de l''huile de coco.',
    'Par rapport à l''huile de coco, elle est légèrement moins riche en acide laurique et donne un savon un peu moins moussant. Comparée à l''huile de palme (chair), elle est beaucoup plus riche en laurique et produit une mousse abondante mais un savon moins dur.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts, bases fortes.',
    'Récipient fermé, au frais. Peut fondre partiellement sans altération.',
    15, 30, false, false, 24, 'a_valider'
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
  (v_academie_id, 'Savon saponifié à froid (pouvoir moussant)',
   'Incorporer 10 à 30 % du poids des huiles. Apporte une mousse abondante et un bon nettoyage. À associer avec des huiles plus douces pour ne pas dessécher.',
   'plage', 10, 30, '% du poids des huiles', '35-45°C', 'Trace en 5-10 min', false, 0);

  -- ------------------------------------------------------------
  -- Huile de tournesol
  -- ------------------------------------------------------------
  v_material_id := 'cb5f67e3-628d-4529-9266-a446d54416ed'::uuid;

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
    'Triglycérides d''acides gras majoritairement linoléique (Helianthus annuus)',
    'Helianthus Annuus Seed Oil, Sunflower Oil, huile de tournesol',
    'Cosmétique, Alimentaire',
    'Liquide jaune pâle à doré, odeur neutre à légèrement végétale',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.92, 230.0,
    'Composition acides gras : 50-65 % acide linoléique (oméga-6), 20-30 % acide oléique, 5-10 % acide palmitique, riche en vitamine E. Indice de saponification 188-194. Huile légère, peu occlusive, pénètre bien. Existe en version "high oleic" (80 %+ oléique) plus stable.',
    'Par rapport à l''huile d''olive, elle est beaucoup plus riche en linoléique et moins stable à l''oxydation, mais plus légère et plus pénétrante. Comparée à l''huile de pépin de raisin, elle a un profil lipidique très proche et est plus économique.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts, chaleur prolongée (rancissement).',
    'Récipient hermétique, au frais, à l''abri de la lumière pour éviter le rancissement oxydatif.',
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
  (v_academie_id, 'Savon saponifié à froid (agent de douceur et conditionnement)',
   'Incorporer 5 à 30 % du poids des huiles. Apporte un toucher doux et soyeux. La version high oleic est préférée pour limiter le rancissement.',
   'plage', 5, 30, '% du poids des huiles', '35-45°C', 'Trace en 15-25 min', false, 0),
  (v_academie_id, 'Macération de plantes (huile de soin)',
   'Faire macérer des plantes sèches dans l''huile pendant 3-4 semaines, filtrer. Excellente base de macération grâce à sa stabilité modérée et sa fluidité.',
   'texte_libre', null, null, 'quantité suffisante pour couvrir les plantes', 'Ambiante', '3-4 semaines', false, 1);

  -- ------------------------------------------------------------
  -- Huile de ricin
  -- ------------------------------------------------------------
  v_material_id := 'cf516d8c-4f9c-4095-8aba-227191bc5985'::uuid;

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
    'Triglycérides d''acide ricinoléique (Ricinus communis)',
    'Ricinus Communis Seed Oil, Castor Oil, huile de ricin',
    'Cosmétique, Alimentaire',
    'Liquide visqueux, jaune très pâle à incolore, odeur très faible',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, miscible à l''alcool, soluble dans les solvants organiques et autres huiles',
    0.96, 230.0,
    'Composition acides gras : 85-90 % acide ricinoléique (oméga-9 hydroxylé unique), 3-5 % acide linoléique. Indice de saponification 175-185. Apporte une mousse crémeuse abondante, un toucher humide et une excellente solubilité dans l''alcool.',
    'Par rapport à toutes les autres huiles végétales, elle est la seule à contenir de l''acide ricinoléique, ce qui lui confère un toucher collant et humide unique. Elle booste la mousse et la solubilité des huiles dans l''alcool. Ne s''utilise jamais pure en savon.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion : effet laxatif connu, ne pas ingérer en grande quantité.',
    'Oxydants forts.',
    'Récipient hermétique, au frais, à l''abri de la lumière.',
    15, 25, false, true, 24, 'a_valider'
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
  (v_academie_id, 'Savon saponifié à froid (boost de mousse crémeuse)',
   'Incorporer 5 à 15 % du poids des huiles maximum. Apporte une mousse dense et crémeuse, un toucher humide et de la brillance.',
   'plage', 5, 15, '% du poids des huiles', '35-45°C', 'Trace en 10-15 min', false, 0),
  (v_academie_id, 'Soin capillaire et cils',
   'Appliquer quelques gouttes pures sur les cils ou le cuir chevelu en massage. Rincer après 30 min. Peut être mélangée à 20 % dans une huile plus fluide.',
   'valeur_unique', 100, null, 'pure', 'Ambiante', '30 min avant shampoing', false, 1);

  -- ------------------------------------------------------------
  -- Huile d'amande douce
  -- ------------------------------------------------------------
  v_material_id := '8cd2cd02-4192-40ce-9783-a19ec329b49e'::uuid;

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
    'Triglycérides d''acides gras majoritairement oléique et linoléique (Prunus amygdalus dulcis)',
    'Prunus Amygdalus Dulcis Oil, Sweet Almond Oil, huile d''amande douce',
    'Cosmétique, Alimentaire',
    'Liquide jaune pâle, fluide, odeur très discrète d''amande',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.92, 220.0,
    'Composition acides gras : 60-70 % acide oléique, 18-25 % acide linoléique, 5-8 % acide palmitique, riche en vitamine E et phytostérols. Indice de saponification 185-195. Huile pénétrante, nourrissante, apaise les peaux sensibles.',
    'Par rapport à l''huile d''olive, elle est plus légère et moins grasse, avec une pénétration plus rapide. Comparée à l''huile de noyau d''abricot, elle est plus nourrissante et plus riche en oléique. C''est l''huile de référence pour les massages.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Peut provoquer une réaction allergique chez les personnes sensibilisées aux fruits à coque.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts.',
    'Récipient hermétique, au frais, à l''abri de la lumière.',
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
  (v_academie_id, 'Savon saponifié à froid (agent de douceur)',
   'Incorporer 10 à 30 % du poids des huiles. Apporte un toucher soyeux et convient aux peaux sensibles et aux bébés.',
   'plage', 10, 30, '% du poids des huiles', '35-45°C', 'Trace en 10-20 min', false, 0),
  (v_academie_id, 'Huile de massage et soin du corps',
   'Appliquer pure ou mélangée (50-100 %) sur la peau. Excellente glisse et bonne absorption.',
   'plage', 50, 100, '% de la formule', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Huile de jojoba
  -- ------------------------------------------------------------
  v_material_id := '2a560d4c-f05a-4662-8694-bd4bddabd4f3'::uuid;

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
    'Esters cireux d''acides gras insaturés (Simmondsia chinensis)',
    'Simmondsia Chinensis Seed Oil, Jojoba Oil, cire liquide de jojoba',
    'Cosmétique',
    'Liquide jaune doré à incolore, inodore, texture sèche et non grasse',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, miscible à la plupart des huiles, stable à l''oxydation',
    0.86, 295.0,
    'Composition : esters cireux (97 %), principalement acides eicosénoïque et docosénoïque avec des alcools gras. Indice de saponification très bas (90-100). Chimiquement stable, ne rancit pas. Toucher sec, non gras, proche du sébum humain.',
    'Contrairement à toutes les autres huiles végétales, c''est une cire liquide et non un triglycéride. Elle ne saponifie quasiment pas et apporte un toucher sec. Comparée à l''huile de coco fractionnée, elle est plus stable et plus sèche au toucher. Indispensable dans les soins sans rinçage.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Bases fortes (saponification très lente), oxydants forts.',
    'Récipient hermétique, à température ambiante. Très stable, ne rancit pas.',
    10, 30, false, false, 48, 'a_valider'
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
  (v_academie_id, 'Sérum visage et huile capillaire sans rinçage',
   'Appliquer quelques gouttes pures sur la peau ou les pointes. Pénètre rapidement sans laisser de film gras.',
   'plage', 1, 10, '% de la formule', 'Ambiante', 'Immédiat', false, 0),
  (v_academie_id, 'Savon saponifié à froid (superfatting ou additif après trace)',
   'Ajouter 1 à 5 % à la trace comme surgras non saponifié pour apporter un toucher sec et soyeux.',
   'plage', 1, 5, '% du poids total (surgras)', 'Trace (30-40°C)', 'Ajout juste avant coulage', false, 1);

  -- ------------------------------------------------------------
  -- Huile d'argan
  -- ------------------------------------------------------------
  v_material_id := '335aa325-ca08-408d-9ca0-39b7645e34b0'::uuid;

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
    'Triglycérides d''acides gras oléique et linoléique (Argania spinosa)',
    'Argania Spinosa Kernel Oil, Argan Oil, huile d''argan, or liquide du Maroc',
    'Cosmétique, Alimentaire',
    'Liquide jaune doré à brun clair, odeur légèrement torréfiée et noisette (vierge)',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.91, 220.0,
    'Composition acides gras : 40-48 % acide oléique, 30-38 % acide linoléique, 12-15 % acide palmitique, riche en insaponifiables (1 %) : schotténol, spinastérol, vitamine E, polyphénols. Indice de saponification 188-197. Propriétés anti-âge et restructurantes reconnues.',
    'Par rapport à l''huile d''olive, elle est moins oléique, plus riche en insaponifiables et son parfum est plus intense. Comparée à l''huile de noisette, elle a un toucher plus sec et est plus précieuse. C''est une huile signature haut de gamme en cosmétique.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Peut provoquer une réaction allergique chez les personnes sensibilisées aux fruits à coque.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger (alimentaire).',
    'Oxydants forts, chaleur prolongée.',
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
  (v_academie_id, 'Sérum anti-âge visage et soin capillaire haut de gamme',
   'Appliquer quelques gouttes pures ou en mélange (1-10 %) sur la peau ou les pointes. Apporte nutrition et éclat.',
   'plage', 1, 10, '% de la formule', 'Ambiante', 'Immédiat', false, 0),
  (v_academie_id, 'Savon saponifié à froid (surgras de luxe)',
   'Utiliser 5 à 20 % dans la formule ou l''ajouter à la trace comme surgras pour un savon riche et doux.',
   'plage', 5, 20, '% du poids des huiles', '35-45°C', 'Trace en 15-20 min', false, 1);
end $$;
