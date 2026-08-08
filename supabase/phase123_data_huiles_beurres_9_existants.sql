-- ============================================================
-- AkoraHub - Patch Phase 123 : fiches Académie pour les 9 produits
-- déjà présents dans le catalogue "Huiles & Beurres Cosmétiques"
-- avant la campagne — contenu DeepSeek, vérifié par l'utilisatrice.
--
-- Termine la catégorie "Huiles & Beurres Cosmétiques" (46/46 : 37
-- nouveaux en phases 118-122 + ces 9 produits déjà existants).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Beurre de cacao
  -- ------------------------------------------------------------
  v_material_id := '8b13b989-7db3-4456-9156-cfc2f4f44618'::uuid;

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
    'Triglycérides d''acides gras saturés et monoinsaturés (Theobroma cacao)',
    'Theobroma Cacao Seed Butter, Cocoa Butter, beurre de cacao',
    'Cosmétique, Alimentaire',
    'Solide jaune pâle à ivoire, texture dure et cassante à température ambiante, fondant au contact de la peau, odeur chocolatée caractéristique, point de fusion 34-38°C',
    'Non applicable (beurre pur)',
    'Insoluble dans l''eau, soluble dans les huiles chaudes et les solvants organiques',
    0.91, 220.0,
    'Composition : 55-65 % de triglycérides saturés (principalement stéarique et palmitique), 30-35 % d''acide oléique, 2-4 % d''acide linoléique. Riche en phytostérols et vitamine E naturelle. Indice de saponification 188-200. Point de fusion 34-38°C. Donne un savon dur, crémeux, avec une mousse fine et stable. Excellente stabilité oxydative.',
    'Par rapport au beurre de karité, il est plus dur, fond à plus haute température et donne un toucher moins gras. Comparé au beurre de kokum, il est moins dur et fond plus facilement sur la peau. C''est le beurre de référence pour la dureté en savonnerie et la stabilité en baume.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer à l''eau. Peau : laver au savon. Ingestion sans danger (alimentaire).',
    'Oxydants forts, bases fortes (saponification exothermique).',
    'Récipient hermétique, au frais, à l''abri de la lumière et de la chaleur. Conserve sa texture solide jusqu''à 30°C.',
    10, 28, false, true, 36, 'a_valider'
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
  (v_academie_id, 'Savon saponifié à froid (agent de dureté majeur)',
   'Incorporer 5 à 20 % du poids des huiles. Apporte dureté, résistance et une mousse crémeuse. Faire fondre au bain-marie avant utilisation.',
   'plage', 5, 20, '% du poids des huiles', '35-45°C', 'Trace en 10-15 min', false, 0),
  (v_academie_id, 'Baume à lèvres et soin solide',
   'Faire fondre 20 à 40 % avec des huiles et autres beurres. Apporte dureté, stabilité et une texture fondante sur les lèvres.',
   'plage', 20, 40, '% de la formule', 'Fusion à 40-50°C', 'Refroidissement rapide', false, 1);

  -- ------------------------------------------------------------
  -- Beurre de karité
  -- ------------------------------------------------------------
  v_material_id := '2906b856-8656-40bf-9534-50e47ab591bd'::uuid;

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
    'Triglycérides d''acides gras saturés et monoinsaturés (Vitellaria paradoxa / Butyrospermum parkii)',
    'Butyrospermum Parkii Butter, Shea Butter, beurre de karité',
    'Cosmétique, Alimentaire',
    'Solide ivoire à jaune pâle (raffiné) ou jaune à beige (brut), texture onctueuse et malléable, fondant facilement sur la peau, odeur neutre (raffiné) ou fumée/noisette (brut), point de fusion 30-38°C',
    'Non applicable (beurre pur)',
    'Insoluble dans l''eau, soluble dans les huiles et solvants organiques',
    0.91, 220.0,
    'Composition : 40-50 % acide oléique, 30-45 % acide stéarique, 5-10 % acide linoléique. Très riche en insaponifiables (3-15 % selon qualité) : phytostérols, esters de karité, vitamine E. Indice de saponification 170-190. Point de fusion 30-38°C. Toucher gras, pénétrant lentement. Exceptionnellement nourrissant et apaisant.',
    'Par rapport au beurre de cacao, il est plus mou, plus gras et fond plus facilement. Comparé au beurre de mangue, il est moins sec et plus occlusif. C''est le beurre le plus polyvalent et le plus utilisé en cosmétique artisanale pour ses propriétés apaisantes et sa richesse en insaponifiables.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Peut provoquer une allergie rare chez les personnes sensibilisées au latex (allergie croisée possible avec le karité brut).',
    'Yeux : rincer. Peau : laver. Ingestion sans danger (alimentaire).',
    'Oxydants forts, bases fortes.',
    'Récipient hermétique, au frais, à l''abri de la lumière. Le karité brut se conserve mieux que le raffiné grâce à ses antioxydants naturels.',
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
  (v_academie_id, 'Savon saponifié à froid (surgras nourrissant)',
   'Incorporer 5 à 20 % du poids des huiles ou ajouter à la trace comme surgras (5-10 %). Apporte un toucher riche et une excellente douceur.',
   'plage', 5, 20, '% du poids des huiles', '35-45°C', 'Trace en 15-20 min', false, 0),
  (v_academie_id, 'Baume corporel et soin des peaux sèches/atopiques',
   'Appliquer pur ou en mélange (30-100 %) sur la peau. Excellente tolérance cutanée, apaise les irritations.',
   'plage', 30, 100, '% de la formule', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Cire d'abeille
  -- ------------------------------------------------------------
  v_material_id := '3eaca88f-ca93-4218-b4a7-5c81515e5ad5'::uuid;

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
    'Mélange d''esters d''acides gras, d''alcools gras et d''hydrocarbures (Apis mellifera)',
    'Cera Alba (blanche), Cera Flava (jaune), Beeswax, cire d''abeille',
    'Cosmétique, Alimentaire',
    'Solide jaune à brun clair (jaune) ou blanc ivoire (blanche), texture dure et cassante, fondant à chaud, odeur miellée caractéristique, point de fusion 62-65°C',
    'Non applicable (cire pure)',
    'Insoluble dans l''eau, soluble dans les huiles chaudes, les alcools chauds et les solvants organiques',
    0.95, 240.0,
    'Composition : esters d''acides gras et d''alcools gras (70-75 %), hydrocarbures (12-16 %), acides gras libres (12-15 %). Point de fusion 62-65°C. Agent filmogène, protecteur et épaississant. Apporte dureté et résistance à la chaleur. La cire blanche est blanchie, la jaune est brute.',
    'Par rapport à la cire de carnauba, elle est moins dure et fond à plus basse température. Comparée à la cire de candelilla (vegan), elle est d''origine animale et plus malléable. Elle est la cire de référence pour les baumes et les sticks depuis des siècles.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Attention aux allergies rares aux produits de la ruche (propolis, pollen).',
    'Yeux : rincer. Peau : laver. Ingestion sans danger (alimentaire E901).',
    'Oxydants forts, bases fortes (saponification partielle).',
    'Récipient hermétique, au frais, à l''abri de la chaleur et des odeurs (absorbe les parfums).',
    10, 30, false, false, 60, 'a_valider'
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
  (v_academie_id, 'Baume à lèvres et stick solide',
   'Faire fondre 10 à 25 % avec les beurres et huiles. Apporte dureté, protection et une tenue en stick.',
   'plage', 10, 25, '% de la formule', 'Fusion à 70-75°C', 'Refroidissement', false, 0),
  (v_academie_id, 'Bougie artisanale traditionnelle',
   'Fondre la cire à 70-75°C, ajouter parfum, couler en moule. Brûle proprement avec une flamme chaude et lumineuse.',
   'valeur_unique', 100, null, 'pure', 'Fusion 70-75°C, coulage 65-70°C', 'Refroidissement 2-3 h', false, 1);

  -- ------------------------------------------------------------
  -- Cire de carnauba
  -- ------------------------------------------------------------
  v_material_id := 'f53121e1-d7fa-43c2-a592-524618ea4b17'::uuid;

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
    'Esters d''acides gras et d''alcools gras (Copernicia cerifera)',
    'Copernicia Cerifera Wax, Carnauba Wax, cire de carnauba',
    'Cosmétique, Alimentaire',
    'Solide jaune pâle à beige (type 1) ou gris-brun (type 3), très dure, cassante, paillettes ou poudre, odeur neutre, point de fusion 80-86°C',
    'Non applicable (cire pure)',
    'Insoluble dans l''eau, soluble dans les huiles très chaudes et les solvants organiques',
    0.97, 260.0,
    'Composition : esters d''acides gras (acide cérotique, acide carnaubique) et d''alcools gras. Point de fusion 80-86°C. Cire végétale la plus dure du marché. Excellent pouvoir filmogène, brillance exceptionnelle, résistance à la chaleur. Le type 1 est le plus pur et le plus utilisé en cosmétique.',
    'Par rapport à la cire d''abeille, elle est beaucoup plus dure et fond à plus haute température. Comparée à la cire de candelilla, elle donne une brillance supérieure et une meilleure résistance à la fusion. Elle est irremplaçable pour les sticks qui doivent résister à la chaleur estivale.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter l''inhalation de poussières lors de la manipulation de poudre.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger (alimentaire E903).',
    'Oxydants forts.',
    'Récipient hermétique, à température ambiante. Très stable, ne craint pas la chaleur modérée.',
    10, 40, false, false, 60, 'a_valider'
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
  (v_academie_id, 'Stick à lèvres résistant à la chaleur',
   'Incorporer 2 à 8 % dans la formule. Une petite quantité suffit à augmenter significativement la résistance à la fusion.',
   'plage', 2, 8, '% de la formule', 'Fusion à 85-90°C', 'Refroidissement rapide', false, 0),
  (v_academie_id, 'Agent de brillance pour bougies et enrobages',
   'Ajouter 2 à 5 % dans la cire de soja ou autre cire végétale pour augmenter la brillance et la dureté de surface.',
   'plage', 2, 5, '% du poids de cire', '80-90°C', 'Refroidissement', false, 1);

  -- ------------------------------------------------------------
  -- Glycérine pure alimentaire (E422)
  -- ------------------------------------------------------------
  v_material_id := '3dd940c0-dd6e-44fa-a1c5-d6b7ed50dcc6'::uuid;

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
    'Propane-1,2,3-triol (glycérol végétal)',
    'Glycerin, Glycérol, E422, glycérine végétale alimentaire',
    'Alimentaire, Cosmétique',
    'Liquide sirupeux incolore, inodore, saveur sucrée, très hygroscopique',
    '6-7 (solution aqueuse)',
    'Miscible à l''eau et à l''alcool en toutes proportions, insoluble dans les huiles',
    1.26, 199.0,
    'Pureté ≥ 99,5 %, conforme aux normes alimentaires (E422). Humectant puissant, plastifiant, agent de texture. Point d''éclair très élevé, non inflammable à température ambiante. Utilisable en alimentation humaine, cosmétique, pharmacie.',
    'Par rapport à la glycérine technique, elle est certifiée sans contaminants et peut être utilisée en alimentaire. Comparée au propylène glycol, elle est plus douce et d''origine naturelle. C''est l''humectant de référence pour les produits clean label.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Produit très visqueux, attention aux projections.',
    'Yeux : rincer abondamment. Peau : laver. Ingestion sans danger (additif alimentaire E422), peut avoir un effet laxatif à haute dose.',
    'Oxydants forts (acide nitrique, permanganate de potassium), acide sulfurique concentré (formation d''acroléine toxique).',
    'Bidon hermétique en PEHD, à température ambiante, à l''abri de l''humidité (très hygroscopique). Éviter le stockage près d''oxydants puissants.',
    10, 30, true, false, 36, 'a_valider'
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
  (v_academie_id, 'Agent humectant et texturant en cosmétique (crèmes, lotions, dentifrice)',
   'Ajouter 2 à 10 % dans la phase aqueuse. Améliore l''hydratation, la texture et la conservation.',
   'plage', 2, 10, '% du produit fini', 'Ambiante', 'Incorporation immédiate', false, 0),
  (v_academie_id, 'Édulcorant et humectant en pâtisserie et confiserie',
   'Ajouter 1 à 5 % dans les glaçages, fondants, pâtes à sucre pour garder une texture souple.',
   'valeur_unique', 3, null, '% du poids de sucre', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Glycérine technique
  -- ------------------------------------------------------------
  v_material_id := '73decf73-0881-424d-bb06-73568235cb74'::uuid;

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
    'Propane-1,2,3-triol (glycérol)',
    'Glycerin Technical, glycérol technique, glycérine brute',
    'Technique',
    'Liquide sirupeux jaune pâle à brun clair, odeur légèrement grasse, hygroscopique',
    '6-7 (solution aqueuse)',
    'Miscible à l''eau et à l''alcool',
    1.25, 190.0,
    'Pureté variable (80-95 %), peut contenir des impuretés, des sels, des traces de méthanol ou d''acides gras. Non conforme aux normes alimentaires. Utilisée pour des applications techniques : antigel, fluides hydrauliques, plastifiants industriels, fabrication de résines.',
    'Par rapport à la glycérine alimentaire (E422), elle est moins pure, non certifiée et ne doit en aucun cas être utilisée en alimentaire ou en cosmétique. Elle est réservée aux usages techniques et industriels. Son coût est généralement inférieur.',
    'Faible',
    array['gants'],
    'Porter des gants pour éviter le contact prolongé avec la peau (effet déshydratant). Ne pas ingérer. Ne pas utiliser en cosmétique.',
    'Yeux : rincer abondamment. Peau : laver au savon. Ingestion : rincer la bouche, boire de l''eau, consulter un médecin si gêne.',
    'Oxydants forts, acide sulfurique concentré.',
    'Bidon hermétique en PEHD, à température ambiante, dans un local ventilé.',
    10, 35, true, false, 36, 'a_valider'
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
  (v_academie_id, 'Antigel et liquide de refroidissement',
   'Utiliser pur ou en mélange avec de l''eau (30-50 %) pour abaisser le point de congélation des circuits.',
   'plage', 30, 50, '% dans l''eau', 'Variable selon climat', 'Action permanente', false, 0),
  (v_academie_id, 'Plastifiant pour résines et colles hydrosolubles',
   'Ajouter 5 à 15 % dans la formulation pour assouplir le film après séchage.',
   'plage', 5, 15, '% du poids de résine', 'Ambiante', 'Pendant le mélange', false, 1);

  -- ------------------------------------------------------------
  -- Huile de coco
  -- ------------------------------------------------------------
  v_material_id := '4295b574-e9ae-4111-84e9-f010f671c5ce'::uuid;

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
    'Triglycérides d''acides gras saturés à chaîne courte (Cocos nucifera)',
    'Cocos Nucifera Oil, Coconut Oil, huile de coco vierge',
    'Cosmétique, Alimentaire',
    'Solide blanc à température ambiante (< 24°C), liquide incolore à jaune pâle au-dessus de 25°C, odeur caractéristique de noix de coco (vierge) ou neutre (raffinée), point de fusion 23-26°C',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.92, 210.0,
    'Composition : 45-53 % acide laurique (C12), 16-21 % acide myristique, 7-10 % acide caprylique, 5-10 % acide caprique. Indice de saponification 248-265. Point de fusion 23-26°C. Excellente mousse en gros bouillons, nettoyage puissant. Peut dessécher si utilisée en trop grande proportion.',
    'Par rapport à l''huile de palmiste, elle est plus riche en acide laurique et donne une mousse plus abondante. Comparée au beurre de babassu, elle est plus économique mais plus desséchante en savon. C''est l''huile de référence pour le pouvoir moussant en savonnerie artisanale.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger (alimentaire).',
    'Oxydants forts, bases fortes (saponification rapide et exothermique).',
    'Récipient hermétique, à température ambiante. Se solidifie en dessous de 24°C sans altération.',
    15, 30, false, false, 36, 'a_valider'
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
  (v_academie_id, 'Savon saponifié à froid (pouvoir moussant principal)',
   'Incorporer 15 à 35 % du poids des huiles. Apporte une mousse abondante et un nettoyage efficace. Au-delà de 30 %, le savon peut être desséchant. Faire fondre avant usage.',
   'plage', 15, 35, '% du poids des huiles', '35-45°C', 'Trace rapide en 5-10 min', false, 0),
  (v_academie_id, 'Soin capillaire (bain d''huile avant-shampoing)',
   'Appliquer l''huile tiède sur les longueurs et pointes, laisser poser 30 min à 1 h, puis laver au shampoing.',
   'valeur_unique', 100, null, 'pure', 'Tiédir à 25-30°C', '30 min à 1 h', false, 1);

  -- ------------------------------------------------------------
  -- Huile de coco/palme
  -- ------------------------------------------------------------
  v_material_id := '8721fcae-1903-45d6-9179-7a8b35847435'::uuid;

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
    'Mélange de triglycérides d''acides gras de coco (Cocos nucifera) et de palme (Elaeis guineensis)',
    'Coconut/Palm Oil Blend, huile de coco/palme, base moussante économique',
    'Cosmétique, Alimentaire',
    'Solide blanc à légèrement jaunâtre à température ambiante, fond vers 25-30°C, liquide jaune pâle au-dessus, odeur neutre à légèrement végétale',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.92, 215.0,
    'Mélange industriel standardisé d''huile de coco (riche en laurique, apporte la mousse) et d''huile de palme (riche en palmitique et oléique, apporte la dureté). Rapport typique 50/50 ou 60/40. Indice de saponification estimé 220-240. Compromis économique pour la savonnerie industrielle et artisanale, bon équilibre mousse/dureté.',
    'Par rapport à l''huile de coco pure, elle est moins moussante mais plus douce et moins desséchante. Comparée à l''huile de palme pure, elle apporte la mousse qui manque au palme. C''est une solution économique prête à l''emploi pour les savonniers qui ne veulent pas gérer deux huiles séparées.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger (alimentaire).',
    'Oxydants forts, bases fortes.',
    'Récipient hermétique, à température ambiante. Peut se solidifier partiellement sans altération.',
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
  (v_academie_id, 'Savon saponifié à froid (base économique équilibrée)',
   'Incorporer 30 à 60 % du poids des huiles. Bon équilibre mousse/dureté/douceur sans avoir à mélanger plusieurs huiles. Faire fondre avant usage.',
   'plage', 30, 60, '% du poids des huiles', '35-45°C', 'Trace en 10-15 min', false, 0);

  -- ------------------------------------------------------------
  -- Paraffine
  -- ------------------------------------------------------------
  v_material_id := '7e9a688b-d5c0-4991-a5fb-3f385a1df8f2'::uuid;

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
    'Mélange d''hydrocarbures saturés linéaires et ramifiés (CnH2n+2, n = 20-40)',
    'Paraffin Wax, Paraffinum Liquidum (version liquide), cire de paraffine, huile minérale',
    'Technique, Cosmétique',
    'Solide blanc translucide, texture cireuse et cassante, fondant en liquide incolore, inodore, point de fusion 45-68°C selon le grade',
    'Non applicable (inerte)',
    'Insoluble dans l''eau et l''alcool, soluble dans les solvants organiques et les hydrocarbures',
    0.90, 200.0,
    'Mélange d''hydrocarbures saturés d''origine pétrochimique. Inerte, non biodégradable, excellent pouvoir occlusif. Point de fusion variable (45-68°C). Utilisée pour les bougies, les baumes barrière, les enrobages. Contrairement aux cires végétales, elle ne contient aucun ester ni acide gras et ne saponifie pas.',
    'Contrairement à toutes les cires végétales du catalogue (abeille, carnauba, candelilla, soja, riz), la paraffine est d''origine pétrochimique, non renouvelable et non biodégradable. Elle ne saponifie pas et n''apporte aucun bénéfice nourrissant à la peau. Son seul intérêt est son coût très bas et son inertie chimique totale.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter l''inhalation de vapeurs lors de la fusion à haute température.',
    'Yeux : rincer. Peau : laver au savon. Ingestion : ne pas faire vomir, boire de l''eau, consulter un médecin si grande quantité.',
    'Oxydants forts. Ne se mélange pas facilement aux huiles végétales sans co-solvant.',
    'Récipient hermétique, à température ambiante. Très stable, ne rancit pas.',
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
  (v_academie_id, 'Bougie économique (coulage en moule ou contenant)',
   'Fondre à 70-80°C, ajouter parfum et colorant, couler à 60-70°C. Excellente tenue, surface lisse, coût très bas.',
   'valeur_unique', 100, null, 'pure ou en mélange majoritaire', 'Fusion 70-80°C, coulage 60-70°C', 'Refroidissement 2-3 h', false, 0),
  (v_academie_id, 'Baume barrière occlusif (protection contre l''humidité)',
   'Incorporer 5 à 20 % dans la formule. Crée un film occlusif imperméable. Usage technique ou soin barrière, pas de valeur nourrissante.',
   'plage', 5, 20, '% de la formule', 'Fusion à 70-80°C', 'Refroidissement', false, 1);
end $$;
