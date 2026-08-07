-- ============================================================
-- AkoraHub - Patch Phase 106 : fiches Académie pour 9 des 22 produits
-- d'origine de la catégorie "Épaississants" — contenu DeepSeek,
-- vérifié par l'utilisatrice. CMC appliqué à ses 3 variantes catalogue.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  r record;
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Agar-Agar (E406)
  -- ------------------------------------------------------------
  v_material_id := '1b6420cf-87d2-4aa4-aebf-d3b39fd7fd55'::uuid;

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
    'Agarose (polymère de galactose)',
    'Agar-agar, E406, gélose, agar',
    'Alimentaire',
    'Poudre blanche à crème, fine, inodore',
    '6-7 (solution à 1,5 % avant chauffage)',
    'Insoluble à froid, se dissout complètement dans l''eau bouillante (95-100 °C) et forme un gel ferme et cassant en refroidissant (35-45 °C)',
    0.80, null,
    'Gélifiant le plus puissant parmi les polysaccharides naturels ; le gel est thermoréversible mais avec une grande hystérésis (fond vers 85 °C, gélifie vers 38 °C). Résiste aux enzymes protéolytiques.',
    'Comparé à la gélatine, l''agar-agar donne un gel plus ferme, plus cassant, qui ne fond pas à température ambiante et convient aux régimes végétariens/véganes. Gélifie à plus haute température que les carraghénanes.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire ; masque anti-poussière recommandé pour les manipulations de grands volumes.',
    'Yeux : rincer à l''eau. Peau : laver. Ingestion sans danger.',
    'Milieux très acides (pH < 4) : hydrolyse partielle, perte de pouvoir gélifiant. Oxydants forts.',
    'Récipient étanche, au sec, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Gélifiant pour desserts, gelées, flans',
   'Disperser la poudre dans le liquide froid, porter à ébullition 1-2 min, verser dans les moules et laisser refroidir pour gélifier.',
   'plage', 0.5, 2, '% du poids du liquide', '95-100 °C (dissolution)', 'Refroidissement 1-2 h', false, 0),
  (v_academie_id, 'Milieu de culture microbien (laboratoire artisanal)',
   'Dissoudre 1,5 % d''agar dans le bouillon nutritif, stériliser à l''autoclave (121 °C, 15 min), couler en boîtes de Petri.',
   'valeur_unique', 1.5, null, '% du bouillon', '95-100 °C', '15-20 min de stérilisation', false, 1);

  -- ------------------------------------------------------------
  -- Amidon modifié (E1400–E1452)
  -- ------------------------------------------------------------
  v_material_id := '9a120f1d-5ab8-4e43-bbee-514ee345db43'::uuid;

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
    'Amidon modifié (réticulé et/ou substitué) ((C₆H₁₀O₅)n modifié)',
    'E1400–E1452, amidon transformé, amidon stabilisé, amidon réticulé',
    'Alimentaire',
    'Poudre blanche fine, inodore',
    '5-7 (dispersion à 10 %)',
    'Dispersible dans l''eau froide (prégélatinisé) ou nécessite chauffage (60-90 °C) selon le type ; résiste à la chaleur, à l''acidité et au cisaillement',
    0.65, null,
    'Densité apparente de la poudre. A subi des traitements physiques ou chimiques pour résister aux conditions extrêmes (stérilisation, congélation, pH acide). Contrairement à l''amidon natif, il ne rétrograde pas.',
    'Par rapport à l''amidon natif, supporte la congélation/décongélation sans synérèse, résiste à la stérilisation UHT et donne des textures plus stables. Comparé à la gomme xanthane, apporte plus de corps et de texture fondante.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. Masque anti-poussière recommandé.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
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
  (v_academie_id, 'Stabilisant de sauces et crèmes dessert UHT',
   'Disperser 2-4 % dans la préparation froide, chauffer progressivement jusqu''à épaississement, stériliser si nécessaire.',
   'plage', 2, 4, '% du produit fini', '70-90 °C', '5-10 min de cuisson', false, 0),
  (v_academie_id, 'Texturant pour yaourts et produits laitiers',
   'Incorporer 0,5-1,5 % dans le lait avant pasteurisation, agiter jusqu''à épaississement.',
   'plage', 0.5, 1.5, '% du lait', '85-90 °C (pasteurisation)', '15-20 min', false, 1);

  -- ------------------------------------------------------------
  -- Amidon natif (maïs, tapioca, pomme de terre)
  -- ------------------------------------------------------------
  v_material_id := '563b90e2-4837-45a6-b0ec-9804bd4863ba'::uuid;

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
    'Amylose / amylopectine (mélange naturel) ((C₆H₁₀O₅)n)',
    'Amidon natif, fécule de maïs, fécule de tapioca, fécule de pomme de terre',
    'Alimentaire',
    'Poudre blanche très fine, soyeuse au toucher, inodore',
    '5-7 (dispersion à 10 %)',
    'Insoluble dans l''eau froide ; se disperse et gonfle à chaud (60-80 °C) pour former un empois visqueux. Rétrograde en refroidissant (surtout le maïs).',
    0.60, null,
    'Densité apparente de la poudre. Principal épaississant culinaire. Chaque origine botanique donne des propriétés différentes : maïs (gel ferme, rétrograde), tapioca (gel neutre, élastique), pomme de terre (viscosité élevée, transparent).',
    'Contrairement à l''amidon modifié, ne supporte pas la congélation ni les pH très acides. Par rapport à la gomme xanthane, nécessite une cuisson et donne une texture plus courte et plus opaque.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. Masque anti-poussière recommandé.',
    'Yeux : rincer. Peau : laver.',
    'Acides forts à chaud (hydrolyse).',
    'Récipient étanche, au sec, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Épaississant pour sauces, soupes, crèmes dessert',
   'Délayer 10-20 g de fécule dans un peu d''eau froide, verser dans le liquide chaud, porter à ébullition 1-2 min jusqu''à épaississement.',
   'plage', 1, 3, '% du liquide', '80-100 °C', '1-2 min d''ébullition', false, 0),
  (v_academie_id, 'Liant pour biscuits et pâtisseries sans gluten',
   'Incorporer 10-20 % de fécule dans le mélange de farines sans gluten pour améliorer la texture et la cohésion.',
   'plage', 10, 20, '% du mélange de farines', 'Variable selon cuisson', 'Pendant le pétrissage', false, 1);

  -- ------------------------------------------------------------
  -- Carraghénanes (E407)
  -- ------------------------------------------------------------
  v_material_id := 'b7514b06-456e-40a7-b179-dd8baa35cb27'::uuid;

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
    'Carraghénane (iota, kappa, lambda) ((C₁₂H₁₈O₉)n sulfaté)',
    'E407, carraghénine, mousse d''Irlande',
    'Alimentaire',
    'Poudre blanche à crème, fine, inodore',
    '7-8 (dispersion à 1 %)',
    'Soluble dans l''eau chaude (70-80 °C). Le type kappa forme un gel ferme et cassant avec les ions potassium ; iota donne un gel mou et élastique avec le calcium ; lambda ne gélifie pas (épaississant).',
    0.80, null,
    'Famille de polysaccharides extraits d''algues rouges. Très utilisés en combinaison avec la gomme de caroube (synergie kappa/LBG) pour des gels élastiques.',
    'Contrairement à l''agar-agar, gélifient à plus basse température et donnent des gels plus élastiques et moins cassants. Par rapport à la gélatine, végétaux et résistent mieux à la chaleur.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. Masque anti-poussière recommandé.',
    'Yeux : rincer. Peau : laver.',
    'Milieux très acides (pH < 3,5) : hydrolyse partielle. Cations potassium (kappa) ou calcium (iota) : gélification.',
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
  (v_academie_id, 'Gélifiant pour flans, crèmes dessert, panna cotta végétale',
   'Disperser 0,5-1,5 % de kappa-carraghénane dans le liquide froid, chauffer à 80 °C, ajouter du potassium si nécessaire, refroidir pour gélifier.',
   'plage', 0.5, 1.5, '% du liquide', '80 °C (dissolution)', 'Refroidissement 1-2 h', false, 0),
  (v_academie_id, 'Stabilisant de crème glacée (anti-cristallisation)',
   'Utiliser 0,1-0,3 % en mélange avec d''autres gommes (LBG, guar), disperser à chaud dans le lait.',
   'valeur_unique', 0.2, null, '% du mix glace', '80-85 °C', 'Pasteurisation 10 min', false, 1);

  -- ------------------------------------------------------------
  -- CMC — 3 variantes catalogue
  -- ------------------------------------------------------------
  for r in
    select * from (values
      ('6e649097-339d-4c3c-85e1-d6df91393131'::uuid), -- CMC
      ('7323d49d-fbc5-4a07-9f5a-915d295bf71f'::uuid), -- CMC / Carboxyméthylcellulose (E466) — Tylose
      ('5488423d-b125-48d8-9d0c-6e20ba770439'::uuid)  -- CMC alimentaire (stabilisation tartrique vin)
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
      'Carboxyméthylcellulose sodique ((C₈H₁₁NaO₇)n)',
      'CMC, E466, gomme cellulosique, CMC sodique',
      'Alimentaire',
      'Poudre blanche à crème, fine, hygroscopique',
      '6-7,5 (solution à 1 %)',
      'Soluble dans l''eau froide ou chaude, forme une solution visqueuse stable. Insoluble dans les solvants organiques.',
      0.75, null,
      'Densité apparente de la poudre. Épaississant cellulosique le plus économique et le plus utilisé. Disponible en différentes viscosités. Bonne stabilité en milieu acide.',
      'Comparée aux gommes guar et xanthane, moins chère et plus stable en milieu acide. Par rapport à l''HPMC et la méthylcellulose, soluble à froid et ne gélifie pas à chaud.',
      'Aucun',
      array['masque'],
      'Porter un masque anti-poussière lors de la manipulation de grandes quantités de poudre fine.',
      'Yeux : rincer à l''eau. Peau : laver. Inhalation : air frais.',
      'Cations polyvalents (calcium, magnésium) : peut réduire la viscosité ou précipiter. Oxydants forts.',
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
    (v_academie_id, 'Épaississant pour détergents liquides (liquide vaisselle, lessive)',
     'Disperser 0,5-2 % de CMC dans l''eau sous agitation, laisser hydrater 1-2 h, puis incorporer les tensioactifs.',
     'plage', 0.5, 2, '% du produit fini', '20-30 °C', '1-2 h d''hydratation', false, 0),
    (v_academie_id, 'Stabilisant de boissons et sauces',
     'Disperser 0,1-0,3 % dans le liquide, agiter jusqu''à dissolution complète.',
     'valeur_unique', 0.2, null, '% du produit', 'Ambiante ou tiède', '30 min d''hydratation', false, 1);
  end loop;

  -- ------------------------------------------------------------
  -- Gélatine alimentaire en poudre (200 Bloom)
  -- ------------------------------------------------------------
  v_material_id := 'be7efc2c-3917-48cb-9a84-4bf09e8429e6'::uuid;

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
    'Protéine animale hydrolysée (collagène de type I principalement)',
    'Gélatine, gélatine en poudre, gélatine 200 Bloom, E441',
    'Alimentaire',
    'Poudre granuleuse blanche à jaune pâle, ou feuilles, inodore',
    '5-6 (solution à 1 %)',
    'Gonfle dans l''eau froide, se dissout dans l''eau chaude (> 50 °C). Forme un gel thermoréversible qui fond vers 30-35 °C.',
    0.40, null,
    'Densité apparente de la poudre. Le pouvoir gélifiant est mesuré en degrés Bloom (200 Bloom = gel standard). Fond dans la bouche, donnant une sensation unique et agréable.',
    'Comparée à l''agar-agar, donne un gel élastique et fondant à température corporelle, idéal pour les desserts. D''origine animale, contrairement aux gommes végétales.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. Masque anti-poussière optionnel.',
    'Yeux : rincer à l''eau. Peau : laver. Ingestion sans danger.',
    'Enzymes protéolytiques (ananas, kiwi, papaye) : hydrolyse et perte de gélification. Acides forts prolongés. Formaldéhyde (tanne la gélatine).',
    'Récipient étanche, au frais et au sec, à l''abri des odeurs.',
    5, 25, true, false, 36, 'a_valider'
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
  (v_academie_id, 'Gélifiant pour mousses, bavarois, gelées',
   'Faire gonfler la poudre dans 5-6 fois son poids d''eau froide (10-15 min), chauffer doucement jusqu''à dissolution complète (60 °C), incorporer à la préparation froide et réfrigérer.',
   'plage', 2, 8, '% du liquide total', '60 °C (dissolution)', 'Réfrigération 4-6 h', false, 0),
  (v_academie_id, 'Agent de collage en brasserie artisanale',
   'Dissoudre 10-30 g de gélatine pour 100 L de bière dans de l''eau tiède, incorporer à la bière froide en fermentation, laisser sédimenter les levures et les troubles.',
   'plage', 10, 30, 'g par 100 L de bière', '5-15 °C (bière froide)', '24-48 h de sédimentation', true, 1);

  -- ------------------------------------------------------------
  -- Glycérine / Glycérol alimentaire (E422)
  -- ------------------------------------------------------------
  v_material_id := '428034db-1597-4960-b52f-479a68e83ec8'::uuid;

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
    'Propane-1,2,3-triol (C₃H₈O₃)',
    'Glycérine, glycérol, glycérol végétal, E422',
    'Alimentaire',
    'Liquide sirupeux incolore, inodore, légèrement sucré',
    '6-7 (solution à 10 %)',
    'Totalement miscible à l''eau et à l''alcool ; hygroscopique',
    1.26, 199,
    'Densité de la glycérine pure à 99,5 %. Humectant et plastifiant puissant, retient l''eau et assouplit les textures. Point d''éclair très élevé, non inflammable à température ambiante.',
    'Comparée au sorbitol, plus hygroscopique et donne une sensation plus humide. Par rapport au propylène glycol, moins fluide, plus douce et d''origine naturelle.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter le contact prolongé avec la peau (effet déshydratant à l''état pur).',
    'Yeux : rincer à l''eau. Peau : laver. Ingestion sans danger à faible dose (effet laxatif à haute dose).',
    'Oxydants forts (acide nitrique, permanganate de potassium) : réaction exothermique violente. Acide sulfurique concentré : formation d''acroléine toxique.',
    'Bidon en PEHD bien fermé, à température ambiante, à l''abri de l''humidité (très hygroscopique). Éviter de stocker près de forts oxydants.',
    10, 30, true, false, 36, 'a_valider'
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
  (v_academie_id, 'Humectant et plastifiant en cosmétique (crèmes, lotions, dentifrice)',
   'Ajouter 2-5 % dans la phase aqueuse pour améliorer l''hydratation et assouplir la texture.',
   'plage', 2, 5, '% du produit fini', '20-30 °C', 'Incorporation immédiate', false, 0),
  (v_academie_id, 'Agent de texture en pâtisserie (fondant, glaçage royal)',
   'Ajouter 1-3 % dans le fondant ou le glaçage pour éviter le dessèchement et garder une texture souple.',
   'valeur_unique', 2, null, '% du poids du sucre', 'Ambiante', 'Pendant le mélange', false, 1);

  -- ------------------------------------------------------------
  -- Gomme arabique (E414)
  -- ------------------------------------------------------------
  v_material_id := 'ca3e6f2c-3b53-4727-9188-25777c7f61d9'::uuid;

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
    'Polysaccharide complexe ramifié (arabinogalactane-protéine)',
    'Gomme arabique, E414, gomme d''acacia',
    'Alimentaire',
    'Poudre blanche à crème, ou nodules translucides, inodore',
    '4,5-5 (solution à 10 %)',
    'Très soluble dans l''eau (jusqu''à 50 %), même à froid. Forme une solution peu visqueuse, même à haute concentration. Faible pouvoir épaississant.',
    0.70, null,
    'Agent émulsifiant et stabilisant de choix pour les émulsions d''huiles essentielles dans l''eau. Seule gomme utilisable à très haute concentration (30-50 %) sans former un gel épais.',
    'Contrairement à la gomme guar ou à la CMC, excellent émulsifiant et ne donne pas de texture visqueuse. Par rapport à la gomme adragante, plus soluble et moins visqueuse.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. Masque anti-poussière recommandé pour les manipulations de grands volumes.',
    'Yeux : rincer. Peau : laver.',
    'Cations polyvalents (calcium, magnésium) : peuvent provoquer une précipitation ou une perte de solubilité. Oxydants forts.',
    'Récipient étanche, au sec, à l''abri de la chaleur et des odeurs.',
    5, 25, true, false, 48, 'a_valider'
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
  (v_academie_id, 'Émulsifiant pour boissons aromatisées (sirops, sodas)',
   'Dissoudre 10-20 % de gomme arabique dans l''eau, ajouter l''huile essentielle, homogénéiser vigoureusement pour former une émulsion stable.',
   'valeur_unique', 15, null, '% de l''émulsion finale', '20-30 °C', '15-30 min d''homogénéisation', false, 0),
  (v_academie_id, 'Enrobage protecteur en confiserie (gommes, bonbons)',
   'Préparer une solution à 30-40 % de gomme arabique, enrober les bonbons par trempage ou pulvérisation, sécher à l''air chaud.',
   'valeur_unique', 35, null, '% de la solution d''enrobage', '40-50 °C (séchage)', 'Plusieurs heures de séchage', false, 1);

  -- ------------------------------------------------------------
  -- Gomme guar (E412)
  -- ------------------------------------------------------------
  v_material_id := '65204732-9e1c-4558-b2e7-a07d9e029a45'::uuid;

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
    'Galactomannane de guar ((C₆H₁₀O₅)n)',
    'Gomme guar, E412, farine de guar',
    'Alimentaire',
    'Poudre blanche à crème, fine, inodore',
    '6-7 (dispersion à 1 %)',
    'Soluble dans l''eau froide, forme une solution très visqueuse. S''hydrate rapidement, parfois avec formation de grumeaux si mal dispersée.',
    0.80, null,
    'Épaississant naturel le plus économique, développe une viscosité élevée à froid sans chauffage. Synergie avec la gomme xanthane.',
    'Comparée à la gomme de caroube (LBG), s''hydrate à froid et donne des solutions plus visqueuses mais moins élastiques. Moins chère que la xanthane mais donne des textures plus gluantes.',
    'Aucun',
    array['masque'],
    'Porter un masque anti-poussière pour éviter l''inhalation de la poudre fine.',
    'Yeux : rincer à l''eau. Peau : laver. Ingestion : boire de l''eau (la gomme gonfle dans l''estomac).',
    'Cations polyvalents (calcium, magnésium) : perte de viscosité. Oxydants forts.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Épaississant pour cosmétiques (shampoings, gels douche)',
   'Disperser 0,5-1,5 % dans l''eau sous agitation, laisser hydrater 30-60 min, puis ajouter les tensioactifs. Prémélanger avec de la glycérine pour éviter les grumeaux.',
   'plage', 0.5, 1.5, '% du produit fini', '20-30 °C', '30-60 min d''hydratation', false, 0),
  (v_academie_id, 'Stabilisant de glaces et sorbets',
   'Mélanger 0,2-0,5 % de gomme guar avec le sucre sec, disperser dans le lait froid, chauffer pour pasteuriser, refroidir et turbiner.',
   'valeur_unique', 0.3, null, '% du mix glace', '85 °C (pasteurisation)', '10 min de chauffage', false, 1);
end $$;
