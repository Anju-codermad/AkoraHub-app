-- ============================================================
-- AkoraHub - Patch Phase 101 : fiches Académie pour les 5 derniers
-- désinfectants — contenu DeepSeek, vérifié par l'utilisatrice.
-- Termine la catégorie "Désinfectants" (16/16).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Acide peracétique (PAA)
  -- ------------------------------------------------------------
  v_material_id := '32ea63f7-7df3-4832-984d-448bf0eded80'::uuid;

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
    'Acide peracétique (C₂H₄O₃)',
    'PAA, APA, acide peroxyacétique, solution d''équilibre PAA',
    'Technique',
    'Liquide incolore à odeur piquante de vinaigre (solution commerciale à 5 % ou 15 %)',
    '1-2 (solution commerciale)',
    'Totalement miscible à l''eau',
    1.13, null,
    'Densité de la solution à 15 %. Biocide extrêmement rapide et large spectre (bactéries, virus, spores, biofilms). Se décompose en acide acétique, eau et oxygène, sans résidus toxiques.',
    'Contrairement à l''eau de Javel, le PAA ne forme pas de sous-produits chlorés toxiques et reste actif en présence de matières organiques. Plus efficace à froid que le peroxyde d''hydrogène seul.',
    'Corrosif',
    array['gants','lunettes','ventilation','tablier','bottes'],
    'Gants en caoutchouc butyle ou nitrile épais, écran facial, combinaison anti-acide, travailler sous hotte ou avec ventilation forcée.',
    'Inhalation : air frais, consulter. Peau : rincer 15 min, retirer vêtements. Yeux : rincer 15 min, consulter. Ingestion : rincer la bouche, ne pas vomir, boire de l''eau, appeler un médecin.',
    'Acides forts, bases fortes, métaux lourds et leurs sels (décomposition catalytique), matières organiques, agents réducteurs.',
    'Bidon en PEHD opaque, local frais et ventilé, à l''écart des sources de chaleur et des matières incompatibles. Ne pas exposer au soleil. Prévoir un bouchon éventé.',
    5, 25, false, true, 6, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H226', 'H314', 'H400')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P260', 'P280', 'P301+P330+P331', 'P303+P361+P353', 'P304+P340', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Désinfection en agroalimentaire (CIP, surfaces)',
   'Diluer à 0,1-0,5 % de produit commercial (15 %) dans l''eau froide ou tiède. Appliquer par circulation ou pulvérisation, laisser agir puis rincer à l''eau potable si nécessaire.',
   'plage', 0.1, 0.5, '% de solution à 15 % (soit 150-750 ppm de PAA pur)', '10-30 °C', '5-15 min', true, 0),
  (v_academie_id, 'Désinfection des circuits d''eau (légionelles)',
   'Injecter la solution diluée pour obtenir 50-100 ppm de PAA dans le circuit, faire circuler, vidanger et rincer.',
   'valeur_unique', 100, null, 'ppm de PAA pur dans l''eau du circuit', '20-30 °C', '30-60 min', true, 1);

  -- ------------------------------------------------------------
  -- Hypochlorite de calcium 70%
  -- ------------------------------------------------------------
  v_material_id := '87c7b0e5-d103-47bb-b4e0-e2b36cb560a7'::uuid;

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
    'Hypochlorite de calcium (Ca(ClO)₂)',
    'HTH, chlorure de chaux, pastilles de chlore sans stabilisant',
    'Technique',
    'Poudre, granulés ou pastilles blanches, forte odeur de chlore',
    '10-11 (solution à 1 %)',
    'Bonne solubilité (21 g/100 mL à 20 °C), un léger trouble de carbonate de calcium peut persister',
    2.35, null,
    'Densité du solide anhydre. Contient environ 65-70 % de chlore actif disponible. Fort pouvoir oxydant et alcalinisant, augmente le pH de l''eau traitée contrairement au TCCA.',
    'Contrairement au TCCA (pastilles stabilisées), l''hypochlorite de calcium n''apporte pas d''acide cyanurique. Par rapport à l''eau de Javel liquide, il est plus concentré, plus stable au stockage et plus économique pour le transport.',
    'Corrosif',
    array['gants','lunettes','masque','ventilation'],
    'Gants en caoutchouc, lunettes de sécurité étanches, masque anti-poussière et anti-chlore, manipuler dans un endroit bien ventilé.',
    'Peau : rincer 15 min, retirer vêtements. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas vomir, boire de l''eau, médecin. Inhalation : air frais, consulter si gêne.',
    'Acides (dégagement violent de chlore gazeux), ammoniaque, matières organiques, produits chlorés stabilisés (TCCA), métaux.',
    'Récipient étanche dans un local frais, sec et très bien ventilé. Tenir rigoureusement à l''écart des acides et des matières combustibles.',
    5, 30, true, false, 12, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H272', 'H302', 'H314', 'H400')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P220', 'P260', 'P280', 'P301+P330+P331', 'P303+P361+P353', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Traitement choc ou régulier de l''eau de piscine',
   'Pré-dissoudre les granulés dans un seau d''eau avant de verser dans le bassin filtration en marche. Pour un traitement régulier, viser 1 à 2 ppm de chlore libre.',
   'valeur_unique', 15, null, 'g de produit à 70 % par 10 m³ d''eau (augmente le chlore de 1 ppm)', 'Ambiante', 'Dissolution rapide, filtration 2-4 h', false, 0),
  (v_academie_id, 'Désinfection de surfaces (sols, murs, matériel)',
   'Dissoudre 10-20 g de granulés par litre d''eau pour obtenir une solution de Javel concentrée. Appliquer au balai ou au chiffon, laisser agir puis rincer.',
   'plage', 10, 20, 'g/L d''eau', 'Ambiante', '10-15 min', false, 1);

  -- ------------------------------------------------------------
  -- Hypochlorite de sodium NaClO (eau de Javel)
  -- ------------------------------------------------------------
  v_material_id := 'b49c6261-ea6d-4dc7-923e-b7885abd6f60'::uuid;

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
    'Hypochlorite de sodium (NaClO)',
    'Eau de Javel, solution d''hypochlorite de sodium',
    'Technique',
    'Liquide limpide jaune-vert, odeur caractéristique de chlore',
    '11-13 (solution commerciale)',
    'Totalement miscible à l''eau (se présente exclusivement en solution aqueuse)',
    1.20, null,
    'Densité de l''eau de Javel concentrée à 36° chlorométriques (9,6 % de chlore actif). Agent oxydant et désinfectant le plus utilisé au monde, peu coûteux et à large spectre.',
    'Par rapport à l''hypochlorite de calcium, l''eau de Javel est liquide, prête à l''emploi, mais moins stable dans le temps. Contrairement au TCCA, elle ne contient pas de stabilisant. Moins cher mais plus corrosif que le PAA.',
    'Corrosif',
    array['gants','lunettes','tablier','ventilation'],
    'Gants en caoutchouc ou nitrile, lunettes de sécurité étanches, éviter l''inhalation des vapeurs, ne jamais mélanger avec des produits acides.',
    'Peau : rincer 15 min. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas vomir, boire de l''eau, appeler un médecin. Inhalation : air frais.',
    'Acides (dégagement de chlore gazeux mortel), ammoniaque et produits ammoniaqués (chloramines toxiques), eau oxygénée, matières organiques.',
    'Bidon en PEHD opaque, local frais et bien ventilé, à l''abri de la lumière directe du soleil et des sources de chaleur. Ne pas stocker plus de 3 mois.',
    5, 25, false, true, 3, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H314', 'H318', 'H400')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P260', 'P280', 'P301+P330+P331', 'P303+P361+P353', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Désinfection des surfaces (sols, WC, salle de bain)',
   'Diluer l''eau de Javel concentrée (9,6 % ou 36° chl) à 0,5-1 % (1 volume de Javel + 9 à 19 volumes d''eau). Appliquer sur la surface propre, laisser agir, rincer si contact alimentaire.',
   'dilution', 1, 10, 'volumes d''eau pour 1 volume de Javel à 9,6 %', 'Ambiante', '5-15 min', false, 0),
  (v_academie_id, 'Potabilisation de l''eau (urgence)',
   'Ajouter 1 à 2 gouttes d''eau de Javel concentrée par litre d''eau claire, agiter et laisser reposer 30 min avant consommation.',
   'texte_libre', 1, 2, 'gouttes de Javel à 9,6 % par litre d''eau', 'Ambiante', '30 min', false, 1);

  -- ------------------------------------------------------------
  -- Peroxyde d'hydrogène alimentaire (H2O2)
  -- ------------------------------------------------------------
  v_material_id := '14107942-bb36-417b-a19f-44efb35120cf'::uuid;

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
    'Peroxyde d''hydrogène (H₂O₂)',
    'Eau oxygénée, peroxyde d''hydrogène, oxygène actif',
    'Alimentaire',
    'Liquide clair incolore, légèrement plus visqueux que l''eau',
    '3-4 (solution commerciale à 35 %)',
    'Totalement miscible à l''eau',
    1.13, null,
    'Densité de la solution à 35 % (grade alimentaire). Oxydant puissant qui se décompose en eau et oxygène sans résidu toxique. Le grade alimentaire certifie l''absence de stabilisants toxiques (étain, phosphonates).',
    'Contrairement aux désinfectants chlorés, il ne génère aucun sous-produit halogéné (THM, chloramines). Par rapport au PAA, il est moins rapide mais plus stable et moins corrosif pour les aciers inoxydables. Inefficace sur les spores à température ambiante.',
    'Corrosif',
    array['gants','lunettes','tablier'],
    'Gants en nitrile ou PVC, lunettes de sécurité étanches, éviter les projections ; à 35 %, le contact cutané provoque des brûlures blanches immédiates.',
    'Peau : rincer immédiatement 15 min (les brûlures blanches disparaissent lentement). Yeux : rincer 15 min, consulter. Ingestion : rincer la bouche, ne pas vomir, boire de l''eau, médecin.',
    'Métaux lourds et leurs sels (décomposition catalytique violente), matières organiques, agents réducteurs, bases fortes, produits chlorés.',
    'Bidon en PEHD opaque muni d''un bouchon éventé (dégagement d''oxygène), local frais et ventilé, à l''abri de la lumière et des sources de chaleur.',
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H318', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P280', 'P301+P312', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Stérilisation chimique des emballages alimentaires (briques, bouteilles)',
   'Appliquer une solution à 1-3 % de H₂O₂ à chaud (60-80 °C) par spray ou trempage, puis rincer à l''eau stérile ou laisser sécher.',
   'valeur_unique', 1, 3, '% de H₂O₂ pur dans l''eau (soit 3-9 % de la solution à 35 %)', '60-80 °C', '10-30 secondes', true, 0),
  (v_academie_id, 'Blanchiment et désinfection en brasserie/laiterie',
   'Faire circuler une solution à 0,5-1 % de H₂O₂ dans les cuves et canalisations après nettoyage alcalin. Rincer à l''eau stérile.',
   'plage', 0.5, 1, '% de H₂O₂ pur (1,5-3 % de solution à 35 %)', '20-40 °C', '15-30 min', true, 1);

  -- ------------------------------------------------------------
  -- TCCA (Trichloroisocyanurate)
  -- ------------------------------------------------------------
  v_material_id := 'd531cc1b-f536-4783-8efe-2951e690673b'::uuid;

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
    'Acide trichloroisocyanurique (C₃Cl₃N₃O₃)',
    'TCCA, trichloro, acide isocyanurique chloré',
    'Technique',
    'Poudre cristalline blanche, granulés ou pastilles, odeur caractéristique de chlore',
    'Acide (2,5-3,5 pour une solution saturée)',
    'Faible solubilité dans l''eau (1,2 g/100 mL à 20 °C), dissolution lente contrôlée',
    2.07, null,
    'Densité du solide. Contient environ 90 % de chlore disponible, libéré lentement par hydrolyse. Apporte de l''acide cyanurique (stabilisant chlore) dans l''eau traitée.',
    'Contrairement à l''hypochlorite de calcium, le TCCA libère son chlore plus lentement, acidifie l''eau et apporte un stabilisant UV. Par rapport à l''eau de Javel, il est solide, concentré et beaucoup plus stable au stockage. L''accumulation d''acide cyanurique peut cependant "bloquer" le chlore.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Gants en caoutchouc, lunettes de sécurité, masque anti-poussière et anti-chlore, manipuler dans un endroit très bien ventilé.',
    'Peau : rincer 15 min. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas vomir, boire de l''eau, médecin. Inhalation : air frais.',
    'Acides forts (dégagement de chlore gazeux), bases fortes, matières organiques, huiles, graisses.',
    'Récipient étanche en plastique, local frais, sec et très bien ventilé. Stocker rigoureusement à l''écart de tout acide, base, ou produit combustible.',
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
  select v_academie_id, id from public.phrases_h where code in ('H272', 'H302', 'H314', 'H335', 'H400')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P220', 'P260', 'P280', 'P301+P330+P331', 'P303+P361+P353', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Traitement régulier de l''eau de piscine',
   'Placer les pastilles dans un doseur flottant ou un chlorinateur. Maintenir un taux de chlore libre entre 1 et 3 ppm. Surveiller le taux d''acide cyanurique (max 50-75 ppm).',
   'valeur_unique', 10, null, 'g de TCCA par 10 m³ d''eau (entretien hebdomadaire)', 'Ambiante', 'Diffusion lente sur plusieurs jours', false, 0),
  (v_academie_id, 'Désinfection de surfaces en élevage (pédiluves, sols)',
   'Dissoudre 20-30 g de granulés dans 10 L d''eau pour obtenir une solution désinfectante. Appliquer au balai ou par trempage.',
   'plage', 2, 3, 'g/L d''eau', 'Ambiante', '10-15 min', true, 1);
end $$;
