-- ============================================================
-- AkoraHub - Patch Phase 136 : fiches Académie pour le lot 1 (8
-- produits) des nouveaux produits "Parfums & Additifs" — contenu
-- DeepSeek, vérifié par l'utilisatrice.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Acétate d'éthyle (arôme fruité)
  -- ------------------------------------------------------------
  v_material_id := '402ad4d7-5f39-4630-8fc0-8ec775b8a284'::uuid;

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
    'Acétate d''éthyle (éthanoate d''éthyle)',
    'Ethyl Acetate, ester acétique, arôme solvant fruité',
    'Alimentaire, Cosmétique',
    'Liquide incolore, mobile, odeur fruitée agréable (poire, banane)',
    'Neutre (7)',
    'Légèrement soluble dans l''eau (8 g/100 mL), miscible à l''alcool et aux huiles essentielles',
    0.90, -4.0,
    'Ester simple, très volatil et très inflammable. Utilisé comme arôme fruité en confiserie, pâtisserie, boissons, et comme solvant pour diluer d''autres arômes ou huiles essentielles en cosmétique. Goût typique de poire et de banane à faible dose.',
    'Contrairement aux aldéhydes (C14, C16, C18), c''est un ester simple, plus volatil et moins puissant olfactivement. Par rapport à l''acétate d''isoamyle, il a une odeur plus légère et fruitée-banane. Il ne contient pas de fonctions aldéhyde mais un ester.',
    'Élevé',
    array['gants','lunettes','ventilation'],
    'Gants en nitrile, lunettes de sécurité, travailler loin des flammes et sources de chaleur. Ventilation adéquate. Éviter l''inhalation prolongée.',
    'Inhalation : air frais. Peau : laver à l''eau. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas faire vomir, appeler un médecin si symptômes.',
    'Oxydants forts, bases fortes, acides forts (hydrolyse lente).',
    'Bidon en métal ou verre, bien fermé, dans un local frais et ventilé, à l''abri des sources d''inflammation.',
    5, 25, false, false, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H225', 'H319', 'H336')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P233', 'P261', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Arôme fruité pour confiserie, pâtisserie, boissons',
   'Diluer dans un solvant (éthanol, propylène glycol) avant incorporation. Dosage typique 10-100 ppm dans le produit fini. Peut être ajouté en fin de cuisson pour éviter l''évaporation.',
   'plage', 10, 100, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 60 °C', 'Immédiat', false, 0),
  (v_academie_id, 'Solvant d''arômes et diluant en cosmétique (parfums)',
   'Utiliser pur ou en mélange pour dissoudre des cristaux aromatiques. Ajouter à la phase alcoolique du parfum.',
   'texte_libre', null, null, 'quantité suffisante pour dissoudre les matières premières', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Acétoïne (arôme beurre)
  -- ------------------------------------------------------------
  v_material_id := 'bc3ea164-c9d2-4462-b495-2206b4ed867e'::uuid;

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
    '3-hydroxybutan-2-one (acétoïne)',
    'Acetoin, acétyl méthyl carbinol, arôme beurre',
    'Alimentaire, Cosmétique',
    'Liquide jaune pâle à incolore, odeur caractéristique de beurre frais, légèrement grasse',
    'Neutre (légèrement acide en solution aqueuse)',
    'Miscible à l''eau, à l''alcool et aux glycols. Peu soluble dans les huiles.',
    1.01, 41.0,
    'Molécule naturelle présente dans le beurre, les fromages, les fruits. Donne une note crémeuse, beurrée, lactée. Très utilisée en association avec le diacétyle pour les arômes beurre, caramel, noisette. Inflammable. En cosmétique, utilisée dans les parfums gourmands.',
    'Par rapport au diacétyle, elle est moins puissante et moins agressive pour les voies respiratoires. Complémentaire des aldéhydes lactoniques (C18) pour les notes crémeuses. L''acétoïne est l''arôme beurre doux, le diacétyle le beurre intense.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité. Éviter l''inhalation prolongée. Inflammable.',
    'Yeux : rincer 15 min. Peau : laver à l''eau et au savon. Ingestion : rincer la bouche, boire de l''eau. Inhalation : air frais.',
    'Oxydants forts, bases fortes.',
    'Bidon hermétique, au frais, à l''abri de la lumière et des sources de chaleur.',
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
  (v_academie_id, 'Arôme beurre pour pâtisserie, confiserie, produits laitiers, margarines',
   'Diluer dans un solvant (propylène glycol, éthanol) à 1-10 %. Ajouter en fin de préparation (0,5-5 ppm dans le produit fini).',
   'plage', 0.5, 5, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 60 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Aldéhyde C14 (gamma-undécalactone, arôme pêche)
  -- ------------------------------------------------------------
  v_material_id := '5ba018ca-8d10-4481-90d2-dddca64e11e1'::uuid;

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
    'Gamma-undécalactone (C₁₁H₂₀O₂), également appelée aldéhyde C14',
    'Peach aldehyde, gamma-undecalactone, aldéhyde C14, arôme pêche',
    'Alimentaire, Cosmétique',
    'Liquide incolore à jaune pâle, odeur intense et fruitée de pêche mûre',
    'Non applicable (huileux, insoluble dans l''eau)',
    'Insoluble dans l''eau, soluble dans l''alcool, les huiles et la plupart des solvants organiques',
    0.94, 110.0,
    'Lactone à noyau gamma, souvent appelée à tort aldéhyde (nom historique). Très puissante, elle est le composant principal des arômes pêche, abricot, prune. Également utilisée en parfumerie fine pour des notes fruitées solaires.',
    'Par rapport à l''aldéhyde C16 (fraise), elle a une note plus lactonique (crème fruitée) que fraise. Contrairement à l''aldéhyde C18 (coco), elle est plus fruitée que grasse. C''est la lactone de référence pour la pêche.',
    'Faible',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité. Éviter le contact prolongé avec la peau. Peut être irritante à l''état pur.',
    'Yeux : rincer 15 min. Peau : laver au savon. Ingestion : rincer la bouche, boire de l''eau, consulter un médecin si grande quantité.',
    'Oxydants forts, bases fortes (ouverture du cycle lactone).',
    'Bidon hermétique, au frais, à l''abri de la lumière et de l''humidité.',
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
  (v_academie_id, 'Arôme pêche/abricot pour confiseries, yaourts, glaces, boissons',
   'Diluer à 1-10 % dans du propylène glycol ou de l''alcool. Ajouter à la préparation à raison de 0,5-5 ppm de produit pur.',
   'plage', 0.5, 5, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 70 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Aldéhyde C16 (éthyl-méthyl-phénylglycidate, arôme fraise)
  -- ------------------------------------------------------------
  v_material_id := '084081e5-d7c3-4183-8605-962cc9e30611'::uuid;

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
    'Éthyl-3-méthyl-3-phénylglycidate (ester glycidique), appelé aldéhyde C16',
    'Strawberry aldehyde, aldéhyde C16, EMPG, arôme fraise',
    'Alimentaire, Cosmétique',
    'Liquide incolore à jaune très pâle, odeur puissante et sucrée de fraise des bois',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau, soluble dans l''alcool, les huiles et les solvants organiques',
    1.09, 100.0,
    'Ester glycidique (époxyde) à odeur intense de fraise. Substance de référence des arômes fraise en confiserie. Non sensible aux acides contrairement à certaines notes fruitées. L''époxyde le rend réactif, mais il est stable dans les conditions normales d''utilisation.',
    'Contrairement à l''aldéhyde C14 (pêche, lactone), c''est un époxyde avec une note plus sucrée, confiturée. Plus puissant que les esters de fraise classiques. Il est le standard historique de la fraise en arôme.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité. Éviter le contact avec la peau (sensibilisant possible).',
    'Peau : laver au savon. Yeux : rincer 15 min. Ingestion : rincer la bouche, boire de l''eau, consulter un médecin si symptômes. En cas de réaction cutanée, consulter un dermatologue.',
    'Acides forts, bases fortes, amines (ouverture de l''époxyde).',
    'Récipient hermétique, au frais, à l''abri de la lumière et de l''humidité.',
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

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H317', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P272', 'P280', 'P302+P352', 'P305+P351+P338', 'P333+P313')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Arôme fraise pour bonbons, chewing-gums, glaces, sirops',
   'Diluer à 1-5 % dans du propylène glycol. Ajouter en fin de cuisson ou dans la masse à raison de 1-10 ppm de produit pur.',
   'plage', 1, 10, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 80 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Aldéhyde C18 (gamma-nonalactone, arôme coco)
  -- ------------------------------------------------------------
  v_material_id := '52982e38-8d4e-4169-a89f-bf0ff008a04c'::uuid;

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
    'Gamma-nonalactone (C₉H₁₆O₂), également appelée aldéhyde C18',
    'Coconut aldehyde, gamma-nonalactone, aldéhyde C18, arôme coco',
    'Alimentaire, Cosmétique',
    'Liquide incolore à jaune pâle, odeur caractéristique de noix de coco fraîche et de lait de coco',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau, soluble dans l''alcool, les huiles, les glycols',
    0.96, 100.0,
    'Lactone gamma à chaîne plus courte que la gamma-undécalactone (C14). Odeur crémeuse de coco, très utilisée en association avec d''autres lactones pour des notes laitières, noisette, amande. Appréciée en cosmétique pour les parfums exotiques et solaires.',
    'Par rapport à l''aldéhyde C14 (pêche), elle a une note coco/crémeuse, moins fruitée. Comparée à la gamma-décalactone, elle est plus laitière. C''est la lactone signature des arômes coco.',
    'Faible',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité.',
    'Yeux : rincer 15 min. Peau : laver au savon. Ingestion : boire de l''eau.',
    'Oxydants forts, bases fortes.',
    'Bidon hermétique, au frais, à l''abri de la lumière.',
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
  (v_academie_id, 'Arôme coco pour confiserie, pâtisserie, crèmes glacées, boissons exotiques',
   'Diluer à 1-10 % dans du propylène glycol. Ajouter 0,5-5 ppm de produit pur dans la préparation.',
   'plage', 0.5, 5, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 70 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Alun de potassium (E522)
  -- ------------------------------------------------------------
  v_material_id := '9b0ab63f-97a1-4101-9afe-a149cda571d5'::uuid;

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
    'Sulfate double d''aluminium et de potassium dodécahydraté (KAl(SO₄)₂·12H₂O)',
    'E522, alun de potassium, pierre d''alun, déodorant cristal, sulfate d''alumine et de potasse',
    'Alimentaire, Cosmétique, Technique',
    'Cristaux incolores ou poudre blanche, inodore, saveur astringente et sucrée',
    '3-4 (solution aqueuse à 1 %)',
    'Soluble dans l''eau (14 g/100 mL à 20 °C), insoluble dans l''alcool',
    1.76, null,
    'Agent affermissant et régulateur d''acidité (E522) utilisé en conserverie (cornichons, oignons) et en pâtisserie (levure chimique). En cosmétique, il est utilisé comme déodorant cristal (pierre d''alun) : il inhibe la prolifération bactérienne responsable des odeurs. L''EFSA a fixé une dose hebdomadaire tolérable (DHT) pour l''aluminium de 1 mg/kg de poids corporel. L''usage externe (déodorant) est considéré comme sûr, mais l''accumulation d''aluminium par ingestion est à surveiller.',
    'Par rapport à l''alun de sodium, il est moins soluble et plus utilisé en alimentaire. Contrairement aux sels de calcium (chlorure de calcium E509), il apporte de l''aluminium et non du calcium. Il n''est pas un conservateur mais un affermissant.',
    'Faible',
    array['lunettes'],
    'Lunettes de sécurité pour éviter les projections. Ne pas inhaler la poudre. Éviter l''ingestion régulière (aluminium).',
    'Yeux : rincer 15 min. Peau : laver. Ingestion : rincer la bouche, boire de l''eau. Consulter un médecin en cas de symptômes.',
    'Bases fortes (formation de gel d''hydroxyde d''aluminium), oxydants forts.',
    'Récipient étanche, au sec, à température ambiante. Protéger de l''humidité.',
    5, 30, true, false, 60, 'a_valider'
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
  (v_academie_id, 'Affermissant pour conserves de légumes (cornichons, oignons)',
   'Ajouter 5-10 g/L dans la saumure de conservation. Donne du croquant aux légumes.',
   'valeur_unique', 10, 10, 'g/L de saumure', 'Ambiante à 80 °C', 'Plusieurs jours', false, 0),
  (v_academie_id, 'Déodorant cristal (pierre d''alun)',
   'Humidifier la pierre et appliquer directement sur les aisselles propres. L''effet antibactérien dure plusieurs heures.',
   'texte_libre', null, null, 'Usage direct', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Ambre gris (ambroxide synthétique)
  -- ------------------------------------------------------------
  v_material_id := 'd56eb262-ef67-4e5a-a9a5-2e4f2dfecc27'::uuid;

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
    'Dodécahydro-3a,6,6,9a-tétraméthyl-naphto[2,1-b]furane (ambroxide, ambre synthétique)',
    'Ambroxide, Ambroxan, ambre gris synthétique, fixateur ambré',
    'Cosmétique (parfumerie), Alimentaire (traces)',
    'Cristaux blancs à poudre cristalline, odeur boisée, ambrée, chaude et marine, très persistante',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau, soluble dans l''alcool, les huiles et les solvants organiques',
    1.10, 160.0,
    'Substitut synthétique de l''ambre gris naturel (concrétion intestinale de cachalot, aujourd''hui protégée). L''ambroxide reproduit l''odeur chaude, marine, légèrement boisée et tabac de l''ambre gris. Fixateur de parfum très puissant : il prolonge la tenue des compositions parfumées. Très stable et non sensibilisant.',
    'Contrairement aux muscs synthétiques (galaxolide), il n''est pas un musc mais un ambre. Par rapport aux résines naturelles (benjoin, myrrhe), il est synthétique et plus diffusif. Il est le standard de la note ambrée moderne.',
    'Faible',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité. Éviter l''inhalation de poudre.',
    'Yeux : rincer 15 min. Peau : laver au savon. Ingestion : boire de l''eau.',
    'Oxydants forts.',
    'Récipient étanche, au frais, à l''abri de la lumière et de l''humidité.',
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
  (v_academie_id, 'Fixateur et note de fond en parfumerie fine, cosmétique, savons',
   'Dissoudre 0,5-5 % dans l''alcool ou les huiles du parfum. Utilisé en traces (0,1-1 %) comme fixateur, ou jusqu''à 10 % pour une note ambrée puissante.',
   'plage', 0.1, 10.0, '% du concentré parfumé', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Anéthol (arôme anis)
  -- ------------------------------------------------------------
  v_material_id := '07e5cff2-a111-4b56-aa17-60c45b683261'::uuid;

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
    'Trans-anéthol (1-méthoxy-4-(prop-1-èn-1-yl)benzène)',
    'Anethole, anéthol, arôme anis, essence d''anis étoilé',
    'Alimentaire, Cosmétique',
    'Liquide incolore à jaune pâle (à température > 20 °C), ou cristaux blancs (point de fusion 21 °C), odeur intense et sucrée d''anis',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau, soluble dans l''alcool, les huiles et les solvants organiques',
    0.99, 90.0,
    'Composant principal des huiles essentielles d''anis, de badiane, de fenouil. Goût très sucré, caractéristique des boissons anisées (pastis, ouzo), confiseries, dentifrices. Sensible à la lumière et à l''oxydation (formation de trans-anéthol époxyde). En cosmétique, utilisé pour les parfums anisés et les produits d''hygiène buccale.',
    'Par rapport à l''eugénol (clou de girofle), il est plus doux et anisé. Contrairement au menthol, il n''a pas d''effet rafraîchissant mais une saveur sucrée intense. C''est la molécule signature des arômes anis.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité. Éviter le contact prolongé avec la peau (sensibilisant possible).',
    'Peau : laver au savon. Yeux : rincer 15 min. Ingestion : rincer la bouche, boire de l''eau, appeler un médecin si symptômes.',
    'Oxydants forts, acides forts (isomérisation).',
    'Récipient hermétique, à l''abri de la lumière et de la chaleur, dans un endroit frais.',
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
  (v_academie_id, 'Arôme anis pour confiseries, boissons, dentifrices, sirops',
   'Diluer à 1-10 % dans de l''alcool. Ajouter 5-50 ppm dans le produit fini. Peut cristalliser à basse température, réchauffer doucement avant emploi.',
   'plage', 5, 50, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 60 °C', 'Immédiat', false, 0);
end $$;
