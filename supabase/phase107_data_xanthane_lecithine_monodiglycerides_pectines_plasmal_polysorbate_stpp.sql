-- ============================================================
-- AkoraHub - Patch Phase 107 : fiches Académie pour 9 des 13 derniers
-- produits d'origine des "Épaississants" — contenu DeepSeek, vérifié
-- par l'utilisatrice. Le contenu "Pectine HM" est appliqué à la fois
-- à "Pectine" (nom générique) et à "Pectine HM (E440i)", la forme HM
-- étant la plus courante pour un nom non spécifié.
--
-- Volontairement laissé de côté : "Stabilisateur glace (combo
-- gommes)" — ce n'est pas une substance propre mais un mélange des
-- gommes déjà documentées (LBG, guar, carraghénane...), pas besoin
-- de fiche Académie séparée.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  r record;
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Gomme xanthane
  -- ------------------------------------------------------------
  v_material_id := '41c5d91b-8f17-4e2d-a5fe-8f5cb85dab83'::uuid;

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
    'Polysaccharide anionique (chaîne de glucose avec acide pyruvique et acide glucuronique) ((C₃₅H₄₉O₂₉)n)',
    'Gomme xanthane, E415',
    'Alimentaire',
    'Poudre blanche à crème, fine, inodore',
    '6-7 (dispersion à 1 %)',
    'Soluble dans l''eau froide ou chaude, donne une solution très visqueuse et pseudoplastique. Insoluble dans les solvants organiques.',
    0.80, null,
    'Produit par fermentation. Très forte viscosité à faible concentration, stable sur une large plage de pH (2-12) et de température. Comportement pseudoplastique. Synergie avec la gomme guar et la LBG.',
    'Contrairement à la gomme guar, stable en milieu acide et résiste mieux à la chaleur et au cisaillement. Par rapport à la CMC, donne des solutions plus transparentes et plus efficace à faible dose. N''est pas un émulsifiant contrairement à la gomme arabique.',
    'Aucun',
    array['masque'],
    'Porter un masque anti-poussière lors de la manipulation de la poudre fine pour éviter l''inhalation.',
    'Yeux : rincer à l''eau. Peau : laver. Inhalation : air frais. Ingestion sans danger.',
    'Cations polyvalents (calcium, magnésium) à haute concentration : peut réduire la viscosité. Oxydants forts.',
    'Récipient étanche, au sec, à température ambiante. Éviter l''humidité.',
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
  (v_academie_id, 'Épaississant et stabilisant pour sauces, vinaigrettes et boissons',
   'Disperser 0,1-0,5 % de gomme xanthane dans le liquide sous agitation vigoureuse. Pour éviter les grumeaux, prémélanger avec un peu d''huile ou de sucre.',
   'plage', 0.1, 0.5, '% du produit fini', '20-80 °C', '15-30 min d''hydratation complète', false, 0),
  (v_academie_id, 'Liant et texturant en boulangerie sans gluten',
   'Ajouter 0,5-1 % du poids de farine dans le mélange sec, bien mélanger avant d''incorporer les liquides.',
   'valeur_unique', 0.75, null, '% du poids de farine', 'Ambiante', 'Pendant le pétrissage', false, 1),
  (v_academie_id, 'Gel douche ou shampoing (transparence et suspension)',
   'Disperser 0,3-0,8 % dans l''eau, hydrater 30 min, ajouter les tensioactifs. La pseudo-plasticité facilite le pompage.',
   'valeur_unique', 0.5, null, '% du produit fini', '20-30 °C', '30 min d''hydratation', false, 2);

  -- ------------------------------------------------------------
  -- Lécithine de soja (E322)
  -- ------------------------------------------------------------
  v_material_id := 'e602e56b-45eb-4097-b924-c10d6364db96'::uuid;

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
    'Mélange de phosphatidylcholines, phosphatidyléthanolamines et phosphatidylinositols',
    'Lécithine de soja, E322, lécithine',
    'Alimentaire',
    'Liquide visqueux ambré à brun, ou poudre déshuilée jaune pâle, odeur caractéristique',
    'Neutre (dispersion dans l''eau)',
    'Dispersible dans l''eau (forme des émulsions), soluble dans les huiles et les solvants organiques',
    1.03, null,
    'Densité du liquide standard. Émulsifiant amphiphile naturel, agent de surface qui stabilise les émulsions huile-dans-eau et eau-dans-huile. Excellente affinité avec la peau.',
    'Contrairement aux mono-diglycérides (E471), plus hydrophile et donne des émulsions H/E plus stables. Par rapport au polysorbate 80, d''origine naturelle et moins éthoxylée. Ne gélifie pas comme les gommes, c''est un émulsifiant pur.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter le contact prolongé avec la peau pour les personnes allergiques au soja (traces).',
    'Yeux : rincer. Peau : laver au savon. Ingestion sans danger.',
    'Acides et bases fortes (hydrolyse). Oxydants.',
    'Bidon fermé, à l''abri de la lumière et de la chaleur, dans un endroit frais. La poudre déshuilée doit être conservée au sec.',
    10, 25, true, true, 18, 'a_valider'
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
  (v_academie_id, 'Émulsifiant pour chocolat et pâtisserie',
   'Ajouter 0,3-0,5 % du poids du chocolat pendant le conchage pour améliorer la fluidité et éviter le blanchiment.',
   'valeur_unique', 0.4, null, '% du poids du chocolat', '50-60 °C', 'Conchage (plusieurs heures)', false, 0),
  (v_academie_id, 'Émulsifiant pour crèmes cosmétiques (cold cream, lotions)',
   'Utiliser 2-5 % dans la phase grasse, chauffer à 70 °C avec les autres corps gras, puis émulsionner avec la phase aqueuse.',
   'plage', 2, 5, '% de la phase grasse', '70-75 °C', 'Émulsification 10-15 min', false, 1);

  -- ------------------------------------------------------------
  -- Mono- et diglycérides d'acides gras (E471)
  -- ------------------------------------------------------------
  v_material_id := 'd75bf7b5-e253-4886-a913-cab515cc687b'::uuid;

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
    'Mono- et diglycérides d''acides gras',
    'E471, mono-diglycérides, GMS (stéarate de glycérol), monostéarate de glycérol',
    'Alimentaire',
    'Poudre blanche à crème (forme poudre) ou pâte blanche à jaunâtre, odeur grasse faible',
    'Non applicable (insoluble)',
    'Insoluble dans l''eau, soluble dans les huiles et graisses chaudes, se disperse dans l''eau chaude',
    0.95, null,
    'Émulsifiant non ionique, stabilise les émulsions eau-dans-huile et huile-dans-eau. Améliore le volume et la texture des produits de boulangerie. Agent anti-rassissement.',
    'Par rapport à la lécithine, plus lipophiles et plus efficaces pour les émulsions E/H. Ne sont pas des gélifiants comme les gommes, mais modifient la cristallisation des graisses.',
    'Aucun',
    array[]::text[],
    'Aucun. Éviter l''inhalation de poussières.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Bases fortes (saponification), oxydants forts.',
    'Récipient étanche, au frais et au sec, à l''abri des odeurs.',
    5, 25, true, false, 24, 'a_valider'
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
  (v_academie_id, 'Améliorant de mie en boulangerie et viennoiserie',
   'Ajouter 0,3-0,5 % du poids de farine lors du pétrissage pour augmenter le volume et prolonger la fraîcheur.',
   'valeur_unique', 0.4, null, '% du poids de farine', 'Ambiante', 'Incorporation au pétrissage', false, 0),
  (v_academie_id, 'Stabilisant de crèmes glacées (anti-fonte, texture)',
   'Incorporer 0,2-0,5 % dans le mix à glace avec les matières grasses, chauffer à 80 °C pour fondre et disperser.',
   'valeur_unique', 0.3, null, '% du mix', '80 °C', '5-10 min de mélange', false, 1);

  -- ------------------------------------------------------------
  -- Pectine (générique) + Pectine HM (E440i) — même contenu HM
  -- ------------------------------------------------------------
  for r in
    select * from (values
      ('c0120176-0f41-412f-a62c-a2603088fd17'::uuid), -- Pectine (générique)
      ('daf69923-e534-45c9-9ab5-2142e504b7b2'::uuid)  -- Pectine HM (E440i)
    ) as t(material_id)
  loop
    insert into public.matieres_premieres_academie (
      matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
      ph_solution, solubilite, densite, point_eclair, particularite,
      difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
      premiers_secours, incompatibilites, consignes_stockage,
      temperature_stockage_min, temperature_stockage_max,
      sensible_humidite, sensible_lumiere, duree_conservation_mois,
      statut_verification
    ) values (
      r.material_id,
      'Acide polygalacturonique partiellement méthylé ((C₆H₁₀O₇)n, degré de méthylation > 50 %)',
      'Pectine HM, E440(i), pectine à haute méthylation',
      'Alimentaire',
      'Poudre blanche à crème, fine, inodore',
      '3-3,5 (dispersion à 1 %)',
      'Soluble dans l''eau chaude (80-100 °C), forme un gel en présence d''une forte concentration en sucre (55-65 %) et à pH acide (2,8-3,5)',
      0.70, null,
      'Gélifiant thermoréversible, idéal pour les confitures et gelées. Le mécanisme de gélification dépend du taux de sucre et de l''acidité. Le gel est ferme et brillant.',
      'Contrairement à l''agar-agar, nécessite beaucoup de sucre et un pH acide pour gélifier. Par rapport aux carraghénanes, donne un gel plus ferme et fruité. Ne gélifie pas en présence de calcium (contrairement à la pectine LM).',
      'Aucun',
      array[]::text[],
      'Aucun. Éviter l''inhalation de poussières.',
      'Yeux : rincer. Peau : laver.',
      'Calcium (peut former des précipités). Alcool éthylique élevé peut précipiter la pectine.',
      'Récipient étanche, au sec, à température ambiante.',
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
    (v_academie_id, 'Gélifiant pour confitures, gelées et marmelades',
     'Mélanger la poudre avec une partie du sucre, ajouter aux fruits et porter à ébullition. Ajouter le reste du sucre, cuire jusqu''à 65 % de sucre soluble et pH 3-3,2. La prise se fait en refroidissant.',
     'plage', 0.5, 1, '% du poids total (ajusté selon la recette)', '100-105 °C (ébullition)', '5-10 min de cuisson', false, 0);
  end loop;

  -- ------------------------------------------------------------
  -- Pectine HM rapide (Extra-Rapide/Rapide)
  -- ------------------------------------------------------------
  v_material_id := '2b4b101a-9250-46ab-82dc-ec4344499163'::uuid;

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
    'Acide polygalacturonique partiellement méthylé, degré de méthylation > 50 % (prise rapide)',
    'Pectine HM rapide, pectine extra rapide, pectine prise rapide',
    'Alimentaire',
    'Poudre blanche à crème, identique à la pectine HM standard',
    '3-3,5 (dispersion à 1 %)',
    'Mêmes propriétés que la HM standard, mais la gélification est plus rapide et à température plus élevée (commence dès 80-90 °C)',
    0.70, null,
    'Variante de pectine HM conçue pour des confitures avec des morceaux de fruits ou une distribution homogène. Gélifie en quelques minutes après cuisson, évitant la flottation des fruits.',
    'Par rapport à la pectine HM standard, permet une prise plus précoce et à plus haute température, idéal pour les confitures artisanales avec morceaux. Nécessite les mêmes conditions sucre/acide.',
    'Aucun',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Identique à la pectine HM.',
    'Récipient étanche, au sec.',
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
    dosage_min, unite_dosage, temperature_utilisation, temps_action,
    a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Confitures avec morceaux de fruits entiers',
   'Mélanger la poudre avec le sucre, ajouter aux fruits et cuire. La prise rapide permet de suspendre les morceaux avant qu''ils ne remontent.',
   'valeur_unique', 0.6, '% du poids total', '100-105 °C', 'Prise en 2-5 min après cuisson', false, 0);

  -- ------------------------------------------------------------
  -- Pectine LM (Faible méthylation) / Amidée
  -- ------------------------------------------------------------
  v_material_id := '4fe03127-5693-4ece-8c1e-7ab07cd648e2'::uuid;

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
    'Acide polygalacturonique partiellement amidé et/ou faiblement méthylé (DM < 50 %)',
    'Pectine LM, pectine amidée, E440(ii), pectine à basse méthylation',
    'Alimentaire',
    'Poudre blanche à crème, fine',
    '4-5 (dispersion à 1 %)',
    'Soluble dans l''eau chaude (70-80 °C). Gélifie en présence de cations calcium (Ca²⁺), sans nécessiter de sucre ou d''acidité. Le gel est thermoréversible.',
    0.70, null,
    'Gélifiant pour produits allégés en sucre, nappages, yaourts. La version amidée est plus tolérante au calcium et donne un gel plus élastique.',
    'Contrairement à la pectine HM, gélifie sans sucre ajouté, idéale pour les produits diététiques. Par rapport à l''alginate de sodium, moins sensible au calcium (pas de grumeaux) et le gel est plus onctueux.',
    'Aucun',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Excès de calcium : prégélification ou texture granuleuse. Phosphates et citrates peuvent séquestrer le calcium et inhiber la gélification.',
    'Récipient étanche, au sec.',
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
  (v_academie_id, 'Gel pour nappages de desserts et yaourts aux fruits allégés',
   'Disperser 0,5-1,5 % de pectine LM dans l''eau, chauffer à 80 °C, ajouter du calcium (lactate ou chlorure), refroidir pour gélifier.',
   'plage', 0.5, 1.5, '% du produit', '80 °C', 'Refroidissement 30 min', false, 0);

  -- ------------------------------------------------------------
  -- Plasmal (mélange phosphates alimentaires)
  -- ------------------------------------------------------------
  v_material_id := '6f7caff7-060e-44ea-a3f8-0c6a52571e28'::uuid;

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
    'Mélange de polyphosphates (E452) et orthophosphates (E339-E341)',
    'Plasmal, phosphates alimentaires, sels de fonte, polyphosphates',
    'Alimentaire',
    'Poudre blanche à légèrement grise, fine, hygroscopique',
    'Alcalin (9-10 pour une solution à 1 % de STPP)',
    'Très soluble dans l''eau, surtout à chaud. Libère des ions phosphate.',
    0.90, null,
    'Mélange spécifique de phosphates utilisé comme séquestrant du calcium, émulsifiant, rétenteur d''eau et agent de fonte pour les fromages fondus et la charcuterie.',
    'Contrairement au STPP pur, "Plasmal" est un mélange équilibré pour des applications fromagères spécifiques. Apporte aussi un pouvoir émulsifiant et une texture onctueuse, contrairement à l''EDTA.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. Éviter l''inhalation de poussières.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Acides forts (hydrolyse), cations calcium et magnésium (précipitation de phosphates insolubles).',
    'Récipient étanche, au sec, à l''abri de l''humidité (très hygroscopique).',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Sel de fonte pour fromages fondus (tranches, à tartiner)',
   'Dissoudre 2-3 % du poids du fromage dans un peu d''eau chaude, ajouter au fromage râpé, chauffer à 80-85 °C en agitant jusqu''à fonte lisse.',
   'valeur_unique', 2.5, null, '% du poids du fromage', '80-85 °C', '5-10 min de fonte', false, 0),
  (v_academie_id, 'Rétenteur d''eau pour charcuterie (saucisses, jambon cuit)',
   'Ajouter 0,3-0,5 % du poids de la mêlée avec le sel lors du malaxage pour améliorer la jutosité et réduire les pertes à la cuisson.',
   'valeur_unique', 0.4, null, '% du poids de viande', '4-8 °C (pendant malaxage)', 'Malaxage 30-60 min', false, 1);

  -- ------------------------------------------------------------
  -- Polysorbate 80 (E433)
  -- ------------------------------------------------------------
  v_material_id := 'e4618428-c9e7-4246-b060-473694e43566'::uuid;

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
    'Mono-oléate de sorbitane polyoxyéthyléné (C₆₄H₁₂₄O₂₆)',
    'Polysorbate 80, E433, Tween 80, polyoxyéthylène (20) sorbitane mono-oléate',
    'Alimentaire',
    'Liquide visqueux jaune à ambré, odeur caractéristique faible',
    '6-7 (solution à 1 %)',
    'Soluble dans l''eau, l''éthanol et les huiles. Forme des émulsions huile-dans-eau stables. Non ionique.',
    1.08, null,
    'Émulsifiant non ionique très efficace pour les huiles essentielles et les arômes. HLB 15,0, donc très hydrophile. Agent solubilisant et dispersant de choix pour les bains moussants et les boissons.',
    'Par rapport à la lécithine, plus hydrophile et permet de solubiliser des huiles essentielles dans l''eau claire. Contrairement aux mono-diglycérides, soluble dans l''eau. Ce n''est pas un épaississant comme les gommes.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. Éviter le contact prolongé avec la peau.',
    'Yeux : rincer. Peau : laver au savon. Ingestion : boire de l''eau, ne pas faire vomir.',
    'Phénols, acides forts, bases fortes. Peut déstabiliser certains conservateurs.',
    'Bidon fermé, à l''abri de la lumière et de la chaleur, dans un endroit sec.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Solubilisant d''huiles essentielles dans les boissons et sirops',
   'Mélanger l''huile essentielle avec le polysorbate 80 (ratio 1:1 à 1:5), agiter, puis diluer dans l''eau pour obtenir une solution claire.',
   'texte_libre', 0.5, 5, 'parties de polysorbate pour 1 partie d''huile (selon l''huile)', 'Ambiante', 'Quelques minutes d''agitation', false, 0),
  (v_academie_id, 'Émulsifiant pour bains moussants et gels douche',
   'Ajouter 1-3 % dans la formulation, mélanger avec les tensioactifs pour solubiliser les parfums et huiles.',
   'plage', 1, 3, '% du produit fini', '20-30 °C', 'Incorporation immédiate', false, 1);

  -- ------------------------------------------------------------
  -- Tripolyphosphate de sodium STPP (E451)
  -- ------------------------------------------------------------
  v_material_id := 'e46e549f-74e9-40f3-afd3-fd9cdbdc6fee'::uuid;

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
    'Triphosphate pentasodique (Na₅P₃O₁₀)',
    'STPP, E451(i), tripolyphosphate de sodium',
    'Alimentaire',
    'Poudre blanche, granuleuse, inodore, hygroscopique',
    '9,5-10 (solution à 1 %)',
    'Très soluble dans l''eau (15 g/100 mL à 20 °C). Insoluble dans l''éthanol.',
    0.90, null,
    'Agent séquestrant le calcium et le magnésium, dispersant, et rétenteur d''eau. Améliore la texture des produits carnés et fromagers. Ingrédient clé des détergents (usage technique).',
    'Par rapport au "Plasmal" (mélange), le composé pur le plus utilisé. Contrairement aux gommes ou gélifiants, n''épaissit pas mais modifie la solubilité des protéines. Plus efficace que le citrate de sodium en détergence.',
    'Modéré',
    array['gants','lunettes'],
    'Porter des gants et des lunettes de protection pour éviter le contact prolongé avec la peau (irritant). Éviter l''inhalation de poussières.',
    'Yeux : rincer 15 min, consulter si irritation. Peau : laver au savon. Ingestion : rincer la bouche, boire de l''eau, consulter un médecin. Inhalation : air frais.',
    'Acides (hydrolyse en phosphates plus simples), cations calcium et magnésium (précipitation de phosphates insolubles).',
    'Récipient étanche, au sec, à l''abri de l''humidité. Éviter le contact avec les acides.',
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
  (v_academie_id, 'Rétenteur d''eau pour produits de la mer et charcuterie',
   'Dissoudre dans l''eau de trempage ou ajouter directement dans la saumure à raison de 0,1-0,5 % du poids du produit.',
   'plage', 0.1, 0.5, '% du poids du produit', '4-8 °C', 'Trempage 30 min à 2 h', false, 0),
  (v_academie_id, 'Séquestrant dans les détergents en poudre pour lave-vaisselle',
   'Incorporer 10-30 % de STPP dans la poudre pour adoucir l''eau et améliorer l''efficacité du lavage.',
   'plage', 10, 30, '% du poids de la poudre', 'Ambiante pour la fabrication', 'Mélange à sec', false, 1);
end $$;
