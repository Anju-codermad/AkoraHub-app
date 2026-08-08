-- ============================================================
-- AkoraHub - Patch Phase 121 : fiches Académie pour le lot 4 (7
-- beurres végétaux) des nouveaux produits "Huiles & Beurres
-- Cosmétiques" — contenu DeepSeek, vérifié par l'utilisatrice.
--
-- Lot 4/5 : Beurre de mangue, Beurre de kokum, Beurre de sal,
-- Beurre de mowrah, Beurre d'illipe, Beurre de cupuaçu, Beurre de
-- babassu.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Beurre de mangue
  -- ------------------------------------------------------------
  v_material_id := '91cce680-82dc-4d05-ae93-0b4dd8d25ed1'::uuid;

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
    'Triglycérides d''acides gras saturés et monoinsaturés (Mangifera indica)',
    'Mangifera Indica Seed Butter, Mango Butter, beurre de mangue',
    'Cosmétique',
    'Solide blanc cassé à jaune pâle, texture fondante et onctueuse, odeur neutre à légèrement sucrée, point de fusion 32-36°C',
    'Non applicable (beurre pur)',
    'Insoluble dans l''eau, soluble dans les huiles et solvants organiques',
    0.91, 220.0,
    'Composition : 40-50 % acide oléique, 35-45 % acide stéarique, 5-8 % acide palmitique, riche en insaponifiables (phytostérols, tocophérols). Indice de saponification 180-195. Point de fusion 32-36°C. Excellente alternative au beurre de cacao, toucher fondant et non gras.',
    'Par rapport au beurre de cacao, il est plus mou, plus onctueux et moins cassant. Comparé au beurre de karité, il est plus ferme, moins gras et pénètre plus vite. Apprécié pour sa texture légère dans les baumes et crèmes.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts.',
    'Récipient hermétique, au frais, à l''abri de la lumière et de la chaleur. Peut fondre partiellement en été.',
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
  (v_academie_id, 'Savon saponifié à froid (agent de dureté et douceur)',
   'Incorporer 5 à 20 % du poids des huiles. Apporte dureté et un toucher soyeux. Faire fondre avant usage.',
   'plage', 5, 20, '% du poids des huiles', '35-45°C', 'Trace en 15-20 min', false, 0),
  (v_academie_id, 'Baume corporel et stick à lèvres',
   'Faire fondre 10 à 40 % avec d''autres beurres, huiles et cires. Toucher fondant et fini non gras.',
   'plage', 10, 40, '% de la formule', 'Fusion à 40-50°C', 'Refroidissement', false, 1);

  -- ------------------------------------------------------------
  -- Beurre de kokum
  -- ------------------------------------------------------------
  v_material_id := '7ff377cf-1509-4406-8ae7-7e941ee1c05e'::uuid;

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
    'Triglycérides d''acides gras saturés (Garcinia indica)',
    'Garcinia Indica Seed Butter, Kokum Butter, beurre de kokum',
    'Cosmétique',
    'Solide blanc-gris à blanc cassé, texture très dure et cassante, fondant lentement sur la peau, odeur neutre, point de fusion 36-40°C',
    'Non applicable (beurre pur)',
    'Insoluble dans l''eau, soluble dans les huiles et solvants organiques',
    0.92, 230.0,
    'Composition : 50-60 % acide stéarique, 30-35 % acide oléique, 2-5 % acide palmitique, très riche en triglycérides stéariques. Indice de saponification 187-195. Point de fusion 36-40°C. Beurre le plus dur et le plus stable du marché. Toucher sec et non gras, fond difficilement.',
    'Par rapport au beurre de cacao, il est plus dur, plus cassant et fond plus lentement. Comparé au beurre de sal, il est plus neutre en odeur et plus stable. Très recherché pour les sticks et les baumes qui doivent résister à la chaleur.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts.',
    'Récipient hermétique, au frais, à l''abri de la lumière.',
    10, 30, false, true, 36, 'a_valider'
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
  (v_academie_id, 'Stick à lèvres et baume solide résistant à la chaleur',
   'Incorporer 10 à 30 % dans la formule. Apporte dureté et résistance à la fusion en été.',
   'plage', 10, 30, '% de la formule', 'Fusion à 50-60°C', 'Refroidissement rapide', false, 0),
  (v_academie_id, 'Savon saponifié à froid (agent de dureté extrême)',
   'Incorporer 3 à 10 % du poids des huiles. Très dur, à utiliser en petite quantité. Faire fondre avant usage.',
   'plage', 3, 10, '% du poids des huiles', '40-50°C', 'Trace en 10-15 min', false, 1);

  -- ------------------------------------------------------------
  -- Beurre de sal
  -- ------------------------------------------------------------
  v_material_id := '69f4c094-7674-4fcc-a04e-6c243879396b'::uuid;

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
    'Triglycérides d''acides gras saturés et monoinsaturés (Shorea robusta)',
    'Shorea Robusta Seed Butter, Sal Butter, beurre de sal',
    'Cosmétique',
    'Solide blanc cassé à beige clair, texture homogène, fondant au contact de la peau, odeur neutre à légèrement végétale, point de fusion 32-38°C',
    'Non applicable (beurre pur)',
    'Insoluble dans l''eau, soluble dans les huiles et solvants organiques',
    0.91, 220.0,
    'Composition : 40-45 % acide oléique, 35-42 % acide stéarique, 5-10 % acide palmitique, riche en insaponifiables. Indice de saponification 180-195. Point de fusion 32-38°C. Toucher sec, pénétration rapide, bonne stabilité oxydative.',
    'Par rapport au beurre de karité, il est plus ferme, moins gras et pénètre plus vite. Comparé au beurre de kokum, il est moins dur et fond plus facilement. Très proche du beurre de mangue mais avec un toucher plus sec.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts.',
    'Récipient hermétique, au frais, à l''abri de la lumière.',
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
  (v_academie_id, 'Baume corporel et soin des mains',
   'Faire fondre 15 à 30 % avec d''autres beurres et huiles. Pénètre rapidement sans effet gras.',
   'plage', 15, 30, '% de la formule', 'Fusion à 40-50°C', 'Refroidissement', false, 0),
  (v_academie_id, 'Savon saponifié à froid (agent de dureté)',
   'Incorporer 5 à 15 % du poids des huiles. Apporte dureté et un toucher sec.',
   'plage', 5, 15, '% du poids des huiles', '35-45°C', 'Trace en 15-20 min', false, 1);

  -- ------------------------------------------------------------
  -- Beurre de mowrah
  -- ------------------------------------------------------------
  v_material_id := '0cca60b6-6cf3-4cdf-b9d6-865f682e0ba9'::uuid;

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
    'Triglycérides d''acides gras saturés et monoinsaturés (Madhuca longifolia)',
    'Madhuca Longifolia Seed Butter, Mowrah Butter, beurre de mowrah, beurre de mahua',
    'Cosmétique',
    'Solide jaune pâle à beige, texture ferme et homogène, odeur neutre à légèrement terreuse, point de fusion 35-40°C',
    'Non applicable (beurre pur)',
    'Insoluble dans l''eau, soluble dans les huiles et solvants organiques',
    0.91, 220.0,
    'Composition : 35-45 % acide oléique, 25-35 % acide stéarique, 20-25 % acide palmitique. Indice de saponification 185-200. Point de fusion 35-40°C. Pouvoir occlusif et protecteur, idéal pour les peaux très sèches.',
    'Par rapport au beurre de sal, il est légèrement plus riche en acide palmitique et a un pouvoir occlusif plus marqué. Moins connu que le karité, il est apprécié pour son toucher protecteur sans être collant.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts.',
    'Récipient hermétique, au frais, à l''abri de la lumière.',
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
  (v_academie_id, 'Baume protecteur peaux sèches et gercées',
   'Faire fondre 20 à 40 % avec des huiles nourrissantes. Excellent pouvoir occlusif et protecteur.',
   'plage', 20, 40, '% de la formule', 'Fusion à 45-55°C', 'Refroidissement', false, 0);

  -- ------------------------------------------------------------
  -- Beurre d'illipe
  -- ------------------------------------------------------------
  v_material_id := 'd7f8d935-7403-4de9-b941-bf4f4512ce93'::uuid;

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
    'Triglycérides d''acides gras saturés et monoinsaturés (Shorea stenoptera)',
    'Shorea Stenoptera Seed Butter, Illipe Butter, beurre d''illipe, beurre de Bornéo, tengkawang',
    'Cosmétique',
    'Solide beige clair à brun clair, texture très dure et cireuse, fondant à température corporelle, odeur neutre à légèrement boisée, point de fusion 35-42°C',
    'Non applicable (beurre pur)',
    'Insoluble dans l''eau, soluble dans les huiles et solvants organiques',
    0.92, 230.0,
    'Composition : 40-50 % acide stéarique, 30-40 % acide oléique, 5-10 % acide palmitique. Indice de saponification 185-195. Point de fusion 35-42°C. Texture très dure, proche du cacao. Très résistant au rancissement.',
    'Par rapport au beurre de cacao, il est encore plus dur et fond plus difficilement. Comparé au kokum, il est légèrement moins cassant et plus facile à incorporer. Excellent pour les sticks qui doivent être très résistants.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts.',
    'Récipient hermétique, au frais, à l''abri de la lumière.',
    10, 30, false, true, 36, 'a_valider'
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
  (v_academie_id, 'Stick à lèvres et baume dur haute résistance',
   'Incorporer 10 à 25 % dans la formule. Apporte une dureté exceptionnelle et une bonne tenue en stick.',
   'plage', 10, 25, '% de la formule', 'Fusion à 55-65°C', 'Refroidissement', false, 0),
  (v_academie_id, 'Savon saponifié à froid (agent de dureté)',
   'Incorporer 3 à 10 % du poids des huiles. Très dur, à utiliser en complément d''autres beurres.',
   'plage', 3, 10, '% du poids des huiles', '40-50°C', 'Trace en 10-15 min', false, 1);

  -- ------------------------------------------------------------
  -- Beurre de cupuaçu
  -- ------------------------------------------------------------
  v_material_id := '0295adea-c111-4e93-b1e4-0ce311ccc6d6'::uuid;

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
    'Triglycérides d''acides gras saturés et monoinsaturés (Theobroma grandiflorum)',
    'Theobroma Grandiflorum Seed Butter, Cupuaçu Butter, beurre de cupuaçu',
    'Cosmétique',
    'Solide blanc cassé à beige pâle, texture molle, onctueuse et légèrement collante, fondant très facilement sur la peau, odeur fruitée douce caractéristique, point de fusion 28-34°C',
    'Non applicable (beurre pur)',
    'Insoluble dans l''eau, soluble dans les huiles et solvants organiques',
    0.91, 210.0,
    'Composition : 38-45 % acide oléique, 30-35 % acide stéarique, 20-25 % acide palmitique, très riche en phytostérols et tocophérols. Indice de saponification 180-190. Point de fusion 28-34°C. Capacité d''absorption d''eau exceptionnelle (jusqu''à 240 % de son poids), excellent humectant.',
    'Par rapport au beurre de karité, il est plus mou, plus onctueux et bien plus hydratant grâce à sa capacité à retenir l''eau. Comparé au beurre de mangue, il fond plus facilement et a une odeur plus présente. Très apprécié pour les soins capillaires.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts.',
    'Récipient hermétique, impérativement à l''abri de la chaleur (fond facilement en été). Au frais.',
    5, 22, false, true, 18, 'a_valider'
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
  (v_academie_id, 'Masque capillaire et soin hydratant intensif',
   'Appliquer pur ou en mélange (20-50 %) sur les pointes sèches ou en masque capillaire. Excellente capacité à retenir l''hydratation.',
   'plage', 20, 50, '% de la formule', 'Ambiante', '30 min avant shampoing', false, 0),
  (v_academie_id, 'Savon saponifié à froid (surgras hydratant)',
   'Incorporer 5 à 15 % à la trace comme surgras. Apporte un toucher très hydratant et un parfum fruité discret.',
   'plage', 5, 15, '% du poids total (surgras)', 'Trace (30-35°C)', 'Ajout avant coulage', false, 1);

  -- ------------------------------------------------------------
  -- Beurre de babassu
  -- ------------------------------------------------------------
  v_material_id := '8168700e-3f6b-42f0-98ed-f93188222404'::uuid;

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
    'Triglycérides d''acides gras saturés (Orbignya oleifera)',
    'Orbignya Oleifera Seed Butter, Babassu Butter, beurre de babassu',
    'Cosmétique',
    'Solide blanc à blanc cassé, texture assez dure, fondant rapidement au contact de la peau, toucher sec et poudré, odeur neutre à légèrement noisette, point de fusion 24-28°C',
    'Non applicable (beurre pur)',
    'Insoluble dans l''eau, soluble dans les huiles et solvants organiques',
    0.91, 210.0,
    'Composition : 40-50 % acide laurique, 15-20 % acide myristique, 10-18 % acide oléique, 6-10 % acide caprique. Indice de saponification 240-255. Point de fusion 24-28°C. Toucher très sec, non gras, pénètre instantanément. Excellent substitut végétalien à l''huile de coco, avec un toucher plus doux.',
    'Par rapport à l''huile de coco, il a un toucher plus sec et moins gras, et fond plus vite. Comparé au beurre de karité, il est beaucoup moins gras et plus pénétrant. En savon, il donne une mousse abondante comme le coco, mais avec moins d''effet desséchant.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts.',
    'Récipient hermétique, au frais. Fond facilement (24-28°C), ne pas exposer à la chaleur.',
    5, 22, false, false, 24, 'a_valider'
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
  (v_academie_id, 'Savon saponifié à froid (pouvoir moussant végétalien)',
   'Incorporer 15 à 35 % du poids des huiles. Mousse abondante et crémeuse, nettoyage doux. Excellente alternative au coco.',
   'plage', 15, 35, '% du poids des huiles', '35-45°C', 'Trace en 5-10 min', false, 0),
  (v_academie_id, 'Sérum et huile de soin légère sans effet gras',
   'Faire fondre et appliquer pur ou en mélange (20-50 %). Pénètre instantanément, idéal pour peaux grasses.',
   'plage', 20, 100, '% de la formule', 'Ambiante', 'Immédiat', false, 1);
end $$;
