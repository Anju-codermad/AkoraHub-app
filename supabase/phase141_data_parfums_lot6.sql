-- ============================================================
-- AkoraHub - Patch Phase 141 : fiches Académie pour le lot 6 (7
-- produits, dernier lot des nouveaux produits) de "Parfums &
-- Additifs" — contenu DeepSeek, vérifié par l'utilisatrice.
-- Xylitol documenté avec avertissement renforcé sur sa toxicité
-- sévère pour les chiens (hypoglycémie, insuffisance hépatique
-- aiguë potentiellement fatale) et la nécessité d'un stockage hors
-- de portée des animaux domestiques.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Pipéronal (héliotropine, arôme vanille/amande)
  -- ------------------------------------------------------------
  v_material_id := 'ee2f03a3-5345-4285-81b2-b404c3ffceb6'::uuid;

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
    '1,3-benzodioxole-5-carbaldéhyde (C₈H₆O₃)',
    'Heliotropine, Pipéronal, aldéhyde pipéronylique, arôme vanille-amande',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche à jaune pâle, odeur douce, chaude, florale, rappelant la vanille, l''amande et la fleur d''héliotrope',
    'Non applicable (faible solubilité dans l''eau)',
    'Peu soluble dans l''eau (0,2 g/100 mL), soluble dans l''alcool, les huiles et les solvants organiques',
    1.34, 110.0,
    'Aldéhyde aromatique naturellement présent dans les fèves de vanille, la fleur d''héliotrope et certains fruits. Arôme vanillé-amandé très apprécié en parfumerie et en confiserie. Sensible à la lumière et à l''oxydation. Peut former des dérivés allergènes en vieillissant.',
    'Par rapport à la vanilline, l''héliotropine a une note plus florale et amandée, moins purement vanillée. Contrairement au benzaldéhyde (amande amère), elle n''évoque pas la cerise mais une amande douce et fleurie. Elle est souvent utilisée en combinaison avec la vanilline pour enrichir les profils vanillés.',
    'Modéré',
    array['gants','lunettes','masque'],
    'Porter des gants en nitrile, des lunettes de sécurité et un masque anti-poussière. Éviter le contact prolongé avec la peau et l''inhalation de poudre.',
    'Yeux : rincer abondamment à l''eau pendant 15 minutes. Peau : laver à l''eau et au savon. Ingestion : rincer la bouche, boire de l''eau, consulter un médecin si symptômes. Inhalation : air frais.',
    'Oxydants forts, bases fortes.',
    'Récipient étanche, au frais, à l''abri de la lumière et de l''humidité. Conserver dans un endroit bien ventilé.',
    5, 30, true, true, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H315', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P270', 'P280', 'P301+P312', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Arôme vanille/amande pour pâtisserie, confiserie, chocolaterie',
   'Diluer dans un solvant (alcool, propylène glycol) avant incorporation. Ajouter 5-50 ppm dans le produit fini. Incorporer en fin de cuisson pour préserver l''arôme.',
   'plage', 5, 50, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 60 °C', 'Immédiat', false, 0),
  (v_academie_id, 'Parfumerie fine et cosmétique (notes florales orientales, savons)',
   'Utiliser pur ou en solution dans la composition parfumée à 0,5-5 %. Apporte une facette vanillée-amandée délicate.',
   'plage', 0.5, 5.0, '% du concentré parfumé', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Polyglycitol (E964) — poudre et sirop
  -- ------------------------------------------------------------
  v_material_id := '06ff2790-3b33-4508-8ad3-27635e24a021'::uuid;

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
    'Mélange de polyols hydrogénés issus de l''hydrolyse d''amidon (sorbitol, maltitol, mannitol, etc.)',
    'Polyglycitol syrup, E964, sirop de polyglycitol, édulcorant de charge polyol',
    'Alimentaire',
    'Sirop : liquide visqueux incolore à jaune pâle, inodore, saveur sucrée neutre. Poudre : poudre blanche à blanc cassé, inodore.',
    'Neutre (5-7 en solution aqueuse)',
    'Très soluble dans l''eau (sirop miscible, poudre > 50 g/100 mL). Insoluble dans l''alcool.',
    1.30, null,
    'Polyol de charge économique obtenu par hydrogénation de sirops de glucose à haut DE. Il constitue une alternative peu coûteuse au sorbitol ou au maltitol, avec un pouvoir sucrant de 40 à 60 % de celui du saccharose. Non cariogène, il est utilisé comme agent de charge dans les produits sans sucre, les confiseries et les sauces. Bien toléré sur le plan digestif jusqu''à 30-50 g/jour.',
    'Par rapport au sorbitol (E420), le polyglycitol a un profil de polyols plus large, offrant une texture plus proche du sucre. Contrairement au maltitol (E965), il est moins coûteux mais son pouvoir sucrant est inférieur. Il est souvent préféré pour les applications industrielles de masse.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Surface glissante en cas de déversement.',
    'Yeux : rincer à l''eau. Peau : laver. Ingestion sans danger (effet laxatif à haute dose).',
    'Oxydants forts.',
    'Récipient étanche, à température ambiante. Pour le sirop, éviter les températures supérieures à 40 °C pour limiter le brunissement. Protéger de l''humidité.',
    10, 30, true, false, 24, 'a_valider'
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Agent de charge édulcorant en confiserie, pâtisserie, glaces, sauces',
   'Incorporer le sirop ou la poudre directement dans la préparation. Ajuster le pouvoir sucrant total avec des édulcorants intenses si nécessaire. Résiste bien à la cuisson.',
   'texte_libre', null, null, 'Selon la recette (remplacement partiel ou total du sucre)', 'Jusqu''à 160 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Protéine végétale hydrolysée (HVP)
  -- ------------------------------------------------------------
  v_material_id := 'fe7d2b1e-adc8-4408-8d41-12a4a844ea4e'::uuid;

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
    'Mélange complexe de peptides et d''acides aminés issus de l''hydrolyse de protéines végétales (soja, maïs, blé, etc.)',
    'Hydrolyzed Vegetable Protein, HVP, protéine végétale hydrolysée, exhausteur de goût naturel',
    'Alimentaire, Cosmétique',
    'Poudre beige à brun clair, hygroscopique, odeur savoureuse caractéristique de bouillon ou de viande',
    '5-6 (solution aqueuse à 1 %)',
    'Très soluble dans l''eau, insoluble dans les solvants organiques',
    0.50, null,
    'Exhausteur de goût naturel obtenu par hydrolyse enzymatique ou acide de protéines végétales. Riche en acide glutamique libre, elle apporte une saveur umami intense sans être un additif (E621). Utilisée pour renforcer les notes savoureuses des bouillons, snacks, sauces et plats préparés. En cosmétique, elle est utilisée dans les soins capillaires pour ses propriétés gainantes et réparatrices.',
    'Par rapport au glutamate monosodique (E621), la HVP contient un spectre plus large d''acides aminés et de peptides, donnant un goût plus complexe et moins métallique. Contrairement à l''extrait de levure, elle peut avoir une note viandée plus prononcée selon la source végétale. Elle est souvent préférée en clean label.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour la manipulation de la poudre. Peut contenir des traces de gluten ou de soja : vérifier l''étiquette pour les allergènes.',
    'Yeux : rincer 15 min. Peau : laver. Ingestion sans danger. Inhalation : air frais.',
    'Oxydants forts, acides forts (hydrolyse supplémentaire).',
    'Récipient étanche, au sec, à l''abri de l''humidité (très hygroscopique). Conserver dans un endroit frais.',
    5, 25, true, false, 18, 'a_valider'
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
  (v_academie_id, 'Exhausteur de goût naturel pour bouillons, snacks, sauces, soupes',
   'Ajouter 0,5-2 % du poids du produit fini directement dans la phase aqueuse. Résiste à la cuisson et à la congélation.',
   'plage', 0.5, 2.0, '% du produit fini', 'Ambiante à 100 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Sel d'aspartame-acésulfame (E962)
  -- ------------------------------------------------------------
  v_material_id := 'b0d738be-f7ff-409c-833b-1c64f20d3991'::uuid;

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
    'Sel de [2-carboxy-β-phénéthyl]-aspartame et d''acésulfame (mélange équimolaire)',
    'Aspartame-acesulfame salt, E962, Twinsweet, édulcorant intense mixte',
    'Alimentaire',
    'Poudre cristalline blanche, inodore, saveur sucrée intense et propre (200 fois le pouvoir sucrant du saccharose)',
    '5-6 (solution aqueuse à 1 %)',
    'Très soluble dans l''eau (25 g/100 mL à 20 °C), peu soluble dans l''alcool',
    0.50, null,
    'Édulcorant intense combinant l''aspartame et l''acésulfame K par liaison saline. Il offre un profil sucré plus équilibré que les deux édulcorants séparés, avec une montée rapide du sucré et une persistance réduite. Utilisé dans les boissons, produits laitiers, confiseries. Contient une source de phénylalanine (aspartame) : doit porter la mention légale pour les personnes atteintes de phénylcétonurie.',
    'Par rapport à l''aspartame seul, le sel a une meilleure stabilité à la chaleur et un goût sucré moins tardif. Contrairement au sucralose (E955), il a un pouvoir sucrant moins élevé mais un profil plus proche du sucre. Il est souvent utilisé en association avec d''autres édulcorants.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour la manipulation de la poudre. Mention obligatoire : "Contient une source de phénylalanine".',
    'Yeux : rincer. Peau : laver. Ingestion sans danger (sauf pour les personnes phénylcétonuriques).',
    'Températures très élevées prolongées (dégradation de l''aspartame au-dessus de 150 °C).',
    'Récipient étanche, au sec, à température ambiante. Protéger de l''humidité.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Édulcorant de table et en formulation pour boissons, desserts, confiseries',
   'Diluer ou saupoudrer directement. Son pouvoir sucrant (200x) permet des dosages très faibles. Ajuster la texture avec un agent de charge (polyol).',
   'texte_libre', null, null, 'Selon le goût désiré (quelques ppm à 0,05 % du produit fini)', 'Jusqu''à 100 °C (éviter les cuissons très longues à haute température)', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Thaumatine (E957)
  -- ------------------------------------------------------------
  v_material_id := '161c3dd2-3a0b-4ddf-8454-d1ac2f0a6a2f'::uuid;

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
    'Mélange de protéines thaumatine I et II extraites du fruit de Thaumatococcus daniellii',
    'Thaumatin, E957, édulcorant protéique, Talin',
    'Alimentaire, Cosmétique',
    'Poudre blanche à crème, inodore, saveur sucrée intense (2000-3000 fois le saccharose), apparition lente et arrière-goût réglissé persistant',
    'Neutre (6-7 en solution aqueuse)',
    'Très soluble dans l''eau, insoluble dans l''alcool et les solvants organiques',
    0.80, null,
    'Édulcorant protéique naturel extrait du fruit africain du katempfé. C''est l''édulcorant le plus puissant connu. Sa saveur sucrée apparaît lentement et persiste longtemps. Il est utilisé comme exhausteur de goût et masqueur d''amertume. Très stable à la chaleur et en milieu acide. Sans valeur calorique, non cariogène. Peut être utilisé comme arôme (il possède un statut dual édulcorant/arôme dans l''UE).',
    'Par rapport à tous les autres édulcorants, la thaumatine est une protéine naturelle, sans arrière-goût métallique, mais avec un profil temporel différent (apparition lente, persistance). Contrairement au sucralose ou à la stévia, elle n''a pas d''amertume et est souvent utilisée pour masquer l''amertume des autres édulcorants intenses.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter l''inhalation de poudre.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Aucune notable. Peut être dénaturée par des températures extrêmes prolongées (> 120 °C) en milieu alcalin.',
    'Récipient étanche, au sec, à température ambiante. Conserver dans un endroit frais et à l''abri de la lumière.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Édulcorant intense et exhausteur de goût en confiserie, boissons, chewing-gums',
   'Utiliser à des doses extrêmement faibles (0,5-5 ppm). Souvent combinée avec d''autres édulcorants pour un profil sucré plus équilibré. Efficace pour masquer l''amertume des polyols ou des vitamines.',
   'plage', 0.5, 5, 'ppm (mg/kg) dans le produit fini', 'Jusqu''à 120 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Vératraldéhyde (arôme vanillé boisé)
  -- ------------------------------------------------------------
  v_material_id := 'edd23b39-2e44-437c-95f0-0ab0b0ae2e21'::uuid;

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
    '3,4-diméthoxybenzaldéhyde (C₉H₁₀O₃)',
    'Veratraldehyde, Vératraldéhyde, aldéhyde vératrique, arôme vanillé boisé',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche à jaune pâle, odeur douce, chaude, boisée, vanillée, rappelant le benjoin et la fève tonka',
    'Non applicable (faible solubilité dans l''eau)',
    'Peu soluble dans l''eau, soluble dans l''alcool, les huiles et les solvants organiques',
    1.15, 100.0,
    'Aldéhyde aromatique à la note vanillée-boisée caractéristique. Utilisé en parfumerie pour des notes orientales et gourmandes, et en arômes alimentaires pour renforcer la vanille, le chocolat, les notes boisées. Plus stable que la vanilline en milieu acide.',
    'Par rapport à la vanilline, le vératraldéhyde a un caractère plus boisé, moins sucré, évoquant le bois de gaïac et la fève tonka. Contrairement au pipéronal (héliotropine), il n''a pas la facette florale amandée. Il est souvent utilisé pour enrichir les compositions vanillées complexes.',
    'Modéré',
    array['gants','lunettes','masque'],
    'Porter des gants en nitrile, des lunettes de sécurité et un masque anti-poussière. Éviter le contact prolongé avec la peau.',
    'Yeux : rincer 15 min. Peau : laver à l''eau et au savon. Ingestion : rincer la bouche, boire de l''eau, appeler un médecin si symptômes. Inhalation : air frais.',
    'Oxydants forts, bases fortes.',
    'Récipient étanche, au frais, à l''abri de la lumière et de l''humidité.',
    5, 30, true, true, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H315', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P270', 'P280', 'P301+P312', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Arôme vanillé/boisé pour pâtisserie, chocolaterie, boissons',
   'Diluer dans un solvant (alcool, propylène glycol) avant incorporation. Ajouter 5-50 ppm dans le produit fini.',
   'plage', 5, 50, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 60 °C', 'Immédiat', false, 0),
  (v_academie_id, 'Parfumerie et cosmétique (notes orientales, boisées, ambrées)',
   'Utiliser pur ou en solution dans la composition parfumée à 0,5-5 %. Apporte une facette boisée-vanillée élégante.',
   'plage', 0.5, 5.0, '% du concentré parfumé', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Xylitol (E967)
  -- ------------------------------------------------------------
  v_material_id := 'e91a7caa-d614-4739-9fde-8cd4b7af937f'::uuid;

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
    '1,2,3,4,5-pentahydroxypentane (C₅H₁₂O₅)',
    'Xylitol, E967, sucre de bouleau, polyol naturel',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche, inodore, saveur sucrée intense (égale au saccharose), sensation de fraîcheur en bouche prononcée',
    'Neutre (5-7 en solution aqueuse)',
    'Très soluble dans l''eau (63 g/100 mL à 20 °C), insoluble dans l''alcool',
    1.52, null,
    'Polyol naturel présent dans de nombreux fruits et légumes, obtenu par hydrogénation du xylose. Pouvoir sucrant identique au sucre de table, mais avec 40 % de calories en moins. Très fort effet rafraîchissant en bouche (chaleur de dissolution négative). Non cariogène, il est recommandé pour les chewing-gums et les dentifrices. EXTRÊMEMENT TOXIQUE POUR LES CHIENS : l''ingestion, même à faible dose, provoque une libération massive d''insuline, entraînant une hypoglycémie sévère, des convulsions, une insuffisance hépatique aiguë pouvant être fatale. Un étiquetage clair est impératif sur tout produit contenant du xylitol, et il doit être stocké hors de portée des animaux domestiques chez le client final.',
    'Par rapport au sorbitol (E420), le xylitol a un pouvoir sucrant bien supérieur et un effet rafraîchissant plus intense. Contrairement à l''érythritol (E968), il apporte des calories (2,4 kcal/g) mais a un goût plus proche du sucre. C''est le polyol le plus utilisé en confiserie sans sucre et en hygiène bucco-dentaire.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire pour l''humain. Tenir impérativement hors de portée des chiens et autres animaux domestiques — toxicité canine sévère (hypoglycémie, insuffisance hépatique aiguë potentiellement mortelle même à faible dose). Informer systématiquement le client final de cette toxicité animale spécifique et recommander un étiquetage clair.',
    'Yeux : rincer. Peau : laver. Ingestion humaine sans danger (peut provoquer un effet laxatif à très haute dose). En cas d''ingestion par un chien, contacter immédiatement un vétérinaire.',
    'Oxydants forts.',
    'Récipient étanche, au sec, à température ambiante. Conserver dans un endroit inaccessible aux animaux domestiques.',
    5, 30, true, false, 36, 'a_valider'
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Édulcorant de table et agent de charge en confiserie, chewing-gums, dentifrices',
   'Utiliser en remplacement 1:1 du sucre. Résiste à la cuisson jusqu''à 180 °C. L''effet rafraîchissant est optimal en association avec des arômes menthe ou eucalyptus.',
   'texte_libre', null, null, 'Selon la recette (jusqu''à 100 % du sucre remplacé)', 'Jusqu''à 180 °C', 'Immédiat', false, 0);
end $$;
