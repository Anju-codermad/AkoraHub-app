-- ============================================================
-- AkoraHub - Patch Phase 113 : fiches Académie pour les 9 charges
-- minérales déjà présentes dans le catalogue avant la campagne —
-- contenu DeepSeek, vérifié par l'utilisatrice.
--
-- Termine la catégorie "Charges Minérales" (25/25 : 16 nouveaux en
-- phase 111/112 + ces 9 produits déjà existants).
--
-- Note : la Diatomite/Kieselguhr peut contenir de la silice
-- cristalline libre (H350i, cancérogène par inhalation) — EPI
-- renforcés (masque FFP2) documentés en conséquence.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Bentonite œnologique
  -- ------------------------------------------------------------
  v_material_id := 'f001ce1c-02e0-4672-9587-c0ec9e42e33e'::uuid;

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
    'Smectite sodique activée, silicate d''aluminium et de magnésium hydraté ((Na,Ca)₀.₃₃(Al,Mg)₂Si₄O₁₀(OH)₂·nH₂O)',
    'Bentonite de clarification, bentonite sodique, terre à foulon œnologique',
    'Technique',
    'Poudre beige clair à grisâtre, très fine',
    '8-9 (suspension aqueuse à 5%)',
    'Insoluble, gonfle en formant une suspension colloïdale stable',
    0.85, null,
    'Très fort pouvoir de gonflement et d''adsorption des protéines. Sélectionnée pour son pouvoir clarifiant élevé et sa faible libération de cations.',
    'Par rapport à la bentonite de fonderie, elle est beaucoup plus pure, sans contaminants métalliques. Comparée à la gélatine de collage, elle élimine les protéines instables sans risque de sur-collage.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour éviter l''inhalation de poudre fine.',
    'Inhalation : air frais. Yeux : rincer abondamment. Peau : laver.',
    'Éviter le contact avec des acides forts qui peuvent libérer des ions métalliques.',
    'Récipient étanche, au sec, à l''écart des odeurs et de l''humidité.',
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Clarification des vins blancs et rosés',
   'Délayer 20-80 g/hL de bentonite dans 10 fois son volume d''eau tiède, laisser gonfler 2-3h, incorporer au vin lors d''un remontage.',
   'plage', 20, 80, 'g/hL de vin', '15-20°C', '4-7 jours de contact, puis soutirage', false, 0);

  -- ------------------------------------------------------------
  -- Céramique filtrante
  -- ------------------------------------------------------------
  v_material_id := 'b3edaa2d-139f-4bb0-a24f-e8bf73c57376'::uuid;

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
    'Silicate d''aluminium et autres oxydes métalliques frittés (mélange Al₂O₃, SiO₂, MgO, Fe₂O₃)',
    'Billes céramiques, médias filtrants céramiques, céramique poreuse',
    'Technique',
    'Billes ou granulés blancs/gris, poreux, durs',
    'Neutre (inerte)',
    'Insoluble dans l''eau. Résiste aux acides et bases doux.',
    2.00, null,
    'Très résistant mécaniquement, longue durée de vie. Filtration en profondeur. Peut être régénéré par calcination.',
    'Par rapport au sable de quartz, les billes céramiques ont une surface spécifique plus élevée et une meilleure rétention des particules. Contrairement à la diatomite, elles sont réutilisables.',
    'Faible',
    array['lunettes'],
    'Lunettes de protection lors de la manipulation en vrac pour éviter les projections.',
    'Yeux : rincer. Inhalation de poussière : air frais.',
    'Acide fluorhydrique (attaque lente).',
    'Sacs ou fûts, au sec, sans précaution particulière.',
    -20, 50, false, false, 240, 'a_valider'
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
  (v_academie_id, 'Support filtrant pour eau potable et filtration industrielle',
   'Remplir le filtre avec les billes céramiques, faire circuler l''eau à traiter. Contre-laver régulièrement.',
   'texte_libre', null, null, 'Volume suffisant pour remplir le filtre', '5-40°C', 'Continu (périodes de quelques mois entre nettoyages)', false, 0);

  -- ------------------------------------------------------------
  -- Charbon actif (vrac)
  -- ------------------------------------------------------------
  v_material_id := 'b7a99c41-72e1-4da5-b97d-2f6322a1bc4f'::uuid;

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
    'Carbone amorphe activé (C)',
    'Charbon activé, carbone actif, charbon absorbant',
    'Technique',
    'Poudre noire ou granulés, inodore',
    '6-8 (neutre à légèrement basique)',
    'Insoluble dans l''eau et les solvants',
    0.45, null,
    'Très grande surface spécifique (500-1500 m²/g). Adsorbe de nombreux composés organiques, le chlore, les odeurs et les couleurs.',
    'Contrairement au graphite, il est amorphe et très poreux, donc absorbant. Par rapport au charbon actif œnologique, il peut contenir plus d''impuretés et n''est pas garanti sans goût résiduel.',
    'Faible',
    array['masque','lunettes'],
    'Porter un masque anti-poussière et des lunettes pour éviter l''inhalation de poudre noire.',
    'Inhalation : air frais. Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Oxydants forts (risque d''incendie), chlore gazeux (peut former des composés toxiques).',
    'Récipient étanche, au sec, à l''écart des matières combustibles et oxydantes.',
    5, 40, true, false, 60, 'a_valider'
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
  (v_academie_id, 'Filtration et purification de l''eau et de l''air',
   'Placer le charbon dans une cartouche filtrante ou en lit fixe, faire passer le fluide à traiter.',
   'texte_libre', null, null, 'Selon le volume à traiter', 'Ambiante', 'Jusqu''à saturation du charbon', false, 0),
  (v_academie_id, 'Absorbant d''odeurs et de couleurs en distillerie artisanale',
   'Agiter 10-50 g/L de charbon dans le distillat, laisser reposer, filtrer.',
   'plage', 10, 50, 'g/L de distillat', '15-25°C', '24-48 h', false, 1);

  -- ------------------------------------------------------------
  -- Charbon actif œnologique (décoloration)
  -- ------------------------------------------------------------
  v_material_id := 'dd0fd105-1cd0-4382-a448-01ca072898ee'::uuid;

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
    'Carbone amorphe activé hautement purifié (C)',
    'Charbon de décoloration œnologique, carbone œnologique',
    'Alimentaire',
    'Poudre noire très fine, inodore et sans goût résiduel',
    '6-7 (suspension neutre)',
    'Insoluble',
    0.40, null,
    'Purifié pour ne pas relarguer de substances indésirables ni de goût. Adsorbe sélectivement les polyphénols oxydés, les colorants bruns et les odeurs. Utilisé en vinification.',
    'Par rapport au charbon actif technique, il est plus fin, plus pur et sans goût. Contrairement au PVPP, il adsorbe une plus large gamme de composés mais peut aussi réduire les arômes.',
    'Faible',
    array['masque','lunettes'],
    'Porter un masque anti-poussière et des lunettes, la poudre étant très volatile et tachante.',
    'Inhalation : air frais. Yeux : rincer. Peau : laver à l''eau et au savon.',
    'Oxydants forts, produits chlorés.',
    'Récipient étanche, au sec, à l''écart des odeurs et des produits oxydants.',
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Décoloration des moûts blancs et des vins oxydés',
   'Disperser 10-100 g/hL dans le moût ou le vin, agiter, laisser en contact 2-3 jours, filtrer ou soutirer.',
   'plage', 10, 100, 'g/hL de vin', '15-20°C', '2-3 jours de contact', false, 0);

  -- ------------------------------------------------------------
  -- Diatomite / Kieselguhr (filtration)
  -- ------------------------------------------------------------
  v_material_id := 'c20e45b2-79ce-431c-8e40-9da2ee3d3cbc'::uuid;

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
    'Silice amorphe hydratée, frustules de diatomées fossilisées (SiO₂ 85-95%, Al₂O₃, Fe₂O₃)',
    'Kieselguhr, terre de diatomées, célite',
    'Technique',
    'Poudre blanche à beige, très fine, abrasive',
    '6-8 (neutre)',
    'Insoluble dans l''eau, chimiquement inerte',
    0.35, null,
    'Structure poreuse très élevée, excellent adjuvant de filtration. La version calcinée est plus blanche et plus perméable. Peut contenir de la silice cristalline libre : classée H350i (peut provoquer le cancer par inhalation) — manipuler exclusivement avec un masque FFP2 et une ventilation adéquate.',
    'Par rapport à la perlite, la diatomite a une plus grande surface spécifique et un pouvoir filtrant plus fin, mais elle est moins légère et peut contenir des traces de silice cristalline, contrairement à la perlite qui n''en contient pas après expansion.',
    'Modéré',
    array['masque','lunettes','ventilation'],
    'Porter un masque anti-poussière FFP2 pour éviter l''inhalation de silice, lunettes et ventilation.',
    'Inhalation : air frais, consulter. Peau : laver. Yeux : rincer 15 min. Ingestion : rincer la bouche, boire de l''eau.',
    'Acide fluorhydrique.',
    'Récipient étanche, au sec, à l''abri de l''humidité et de l''abrasion.',
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

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319', 'H335', 'H350i')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P201', 'P261', 'P280', 'P305+P351+P338', 'P308+P313')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Adjuvant de filtration en œnologie, brasserie et agroalimentaire',
   'Mettre en place une précouche de diatomite sur le filtre, puis ajouter en continu dans le liquide (alluvionnage) à raison de 0,5-1,5 g/L.',
   'plage', 0.5, 1.5, 'g/L de liquide à filtrer', '0-20°C', 'Pendant la filtration', false, 0);

  -- ------------------------------------------------------------
  -- Sel alimentaire raffiné
  -- ------------------------------------------------------------
  v_material_id := '6ae2b0bc-4799-4f44-9d1f-b655ca2cdc81'::uuid;

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
    'Chlorure de sodium (NaCl)',
    'Sel de table, sel fin, sel raffiné',
    'Alimentaire',
    'Cristaux blancs, fins, inodores',
    '7 (solution neutre)',
    'Très soluble (36 g/100 mL à 20°C)',
    1.20, null,
    'Purifié et séché, souvent additionné d''anti-agglomérant (E535 ou E551). Goût salé pur.',
    'Par rapport au sel brut (gemme ou marin), il est plus fin, plus blanc et ne contient pas d''impuretés. Moins hygroscopique que le chlorure de calcium.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. En milieu industriel, éviter le contact prolongé avec la peau (desséchant).',
    'Yeux : rincer. Peau : laver. Ingestion en grande quantité : boire de l''eau.',
    'Acides forts (dégagement de HCl gazeux), sels d''argent (précipité).',
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
  (v_academie_id, 'Assaisonnement et conservation alimentaire',
   'Utiliser selon le goût ou la recette. Pour les saumures, dissoudre 10-30 g/L d''eau.',
   'texte_libre', null, null, 'Quantité suffisante', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Sel de table / Chlorure de sodium alimentaire (NaCl)
  -- ------------------------------------------------------------
  v_material_id := '4fb974d5-235c-42e4-960c-eff8c5802ec6'::uuid;

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
    'Chlorure de sodium avec anti-agglomérant (NaCl)',
    'Sel fin, sel de table, sel de cuisine, sel raffiné',
    'Alimentaire',
    'Cristaux blancs très fins, fluides, inodores',
    '7 (neutre)',
    'Très soluble (36 g/100 mL à 20°C)',
    1.20, null,
    'Additionné d''anti-agglomérant (ferrocyanure de sodium E535 ou silice colloïdale E551) pour assurer une bonne fluidité, même en milieu humide.',
    'Similaire au sel raffiné pur, mais il contient volontairement un anti-mottant. À ne pas utiliser pour les saumures de longue conservation (l''anti-agglomérant peut troubler).',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Acides forts, nitrates d''argent, oxydants forts.',
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
  (v_academie_id, 'Usage domestique et boulangerie',
   'Ajouter à la pâte à pain (1,8-2% du poids de farine) ou comme sel de table.',
   'valeur_unique', 2, null, '% du poids de farine', 'Ambiante', 'Pendant le pétrissage', false, 0);

  -- ------------------------------------------------------------
  -- Silice colloïdale / Dioxyde de silicium (E551)
  -- ------------------------------------------------------------
  v_material_id := '9ab77c5f-80d6-4110-8f80-9c3b22d445e5'::uuid;

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
    'Dioxyde de silicium amorphe (SiO₂)',
    'E551, silice pyrogénée, Aérosil, silice colloïdale anhydre',
    'Alimentaire',
    'Poudre blanche extrêmement légère et volatile',
    '3,5-4,5 (suspension aqueuse à 4%)',
    'Insoluble dans l''eau, forme des gels colloïdaux',
    0.05, null,
    'Agent anti-agglomérant, épaississant pour liquides non aqueux. Grande surface spécifique (200-400 m²/g).',
    'Contrairement au talc ou à la diatomite, elle ne provient pas de silice cristalline et est amorphe. Sa légèreté et sa pureté en font l''anti-agglomérant de choix pour les poudres alimentaires.',
    'Faible',
    array['masque'],
    'Porter un masque FFP2 pour éviter l''inhalation de cette poudre ultra-volatile.',
    'Inhalation : air frais. Yeux : rincer. Peau : laver.',
    'Acide fluorhydrique.',
    'Récipient étanche, au sec, à l''abri des courants d''air.',
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
  (v_academie_id, 'Anti-agglomérant pour épices, poudres alimentaires et sels',
   'Ajouter 0,5-1% en poids de silice, mélanger intimement à sec.',
   'plage', 0.5, 1, '% du poids de la poudre', 'Ambiante', 'Immédiat', false, 0),
  (v_academie_id, 'Épaississant de phase grasse en cosmétique',
   'Disperser 2-5% dans l''huile sous agitation rapide pour former un gel.',
   'plage', 2, 5, '% de la phase huileuse', 'Ambiante', '10 min d''agitation', false, 1);

  -- ------------------------------------------------------------
  -- Sulfate de sodium
  -- ------------------------------------------------------------
  v_material_id := '06f73d2b-b72a-4c67-91d2-3375ca3c1dae'::uuid;

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
    'Sulfate de sodium décahydraté ou anhydre selon grade (Na₂SO₄·10H₂O ou Na₂SO₄)',
    'Sel de Glauber, sulfate de soude, sulfate de sodium anhydre',
    'Technique',
    'Poudre cristalline blanche (anhydre) ou cristaux incolores (décahydraté), inodore',
    '6-7 (neutre)',
    'Très soluble dans l''eau chaude (anhydre : 42 g/100 mL à 100°C ; décahydraté : fond à 32°C dans son eau de cristallisation)',
    1.46, null,
    'Efflorescent à l''air sec (perd son eau). Utilisé comme charge inerte, régulateur de détergence et laxatif osmotique.',
    'Par rapport au chlorure de sodium, il n''est pas salé et n''augmente pas la corrosion. Moins hygroscopique que le carbonate de sodium.',
    'Faible',
    array[]::text[],
    'Aucun obligatoire. Éviter l''inhalation de poussières.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau (effet laxatif à haute dose).',
    'Acides forts (dégagement de SO₂ si chauffé).',
    'Récipient étanche, au sec, à l''abri de l''humidité (le décahydraté se déshydrate, l''anhydre s''hydrate).',
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Charge pour lessives en poudre',
   'Mélanger à sec 20-50% de sulfate de sodium avec les tensioactifs et autres ingrédients.',
   'plage', 20, 50, '% du poids de la lessive', 'Ambiante', 'Pendant le mélange', false, 0),
  (v_academie_id, 'Adjuvant textile (teinture)',
   'Ajouter 10-30 g/L au bain de teinture pour uniformiser la pénétration du colorant.',
   'plage', 10, 30, 'g/L de bain', '40-90°C', 'Pendant la teinture (30-60 min)', false, 1);
end $$;
