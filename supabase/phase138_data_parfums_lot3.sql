-- ============================================================
-- AkoraHub - Patch Phase 138 : fiches Académie pour le lot 3 (8
-- produits) des nouveaux produits "Parfums & Additifs" — contenu
-- DeepSeek, vérifié par l'utilisatrice.
-- Diacétyle documenté avec avertissements renforcés (risque de
-- bronchiolite oblitérante en exposition professionnelle chronique
-- à des vapeurs concentrées). Furfuryl mercaptan documenté avec
-- avertissements renforcés (odeur détectable au ppb, usage
-- exclusivement en solution pré-diluée).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Diacétyle (arôme beurre)
  -- ------------------------------------------------------------
  v_material_id := '77cdf41c-1e2a-4f47-beb4-ee774d4b0f21'::uuid;

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
    '2,3-butanedione (C₄H₆O₂)',
    'Diacetyl, arôme beurre, butanedione',
    'Alimentaire, Cosmétique',
    'Liquide jaune à jaune-vert, odeur très intense de beurre frais, légèrement piquant',
    'Neutre (légèrement acide en solution aqueuse)',
    'Soluble dans l''eau (20 g/100 mL), miscible à l''alcool, aux glycols et aux huiles',
    0.98, 6.0,
    'Arôme beurre puissant, naturellement présent dans le beurre, les fromages et la fermentation lactique. Très volatil et très inflammable (point éclair bas). L''inhalation répétée de vapeurs concentrées, en particulier à chaud, est associée à un risque documenté de bronchiolite oblitérante (« poumon de pop-corn »), une maladie respiratoire grave et irréversible. Ce risque concerne exclusivement les expositions professionnelles chroniques en milieu confiné (usines d''arômes, production de pop-corn micro-ondes). L''usage ponctuel dilué en cuisine ne présente pas de danger.',
    'Par rapport à l''acétoïne, le diacétyle est plus puissant (note beurre intense) mais beaucoup plus volatil et dangereux à l''inhalation concentrée. Il est souvent utilisé en mélange avec l''acétoïne pour un profil beurre complet.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Gants en nitrile, lunettes de sécurité étanches, masque à cartouche filtrante pour vapeurs organiques (type A). Manipuler impérativement sous hotte aspirante ou avec un système clos pour toute quantité non diluée. Éviter absolument l''inhalation des vapeurs concentrées, surtout à chaud. Utiliser des systèmes de ventilation efficaces.',
    'Inhalation : transporter la victime à l''air frais, consulter immédiatement un médecin. Peau : rincer 15 min, retirer les vêtements contaminés. Yeux : rincer 15 min, consulter un ophtalmologue. Ingestion : rincer la bouche, ne pas faire vomir, appeler un centre antipoison.',
    'Oxydants forts, bases fortes, chaleur (dégagement de vapeurs).',
    'Bidon en métal ou verre, bien fermé, dans un local frais, ventilé, à l''abri des sources d''inflammation et de la chaleur. Stocker sous atmosphère inerte si possible.',
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

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H225', 'H302', 'H315', 'H318', 'H331', 'H335', 'H373')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P260', 'P280', 'P304+P340', 'P305+P351+P338', 'P311', 'P403+P233')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Arôme beurre pour margarines, pop-corn, pâtisseries, confiseries',
   'Utiliser exclusivement en solution pré-diluée (0,1-1 % dans du propylène glycol). Ajouter en fin de préparation, à froid si possible. Dosage final dans l''aliment : 0,5-5 ppm.',
   'plage', 0.5, 5, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 40 °C (éviter de chauffer le produit pur)', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Érythritol (E968)
  -- ------------------------------------------------------------
  v_material_id := 'f6ab44f8-2991-44f6-80db-de9bf553f65a'::uuid;

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
    '1,2,3,4-butanetétrol (C₄H₁₀O₄)',
    'Erythritol, E968, polyol naturel, édulcorant de charge',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche, inodore, saveur sucrée propre (60-70 % du pouvoir sucrant du saccharose), sensation de fraîcheur en bouche',
    'Neutre (5-7 en solution aqueuse)',
    'Modérément soluble dans l''eau (37 g/100 mL à 20 °C), insoluble dans l''alcool',
    1.45, null,
    'Polyol naturel présent dans les fruits, obtenu par fermentation. Non cariogène, très faible indice glycémique (0), quasiment non calorique (0,2 kcal/g). N''est pas métabolisé et est excrété dans l''urine, ce qui le rend bien toléré en digestion (pas d''effet laxatif jusqu''à 0,8 g/kg). Bonne stabilité à la chaleur.',
    'Par rapport au xylitol (E967), l''érythritol a un pouvoir sucrant inférieur, mais est bien mieux toléré sur le plan digestif. Contrairement au maltitol, il n''a pratiquement pas de calories. Il est le seul polyol quasi acalorique.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter l''inhalation de poussières.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Édulcorant de charge et texturant en pâtisserie, confiserie, boissons',
   'Utiliser en remplacement partiel ou total du sucre, en ajustant le pouvoir sucrant (60-70 %). Résiste à la cuisson. Peut être combiné avec des édulcorants intenses (stévia, sucralose).',
   'texte_libre', null, null, 'Selon la recette (jusqu''à 100 % du sucre remplacé)', 'Jusqu''à 180 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Éthylmaltol (E637)
  -- ------------------------------------------------------------
  v_material_id := 'd2e587e9-6951-4e7e-ad29-1ccc7cac3092'::uuid;

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
    '2-éthyl-3-hydroxy-4H-pyran-4-one (C₇H₈O₃)',
    'Ethyl maltol, E637, exhausteur de goût sucré, arôme caramel',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche à jaune pâle, odeur sucrée intense de caramel, barbe à papa, fruit confit',
    'Faiblement acide (5-6 en solution aqueuse)',
    'Soluble dans l''eau (1,5 g/100 mL à 20 °C), très soluble dans l''alcool et les glycols',
    1.30, 125.0,
    'Exhausteur de goût sucré et arôme, 4 à 6 fois plus puissant que le maltol (E636). Il renforce la perception du sucré, des notes fruitées et caramélisées. Utilisé pour arrondir les arômes et masquer l''amertume des édulcorants intenses. En cosmétique, il apporte une note gourmande aux parfums.',
    'Par rapport au maltol (E636), il est plus puissant et plus stable. Contrairement à la vanilline, il n''apporte pas une note vanillée mais un fond sucré/caramel. Il est souvent associé à la vanilline pour un profil complet.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière lors de la manipulation de la poudre. Éviter l''inhalation de poussières.',
    'Yeux : rincer 15 min. Peau : laver. Ingestion : boire de l''eau.',
    'Oxydants forts.',
    'Récipient étanche, au frais, à l''abri de la lumière et de l''humidité.',
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
  (v_academie_id, 'Exhausteur de goût sucré en confiserie, boissons, pâtisserie, arômes',
   'Diluer à 1-10 % dans du propylène glycol. Ajouter 5-50 ppm dans le produit fini. Effet optimal à pH 4-6.',
   'plage', 5, 50, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 80 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Eucalyptol (1,8-cinéole)
  -- ------------------------------------------------------------
  v_material_id := 'ac9e6293-7848-4106-8b43-143b69826d21'::uuid;

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
    '1,3,3-triméthyl-2-oxabicyclo[2.2.2]octane (C₁₀H₁₈O)',
    'Eucalyptol, 1,8-cineole, essence d''eucalyptus, arôme mentholé/eucalyptus',
    'Alimentaire, Cosmétique, Pharmaceutique',
    'Liquide incolore, odeur fraîche, camphrée, d''eucalyptus et de romarin',
    'Non applicable (insoluble dans l''eau)',
    'Très peu soluble dans l''eau (0,35 g/100 mL), miscible à l''alcool, aux huiles et aux solvants organiques',
    0.92, 50.0,
    'Principal composant de l''huile essentielle d''eucalyptus (jusqu''à 90 %). Utilisé comme arôme frais dans les confiseries, bonbons, chewing-gums, et en cosmétique pour les produits d''hygiène buccale et les inhalations. Sensation de fraîcheur non glaciale contrairement au menthol.',
    'Par rapport au menthol, il procure une fraîcheur respiratoire sans l''effet glaçon sur la peau. Contrairement au camphre, il est moins intense et plus doux. Il est souvent utilisé en combinaison avec le menthol pour un effet complet.',
    'Modéré',
    array['gants','lunettes','ventilation'],
    'Gants en nitrile, lunettes de sécurité. Travailler dans un endroit ventilé (odeur forte). Éviter l''inhalation prolongée.',
    'Yeux : rincer 15 min. Peau : laver au savon. Ingestion : rincer la bouche, boire de l''eau, appeler un médecin si symptômes. Inhalation : air frais.',
    'Oxydants forts, acides forts.',
    'Bidon en métal ou verre, bien fermé, au frais, à l''abri de la lumière.',
    5, 25, false, true, 36, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H226', 'H315', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P261', 'P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Arôme fraîcheur pour confiseries, bonbons, chewing-gums, sirops',
   'Diluer à 1-5 % dans de l''alcool ou un glycol. Ajouter 10-100 ppm dans le produit fini. Peut cristalliser à basse température.',
   'plage', 10, 100, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 50 °C', 'Immédiat', false, 0),
  (v_academie_id, 'Parfumerie et cosmétique (dentifrices, bains de bouche, inhalations)',
   'Ajouter 0,5-2 % dans la phase alcoolique ou huileuse du produit.',
   'plage', 0.5, 2.0, '% du produit fini', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Eugénol (arôme clou de girofle)
  -- ------------------------------------------------------------
  v_material_id := '769e7241-bb95-4134-a1af-ddfccfa48e8a'::uuid;

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
    '4-allyl-2-méthoxyphénol (C₁₀H₁₂O₂)',
    'Eugenol, essence de girofle, arôme clou de girofle',
    'Alimentaire, Cosmétique, Pharmaceutique',
    'Liquide huileux incolore à jaune pâle, odeur puissante et épicée de clou de girofle',
    'Non applicable (insoluble dans l''eau)',
    'Très peu soluble dans l''eau, miscible à l''alcool, aux huiles, aux solvants organiques',
    1.07, 100.0,
    'Principal composant de l''huile essentielle de clou de girofle (80-90 %). Arôme épicé chaud, utilisé en pâtisserie, charcuterie, et en dentisterie (propriétés antiseptiques et anesthésiantes locales). En cosmétique, il est utilisé dans les parfums orientaux et les produits pour les dents.',
    'Par rapport à l''anéthol (anis), il est plus épicé et piquant. Contrairement au menthol ou à l''eucalyptol, il n''a pas d''effet rafraîchissant mais un effet chauffant. C''est l''arôme signature du pain d''épices.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité. Éviter le contact prolongé avec la peau (sensibilisant possible).',
    'Peau : laver au savon. Yeux : rincer 15 min. Ingestion : rincer la bouche, boire de l''eau, appeler un médecin si symptômes. Inhalation : air frais.',
    'Oxydants forts, bases fortes.',
    'Bidon en verre ambré ou métal, bien fermé, au frais, à l''abri de la lumière.',
    5, 25, false, true, 36, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H315', 'H317', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P270', 'P272', 'P280', 'P301+P312', 'P305+P351+P338', 'P333+P313')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Arôme épicé pour pâtisserie, pain d''épices, charcuteries, boissons',
   'Diluer à 1-5 % dans de l''alcool. Ajouter 5-50 ppm dans le produit fini. Incorporer en fin de cuisson si possible.',
   'plage', 5, 50, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 60 °C', 'Immédiat', false, 0),
  (v_academie_id, 'Parfumerie orientale et produits d''hygiène buccale',
   'Utiliser pur ou en solution dans la composition parfumée à 0,5-2 %.',
   'plage', 0.5, 2.0, '% du concentré parfumé', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Extrait de levure (autolysat de levure)
  -- ------------------------------------------------------------
  v_material_id := '6758d37c-51be-4cc2-a97f-28fae277ff15'::uuid;

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
    'Mélange complexe de protéines, peptides, acides aminés, nucléotides et vitamines issus de l''autolyse de Saccharomyces cerevisiae',
    'Yeast Extract, autolysat de levure, exhausteur de goût naturel',
    'Alimentaire, Cosmétique',
    'Poudre beige à brun clair, ou pâte visqueuse, odeur savoureuse de bouillon, umami',
    '5-6 (solution aqueuse à 1 %)',
    'Très soluble dans l''eau, insoluble dans les solvants organiques',
    0.50, null,
    'Ingrédient naturel riche en acide glutamique libre, il apporte une saveur umami (savoureuse) aux préparations culinaires. Utilisé comme exhausteur de goût propre, sans le caractère artificiel du glutamate monosodique. Excellente alternative clean-label au MSG. En cosmétique, il est utilisé dans les soins capillaires pour ses propriétés gainantes.',
    'Par rapport au glutamate monosodique (E621), il contient de l''acide glutamique naturellement présent dans la levure, avec un profil gustatif plus complexe et moins ciblé. Il n''est pas un additif mais un ingrédient. Il est l''exhausteur de goût de référence en cuisine bio.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière lors de la manipulation de la poudre. Peut provoquer une irritation respiratoire chez les personnes sensibles aux poussières.',
    'Yeux : rincer 15 min. Peau : laver. Ingestion sans danger. Inhalation : air frais.',
    'Oxydants forts, acides forts.',
    'Récipient étanche, au sec, à l''abri de l''humidité (hygroscopique).',
    5, 30, true, false, 24, 'a_valider'
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
  (v_academie_id, 'Exhausteur de goût naturel pour bouillons, sauces, snacks, soupes',
   'Ajouter 0,5-2 % du produit fini. Incorporer en phase aqueuse. Résiste à la cuisson.',
   'plage', 0.5, 2.0, '% du produit fini', 'Ambiante à 100 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Furfuryl mercaptan (arôme café)
  -- ------------------------------------------------------------
  v_material_id := '63972d8a-a2ca-40f5-9abd-37dafca4b8a8'::uuid;

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
    '2-furanméthanethiol (C₅H₆OS)',
    'Furfuryl mercaptan, arôme café, 2-furylméthanethiol',
    'Alimentaire, Cosmétique',
    'Liquide incolore à jaune pâle, odeur extrêmement puissante de café torréfié, noisette grillée',
    'Non applicable (très peu soluble dans l''eau)',
    'Très peu soluble dans l''eau, soluble dans l''alcool et les huiles',
    1.13, 50.0,
    'Molécule à l''odeur exceptionnellement puissante : seuil de détection olfactive de l''ordre de 0,005 ppb (parties par milliard). Elle est responsable de l''arôme caractéristique du café fraîchement torréfié. S''utilise exclusivement en solution pré-diluée (0,001-0,1 %), car la manipulation du produit pur peut contaminer durablement un espace de travail (odeur persistante sur le matériel, les vêtements, la peau). La moindre goutte peut saturer une pièce entière pendant des jours. Ne jamais manipuler le produit pur hors d''un système clos ou d''une hotte.',
    'Comparé à d''autres composés soufrés, c''est l''un des plus odorants connus. Il définit à lui seul la note café torréfié, alors que d''autres mercaptans (comme le butylmercaptan) évoquent l''ail ou le gaz.',
    'Modéré',
    array['gants','lunettes','masque','ventilation'],
    'Gants en nitrile, lunettes de sécurité, masque à cartouche pour vapeurs organiques et composés soufrés. Manipuler impérativement sous hotte aspirante ou en local très ventilé. Utiliser exclusivement en solution pré-diluée. Éviter tout contact avec la peau et les vêtements. Le produit pur ne doit jamais être ouvert en dehors d''un système clos ou d''une hotte.',
    'Yeux : rincer 15 min. Peau : laver immédiatement avec un détergent doux, puis rincer à l''eau. Ingestion : rincer la bouche, boire de l''eau, appeler un médecin si symptômes. Inhalation : air frais. En cas de contamination des vêtements, les retirer et les aérer longuement.',
    'Oxydants forts, bases fortes, acides forts.',
    'Flacon en verre ambré avec bouchon étanche, dans un endroit frais, ventilé et isolé. Stocker le flacon d''origine dans un sac ou un contenant secondaire pour confiner les odeurs.',
    2, 8, false, true, 12, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H226', 'H302', 'H315', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P261', 'P264', 'P280', 'P301+P312', 'P305+P351+P338', 'P403+P233')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Arôme café intense pour confiserie, glaces, boissons, yaourts',
   'Se manipule exclusivement en solution pré-diluée (0,001-0,1 % dans du propylène glycol ou de l''éthanol). Ajouter 0,5-5 ppb dans le produit fini. Ne jamais utiliser pur.',
   'plage', 0.5, 5, 'ppb (µg/kg) dans le produit fini', 'Ambiante à 50 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Galaxolide (musc polycyclique)
  -- ------------------------------------------------------------
  v_material_id := 'a3b5b650-41e3-4658-97b1-da6282a6372b'::uuid;

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
    '1,3,4,6,7,8-hexahydro-4,6,6,7,8,8-hexaméthylcyclopenta[g]-2-benzopyrane (C₁₈H₂₆O)',
    'Galaxolide, HHCB, musc polycyclique synthétique',
    'Cosmétique (parfumerie), Technique',
    'Liquide visqueux incolore à jaune pâle, odeur musquée, douce, florale, très persistante',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau, soluble dans l''alcool, les huiles et la plupart des solvants organiques',
    1.01, 150.0,
    'Musc polycyclique de synthèse le plus utilisé au monde. Excellente stabilité, faible coût, bonne fixation. Note de fond musquée douce, légèrement boisée, très rémanente. Cependant, il est peu biodégradable, bioaccumulable et suspecté d''être un perturbateur endocrinien. Son usage est de plus en plus restreint dans l''UE (REACH) et certaines marques l''ont retiré de leurs formulations.',
    'Par rapport à la civettone (musc macrocyclique), le galaxolide est moins cher, plus stable, mais beaucoup moins respectueux de l''environnement et plus controversé. Contrairement à l''ambroxide (ambre), il a une odeur musquée et non ambrée.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité. Éviter l''inhalation prolongée et le contact cutané. Produit suspecté de toxicité environnementale : ne pas rejeter dans les égouts.',
    'Yeux : rincer 15 min. Peau : laver au savon. Ingestion : rincer la bouche, boire de l''eau, consulter un médecin si symptômes.',
    'Oxydants forts.',
    'Bidon hermétique, à température ambiante, à l''abri de la lumière. Stocker dans un local ventilé.',
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

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319', 'H335', 'H410')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P273', 'P280', 'P305+P351+P338', 'P391', 'P501')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Note de fond musquée en parfumerie fine, lessives, adoucissants',
   'Utiliser pur ou en solution dans le concentré parfumé à 1-15 %. Apporte une excellente fixation et une odeur propre et douce.',
   'plage', 1, 15, '% du concentré parfumé', 'Ambiante', 'Immédiat', false, 0);
end $$;
