-- ============================================================
-- AkoraHub - Patch Phase 120 : fiches Académie pour le lot 3 (9
-- huiles actives et alimentaires) des nouveaux produits "Huiles &
-- Beurres Cosmétiques" — contenu DeepSeek, vérifié par l'utilisatrice.
--
-- Lot 3/5 : Huile de bourrache, Huile d'onagre, Huile de rose
-- musquée, Huile de neem, Huile de germe de blé, Huile de coton,
-- Huile de soja, Huile de maïs, Huile d'arachide.
--
-- Huile de neem documentée avec niveau_danger 'Élevé' et phrases
-- H302/H315/H319 : usage cosmétique externe uniquement, toxique par
-- ingestion (intoxications graves documentées chez le nourrisson),
-- également utilisable comme biocide/insecticide naturel — inclusion
-- décidée par l'utilisatrice suivant la recommandation (voir phase117).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Huile de bourrache
  -- ------------------------------------------------------------
  v_material_id := '49768659-7741-4c33-af51-ddd6a073f2fd'::uuid;

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
    'Triglycérides d''acides gras polyinsaturés riches en acide gamma-linolénique (Borago officinalis)',
    'Borago Officinalis Seed Oil, Borage Oil, huile de bourrache',
    'Cosmétique, Alimentaire (complément)',
    'Liquide jaune doré à jaune-vert, odeur légèrement herbacée',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.92, 220.0,
    'Composition : 35-40 % acide linoléique, 15-20 % acide gamma-linolénique (GLA, oméga-6 rare), 15-20 % acide oléique. Indice de saponification 185-195. Très riche en GLA aux propriétés anti-inflammatoires, régénérantes et apaisantes cutanées. Très sensible à l''oxydation.',
    'Par rapport à l''huile d''onagre, elle est 2 à 3 fois plus riche en GLA et donc plus active sur les peaux atopiques. Comparée à l''huile de chanvre, elle a une action plus ciblée anti-inflammatoire grâce au GLA. Huile de niche haut de gamme.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger en complément alimentaire (respecter les doses).',
    'Oxydants forts, chaleur, lumière (rancissement rapide).',
    'Récipient hermétique sous atmosphère inerte, impérativement au réfrigérateur après ouverture. Huile très fragile.',
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
  (v_academie_id, 'Sérum visage anti-inflammatoire peaux à problèmes (eczéma, acné)',
   'Appliquer 1 à 3 gouttes pures ou en mélange (2-5 %) sur les zones concernées. Ne pas chauffer.',
   'plage', 2, 5, '% de la formule', 'Ambiante', 'Immédiat', false, 0),
  (v_academie_id, 'Savon saponifié à froid (surgras apaisant)',
   'Ajouter 3 à 8 % à la trace comme surgras pour bénéficier du GLA intact.',
   'plage', 3, 8, '% du poids total (surgras)', 'Trace (30-35°C)', 'Ajout avant coulage', false, 1);

  -- ------------------------------------------------------------
  -- Huile d'onagre
  -- ------------------------------------------------------------
  v_material_id := 'cbf9e241-0a7d-46de-9856-d98e9bd33ecb'::uuid;

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
    'Triglycérides d''acides gras polyinsaturés riches en acide gamma-linolénique (Oenothera biennis)',
    'Oenothera Biennis Oil, Evening Primrose Oil, huile d''onagre, huile de primevère du soir',
    'Cosmétique, Alimentaire (complément)',
    'Liquide jaune à jaune-vert, odeur légèrement végétale',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.92, 220.0,
    'Composition : 65-75 % acide linoléique, 8-12 % acide gamma-linolénique (GLA), 5-10 % acide oléique. Indice de saponification 185-195. Riche en GLA, elle calme les inflammations cutanées, régule le cycle cellulaire, idéale pour peaux sèches et matures.',
    'Par rapport à l''huile de bourrache, elle contient moins de GLA mais reste une référence historique pour les soins de la peau. Elle est souvent plus disponible et moins chère que la bourrache.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger en complément alimentaire.',
    'Oxydants forts, chaleur, lumière.',
    'Récipient hermétique, au réfrigérateur après ouverture. Huile fragile.',
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
  (v_academie_id, 'Soin anti-âge et peaux matures',
   'Appliquer quelques gouttes pures ou en mélange (2-5 %) sur le visage et le cou. Pénètre bien.',
   'plage', 2, 5, '% de la formule', 'Ambiante', 'Immédiat', false, 0),
  (v_academie_id, 'Savon saponifié à froid (surgras réparateur)',
   'Ajouter 3 à 8 % à la trace pour un savon doux et apaisant.',
   'plage', 3, 8, '% du poids total (surgras)', 'Trace (30-35°C)', 'Ajout avant coulage', false, 1);

  -- ------------------------------------------------------------
  -- Huile de rose musquée
  -- ------------------------------------------------------------
  v_material_id := '7a803962-043c-415b-a5d8-2895df182c46'::uuid;

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
    'Triglycérides d''acides gras insaturés (Rosa rubiginosa / Rosa moschata)',
    'Rosa Canina Fruit Oil, Rosehip Oil, huile de rose musquée, huile d''églantier',
    'Cosmétique',
    'Liquide jaune-orangé à rouge-orangé, odeur légèrement terreuse et caractéristique',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.92, 220.0,
    'Composition : 40-50 % acide linoléique, 20-30 % acide alpha-linolénique (oméga-3), 10-15 % acide oléique, riche en acide trans-rétinoïque naturel (pro-vitamine A). Indice de saponification 185-193. Action régénérante, anti-taches, cicatrisante, anti-âge reconnue.',
    'Par rapport à l''huile d''onagre, elle contient de la pro-vitamine A naturelle unique qui lui donne son pouvoir anti-taches. Plus stable que l''huile de chanvre mais moins que l''huile de jojoba. Huile signature des soins anti-âge.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Usage externe uniquement.',
    'Oxydants forts, chaleur, lumière.',
    'Récipient hermétique opaque, au frais, à l''abri de la lumière. Conserver idéalement au réfrigérateur après ouverture.',
    5, 20, false, true, 9, 'a_valider'
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
  (v_academie_id, 'Sérum anti-taches, cicatrices et vergetures',
   'Appliquer 1 à 3 gouttes pures ou en mélange (2-5 %) localement sur les taches ou cicatrices. Usage quotidien.',
   'plage', 2, 5, '% de la formule', 'Ambiante', 'Plusieurs semaines pour des résultats visibles', false, 0),
  (v_academie_id, 'Savon saponifié à froid (surgras régénérant)',
   'Ajouter 3 à 10 % à la trace comme surgras pour un savon traitant anti-âge.',
   'plage', 3, 10, '% du poids total (surgras)', 'Trace (30-35°C)', 'Ajout avant coulage', false, 1);

  -- ------------------------------------------------------------
  -- Huile de neem
  -- ------------------------------------------------------------
  v_material_id := '4d861be1-67be-475b-91be-30bbfdef7f47'::uuid;

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
    'Triglycérides d''acides gras saturés et insaturés avec limonoïdes (Azadirachta indica)',
    'Azadirachta Indica Seed Oil, Neem Oil, huile de neem, margousier',
    'Cosmétique, Technique (biocide)',
    'Liquide épais, brun-vert foncé, odeur très forte, soufrée et amère',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.92, 200.0,
    'Composition : 40-50 % acide oléique, 15-20 % acide linoléique, 15-20 % acide palmitique, riche en azadirachtine, nimbine, nimbidine (limonoïdes actifs). Indice de saponification 175-195. Insecticide naturel, antifongique puissant. Usage exclusivement externe (cosmétique). Toxique par ingestion : cas graves d''hypoglycémie, d''encéphalopathie, coma chez l''enfant et le nourrisson. Interdit en usage alimentaire. Tenir hors de portée des enfants. Ne JAMAIS administrer par voie orale.',
    'Contrairement à toutes les autres huiles du catalogue, elle est insecticide et biocide. Elle n''est pas un soin quotidien mais un traitement ciblé. Son odeur très forte et sa toxicité digestive la réservent à des usages très spécifiques.',
    'Élevé',
    array['gants','lunettes','ventilation'],
    'Porter des gants et des lunettes pour éviter le contact cutané prolongé. Utiliser dans un espace ventilé en raison de l''odeur forte. Éviter l''inhalation de vapeurs lors du chauffage. Ne pas ingérer. Toxique par ingestion.',
    'Yeux : rincer 15 min, consulter si irritation. Peau : laver au savon, retirer les vêtements contaminés. Ingestion : rincer la bouche, ne pas faire vomir, appeler immédiatement un centre antipoison ou un médecin. Risque vital chez l''enfant.',
    'Oxydants forts.',
    'Récipient hermétique, à l''écart des aliments, hors de portée des enfants, dans un placard fermé à clé si nécessaire. Étiqueter clairement "Toxique — Ne pas avaler".',
    10, 30, false, true, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H315', 'H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P270', 'P280', 'P301+P312', 'P305+P351+P338', 'P337+P313')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Soin capillaire antipelliculaire et anti-poux',
   'Ajouter 5-10 % d''huile de neem dans une huile de support (coco, ricin). Appliquer sur le cuir chevelu, laisser poser 1-2 h, puis laver au shampoing. Ne pas avaler.',
   'plage', 5, 10, '% du mélange d''huiles', 'Ambiante', '1 à 2 heures de pose', false, 0),
  (v_academie_id, 'Savon insectifuge et antifongique',
   'Ajouter 5 à 15 % dans la formule de savon saponifié à froid. Complémentaire avec d''autres huiles pour masquer l''odeur. Étiqueter clairement.',
   'plage', 5, 15, '% du poids des huiles', '35-45°C', 'Trace en 10-15 min', false, 1);

  -- ------------------------------------------------------------
  -- Huile de germe de blé
  -- ------------------------------------------------------------
  v_material_id := '92ad627d-d837-48bd-a324-63697ab5a230'::uuid;

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
    'Triglycérides d''acides gras essentiels (Triticum vulgare)',
    'Triticum Vulgare Germ Oil, Wheat Germ Oil, huile de germe de blé',
    'Cosmétique, Alimentaire',
    'Liquide épais, jaune-orangé à brun clair, odeur céréalière prononcée',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.93, 230.0,
    'Composition : 45-60 % acide linoléique, 12-20 % acide oléique, 10-15 % acide palmitique. Exceptionnellement riche en vitamine E naturelle (tocophérols : 150-250 mg/100g), phytostérols. Indice de saponification 180-190. Antioxydant naturel puissant, utilisé comme conservateur antioxydant dans les mélanges d''huiles.',
    'Par rapport à toutes les autres huiles végétales, c''est la plus riche en vitamine E naturelle. Elle sert souvent d''additif antioxydant (5-10 %) dans les mélanges d''huiles fragiles pour prolonger leur durée de vie. Très épaisse et odorante.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Peut provoquer une réaction allergique chez les personnes sensibilisées au gluten.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger (alimentaire).',
    'Oxydants forts.',
    'Récipient hermétique, au frais, à l''abri de la lumière. Se solidifie partiellement à basse température.',
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
  (v_academie_id, 'Additif antioxydant pour mélanges d''huiles fragiles',
   'Ajouter 5 à 10 % d''huile de germe de blé dans un mélange d''huiles riches en polyinsaturés pour ralentir le rancissement (ex : macérats, sérums).',
   'plage', 5, 10, '% du mélange d''huiles', 'Ambiante', 'Immédiat', false, 0),
  (v_academie_id, 'Savon saponifié à froid (surgras antioxydant)',
   'Ajouter 5 à 10 % à la trace comme surgras. Apporte un toucher riche et protège le savon du rancissement.',
   'plage', 5, 10, '% du poids total (surgras)', 'Trace (30-40°C)', 'Ajout avant coulage', false, 1);

  -- ------------------------------------------------------------
  -- Huile de coton
  -- ------------------------------------------------------------
  v_material_id := '83bf2525-45f0-4942-83ce-fb163548cf25'::uuid;

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
    'Triglycérides d''acides gras (Gossypium herbaceum)',
    'Gossypium Herbaceum Seed Oil, Cottonseed Oil, huile de coton',
    'Alimentaire, Cosmétique',
    'Liquide jaune pâle à doré, fluide, odeur neutre à légèrement végétale',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.92, 230.0,
    'Composition : 45-55 % acide linoléique, 18-25 % acide oléique, 20-25 % acide palmitique. Indice de saponification 189-198. Huile économique, bon équilibre saturés/insaturés. Peut contenir des traces de gossypol (toxique si non raffinée).',
    'Par rapport à l''huile de soja, elle est plus riche en acide palmitique et donne un savon plus dur. Moins utilisée en cosmétique artisanale que l''huile de tournesol, mais économique pour la savonnerie en mélange.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Utiliser exclusivement de l''huile raffinée pour éviter le gossypol.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger (huile raffinée).',
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
  (v_academie_id, 'Savon saponifié à froid (huile de base économique)',
   'Incorporer 10 à 30 % du poids des huiles. Apporte dureté, mousse stable et un bon rapport qualité/prix.',
   'plage', 10, 30, '% du poids des huiles', '35-45°C', 'Trace en 15-20 min', false, 0);

  -- ------------------------------------------------------------
  -- Huile de soja
  -- ------------------------------------------------------------
  v_material_id := '688edf3b-3249-4b5f-b694-5ffec4f50b19'::uuid;

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
    'Triglycérides d''acides gras (Glycine max)',
    'Glycine Soja Oil, Soybean Oil, huile de soja',
    'Alimentaire, Cosmétique',
    'Liquide jaune pâle à doré, fluide, odeur neutre à légèrement végétale',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.92, 230.0,
    'Composition : 48-58 % acide linoléique, 18-25 % acide oléique, 8-13 % acide palmitique, riche en lécithine (0.5-1.5 %). Indice de saponification 188-195. Huile économique, bon conditionnement, accélère la trace en savonnerie.',
    'Par rapport à l''huile de tournesol, elle accélère significativement la trace en savon à froid. Comparable à l''huile de maïs pour son usage économique. La présence de lécithine naturelle peut troubler les macérats.',
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
  (v_academie_id, 'Savon saponifié à froid (huile de remplissage économique)',
   'Incorporer 10 à 40 % du poids des huiles. Apporte dureté et mousse stable. Accélère la trace, travailler rapidement.',
   'plage', 10, 40, '% du poids des huiles', '35-45°C', 'Trace rapide en 5-15 min', false, 0);

  -- ------------------------------------------------------------
  -- Huile de maïs
  -- ------------------------------------------------------------
  v_material_id := '22832a81-a5ab-4a52-8036-e0fc2ad40ce0'::uuid;

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
    'Triglycérides d''acides gras (Zea mays)',
    'Zea Mays Oil, Corn Oil, huile de maïs',
    'Alimentaire, Cosmétique',
    'Liquide jaune doré à jaune pâle, fluide, odeur neutre',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.92, 230.0,
    'Composition : 50-60 % acide linoléique, 25-30 % acide oléique, 10-12 % acide palmitique, riche en phytostérols et vitamine E. Indice de saponification 187-195. Huile très économique, bon conditionnement cutané, légèrement plus stable que le soja.',
    'Par rapport à l''huile de soja, elle accélère moins la trace et donne un savon légèrement plus doux. Comparable à l''huile de coton pour son rapport qualité/prix. Excellente huile de dilution pour les macérats.',
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
  (v_academie_id, 'Savon saponifié à froid (huile de base économique)',
   'Incorporer 10 à 40 % du poids des huiles. Apporte conditionnement et mousse stable. Trace moins rapide qu''avec le soja.',
   'plage', 10, 40, '% du poids des huiles', '35-45°C', 'Trace en 10-20 min', false, 0);

  -- ------------------------------------------------------------
  -- Huile d'arachide
  -- ------------------------------------------------------------
  v_material_id := 'ecb2728d-64cb-4f00-b1ce-40aabd0fb60b'::uuid;

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
    'Triglycérides d''acides gras (Arachis hypogaea)',
    'Arachis Hypogaea Oil, Peanut Oil, huile d''arachide, huile de cacahuète',
    'Alimentaire, Cosmétique',
    'Liquide jaune pâle à doré, fluide, odeur légère de cacahuète',
    'Non applicable (huile pure)',
    'Insoluble dans l''eau, soluble dans les solvants organiques et autres huiles',
    0.91, 230.0,
    'Composition : 40-50 % acide oléique, 25-35 % acide linoléique, 10-15 % acide palmitique. Indice de saponification 185-195. Huile économique, stable à la cuisson, bon conditionnement cutané. Très bon support pour les macérations. Allergène majeur.',
    'Par rapport à l''huile de tournesol, elle est plus riche en oléique et plus stable à l''oxydation. Comparable à l''huile de coton pour la savonnerie. Son caractère allergène la fait souvent éviter en cosmétique artisanale destinée à la vente.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Allergène alimentaire majeur — étiquetage obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger sauf pour les personnes allergiques aux arachides (risque de choc anaphylactique).',
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
  (v_academie_id, 'Savon saponifié à froid (huile de base économique)',
   'Incorporer 10 à 25 % du poids des huiles. Apporte dureté et conditionnement. Mentionner la présence d''huile d''arachide sur l''étiquette.',
   'plage', 10, 25, '% du poids des huiles', '35-45°C', 'Trace en 15-20 min', false, 0),
  (v_academie_id, 'Macération de plantes (huile support économique)',
   'Faire macérer des plantes sèches dans l''huile pendant 3-4 semaines, filtrer. Bonne stabilité et bon prix.',
   'texte_libre', null, null, 'quantité suffisante pour couvrir les plantes', 'Ambiante', '3-4 semaines', false, 1);
end $$;
