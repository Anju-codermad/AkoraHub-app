-- ============================================================
-- AkoraHub - Patch Phase 140 : fiches Académie pour le lot 5 (8
-- produits) des nouveaux produits "Parfums & Additifs" — contenu
-- DeepSeek, vérifié par l'utilisatrice.
-- Linalol documenté comme allergène de parfum à déclaration
-- obligatoire (UE), sensible à l'oxydation. Musc cétone documenté
-- avec avertissements renforcés (nitro-musc PBT sévèrement restreint
-- par l'IFRA, phototoxicité, caractère daté de la matière première).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Linalol (arôme fleuri/lavande)
  -- ------------------------------------------------------------
  v_material_id := '82b7961c-bbd9-498b-b67d-694f4f515580'::uuid;

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
    '3,7-diméthyl-1,6-octadién-3-ol (C₁₀H₁₈O)',
    'Linalool, linalol, arôme lavande, allergène de parfum',
    'Alimentaire, Cosmétique',
    'Liquide incolore à jaune très pâle, odeur florale fraîche, boisée, légèrement citronnée',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau, miscible à l''alcool, aux huiles et aux solvants organiques',
    0.87, 75.0,
    'Principal composant odorant de la lavande, du bois de rose, du coriandre. Note florale polyvalente, très utilisée en parfumerie, cosmétique et arômes alimentaires. C''est l''un des 26 allergènes de parfum à déclaration obligatoire dans l''UE (règlement cosmétique 1223/2009) lorsqu''il dépasse 0,001 % dans les produits sans rinçage et 0,01 % dans les produits à rincer. Il est sensible à l''oxydation : au contact de l''air, il forme des hydroperoxydes de linalol, qui sont beaucoup plus allergisants que la molécule fraîche. Il doit impérativement être stocké à l''abri de l''air et de la lumière, et enrichi d''antioxydants pour limiter cette dégradation.',
    'Par rapport au menthol, le linalol n''a pas d''effet rafraîchissant mais une odeur florale-boisée. Contrairement au géraniol (rose), il est plus léger et moins rosé. Il est souvent associé à l''acétate de linalyle pour un profil lavande complet.',
    'Faible',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité. Éviter le contact prolongé avec la peau (sensibilisant possible, surtout si le produit est oxydé).',
    'Yeux : rincer 15 min. Peau : laver au savon. Ingestion : rincer la bouche, boire de l''eau, consulter un médecin si symptômes.',
    'Oxydants forts, acides forts (déshydratation), air (oxydation).',
    'Bidon en verre ambré ou métal, rempli à ras bord et fermé hermétiquement, à l''abri de l''air, de la lumière et de la chaleur. Stocker sous atmosphère inerte (azote) si possible. Contrôler la teneur en peroxydes avant usage.',
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
  (v_academie_id, 'Arôme fleuri en confiserie, boissons, pâtisseries, glaces',
   'Diluer à 1-10 % dans de l''alcool ou du propylène glycol. Ajouter 5-50 ppm dans le produit fini. Incorporer en fin de préparation.',
   'plage', 5, 50, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 60 °C', 'Immédiat', false, 0),
  (v_academie_id, 'Parfumerie et cosmétique (notes florales, savons, crèmes)',
   'Utiliser pur ou en solution dans la composition parfumée à 1-10 %. Respecter les seuils de déclaration obligatoire de l''allergène.',
   'plage', 1, 10, '% du concentré parfumé', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Maltitol (E965) — sirop et poudre
  -- ------------------------------------------------------------
  v_material_id := '1706457e-4064-494b-9cff-106c5e58772d'::uuid;

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
    '4-O-α-D-glucopyranosyl-D-glucitol (C₁₂H₂₄O₁₁)',
    'Maltitol, E965, édulcorant polyol, sirop de maltitol',
    'Alimentaire, Cosmétique',
    'Sirop : liquide visqueux incolore à jaune pâle, inodore, saveur sucrée propre (90 % du pouvoir sucrant du saccharose). Poudre : poudre cristalline blanche, inodore.',
    'Neutre (5-7 en solution aqueuse)',
    'Sirop miscible à l''eau. Poudre très soluble dans l''eau (60 g/100 mL à 20 °C), insoluble dans l''alcool',
    1.36, null,
    'Polyol obtenu par hydrogénation du maltose (issu de l''amidon). Excellent substitut du saccharose : pouvoir sucrant très proche, même texture, même volume. Non cariogène, index glycémique modéré (35). Le sirop est idéal pour les sauces, glaces, confiseries ; la poudre pour la pâtisserie. Peut provoquer un effet laxatif à des doses supérieures à 50 g/jour.',
    'Par rapport au sorbitol (E420), le maltitol a un pouvoir sucrant bien supérieur et une texture plus proche du sucre. Contrairement à l''isomalt (E953), il est plus hygroscopique et convient mieux aux produits moelleux qu''aux bonbons durs.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Surface glissante en cas de déversement.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger (effet laxatif à haute dose).',
    'Oxydants forts.',
    'Récipient étanche, à température ambiante. Le sirop doit être protégé de la cristallisation (éviter les chocs thermiques).',
    15, 30, true, false, 24, 'a_valider'
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
  (v_academie_id, 'Substitut du sucre en pâtisserie, confiserie, glaces, boissons',
   'Remplacer le sucre en volume (1:1). Le sirop s''incorpore directement ; la poudre se dissout dans la phase aqueuse. Résiste à la cuisson.',
   'texte_libre', null, null, 'Selon la recette (jusqu''à 100 % du sucre remplacé)', 'Jusqu''à 160 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Maltol (E636)
  -- ------------------------------------------------------------
  v_material_id := 'bdb4f9db-8768-46fd-bb5f-8f678dfca902'::uuid;

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
    '3-hydroxy-2-méthyl-4H-pyran-4-one (C₆H₆O₃)',
    'Maltol, E636, exhausteur de goût sucré, arôme caramel, sucre cuit',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche à jaune pâle, odeur sucrée intense de caramel, sucre cuit, fruit confit',
    'Faiblement acide (5-6 en solution aqueuse)',
    'Soluble dans l''eau (1,2 g/100 mL à 20 °C), très soluble dans l''alcool et les glycols',
    1.30, 127.0,
    'Exhausteur de goût sucré naturellement présent dans le malt, le pain grillé, le caramel. Il renforce la perception du sucré, des notes caramélisées et fruitées. Utilisé pour arrondir les arômes et améliorer la sensation en bouche des édulcorants intenses. En cosmétique, il parfume les produits gourmands.',
    'Par rapport à l''éthylmaltol (E637), il est moins puissant (4 à 6 fois moins) mais a un goût plus proche du caramel naturel. Contrairement à la vanilline, il n''apporte pas une note vanillée mais un fond de sucre cuit. Ils sont souvent associés.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière lors de la manipulation de la poudre.',
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
   'Diluer à 1-10 % dans du propylène glycol. Ajouter 10-100 ppm dans le produit fini.',
   'plage', 10, 100, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 80 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Mannitol (E421)
  -- ------------------------------------------------------------
  v_material_id := 'e5fb83e7-5bd7-4ad6-ad9a-da647d28d722'::uuid;

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
    'D-mannitol (C₆H₁₄O₆)',
    'Mannitol, E421, édulcorant polyol, sucre de manne',
    'Alimentaire, Cosmétique, Pharmaceutique',
    'Poudre cristalline blanche, inodore, saveur sucrée propre (50-60 % du pouvoir sucrant du saccharose), sensation de fraîcheur en bouche',
    'Neutre (5-7 en solution aqueuse)',
    'Soluble dans l''eau (18 g/100 mL à 20 °C), insoluble dans l''alcool',
    1.49, null,
    'Polyol naturel présent dans les algues, les fruits, les champignons. Très faible indice glycémique (0), non cariogène, bien toléré sur le plan digestif (pas d''effet laxatif aux doses usuelles). Excellente stabilité à la chaleur. Utilisé comme édulcorant de charge, anti-agglomérant, et en pharmacie (excipient, diurétique osmotique).',
    'Par rapport au sorbitol (E420), il est moins hygroscopique et a un pouvoir sucrant plus élevé. Contrairement à l''érythritol (E968), il est moins calorique (1,6 kcal/g contre 0,2) mais a une meilleure stabilité thermique. Il est le polyol de choix pour les enrobages pharmaceutiques.',
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
  (v_academie_id, 'Édulcorant de charge, anti-agglomérant, enrobage de confiserie, comprimés',
   'Utiliser en remplacement partiel du sucre. Peut être mélangé à des édulcorants intenses. Idéal pour les pâtisseries, les enrobages de chewing-gum et les comprimés.',
   'texte_libre', null, null, 'Selon la recette', 'Jusqu''à 180 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Menthol (arôme menthe)
  -- ------------------------------------------------------------
  v_material_id := 'd4d3c1fa-d08f-4d02-81a9-c0858c8dc5af'::uuid;

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
    '5-méthyl-2-(propan-2-yl)cyclohexan-1-ol (C₁₀H₂₀O)',
    'Menthol, L-menthol, arôme menthe, essence de menthe',
    'Alimentaire, Cosmétique, Pharmaceutique',
    'Cristaux incolores ou poudre cristalline blanche, odeur puissante de menthe poivrée, effet rafraîchissant intense sur la peau et les muqueuses',
    'Non applicable (très peu soluble dans l''eau)',
    'Très peu soluble dans l''eau (0,04 g/100 mL), très soluble dans l''alcool, les huiles et les solvants organiques',
    0.89, 93.0,
    'Principal composant de l''huile essentielle de menthe poivrée. La sensation de froid est due à l''activation des récepteurs TRPM8 de la peau et des muqueuses, et non à une baisse réelle de température. Utilisé comme arôme dans les confiseries, dentifrices, boissons, et comme actif rafraîchissant en cosmétique (gels, après-rasage). Peut être irritant pour les yeux et les muqueuses à l''état pur.',
    'Par rapport à l''eucalyptol (1,8-cinéole), le menthol a un effet froid intense sur la peau et un goût mentholé prononcé. Contrairement au camphre, il est moins volatil et plus rafraîchissant. C''est l''agent rafraîchissant de référence.',
    'Modéré',
    array['gants','lunettes','ventilation'],
    'Gants en nitrile, lunettes de sécurité. Éviter le contact avec les yeux et les muqueuses. Travailler dans un endroit ventilé (vapeurs intenses).',
    'Yeux : rincer 15 min, consulter un ophtalmologue. Peau : laver. Ingestion : rincer la bouche, boire de l''eau, appeler un médecin si symptômes. Inhalation : air frais.',
    'Oxydants forts, acides forts (déshydratation).',
    'Récipient étanche, au frais, à l''abri de la lumière. Conserver dans un endroit sec (les cristaux peuvent s''agglomérer à la chaleur).',
    5, 25, false, true, 60, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H315', 'H318', 'H332', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P280', 'P301+P312', 'P304+P340', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Arôme menthe pour confiseries, chewing-gums, dentifrices, boissons',
   'Dissoudre les cristaux dans de l''alcool ou un glycol avant incorporation. Ajouter 50-200 ppm dans le produit fini.',
   'plage', 50, 200, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 50 °C', 'Immédiat', false, 0),
  (v_academie_id, 'Actif rafraîchissant en cosmétique (gels, crèmes, shampoings)',
   'Dissoudre 0,1-1 % dans la phase huileuse ou alcoolique. Ne pas surdoser (risque d''irritation).',
   'plage', 0.1, 1.0, '% du produit fini', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Musc cétone
  -- ------------------------------------------------------------
  v_material_id := '521495cb-ce6d-41f4-838c-c38f8a22c2cf'::uuid;

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
    '4-tert-butyl-3,5-dinitro-2,6-diméthylacétophénone (C₁₄H₁₈N₂O₅)',
    'Musk Ketone, nitro-musc, musc cétone',
    'Cosmétique (parfumerie, usage restreint)',
    'Poudre cristalline jaune pâle, odeur musquée, chaude, légèrement animale, très persistante',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau, soluble dans l''alcool, les huiles et les solvants organiques',
    1.20, null,
    'Nitro-musc historique de la parfumerie, aujourd''hui très controversé. Son usage est sévèrement restreint par l''IFRA en raison d''une phototoxicité documentée et de sa persistance et bioaccumulation environnementale (classé PBT : persistant, bioaccumulable, toxique). Il ne peut être utilisé qu''à des concentrations très faibles, strictement définies par les normes IFRA en vigueur (généralement < 0,1 % du produit fini). La plupart des industriels l''ont abandonné au profit des muscs polycycliques ou macrocycliques plus sûrs et plus écologiques. Son inscription au catalogue est à but informatif et historique ; sa commercialisation implique de vérifier les limites réglementaires locales en vigueur au moment de la vente et d''informer systématiquement le client final du caractère daté et controversé de cette matière première.',
    'Par rapport au galaxolide (musc polycyclique), le musc cétone a une odeur plus animale et plus chaude, mais il est phototoxique et bien plus polluant. Contrairement à la civettone (musc macrocyclique), il n''est pas biodégradable. C''est un musc de l''ancienne génération.',
    'Élevé',
    array['gants','lunettes','masque'],
    'Gants en nitrile, lunettes de sécurité, masque anti-poussière. Éviter l''exposition à la lumière après application sur la peau (phototoxicité). Ne pas rejeter dans l''environnement. Respecter impérativement les limites IFRA et REACH en vigueur.',
    'Yeux : rincer 15 min. Peau : laver immédiatement au savon. Ingestion : rincer la bouche, boire de l''eau, appeler un centre antipoison. En cas d''exposition solaire après contact cutané, protéger la zone exposée et consulter un dermatologue.',
    'Oxydants forts, agents réducteurs, bases fortes.',
    'Récipient étanche, au frais, à l''abri de la lumière, dans un local ventilé. Tenir à l''écart des denrées alimentaires.',
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H315', 'H317', 'H319', 'H335', 'H373', 'H410')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P260', 'P264', 'P273', 'P280', 'P301+P312', 'P302+P352', 'P305+P351+P338', 'P314', 'P333+P313', 'P391', 'P501')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Note de fond musquée historique en parfumerie (usage très restreint)',
   'Utiliser en solution pré-diluée. Respecter strictement les limites IFRA (< 0,1 % du produit fini pour les applications sur peau, voire interdit). Informer le client du caractère phototoxique et environnementalement persistant.',
   'plage', 0.01, 0.1, '% du produit fini (selon IFRA)', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Myrrhe (résine)
  -- ------------------------------------------------------------
  v_material_id := '6884f1be-ed73-4cff-b46d-6b105ea2a00b'::uuid;

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
    'Gomme-résine exsudée de Commiphora myrrha, contenant des terpènes, sesquiterpènes, polysaccharides et résines',
    'Myrrh, résine de myrrhe, gomme myrrhe, Commiphora myrrha gum',
    'Cosmétique, Alimentaire (usage limité comme arôme), Technique (encens)',
    'Larmes ou fragments solides, cassants, brun-rouge à brun foncé, odeur balsamique, chaude, légèrement amère et fumée. Point de ramollissement 60-80 °C.',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau, partiellement soluble dans l''alcool, soluble dans les solvants organiques',
    1.20, 100.0,
    'Résine naturelle historique, utilisée depuis l''Antiquité comme encens, fixateur de parfum, et ingrédient de baumes. En cosmétique, elle apporte un parfum chaud, résineux et des propriétés antiseptiques douces. En alimentaire, elle est autorisée comme arôme dans certains produits (amers, vermouths). La forme "teinture de myrrhe" (dissoute dans l''alcool) est la plus pratique pour les formulations liquides.',
    'Par rapport à l''oliban (encens), la myrrhe a une odeur plus amère, fumée et moins citronnée. Comparée au benjoin, elle est moins douce et vanillée. La myrrhe est la résine balsamique par excellence.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière si manipulation de poudre. Peut être irritant pour les voies respiratoires sous forme de poussière fine.',
    'Yeux : rincer. Peau : laver au savon. Ingestion : boire de l''eau.',
    'Oxydants forts.',
    'Récipient étanche, au frais, à l''abri de la lumière et de l''humidité.',
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
  (v_academie_id, 'Fixateur de parfum en cosmétique, savonnerie et parfumerie',
   'Broyer la résine et la macérer dans l''alcool à chaud (50 °C) pendant plusieurs heures, filtrer. Utiliser la teinture à 1-5 % dans la composition parfumée.',
   'plage', 1, 5, '% du concentré parfumé', 'Macération à 50 °C', 'Plusieurs heures', false, 0),
  (v_academie_id, 'Arôme amer en agroalimentaire (vermouths, bitters, produits de bouche)',
   'Utiliser la teinture de myrrhe diluée. Ajouter 0,01-0,1 % du produit fini. Respecter les réglementations locales.',
   'plage', 0.01, 0.1, '% du produit fini', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Oliban (encens, résine)
  -- ------------------------------------------------------------
  v_material_id := '9da07b1d-e948-4c2f-a62b-1e180a52c21e'::uuid;

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
    'Gomme-résine exsudée de Boswellia carterii, contenant des acides boswelliques, des terpènes, des polysaccharides',
    'Frankincense, Boswellia Carterii Gum, résine d''encens, oliban',
    'Cosmétique, Alimentaire (usage limité comme arôme), Technique (encens)',
    'Larmes ou fragments solides, cassants, jaune pâle à ambré, odeur boisée, citronnée, résineuse, légèrement épicée. Point de ramollissement 70-90 °C.',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau, partiellement soluble dans l''alcool, soluble dans les solvants organiques',
    1.10, null,
    'Résine naturelle historique, très utilisée en parfumerie comme fixateur et note de fond boisée. Elle apporte une odeur fraîche, citronnée, légèrement épicée et balsamique. En cosmétique, elle est réputée pour ses propriétés anti-âge et apaisantes. En alimentaire, son usage est limité comme arôme. La forme "teinture d''oliban" est la plus pratique pour les formulations.',
    'Par rapport à la myrrhe, l''oliban a une odeur plus fraîche, citronnée et moins amère. Comparé au benjoin, il est moins vanillé et plus boisé. L''oliban est l''encens traditionnel des églises.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière si manipulation de poudre. Irritant possible pour les voies respiratoires sous forme de poussière fine.',
    'Yeux : rincer. Peau : laver au savon. Ingestion : boire de l''eau.',
    'Oxydants forts.',
    'Récipient étanche, au frais, à l''abri de la lumière et de l''humidité.',
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
  (v_academie_id, 'Fixateur de parfum en cosmétique, savonnerie et parfumerie',
   'Broyer la résine et la macérer dans l''alcool à chaud (50 °C) pendant plusieurs heures, filtrer. Utiliser la teinture à 1-5 % dans la composition parfumée.',
   'plage', 1, 5, '% du concentré parfumé', 'Macération à 50 °C', 'Plusieurs heures', false, 0),
  (v_academie_id, 'Arôme alimentaire (note résineuse/boisée) pour boissons, confiseries',
   'Utiliser la teinture d''oliban diluée. Ajouter 0,01-0,1 % du produit fini. Respecter les réglementations locales.',
   'plage', 0.01, 0.1, '% du produit fini', 'Ambiante', 'Immédiat', false, 1);
end $$;
