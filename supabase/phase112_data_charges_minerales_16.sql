-- ============================================================
-- AkoraHub - Patch Phase 112 : fiches Académie pour les 16 nouvelles
-- charges minérales ajoutées en phase 111 — contenu DeepSeek,
-- vérifié par l'utilisatrice.
--
-- Ne couvre pas encore les 9 produits déjà présents avant cette
-- campagne (Bentonite œnologique, Céramique filtrante, Charbon actif
-- (vrac), Charbon actif œnologique, Diatomite/Kieselguhr, Sel
-- alimentaire raffiné, Sel de table, Silice colloïdale, Sulfate de
-- sodium).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Dolomie
  -- ------------------------------------------------------------
  v_material_id := 'cf691369-38e0-4b5b-b9fe-cca6e9184995'::uuid;

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
    'Carbonate de calcium et magnésium (CaMg(CO₃)₂)',
    'Dolomie, dolomite, carbonate double de calcium et magnésium',
    'Technique',
    'Poudre blanche à grisâtre, fine, inodore',
    '9-10 (suspension aqueuse)',
    'Très faible solubilité dans l''eau (0,01 g/100 mL), soluble dans les acides avec effervescence',
    2.85, null,
    'Source naturelle de calcium et magnésium, utilisée comme charge minérale et amendement agricole. Réagit avec les acides en libérant du CO₂.',
    'Moins réactif que la chaux, plus riche en magnésium que le carbonate de calcium pur. Idéal pour ajuster le pH des sols sans apport excessif de calcium.',
    'Faible',
    array['masque','lunettes'],
    'Porter un masque anti-poussière et des lunettes de protection en cas de manipulation prolongée.',
    'Inhalation : air frais. Yeux : rincer à l''eau. Peau : laver. Ingestion : boire de l''eau.',
    'Acides (réaction effervescente), sels d''aluminium en milieu acide.',
    'Récipient étanche, au sec, à l''abri de l''humidité et des acides.',
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
  (v_academie_id, 'Amendement agricole et jardinage',
   'Épandre 100-300 g/m² sur le sol, incorporer par griffage. Corrige l''acidité et apporte du magnésium.',
   'plage', 100, 300, 'g/m²', 'Ambiante', 'Plusieurs semaines', false, 0),
  (v_academie_id, 'Charge minérale pour peintures et enduits',
   'Incorporer 10-30% en poids dans le liant sous agitation.',
   'plage', 10, 30, '% du poids total', 'Ambiante', 'Mélange immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Graphite
  -- ------------------------------------------------------------
  v_material_id := 'f0ade415-ceb5-486c-a929-d26cd1afc89b'::uuid;

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
    'Carbone minéral (C)',
    'Graphite naturel, plombagine',
    'Technique',
    'Poudre noire grasse au toucher, cristaux hexagonaux',
    'Neutre (insoluble)',
    'Insoluble dans l''eau et les solvants courants',
    2.25, null,
    'Lubrifiant solide, conducteur électrique, résistant aux hautes températures. La poussière peut être irritante pour les voies respiratoires.',
    'Contrairement au talc, le graphite est conducteur et lubrifiant même à sec. Il ne fond pas mais se sublime à très haute température. Ne pas confondre avec le charbon actif (absorbant).',
    'Faible',
    array['masque','lunettes'],
    'Porter un masque anti-poussière pour éviter l''inhalation de particules. Lunettes de protection recommandées.',
    'Inhalation : air frais. Yeux : rincer. Peau : laver à l''eau et au savon. Ingestion : boire de l''eau.',
    'Oxydants forts (fluor, trioxyde de chlore).',
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Lubrifiant sec pour serrures et mécanismes',
   'Appliquer une petite quantité de poudre sur les parties mobiles, faire fonctionner pour répartir.',
   'valeur_unique', 1, null, 'pincée', 'Ambiante', 'Immédiat', false, 0),
  (v_academie_id, 'Charge conductrice pour peintures antistatiques',
   'Disperser 5-15% de graphite en poids dans le liant, bien homogénéiser.',
   'plage', 5, 15, '% du poids total', 'Ambiante', 'Mélange', false, 1);

  -- ------------------------------------------------------------
  -- Gypse
  -- ------------------------------------------------------------
  v_material_id := '5d2631ed-6879-4555-a34e-b01f1f6e2574'::uuid;

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
    'Sulfate de calcium dihydraté (CaSO₄·2H₂O)',
    'Pierre à plâtre, sulfate de calcium, gypse',
    'Technique',
    'Poudre blanche à grisâtre, fine, inodore',
    '7 (suspension neutre)',
    'Faible solubilité (0,2 g/100 mL à 20°C)',
    2.32, null,
    'Se déshydrate partiellement à la chaleur (plâtre). Utilisé en œnologie pour réguler l''acidité et comme charge minérale.',
    'Par rapport à la dolomie, le gypse n''a pas d''effet alcalinisant notable. Il apporte du calcium sans modifier le pH. Utilisé en œnologie pour le plâtrage des vins.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière en cas de manipulation prolongée.',
    'Inhalation : air frais. Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Acides forts (dissolution lente).',
    'Récipient étanche, au sec, à l''abri de l''humidité.',
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
  (v_academie_id, 'Plâtrage des vins (œnologie)',
   'Dissoudre 1-2 g/L dans le moût ou le vin, remuer. Précipite les tartrates et réduit l''acidité.',
   'plage', 1, 2, 'g/L de moût/vin', '15-20°C', '24-48 h de sédimentation', false, 0),
  (v_academie_id, 'Charge pour plâtre et moulage',
   'Gâcher la poudre avec de l''eau (ratio 1:1 à 1:2) pour obtenir une pâte, couler dans un moule.',
   'texte_libre', null, null, 'quantité suffisante pour la pâte', 'Ambiante', 'Prise en 10-30 min', false, 1);

  -- ------------------------------------------------------------
  -- Illite (argile verte)
  -- ------------------------------------------------------------
  v_material_id := '396a4a36-b538-46ed-b9d6-5f270c32366e'::uuid;

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
    'Phyllosilicate d''aluminium, potassium, magnésium et fer ((K,H₃O)Al₂(Si,Al)₄O₁₀(OH)₂)',
    'Argile verte, illite, terre verte',
    'Cosmétique',
    'Poudre fine, vert pâle à vert foncé, odeur terreuse',
    '8-9 (pâte aqueuse)',
    'Insoluble dans l''eau, forme une pâte onctueuse',
    2.60, null,
    'Argile riche en minéraux, absorbante, purifiante. Utilisée dans les masques et savons pour peaux normales à grasses.',
    'Plus douce que la bentonite, moins absorbante que le kaolin. Sa couleur verte naturelle est appréciée en cosmétique.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. Éviter l''inhalation de poussières.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Aucune notable.',
    'Récipient étanche, au sec, à l''abri de l''humidité.',
    5, 30, true, false, 48, 'a_valider'
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
  (v_academie_id, 'Masque facial purifiant',
   'Mélanger 1 à 2 cuillères à soupe d''illite avec de l''eau ou un hydrolat jusqu''à obtenir une pâte, appliquer sur le visage, laisser sécher 5-10 min, rincer.',
   'valeur_unique', 15, null, 'g par masque', 'Ambiante', '5-10 min', false, 0),
  (v_academie_id, 'Colorant naturel en savonnerie',
   'Incorporer 1 à 5% d''illite en poudre dans la pâte à savon à la trace, mélanger pour obtenir une couleur verte.',
   'plage', 1, 5, '% du poids des huiles', '30-40°C (trace)', 'Pendant le mélange', false, 1);

  -- ------------------------------------------------------------
  -- Kaolin
  -- ------------------------------------------------------------
  v_material_id := '4e11560a-2f95-47fb-9c61-8943462fe944'::uuid;

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
    'Silicate d''aluminium hydraté (Al₂Si₂O₅(OH)₄)',
    'Argile blanche, kaolinite, terre à porcelaine',
    'Cosmétique',
    'Poudre très fine, blanche, douce au toucher, inodore',
    '4-6 (pâte aqueuse)',
    'Insoluble dans l''eau, se disperse facilement',
    2.60, null,
    'Argile non gonflante, très douce, absorbante. Idéale pour les peaux sensibles et les poudres libres.',
    'Contrairement à la bentonite, le kaolin n''est pas gonflant et a un pouvoir absorbant supérieur mais un pouvoir épaississant très faible. Plus doux que l''illite.',
    'Aucun',
    array['masque'],
    'Porter un masque anti-poussière lors de la manipulation de grands volumes.',
    'Inhalation : air frais. Yeux : rincer. Peau : laver.',
    'Aucune notable.',
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
  (v_academie_id, 'Poudre libre matifiante (cosmétique)',
   'Appliquer le kaolin pur au pinceau sur le visage pour absorber l''excès de sébum.',
   'valeur_unique', 100, null, '% (pur)', 'Ambiante', 'Immédiat', false, 0),
  (v_academie_id, 'Charge pour céramique et porcelaine',
   'Mélanger 20-50% de kaolin avec du feldspath et du quartz, humidifier, façonner et cuire à haute température.',
   'plage', 20, 50, '% de la pâte céramique', '1000-1300°C (cuisson)', 'Variable selon la cuisson', false, 1);

  -- ------------------------------------------------------------
  -- Mica
  -- ------------------------------------------------------------
  v_material_id := 'fa477095-a2a0-46e9-975f-f2f51ef67fd2'::uuid;

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
    'Silicate d''aluminium et de potassium (KAl₂(AlSi₃O₁₀)(OH)₂)',
    'Muscovite, mica blanc, paillettes minérales',
    'Cosmétique',
    'Paillettes fines ou poudre nacrée, blanc à grisâtre, reflet brillant',
    'Neutre (insoluble)',
    'Insoluble dans l''eau, se disperse facilement',
    2.80, null,
    'Minéral naturel à structure lamellaire, apporte brillance et toucher soyeux. Utilisé comme pigment nacré et charge dans les cosmétiques.',
    'Contrairement au talc, le mica a des propriétés optiques (éclat) et est moins absorbant. Il est souvent enrobé de pigments pour créer des nacres.',
    'Aucun',
    array['masque'],
    'Porter un masque anti-poussière pour éviter l''inhalation de paillettes.',
    'Inhalation : air frais. Yeux : rincer. Peau : laver.',
    'Acides fluorhydriques (attaque des silicates).',
    'Récipient étanche, au sec, à l''abri de l''humidité et des chocs.',
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
  (v_academie_id, 'Pigment nacré pour cosmétiques (fards, poudres, vernis)',
   'Incorporer 5 à 30% de mica dans la poudre ou la base pour apporter de la brillance.',
   'plage', 5, 30, '% du produit fini', 'Ambiante', 'Mélange', false, 0),
  (v_academie_id, 'Charge pour peintures et revêtements décoratifs',
   'Ajouter 5-15% de mica dans la peinture pour un effet nacré.',
   'plage', 5, 15, '% du volume de peinture', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Oxyde de magnésium
  -- ------------------------------------------------------------
  v_material_id := 'aa531c97-9201-4117-a402-f9a3b1f028cf'::uuid;

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
    'Oxyde de magnésium (MgO)',
    'Magnésie, magnésie calcinée, périclase',
    'Technique',
    'Poudre blanche fine, inodore',
    '10-11 (suspension aqueuse)',
    'Très faible solubilité (0,008 g/100 mL), réagit avec l''eau pour former Mg(OH)₂',
    3.58, null,
    'Réfractaire, point de fusion très élevé (2800°C). Utilisé comme anti-acide, isolant thermique et charge ignifugeante. Réagit avec l''eau lentement.',
    'Contrairement au carbonate de magnésium, l''oxyde de magnésium est plus alcalin et plus résistant à la chaleur. Il est moins utilisé en cosmétique mais présent dans des poudres libres.',
    'Faible',
    array['masque','lunettes'],
    'Porter un masque anti-poussière et des lunettes de protection. Éviter le contact prolongé avec la peau (alcalin).',
    'Inhalation : air frais. Peau : rincer abondamment. Yeux : rincer 15 min. Ingestion : boire de l''eau, ne pas faire vomir.',
    'Acides (réaction exothermique), eau (prise en masse lente).',
    'Récipient étanche, au sec, à l''abri de l''humidité et des acides.',
    5, 35, true, false, 24, 'a_valider'
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
  (v_academie_id, 'Charge ignifugeante pour câbles et plastiques',
   'Incorporer 10-40% d''oxyde de magnésium dans le polymère lors de la formulation.',
   'plage', 10, 40, '% du poids du polymère', '150-200°C (mise en œuvre)', 'Pendant l''extrusion', false, 0),
  (v_academie_id, 'Anti-acide gastrique (usage pharmaceutique)',
   'Prendre 0,5 à 1 g par prise, pas plus de 4 prises par jour, avec de l''eau.',
   'valeur_unique', 1, null, 'g', 'Ambiante', 'Immédiat', true, 1);

  -- ------------------------------------------------------------
  -- Oxyde de zinc
  -- ------------------------------------------------------------
  v_material_id := '251add8a-f3ba-4e47-aed3-f98eff70ab23'::uuid;

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
    'Oxyde de zinc (ZnO)',
    'Blanc de zinc, zincite, ZnO',
    'Cosmétique',
    'Poudre blanche très fine, inodore',
    '7-8 (suspension neutre à légèrement basique)',
    'Insoluble dans l''eau (0,0004 g/100 mL), soluble dans les acides et les bases',
    5.61, null,
    'Écran minéral UV (UVA/UVB). Peut provoquer la fièvre des fondeurs en cas d''inhalation de fumées lors de soudage ou chauffage à très haute température. L''usage cosmétique (poudre, crème) ne présente pas ce risque.',
    'Par rapport au dioxyde de titane, il couvre une plus large partie du spectre UVA. Moins couvrant que le talc, il est surtout utilisé pour ses propriétés anti-UV et apaisantes.',
    'Modéré',
    array['masque','lunettes'],
    'Porter un masque anti-poussière pour éviter l''inhalation de poudre fine. Éviter de respirer les fumées dégagées lors de chauffage à plus de 900°C (soudure, métallurgie) en raison du risque de fièvre des fondeurs.',
    'Inhalation : air frais, consulter si symptômes de fièvre (frissons, toux). Peau : laver. Yeux : rincer 15 min. Ingestion : boire de l''eau, consulter un médecin si grande quantité.',
    'Acides forts, bases fortes. Éviter le contact avec le chlorure de magnésium en milieu aqueux (formation d''oxychlorure).',
    'Récipient étanche, au sec, à l''abri des acides et bases.',
    5, 35, false, false, 48, 'a_valider'
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
  (v_academie_id, 'Écran solaire minéral (cosmétique)',
   'Disperser 5 à 20% d''oxyde de zinc dans la phase grasse ou sous forme de poudre micronisée dans une crème. Appliquer généreusement sur la peau.',
   'plage', 5, 20, '% du produit fini', 'Ambiante', 'Immédiat', false, 0),
  (v_academie_id, 'Poudre matifiante et apaisante (soins bébé, peaux irritées)',
   'Appliquer une fine couche de poudre pure sur les zones irritées ou humides.',
   'valeur_unique', 100, null, '% (pur)', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Perlite expansée
  -- ------------------------------------------------------------
  v_material_id := 'f06ec181-5122-423c-9e20-bc2dfd00f9bd'::uuid;

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
    'Silicate d''aluminium et de sodium amorphe expansé (mélange amorphe, ~70-75% SiO₂)',
    'Perlite, perlite expansée, agro-perlite',
    'Technique',
    'Granulés blancs, très légers, poreux, inodores',
    '6,5-7,5 (neutre)',
    'Insoluble dans l''eau. Chimiquement inerte.',
    0.10, null,
    'Densité apparente extrêmement faible (0,08-0,15). Excellent pouvoir absorbant et isolant. Inerte et stérile. La perlite brute (non expansée) a une densité de 2,2-2,4 ; c''est le chauffage à 800-1100°C qui provoque l''expansion.',
    'Par rapport à la vermiculite, la perlite est moins absorbante et moins alcaline. Elle retient moins l''eau mais assure un meilleur drainage. Plus légère que le sable de quartz.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour éviter l''inhalation de fines particules irritantes.',
    'Inhalation : air frais. Yeux : rincer à l''eau. Peau : laver.',
    'Acide fluorhydrique (attaque lente du verre).',
    'Sacs étanches ou silos, au sec, à l''abri du vent (produit très léger).',
    5, 50, true, false, 120, 'a_valider'
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
  (v_academie_id, 'Adjuvant de filtration (œnologie, agroalimentaire)',
   'Déposer une pré-couche de perlite sur le filtre, puis ajouter en continu dans le liquide à filtrer (alluvionnage).',
   'plage', 0.5, 2, 'g/L de liquide à filtrer', '0-20°C (vin)', 'Pendant la filtration', false, 0),
  (v_academie_id, 'Support de culture et drainage (horticulture)',
   'Mélanger 30-50% de perlite avec du terreau ou de la terre pour alléger le substrat.',
   'plage', 30, 50, '% du volume du substrat', 'Ambiante', 'Permanent', false, 1);

  -- ------------------------------------------------------------
  -- Phosphate tricalcique
  -- ------------------------------------------------------------
  v_material_id := '17ae04e2-817c-4c52-b433-88290784f748'::uuid;

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
    'Orthophosphate de calcium tribasique (Ca₃(PO₄)₂)',
    'TCP, phosphate de calcium, E341(iii)',
    'Alimentaire',
    'Poudre blanche très fine, inodore',
    '7-8 (suspension)',
    'Pratiquement insoluble dans l''eau (0,002 g/100 mL), soluble dans les acides dilués',
    3.14, null,
    'Agent anti-agglomérant (E341) et source de calcium. Abrasif très doux utilisé dans les dentifrices. Bonne affinité avec la peau.',
    'Moins alcalin que le carbonate de calcium, plus doux comme abrasif. Il n''a pas les propriétés UV de l''oxyde de zinc, mais il est moins coûteux comme charge blanche.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière lors de la manipulation de grandes quantités.',
    'Inhalation : air frais. Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Acides forts (dissolution avec effervescence).',
    'Récipient étanche, au sec, à l''écart des acides.',
    5, 35, false, false, 36, 'a_valider'
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
  (v_academie_id, 'Abrasif doux en dentifrice',
   'Incorporer 10 à 30% de TCP dans la pâte dentifrice.',
   'plage', 10, 30, '% du produit fini', 'Ambiante', 'Pendant le brossage', false, 0),
  (v_academie_id, 'Anti-agglomérant en alimentation animale et humaine',
   'Ajouter 0,5 à 2% en poids dans la poudre à fluidifier.',
   'plage', 0.5, 2, '% du poids total', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Pierre ponce
  -- ------------------------------------------------------------
  v_material_id := '72afbbbd-858e-4631-8e8c-1f385da8943e'::uuid;

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
    'Silicate d''aluminium et de potassium vitreux (mélange vitreux SiO₂, Al₂O₃, K₂O, Na₂O)',
    'Ponce, poudre de pierre ponce, pumice',
    'Cosmétique',
    'Poudre grise à blanche, granuleuse, abrasive au toucher',
    'Neutre (insoluble)',
    'Insoluble dans l''eau. Très dure (6 sur l''échelle de Mohs).',
    0.80, null,
    'Verre volcanique expansé, très dur, utilisé pour ses propriétés abrasives et exfoliantes. Neutre chimiquement.',
    'Contrairement au talc ou au kaolin, elle ne glisse pas et est très abrasive. Par rapport au sable de quartz, elle est plus légère et moins coupante, mais tout aussi efficace pour le ponçage.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour éviter l''inhalation de poudre siliceuse.',
    'Inhalation : air frais. Yeux : rincer à l''eau. Peau : laver.',
    'Aucune notable.',
    'Récipient étanche, au sec, à l''abri de l''humidité.',
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
  (v_academie_id, 'Exfoliant mécanique en cosmétique (savons, gommages)',
   'Incorporer 2 à 5% de poudre fine dans un savon ou un gel douche, mélanger avant usage.',
   'plage', 2, 5, '% du produit fini', 'Ambiante', 'Pendant le massage', false, 0),
  (v_academie_id, 'Poudre à récurer et polir (entretien ménager)',
   'Saupoudrer la pierre ponce sur une éponge humide, frotter la surface, rincer.',
   'texte_libre', null, null, 'Quantité suffisante', 'Ambiante', 'Quelques minutes', false, 1);

  -- ------------------------------------------------------------
  -- Rhassoul (argile marocaine, ghassoul)
  -- ------------------------------------------------------------
  v_material_id := '4deb0389-7d91-4f59-86db-bbeefd77817c'::uuid;

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
    'Silicate de magnésium et d''aluminium hydraté naturel (mélange de smectites, illite et kaolinite)',
    'Argile marocaine, ghassoul, terre à foulon',
    'Cosmétique',
    'Poudre fine, beige à brun clair, toucher très doux et savonneux',
    '7-8 (pâte aqueuse)',
    'Insoluble, gonfle légèrement dans l''eau pour former une pâte onctueuse',
    2.00, null,
    'Argile marocaine naturelle, très douce, à haut pouvoir absorbant et nettoyant sans détergent. Riche en minéraux, elle laisse la peau douce.',
    'Contrairement à la bentonite, le rhassoul ne gonfle pas excessivement et sa texture est plus crémeuse. Il est moins agressif que l''illite tout en ayant un pouvoir lavant (dégraissant) naturel très apprécié.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. Éviter l''inhalation de poussières.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Aucune notable.',
    'Récipient étanche, au sec, à l''abri de l''humidité.',
    5, 30, true, false, 48, 'a_valider'
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
  (v_academie_id, 'Masque capillaire et soin du visage (cosmétique)',
   'Mélanger 1 à 2 cuillères à soupe de rhassoul avec de l''eau ou un hydrolat pour former une pâte. Appliquer sur les cheveux ou le visage, laisser poser 5-10 min, rincer.',
   'valeur_unique', 15, null, 'g par application', 'Ambiante', '5-10 min', false, 0),
  (v_academie_id, 'Savonnerie (ajout dans la pâte à savon)',
   'Incorporer 1 à 5% de rhassoul en poudre à la trace dans la pâte à savon pour un effet doux et gommant.',
   'plage', 1, 5, '% du poids des huiles', '30-40°C (trace)', 'Pendant le mélange', false, 1);

  -- ------------------------------------------------------------
  -- Sulfate de baryum naturel (barytine)
  -- ------------------------------------------------------------
  v_material_id := '3d9de16e-c8fe-4ffc-822e-1083eae99c74'::uuid;

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
    'Sulfate de baryum (BaSO₄)',
    'Barytine, baryte, blanc fixe, sulfate de baryum',
    'Technique',
    'Poudre blanche très lourde, fine, inodore',
    'Neutre (insoluble)',
    'Pratiquement insoluble dans l''eau (0,0002 g/100 mL) et les acides',
    4.50, null,
    'Densité exceptionnellement élevée pour une poudre minérale. Très inerte chimiquement. Utilisé comme charge lourde pour augmenter la densité des boues de forage et des plastiques.',
    'Par rapport au carbonate de calcium, il est beaucoup plus lourd, plus inerte (résiste aux acides) et plus opaque aux rayons X. Attention : le produit pur (sulfate) est très peu toxique du fait de son insolubilité, mais les sels de baryum solubles sont, eux, toxiques — ne pas confondre.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour éviter l''inhalation de poudre lourde. Ne pas ingérer.',
    'Inhalation : air frais. Yeux : rincer. Peau : laver. Ingestion : rincer la bouche, boire de l''eau, appeler un médecin si symptômes.',
    'Aucune (très inerte).',
    'Récipient étanche, au sec. Produit lourd, prévoir des contenants solides.',
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
  (v_academie_id, 'Charge lourde pour peintures et résines',
   'Ajouter 10 à 40% de barytine sous agitation lente pour alourdir et donner du corps.',
   'plage', 10, 40, '% du poids du liant', 'Ambiante', 'Mélange', false, 0),
  (v_academie_id, 'Alourdissant pour boues de forage',
   'Incorporer la barytine dans l''eau ou la boue pour atteindre la densité désirée (jusqu''à 2,5 kg/L).',
   'plage', 10, 50, '% du volume de la boue', 'Ambiante à 150°C', 'Pendant la circulation', false, 1);

  -- ------------------------------------------------------------
  -- Talc
  -- ------------------------------------------------------------
  v_material_id := 'cf2e34f8-764e-42aa-8bda-fa668a37f6ff'::uuid;

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
    'Silicate de magnésium hydraté (Mg₃Si₄O₁₀(OH)₂)',
    'Talc, pierre à savon, stéatite',
    'Cosmétique',
    'Poudre blanche très fine, douce et onctueuse au toucher',
    '8-9 (suspension)',
    'Insoluble dans l''eau. Très hydrophobe.',
    2.70, null,
    'Le minéral le plus tendre (dureté 1 sur l''échelle de Mohs). Excellent pouvoir glissant, absorbant et matifiant. Inerte. À utiliser avec précaution en inhalation (risque de talcose en cas d''exposition professionnelle massive au talc non contrôlé).',
    'Contrairement au kaolin, il est plus doux, plus glissant et moins absorbant. Par rapport au mica, il n''est pas brillant et apporte un toucher mat et poudré.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour les manipulations de longue durée ou de grands volumes.',
    'Inhalation : air frais. Yeux : rincer. Peau : laver. Ingestion : boire de l''eau (faible toxicité aiguë).',
    'Aucune notable.',
    'Récipient étanche, au sec, à l''abri de l''humidité.',
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
  (v_academie_id, 'Poudre pour le corps et maquillage (cosmétique)',
   'Appliquer le talc pur ou parfumé sur la peau pour absorber l''humidité et parfumer.',
   'valeur_unique', 100, null, '% (pur)', 'Ambiante', 'Immédiat', false, 0),
  (v_academie_id, 'Lubrifiant solide pour chambres à air et câbles',
   'Saupoudrer du talc sur les surfaces en caoutchouc pour faciliter le montage.',
   'texte_libre', null, null, 'Quantité suffisante', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Vermiculite expansée
  -- ------------------------------------------------------------
  v_material_id := 'c6e876d4-9ece-4a23-89b6-578a9d9f86bc'::uuid;

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
    'Silicate de magnésium, fer et aluminium hydraté expansé ((Mg,Fe²⁺,Fe³⁺)₃[(Si,Al)₄O₁₀](OH)₂·4H₂O)',
    'Vermiculite, vermiculite exfoliée',
    'Technique',
    'Granulés bruns dorés en accordéon, très légers, inodores',
    '7-8 (neutre à légèrement alcalin)',
    'Insoluble dans l''eau. Très absorbante (jusqu''à 3-4 fois son poids en eau).',
    0.10, null,
    'Densité apparente très basse (0,07-0,15). Grande capacité de rétention d''eau et d''échange cationique. Isolant thermique et phonique.',
    'Par rapport à la perlite, la vermiculite retient beaucoup plus l''eau. Elle est plus alcaline et plus riche en magnésium. Utilisée pour l''isolation et l''horticulture.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour éviter l''inhalation de poussières.',
    'Inhalation : air frais. Yeux : rincer. Peau : laver.',
    'Aucune notable.',
    'Sacs ou silos, au sec, à l''abri de l''humidité (perte de ses propriétés isolantes si mouillée).',
    5, 40, true, false, 120, 'a_valider'
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
  (v_academie_id, 'Support de culture et rétention d''eau (horticulture)',
   'Mélanger 20-50% de vermiculite avec du terreau pour améliorer la rétention d''eau et l''aération.',
   'plage', 20, 50, '% du volume du substrat', 'Ambiante', 'Permanent', false, 0),
  (v_academie_id, 'Isolation thermique et phonique (construction)',
   'Verser ou souffler la vermiculite entre les solives ou dans les combles pour une épaisseur de 10-20 cm.',
   'texte_libre', null, null, 'Quantité suffisante pour l''épaisseur désirée', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Zéolithe naturelle (clinoptilolite)
  -- ------------------------------------------------------------
  v_material_id := '9e32eafc-3c98-4060-b339-3ea8b832ea60'::uuid;

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
    'Aluminosilicate de sodium, potassium et calcium hydraté, clinoptilolite ((Na,K,Ca)₂₋₃Al₃(Al,Si)₂Si₁₃O₃₆·12H₂O)',
    'Clinoptilolite, zéolithe, pierre à ammoniaque',
    'Technique',
    'Granulés ou poudre gris-vert à blanc cassé, inodore',
    '7-8 (suspension neutre)',
    'Insoluble dans l''eau. Structure microporeuse. Haute capacité d''échange cationique.',
    0.80, null,
    'Tamis moléculaire naturel, absorbe sélectivement l''ammoniac, certains métaux lourds et l''eau. Sert de support filtrant et de stabilisant en œnologie.',
    'Contrairement à la bentonite, la zéolithe adsorbe des molécules spécifiques (effet de tamis) et ne gonfle pas. Elle est plus efficace pour piéger l''azote ammoniacal.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour éviter l''inhalation de poudre fine.',
    'Inhalation : air frais. Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Acides forts (dégradation de la structure).',
    'Récipient étanche, au sec. Éviter de stocker près de produits volatils ammoniaqués (adsorption).',
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
  (v_academie_id, 'Stabilisation tartrique et adsorption en œnologie',
   'Disperser 50-80 g/hL de zéolithe dans le vin, laisser en contact quelques jours, soutirer.',
   'plage', 50, 80, 'g/hL de vin', '10-20°C', '2-4 jours de contact', false, 0),
  (v_academie_id, 'Support filtrant pour aquarium et bassin',
   'Placer la zéolithe dans un filet ou un filtre, remplacer tous les 1 à 2 mois.',
   'valeur_unique', 500, null, 'g pour 100 L d''eau', '15-25°C', 'Permanent (renouvellement périodique)', false, 1);
end $$;
