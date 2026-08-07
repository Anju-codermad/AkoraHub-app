-- ============================================================
-- AkoraHub - Patch Phase 100 : fiches Académie pour les 11 nouveaux
-- désinfectants — contenu DeepSeek, vérifié par l'utilisatrice.
-- Termine la catégorie "Désinfectants" (16/16, en comptant les 5
-- produits déjà présents avant cette campagne, non traités ici).
--
-- Note : certains codes H suggérés par DeepSeek (H400, H410, H330,
-- H331, H334, H336, H372) peuvent être absents du seed phase86
-- (phrases rares/environnementales) — inserts conditionnels, ne
-- bloquent pas si absents.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Chlorure de benzalkonium (BAC)
  -- ------------------------------------------------------------
  v_material_id := '09130042-2c9c-45ff-be74-b79621894858'::uuid;

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
    'Chlorure de benzalkonium (mélange d''alkylbenzyldiméthylammonium, C8-C18)',
    'BAC, BKC, chlorure d''alkyldiméthylbenzylammonium, Quat',
    'Technique',
    'Liquide visqueux incolore à jaune pâle (solution aqueuse à 50 % ou 80 %)',
    '6-8 (solution à 1 %)',
    'Totalement miscible à l''eau, moussant',
    0.98, null,
    'Densité de la solution commerciale à 50 %. Tensioactif cationique à fort pouvoir mouillant ; bonne rémanence sur les surfaces, actif même après séchage. Inactivé par les savons anioniques.',
    'Par rapport au DDAC, le BAC est plus moussant et plus utilisé dans les usages domestiques et institutionnels. Contrairement à l''eau de Javel, il n''est pas corrosif et reste actif plus longtemps, mais est inefficace sur les spores.',
    'Corrosif',
    array['gants','lunettes','tablier'],
    'Gants en nitrile ou néoprène, lunettes de sécurité étanches, éviter le contact prolongé avec la peau (irritant).',
    'Peau : rincer 15 min, retirer vêtements. Yeux : rincer 15 min, consulter. Ingestion : rincer la bouche, ne pas faire vomir, boire de l''eau, appeler un médecin. Inhalation : air frais.',
    'Tensioactifs anioniques (savons, SDS), acides forts, oxydants puissants, eau de Javel.',
    'Bidon en PEHD bien fermé, à l''abri du gel et des températures supérieures à 40 °C. Ne pas mélanger avec des détergents anioniques dans le même bidon.',
    5, 35, false, false, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H314', 'H400')
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
  (v_academie_id, 'Désinfection des surfaces (sols, murs, mobilier)',
   'Diluer à 0,5-2 % dans l''eau, appliquer au balai ou au chiffon, laisser agir 5 min, rincer si contact alimentaire.',
   'plage', 0.5, 2, '% de solution commerciale (50 %)', 'Ambiante', '5-10 min', false, 0),
  (v_academie_id, 'Désinfection en agroalimentaire (surfaces, matériel)',
   'Diluer à 0,1-0,5 %, appliquer par pulvérisation ou trempage, laisser agir 5-15 min, rincer soigneusement à l''eau potable.',
   'plage', 0.1, 0.5, '% de solution commerciale (50 %)', '20-40 °C', '5-15 min', true, 1),
  (v_academie_id, 'Traitement anti-algues et désinfection piscine',
   'Verser la dose préconisée dans le bassin, filtration en marche.',
   'valeur_unique', 10, null, 'L de solution à 10 % pour 50 m³ d''eau', 'Ambiante', '24-48 h', true, 2);

  -- ------------------------------------------------------------
  -- Chlorure de didecyldiméthylammonium (DDAC)
  -- ------------------------------------------------------------
  v_material_id := 'a55624d6-dd20-4fcf-978c-0e16af262aa3'::uuid;

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
    'Chlorure de didecyldiméthylammonium (C₂₂H₄₈ClN)',
    'DDAC, Quat DDAC',
    'Technique',
    'Liquide visqueux incolore à jaune très pâle (solution à 50 % ou 80 %)',
    '6-8 (solution à 1 %)',
    'Totalement miscible à l''eau, peu moussant',
    0.93, null,
    'Densité de la solution à 50 %. Ammonium quaternaire peu moussant, spécialisé pour les formulations professionnelles où la mousse est indésirable (CIP, pulvérisation).',
    'Moins moussant que le BAC, il est préféré en agroalimentaire et en élevage pour éviter les résidus de mousse. Spectre biocide similaire mais meilleure activité sur les levures.',
    'Corrosif',
    array['gants','lunettes','tablier'],
    'Gants nitrile, lunettes étanches, éviter les éclaboussures.',
    'Peau : rincer 15 min. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas faire vomir, boire de l''eau, médecin. Inhalation : air frais.',
    'Tensioactifs anioniques, acides forts, eau de Javel.',
    'Bidon en PEHD fermé, à l''abri du gel. Ne pas mélanger avec des produits incompatibles.',
    5, 40, false, false, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H314', 'H410')
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
  (v_academie_id, 'Désinfection en élevage (bâtiments, matériel)',
   'Diluer à 0,5-1 %, appliquer par pulvérisation sur les surfaces préalablement nettoyées, laisser agir, rincer si nécessaire.',
   'plage', 0.5, 1, '% de solution commerciale (50 %)', 'Ambiante à 40 °C', '15-30 min', true, 0),
  (v_academie_id, 'Nettoyage en place (CIP) désinfectant',
   'Après la phase de nettoyage alcalin et rinçage, faire circuler une solution à 0,2-0,5 % de DDAC.',
   'valeur_unique', 0.3, null, '% de solution (50 %)', '20-40 °C', '15-20 min', true, 1);

  -- ------------------------------------------------------------
  -- PHMB (polyhexaméthylène biguanide)
  -- ------------------------------------------------------------
  v_material_id := '160acde6-fa07-4b58-aa42-00c0846b0f3a'::uuid;

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
    'Polyhexaméthylène biguanide ((C₈H₁₆N₅Cl)n)',
    'PHMB, polyhexanide, Baquacil, Vantocil',
    'Technique',
    'Liquide clair incolore à jaune très pâle (solution à 20 %)',
    '5-6 (solution à 1 %)',
    'Totalement miscible à l''eau',
    1.04, null,
    'Densité de la solution à 20 %. Polymère cationique à large spectre, non oxydant, non irritant aux doses d''usage pour les piscines.',
    'Contrairement au chlore ou au brome, le PHMB ne dégage pas d''odeur, n''irrite pas les yeux et ne se dégrade pas avec les UV ; idéal pour les piscines sans chlore. Moins efficace contre les virus que le chlore.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité, éviter le contact avec les yeux à l''état concentré.',
    'Yeux : rincer 15 min. Peau : laver à l''eau. Ingestion : rincer la bouche, boire de l''eau, consulter un médecin si des symptômes apparaissent.',
    'Tensioactifs anioniques, acides forts, oxydants puissants (chlore, brome).',
    'Bidon en PEHD, à l''abri du gel, température ambiante stable.',
    5, 35, false, false, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H319', 'H410')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P270', 'P273', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Traitement piscine sans chlore',
   'Verser directement dans le bassin filtration en marche. Renouveler toutes les 1 à 2 semaines.',
   'plage', 5, 10, 'mL de solution à 20 % par m³ d''eau', 'Ambiante', 'Action permanente', false, 0),
  (v_academie_id, 'Désinfection des surfaces (industrie, agroalimentaire)',
   'Appliquer une solution diluée à 0,1-0,5 % sur les surfaces propres, laisser agir puis rincer si nécessaire.',
   'plage', 0.1, 0.5, '% de solution commerciale (20 %)', 'Ambiante', '5-15 min', true, 1);

  -- ------------------------------------------------------------
  -- Éthanol 96° (alcool éthylique)
  -- ------------------------------------------------------------
  v_material_id := '4b9f7ce0-93b8-4528-9f70-6c0581dd32c3'::uuid;

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
    'Éthanol (C₂H₅OH)',
    'Alcool éthylique, alcool à 96°, éthanol dénaturé',
    'Technique',
    'Liquide incolore, mobile, odeur caractéristique',
    '7 (neutre)',
    'Totalement miscible à l''eau',
    0.79, 13,
    'Densité de l''alcool pur. Désinfectant à large spectre (bactéricide, virucide sur virus enveloppés). Optimal entre 60 et 70 % (v/v) ; inefficace sur les spores. Très inflammable.',
    'Par rapport à l''isopropanol, l''éthanol est moins gras et plus adapté aux gels hydroalcooliques pour les mains. Contrairement à l''eau de Javel, il ne tache pas et ne dégage pas de vapeurs toxiques, mais il est inactif sur le virus de l''hépatite.',
    'Élevé',
    array['gants','lunettes','ventilation'],
    'Gants résistants aux solvants (nitrile), lunettes de sécurité, travailler loin des flammes et sources de chaleur, ventilation adéquate.',
    'Peau : laver à l''eau. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas faire vomir. Inhalation : air frais. En cas d''incendie : CO₂, poudre, mousse.',
    'Oxydants forts, acides forts, bases fortes.',
    'Local ventilé, à l''écart des flammes et sources de chaleur, dans un récipient en acier inoxydable ou PEHD.',
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

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H225', 'H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P233', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Gel hydroalcoolique (désinfection des mains)',
   'Mélanger 70 % d''éthanol 96°, 0,5-1 % d''épaississant (carbomer), ajuster le pH avec triéthanolamine, ajouter eau qsp 100 %.',
   'valeur_unique', 70, null, '% d''éthanol 96° (soit 67 % d''alcool pur)', 'Ambiante', 'Quelques secondes de friction', false, 0),
  (v_academie_id, 'Désinfection de surfaces propres',
   'Pulvériser l''éthanol à 70 % sur la surface, laisser agir 1-5 min, essuyer avec un chiffon propre.',
   'valeur_unique', 70, null, '% (v/v)', 'Ambiante', '1-5 min', false, 1);

  -- ------------------------------------------------------------
  -- Isopropanol (IPA)
  -- ------------------------------------------------------------
  v_material_id := 'bd90ae09-0aad-43b7-b6cc-c8c633627b16'::uuid;

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
    'Isopropanol (C₃H₈O)',
    'Alcool isopropylique, IPA, propan-2-ol',
    'Technique',
    'Liquide incolore, odeur d''alcool',
    '7 (neutre)',
    'Totalement miscible à l''eau',
    0.79, 12,
    'Densité de l''alcool pur. Excellent dégraissant et désinfectant. Optimal à 70 % (v/v). Évaporation rapide sans résidu, utilisé pour le nettoyage électronique.',
    'Par rapport à l''éthanol, il dégraisse mieux mais est plus toxique et ne doit pas être utilisé pour les gels hydroalcooliques pour les mains.',
    'Élevé',
    array['gants','lunettes','ventilation'],
    'Gants résistants aux solvants (nitrile), lunettes de sécurité, manipuler loin des flammes.',
    'Yeux : rincer. Peau : laver. Ingestion : rincer la bouche, ne pas vomir, appeler un médecin. Inhalation : air frais, consulter si gêne.',
    'Oxydants forts, acides forts.',
    'Bidon en métal ou PEHD, local ventilé, à l''écart des flammes.',
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

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H225', 'H319', 'H336')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P233', 'P261', 'P280')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Nettoyage électronique (circuits imprimés, contacts)',
   'Appliquer l''IPA pur ou à 90 % avec un chiffon non pelucheux ou un spray, laisser sécher à l''air.',
   'valeur_unique', 90, null, '% (v/v)', 'Ambiante', 'Quelques secondes', false, 0),
  (v_academie_id, 'Désinfectant de surfaces industrielles',
   'Appliquer une solution à 70 %, laisser agir 5 min, essuyer.',
   'valeur_unique', 70, null, '% (v/v)', 'Ambiante', '5 min', false, 1);

  -- ------------------------------------------------------------
  -- BCDMH (brome piscine/SPA)
  -- ------------------------------------------------------------
  v_material_id := 'c4094414-0916-47a2-a9f0-6e4f2fc5e40c'::uuid;

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
    'Bromo-1-chloro-5,5-diméthylhydantoïne (C₅H₆BrClN₂O₂)',
    'BCDMH, pastilles de brome, bromo-chloro-diméthylhydantoïne',
    'Technique',
    'Pastilles ou granulés blancs à légèrement jaunâtres, odeur caractéristique de brome',
    'Acide (se décompose lentement dans l''eau en libérant HOBr et HOCl)',
    'Peu soluble dans l''eau (0,2 g/100 mL), dissolution lente contrôlée',
    1.90, null,
    'Désinfectant mixte brome/chlore à dissolution lente, idéal pour un traitement continu de l''eau. Plus stable que le chlore à chaud (spas, jacuzzis).',
    'Contrairement au TCCA (pastilles de chlore stabilisé), le BCDMH libère du brome, moins irritant, moins odorant et plus actif à pH élevé. Il est préféré pour les spas.',
    'Élevé',
    array['gants','lunettes','masque'],
    'Gants résistants aux produits chimiques, lunettes étanches, masque anti-poussière, éviter le contact avec les acides.',
    'Peau : rincer 15 min. Yeux : rincer 15 min, consulter. Ingestion : rincer la bouche, ne pas vomir, boire de l''eau, médecin. Inhalation : air frais.',
    'Acides, bases fortes, matières organiques, produits chlorés concentrés.',
    'Récipient étanche dans un local frais, sec et bien ventilé. Ne jamais stocker à proximité d''acides ou de matières combustibles.',
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
  select v_academie_id, id from public.phrases_h where code in ('H272', 'H302', 'H314', 'H400')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P260', 'P280', 'P301+P330+P331', 'P303+P361+P353', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, unite_dosage, temperature_utilisation, temps_action,
    a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Traitement désinfectant de l''eau de piscine / SPA',
   'Placer les pastilles dans un doseur flottant ou un brominateur. Maintenir un taux de brome actif entre 2 et 5 ppm.',
   'valeur_unique', 20, 'g de pastilles par 1000 L d''eau (entretien)', 'Ambiante à 40 °C (spa)', 'Diffusion lente (plusieurs jours)', false, 0);

  -- ------------------------------------------------------------
  -- Dioxyde de chlore (kit chlorite de sodium + activateur)
  -- ------------------------------------------------------------
  v_material_id := '7549c713-48c3-4eef-8955-7f3dc39083e6'::uuid;

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
    'Dioxyde de chlore, solution stabilisée (ClO₂)',
    'Chlorine dioxide, kit activable (chlorite de sodium + acide)',
    'Technique',
    'Liquide clair jaune verdâtre (solution stabilisée à 5 % ou générée in situ)',
    '3-5 (solution activée)',
    'Très soluble dans l''eau (se présente sous forme de gaz dissous)',
    1.02, null,
    'Densité de la solution stabilisée à 5 %. Biocide gazeux dissous extrêmement efficace contre les biofilms, les virus et les spores. Ne forme pas de sous-produits chlorés toxiques (THM).',
    'Plus oxydant que l''eau de Javel, il ne réagit pas avec l''ammoniac et ne génère pas de chloramines malodorantes. Il doit être généré sur place ou conservé en solution acide stabilisée.',
    'Corrosif',
    array['gants','lunettes','ventilation','masque'],
    'Gants nitrile, lunettes étanches, masque à gaz pour les vapeurs de chlore si manipulation de grands volumes.',
    'Inhalation : air frais, consulter immédiatement. Peau : rincer 15 min, retirer vêtements. Yeux : rincer 15 min, consulter. Ingestion : rincer la bouche, ne pas vomir, médecin.',
    'Matières organiques, acides concentrés, bases, métaux.',
    'Stocker la solution mère au frais, à l''abri de la lumière, dans un local ventilé.',
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
  select v_academie_id, id from public.phrases_h where code in ('H314', 'H330', 'H400')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P260', 'P280', 'P284', 'P301+P330+P331', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Désinfection de l''eau potable (réseaux, réservoirs)',
   'Injecter une solution activée pour obtenir une concentration résiduelle de 0,2 à 0,5 ppm dans l''eau à traiter.',
   'plage', 0.2, 0.5, 'g/m³ (ppm)', 'Ambiante', '30 min minimum', true, 0),
  (v_academie_id, 'Désinfection de surfaces en agroalimentaire',
   'Appliquer une solution à 5-10 ppm par pulvérisation ou circulation, sans rinçage dans certains cas réglementés.',
   'valeur_unique', 10, null, 'ppm (mg/L)', '20-30 °C', '5-10 min', true, 1);

  -- ------------------------------------------------------------
  -- Glutaraldéhyde 50%
  -- ------------------------------------------------------------
  v_material_id := '89964114-c15b-4aa9-a4cb-f2bec519ac11'::uuid;

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
    'Glutaraldéhyde (C₅H₈O₂)',
    'Glutaral, pentane-1,5-dial',
    'Technique',
    'Liquide clair incolore à jaune pâle (solution à 50 %), odeur piquante',
    '3-4 (solution concentrée) ; 7-8 (solution activée au bicarbonate)',
    'Totalement miscible à l''eau',
    1.13, null,
    'Densité de la solution à 50 %. Aldéhyde très réactif, l''un des rares désinfectants sporicides à froid. Doit être "activé" (pH alcalin) pour une efficacité optimale.',
    'Par rapport aux QUATs ou aux aldéhydes plus simples, il est sporicide. Il est plus toxique que le PHMB mais plus efficace pour la stérilisation de matériel.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Gants en caoutchouc butyle, écran facial, masque filtrant pour vapeurs organiques (type A), travailler sous hotte.',
    'Inhalation : air frais, consulter. Peau : rincer 15 min, retirer vêtements. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas vomir, médecin.',
    'Bases fortes (activation), acides, oxydants.',
    'Local frais et ventilé, récipient étanche en plastique, à l''écart des aliments. La solution activée se dégrade en quelques jours.',
    5, 25, false, false, 12, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H314', 'H331', 'H334', 'H400')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P260', 'P280', 'P284', 'P301+P330+P331', 'P304+P340', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, unite_dosage, temperature_utilisation, temps_action,
    a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Stérilisation à froid du matériel (médical, vétérinaire)',
   'Diluer à 2 % (4 mL de solution à 50 % pour 96 mL d''eau), activer avec un agent alcalin (bicarbonate 0,3 %), immerger le matériel propre 10 à 30 min.',
   'valeur_unique', 2, '% de produit pur (4 % de la solution à 50 %)', '20-25 °C', '10-30 min', false, 0);

  -- ------------------------------------------------------------
  -- Chloramine-T
  -- ------------------------------------------------------------
  v_material_id := '1c2d1783-79f8-4589-93f0-85480321f8a6'::uuid;

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
    'Tosylchloramide sodique trihydratée (C₇H₇ClNNaO₂S·3H₂O)',
    'Chloramine-T, chloramine T',
    'Technique',
    'Poudre cristalline blanche à légèrement jaunâtre, légère odeur de chlore',
    '8-9 (solution à 1 %)',
    'Très soluble dans l''eau (15 g/100 mL à 20 °C)',
    1.40, null,
    'Agent de chloration douce libérant lentement du chlore actif (12-13 % de chlore disponible). Moins agressif que l''hypochlorite de sodium.',
    'Par rapport à l''eau de Javel, la Chloramine-T libère le chlore plus lentement, ce qui la rend moins irritante mais aussi moins rapide d''action. Souvent utilisée quand un effet rémanent est souhaité.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en caoutchouc, lunettes de protection, éviter l''inhalation de poussières.',
    'Peau : rincer 15 min. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas vomir, boire de l''eau, médecin. Inhalation : air frais.',
    'Acides, bases fortes, matières organiques, produits chlorés concentrés.',
    'Récipient étanche, au sec, dans un local frais et ventilé, à l''abri de la lumière.',
    5, 25, true, true, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H314', 'H334', 'H410')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P260', 'P280', 'P301+P330+P331', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Désinfection de l''eau (aquaculture, bassins)',
   'Dissoudre la dose nécessaire dans un seau d''eau, répartir uniformément dans le bassin.',
   'plage', 2, 5, 'g/m³ d''eau', 'Ambiante', 'Action lente, plusieurs heures', true, 0),
  (v_academie_id, 'Désinfectant de surfaces pour laboratoire / milieu médical',
   'Préparer une solution à 0,1-0,5 %, laver ou essuyer les surfaces, laisser agir puis rincer.',
   'plage', 0.1, 0.5, '% (m/v) dans l''eau', 'Ambiante', '10-15 min', false, 1);

  -- ------------------------------------------------------------
  -- Nitrate d'argent (AgNO₃)
  -- ------------------------------------------------------------
  v_material_id := 'b7daf3ea-4bc4-4a29-beb5-99ab02b47a94'::uuid;

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
    'Nitrate d''argent (AgNO₃)',
    'Pierre infernale (usage médical), cristaux d''argent',
    'Technique',
    'Cristaux incolores à blancs, ou poudre cristalline',
    '5-6 (solution à 1 %)',
    'Très soluble (216 g/100 mL à 20 °C)',
    4.35, null,
    'Agent oxydant et biocide à large spectre sous forme d''ions Ag⁺ (effet oligodynamique). Tache la peau et les vêtements en noir sous l''effet de la lumière.',
    'Contrairement aux désinfectants classiques, l''argent n''a pas d''odeur, ne s''évapore pas et est actif à très faible dose. Utilisé en traitement de l''eau de longue durée.',
    'Corrosif',
    array['gants','lunettes'],
    'Gants nitrile, lunettes étanches, éviter absolument le contact avec la peau et les yeux (taches noires et brûlures).',
    'Peau : rincer 15 min (des taches noires peuvent apparaître). Yeux : rincer 15 min, consulter. Ingestion : rincer la bouche, ne pas vomir, boire de l''eau, médecin.',
    'Matières organiques, bases, chlorures (précipitation de AgCl), ammoniaque (formation de composés explosifs).',
    'Flacon en verre brun bien fermé, à l''abri de la lumière, dans un local frais et sec.',
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
  select v_academie_id, id from public.phrases_h where code in ('H272', 'H314', 'H410')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P280', 'P301+P330+P331', 'P303+P361+P353', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Désinfection de l''eau potable (longue conservation)',
   'Préparer une solution mère à 1 %, doser pour obtenir une concentration de 0,01 à 0,1 ppm d''argent dans l''eau à traiter.',
   'plage', 0.01, 0.1, 'g/m³ (ppm)', 'Ambiante', 'Action permanente', true, 0);

  -- ------------------------------------------------------------
  -- Iode cristallisé (I₂)
  -- ------------------------------------------------------------
  v_material_id := '47afda45-1346-4f28-a458-eee9edcfba3d'::uuid;

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
    'Iode (I₂)',
    'Iode, iodine',
    'Technique',
    'Paillettes ou cristaux gris-violet à noir, éclat métallique, odeur caractéristique',
    '5-6 (solution saturée dans l''eau)',
    'Très faible dans l''eau (0,03 g/100 mL), soluble dans l''alcool ou en présence d''iodure de potassium (solution de Lugol)',
    4.93, null,
    'Se sublime à température ambiante en dégageant des vapeurs violettes irritantes. Biocide puissant à large spectre utilisé en solution alcoolique (teinture d''iode) ou en complexe (iodophores).',
    'Par rapport au chlore, l''iode est moins sensible au pH et aux matières organiques, mais il est plus coûteux et peut colorer les surfaces.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Gants résistants aux produits chimiques, lunettes étanches, masque à cartouche pour vapeurs d''iode.',
    'Inhalation : air frais, consulter. Peau : laver à l''eau. Yeux : rincer 15 min. Ingestion : rincer la bouche, boire de l''eau, ne pas faire vomir, appeler un médecin.',
    'Ammoniaque (formation d''iodure d''azote explosif), métaux alcalins, poudres métalliques.',
    'Flacon en verre brun, à l''abri de la lumière et de la chaleur, local ventilé. Ne pas stocker à proximité de l''ammoniaque.',
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
  select v_academie_id, id from public.phrases_h where code in ('H312', 'H332', 'H315', 'H319', 'H372', 'H400')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P260', 'P280', 'P302+P352', 'P304+P340', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_texte, temperature_utilisation, temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Désinfection d''urgence de l''eau de boisson',
   'Préparer une solution de Lugol (iode + iodure de potassium), ajouter 2 à 5 gouttes par litre d''eau claire, agiter et laisser agir 30 min avant de boire.',
   'texte_libre', '5 gouttes de solution de Lugol à 2 % par litre d''eau', 'Ambiante', '30 min', false, 0),
  (v_academie_id, 'Teinture d''iode (antiseptique cutané)',
   'Dissoudre 2 g d''iode et 2,5 g d''iodure de potassium dans 50 mL d''éthanol, compléter à 100 mL avec de l''eau purifiée.',
   'valeur_unique', '2 % d''iode (m/v)', 'Ambiante', 'Application locale', false, 1);
end $$;
