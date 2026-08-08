-- ============================================================
-- AkoraHub - Patch Phase 125 : fiches Académie pour le lot 1 (8
-- conservateurs cosmétiques) des nouveaux produits "Conservateurs &
-- Antioxydants" — contenu DeepSeek, vérifié par l'utilisatrice.
--
-- Lot 1/4 : Phénoxyéthanol, Acide benzoïque (E210), Acide
-- déhydroacétique (DHA) et sodium déhydroacétate, Méthylparabène,
-- Éthylparabène, Éthylhexylglycérine, Caprylyl glycol, Capryloyl
-- glycine.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Phénoxyéthanol
  -- ------------------------------------------------------------
  v_material_id := '2e0a316c-38ed-4f75-bbc0-198ea774db4f'::uuid;

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
    '2-phénoxyéthanol (C₈H₁₀O₂)',
    'Phenoxyethanol, Phénoxétol, EGPh, conservateur cosmétique',
    'Cosmétique',
    'Liquide incolore à jaune très pâle, visqueux, odeur florale rosée discrète',
    'Non applicable (liquide pur)',
    'Faible solubilité dans l''eau (2,5 %), miscible à l''alcool, aux glycols et aux huiles',
    1.10, 127.0,
    'Conservateur de référence en cosmétique, actif sur les bactéries Gram-négatives, Gram-positives et les levures. Peu actif sur les moisissures seules (souvent associé à un fongicide comme le sorbate ou le caprylyl glycol). Limite réglementaire UE : 1,0 % maximum dans le produit fini. Efficace à pH 3-10.',
    'Contrairement aux parabènes, il n''est pas estérifié et ne génère pas de controverses hormonales. Par rapport à l''éthylhexylglycérine, il a un spectre plus large mais une solubilité dans l''eau plus faible. Souvent le conservateur de choix en remplacement des parabènes.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de protection. Éviter le contact avec les yeux (irritant).',
    'Yeux : rincer 15 min, consulter si irritation. Peau : laver au savon. Ingestion : rincer la bouche, boire de l''eau, appeler un médecin si symptômes.',
    'Tensioactifs non ioniques éthoxylés (peut réduire l''activité), bases fortes.',
    'Bidon bien fermé dans un endroit frais, sec et ventilé. À l''abri de la lumière.',
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H319')
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
  (v_academie_id, 'Conservateur pour crèmes, lotions, shampoings',
   'Incorporer 0,5 à 1,0 % dans la phase aqueuse ou en fin de formulation (température < 60°C). Pour une meilleure efficacité, associer à un booster (caprylyl glycol, éthylhexylglycérine) ou à un fongicide.',
   'plage', 0.5, 1.0, '% du produit fini', 'Incorporez en dessous de 60°C', 'Action conservatrice immédiate, vérification par challenge test', false, 0);

  -- ------------------------------------------------------------
  -- Acide benzoïque (E210)
  -- ------------------------------------------------------------
  v_material_id := '142afc7f-3d35-4751-b04e-b08f503cc944'::uuid;

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
    'Acide benzoïque (C₇H₆O₂)',
    'E210, Benzoic Acid, acide benzènecarboxylique, conservateur alimentaire/cosmétique',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche, légèrement odorante (odeur d''amande), se sublime facilement à chaud',
    '2,8 (solution saturée à 20°C)',
    'Faible dans l''eau froide (0,3 g/100 mL à 20°C), bonne dans l''eau chaude, l''éthanol et les glycols',
    1.32, 121.0,
    'Conservateur actif sur les levures, moisissures et certaines bactéries. Efficace uniquement à pH < 4,5 (forme acide non dissociée). Très utilisé en agroalimentaire (boissons acides, confitures) et cosmétique (produits à pH acide). Dose max en cosmétique UE : 0,5 % (acide) ou 2,5 % (benzoate de sodium). En alimentaire : 150-500 ppm selon le produit.',
    'Par rapport au benzoate de sodium (E211), il est moins soluble dans l''eau mais ne libère pas de sodium. Contrairement à l''acide sorbique (E200), il est actif jusqu''à pH 4,5 alors que le sorbique monte à pH 6,5. Il est souvent utilisé en combinaison avec le sorbate pour un spectre plus large.',
    'Modéré',
    array['gants','lunettes','masque'],
    'Porter des gants (nitrile), des lunettes et un masque anti-poussière. Irritant pour les voies respiratoires.',
    'Yeux : rincer 15 min. Peau : laver à l''eau et au savon. Ingestion : rincer la bouche, boire de l''eau. Inhalation : air frais, consulter si gêne respiratoire.',
    'Oxydants forts, bases fortes (formation de benzoate), fer (coloration).',
    'Récipient étanche, au sec, à température ambiante, à l''écart des sources de chaleur (se sublime).',
    5, 30, false, false, 36, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319', 'H335', 'H372')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P260', 'P264', 'P280', 'P305+P351+P338', 'P314')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Conservateur pour boissons gazeuses, confitures, produits à pH acide',
   'Dissoudre dans l''eau chaude ou prémélanger avec un peu d''alcool/glycol avant d''incorporer. Ajuster le pH en dessous de 4,5. Dosage typique 0,05-0,1 %.',
   'plage', 0.05, 0.1, '% du produit fini', '20-80°C', 'Immédiat', false, 0),
  (v_academie_id, 'Conservateur cosmétique pour crèmes acides (AHA, vitamine C)',
   'Ajouter 0,2-0,5 % dans la phase chaude (> 60°C) pour dissoudre. Vérifier que le pH final est inférieur à 4,5.',
   'plage', 0.2, 0.5, '% du produit fini', '60-70°C', 'Dissolution puis refroidissement', false, 1);

  -- ------------------------------------------------------------
  -- Acide déhydroacétique (DHA) et sodium déhydroacétate
  -- ------------------------------------------------------------
  v_material_id := '1af35de6-63fb-4615-a7e0-86c46cd3265f'::uuid;

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
    'Acide 3-acétyl-6-méthyl-2H-pyrane-2,4(3H)-dione et son sel de sodium',
    'Dehydroacetic Acid (DHA), Sodium Dehydroacetate, Geogard 111A (si combiné), conservateur cosmétique',
    'Cosmétique, Alimentaire',
    'Poudre cristalline blanche à blanc cassé, inodore',
    '4-5 (acide) / 7-8 (sel de sodium)',
    'Acide : peu soluble dans l''eau (< 0,1 %), soluble dans les glycols, l''alcool. Sel de sodium : très soluble dans l''eau (> 30 %).',
    1.30, null,
    'Conservateur à large spectre (bactéries, levures, moisissures). Efficace sur une large plage de pH (3-7). L''acide DHA est souvent utilisé sous sa forme de sel de sodium pour la solubilité. Limite UE cosmétique : 0,6 % (en acide). Souvent associé à l''alcool benzylique ou au phénoxyéthanol.',
    'Par rapport au benzoate de sodium, il couvre mieux les moisissures et reste actif à pH plus élevé (jusqu''à 7). Contrairement au phénoxyéthanol, il est solide et plus facile à manipuler en poudre. Il est souvent privilégié dans les formulations "naturelles" car autorisé par certains labels (Ecocert).',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour la manipulation de la poudre.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Bases fortes, agents réducteurs puissants, sels de fer (coloration).',
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Conservateur pour crèmes, lotions, gels douche (label bio)',
   'Ajouter 0,2-0,6 % (en équivalent acide) dans la phase aqueuse. Prémélanger l''acide dans un glycol si nécessaire. Efficace dès l''incorporation.',
   'plage', 0.2, 0.6, '% du produit fini', 'Ambiante à 60°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Méthylparabène
  -- ------------------------------------------------------------
  v_material_id := 'b1917c1f-044d-4e5f-8888-a188073b6689'::uuid;

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
    'Méthyl 4-hydroxybenzoate (C₈H₈O₃)',
    'Methylparaben, E218, Nipagine, conservateur parahydroxybenzoïque',
    'Cosmétique, Alimentaire',
    'Poudre cristalline blanche, inodore',
    '6-7 (solution à 0,1 %)',
    'Faible dans l''eau (0,25 % à 20°C), soluble dans l''alcool, les glycols, les huiles chaudes',
    1.35, null,
    'Conservateur antimicrobien de la famille des parabènes. Très efficace contre les moisissures et les levures, bonne activité sur les bactéries Gram-positives. Efficace sur une large plage de pH (3-8). Réglementation UE : autorisé sans restriction de concentration (généralement 0,4 % en usage individuel, 0,8 % en mélange de parabènes). Non restreint contrairement au propylparabène et au butylparabène (restreints à 0,14 % combiné depuis 2014).',
    'Par rapport à l''éthylparabène, il est plus soluble dans l''eau mais légèrement moins actif. Comparé au phénoxyéthanol, il est plus efficace contre les moisissures. Il a été injustement décrié par la controverse des parabènes, mais reste l''un des conservateurs les plus sûrs et les mieux étudiés.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière lors de la manipulation de la poudre.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Tensioactifs non ioniques éthoxylés (désactivation partielle), bases fortes (hydrolyse), sels de fer (coloration).',
    'Récipient étanche, au sec, à température ambiante.',
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Conservateur pour cosmétiques (crèmes, gels, lotions)',
   'Dissoudre 0,2-0,4 % dans la phase chaude (60-70°C) ou prémélanger dans un glycol. Bonne stabilité thermique.',
   'plage', 0.2, 0.4, '% du produit fini', '60-70°C', 'Immédiat', false, 0),
  (v_academie_id, 'Conservateur alimentaire (E218) pour pâtisseries, snacks',
   'Ajouter 0,05-0,1 % dans la phase grasse ou la pâte. Autorisé dans l''UE pour certains aliments.',
   'plage', 0.05, 0.1, '% du produit fini', 'Ambiante à cuisson', 'Pendant la préparation', false, 1);

  -- ------------------------------------------------------------
  -- Éthylparabène
  -- ------------------------------------------------------------
  v_material_id := '8c2c5aa3-390c-4dad-b034-8c06cc167025'::uuid;

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
    'Éthyl 4-hydroxybenzoate (C₉H₁₀O₃)',
    'Ethylparaben, E214, Nipasol, conservateur parahydroxybenzoïque',
    'Cosmétique, Alimentaire',
    'Poudre cristalline blanche, inodore',
    '6-7 (solution à 0,1 %)',
    'Très faible dans l''eau (0,11 % à 20°C), soluble dans l''alcool, les glycols, les huiles chaudes',
    1.33, null,
    'Conservateur de la famille des parabènes, légèrement plus lipophile que le méthylparabène. Bonne activité sur les moisissures, levures et bactéries Gram-positives. Efficace pH 3-8. Réglementation UE : autorisé sans restriction de concentration (mêmes limites que le méthylparabène : 0,4 % individuel, 0,8 % en mélange). Non restreint contrairement au propyl/butylparabène.',
    'Par rapport au méthylparabène, il est moins soluble dans l''eau mais plus actif sur certaines levures. Il est souvent utilisé en combinaison avec le méthylparabène pour un spectre plus large. Comme lui, il n''est pas soumis aux restrictions du propyl/butylparabène.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière lors de la manipulation de la poudre.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Tensioactifs éthoxylés, bases fortes, sels de fer.',
    'Récipient étanche, au sec, à température ambiante.',
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Conservateur pour cosmétiques (en synergie avec méthylparabène)',
   'Utiliser 0,2-0,4 % en mélange avec le méthylparabène (ratio 1:1 à 1:3). Dissoudre dans la phase chaude ou prémélanger dans un glycol.',
   'plage', 0.1, 0.3, '% du produit fini', '60-70°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Éthylhexylglycérine
  -- ------------------------------------------------------------
  v_material_id := 'ecd4191b-6d29-48ef-9589-9b3dd8aada85'::uuid;

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
    '3-[2-(éthylhexyl)oxy]propane-1,2-diol (C₁₁H₂₄O₃)',
    'Ethylhexylglycerin, Octoxyglycérine, booster de conservation',
    'Cosmétique',
    'Liquide incolore à jaune très pâle, légèrement visqueux, odeur neutre',
    'Non applicable (liquide pur)',
    'Faible solubilité dans l''eau, miscible aux huiles, alcools, glycols',
    0.96, 160.0,
    'Agent multifonctionnel : tensioactif doux, émollient, et surtout booster de conservation. Il déstabilise la membrane des micro-organismes, ce qui potentialise l''action des conservateurs classiques (phénoxyéthanol, parabènes, etc.). Limite d''usage : 1,0 % en cosmétique. Améliore aussi le toucher des formules.',
    'Contrairement au caprylyl glycol, il est plus lipophile et plus actif comme booster. Il n''est pas un conservateur à lui seul, mais un potentialisateur. Il est souvent le remplaçant moderne des parabènes en combinaison avec le phénoxyéthanol.',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes recommandés. Peut être irritant pour les yeux à l''état pur.',
    'Yeux : rincer 15 min. Peau : laver au savon. Ingestion : boire de l''eau.',
    'Oxydants forts.',
    'Bidon bien fermé, à température ambiante, à l''abri de la lumière.',
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
  select v_academie_id, id from public.phrases_h where code in ('H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Booster de conservation pour crèmes et lotions',
   'Ajouter 0,2-1,0 % en combinaison avec un conservateur primaire (ex : phénoxyéthanol 0,5 % + éthylhexylglycérine 0,3 %). Incorporer en phase grasse ou en fin de formulation.',
   'plage', 0.2, 1.0, '% du produit fini', 'Ambiante à 60°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Caprylyl glycol
  -- ------------------------------------------------------------
  v_material_id := 'f3c35ff6-2766-40f7-b1de-2d12181c346d'::uuid;

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
    '1,2-octanediol (C₈H₁₈O₂)',
    'Caprylyl Glycol, booster de conservation',
    'Cosmétique',
    'Solide blanc à blanc cassé (paillettes ou poudre), fond vers 37°C, odeur neutre',
    'Non applicable',
    'Faible dans l''eau (< 1 %), soluble dans l''alcool, les glycols, les huiles',
    0.90, 130.0,
    'Diol à chaîne moyenne, agent hydratant et booster de conservation. Il agit en synergie avec d''autres conservateurs en perturbant la membrane microbienne. Souvent associé au phénoxyéthanol ou à l''éthylhexylglycérine. Limite d''usage : 0,5-1,0 %. Apporte un toucher doux et soyeux.',
    'Par rapport à l''éthylhexylglycérine, il est solide à température ambiante et plus hydratant. Il est moins lipophile et souvent utilisé en mélange avec le phénoxyéthanol. Il fait partie des boosters "verts" appréciés en cosmétique naturelle.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour manipuler la poudre/les paillettes.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Oxydants forts.',
    'Récipient étanche, au frais (fond à 37°C), à l''abri de la chaleur.',
    5, 25, false, false, 36, 'a_valider'
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
  (v_academie_id, 'Booster de conservation et agent hydratant',
   'Ajouter 0,3-1,0 % dans la phase huileuse ou en fin de formulation avec le conservateur primaire. Fondre si nécessaire avant incorporation.',
   'plage', 0.3, 1.0, '% du produit fini', 'Ambiante à 60°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Capryloyl glycine
  -- ------------------------------------------------------------
  v_material_id := '0c834b32-e700-418d-915d-b74f180c046b'::uuid;

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
    'Acide N-(1-oxooctyl)glycine (C₁₀H₁₉NO₃)',
    'Capryloyl Glycine, Lipacide C8G, booster de conservation',
    'Cosmétique',
    'Poudre blanche fine, odeur neutre',
    'Acide (pKa ~ 4-5)',
    'Faible solubilité dans l''eau, soluble dans les glycols et l''alcool, partiellement dans les huiles',
    0.80, null,
    'Dérivé d''acide aminé (glycine) et d''acide caprylique. Agent multifonctionnel : conservateur doux, séborégulateur, antifongique. Actif principalement sur les bactéries Gram-positives et les levures. Utilisé à pH légèrement acide (4-6). Souvent associé à d''autres conservateurs. Limite d''usage : 0,5-1,0 %.',
    'Par rapport au caprylyl glycol, il est plus polaire (fonction acide aminé) et a une activité antifongique plus marquée. Il est plus proche d''un conservateur actif que d''un simple booster. Apprécié dans les soins purifiants et les déodorants.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour manipuler la poudre.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Bases fortes (neutralisation), oxydants forts.',
    'Récipient étanche, au sec, à température ambiante.',
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
  (v_academie_id, 'Conservateur doux et actif purifiant pour gels, crèmes',
   'Ajouter 0,5-1,0 % dans la phase aqueuse ou prémélanger dans un glycol. Ajuster le pH en dessous de 6 pour une efficacité optimale.',
   'plage', 0.5, 1.0, '% du produit fini', 'Ambiante à 60°C', 'Immédiat', false, 0);
end $$;
