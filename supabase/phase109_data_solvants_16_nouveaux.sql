-- ============================================================
-- AkoraHub - Patch Phase 109 : fiches Académie pour les 16 nouveaux
-- solvants ajoutés en phase 108 — contenu DeepSeek, vérifié par
-- l'utilisatrice.
--
-- Inclut 3 produits sensibles avec grade strict "Technique" et
-- avertissements renforcés (usage encadré, EPI complets, substitution
-- recommandée) : Xylène (reprotoxique), n-Hexane (neurotoxique,
-- restreint REACH), Éther diéthylique (peroxydes explosifs).
--
-- Ne couvre pas encore les 7 produits déjà présents avant cette
-- campagne (Alcool benzylique, Alcool cétylique, Alcool dénaturé,
-- IPA, Éthanol, Méthanol, Propylène glycol).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Acétone (propan-2-one)
  -- ------------------------------------------------------------
  v_material_id := '29e907fa-8f6f-4bbc-a022-d6790a168939'::uuid;

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
    'Propan-2-one (C₃H₆O)',
    'Diméthylcétone, propanone',
    'Technique',
    'Liquide incolore, très fluide, odeur fruitée caractéristique',
    'Neutre (7)',
    'Miscible à l''eau et à la plupart des solvants organiques',
    0.79, -18,
    'Solvant très volatil et très inflammable. Excellente capacité de dissolution des graisses, résines et plastiques. S''évapore sans laisser de résidu.',
    'Plus efficace que l''éthanol pour dissoudre les vernis et résines synthétiques. Plus volatil que la MEK. Incontournable pour le nettoyage de précision et le dissolvant de vernis à ongles.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Gants en caoutchouc butyle ou nitrile, lunettes de sécurité, masque à cartouche pour vapeurs organiques, ventilation adéquate.',
    'Inhalation : air frais. Peau : laver à l''eau. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas faire vomir, appeler un médecin.',
    'Oxydants forts (peroxydes, acide nitrique), bases fortes, chloroforme.',
    'Bidon métallique ou en verre, dans un local frais, sec et très bien ventilé, à l''abri des sources de chaleur et des oxydants.',
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
  (v_academie_id, 'Dégraissant et nettoyant',
   'Appliquer l''acétone pur avec un chiffon ou par trempage. Évacuer les vapeurs. Séchage rapide à l''air.',
   'valeur_unique', 100, null, '% (pur)', 'Ambiante', 'Quelques secondes', false, 0),
  (v_academie_id, 'Dissolvant de vernis à ongles',
   'Imbiber un coton d''acétone, appliquer sur l''ongle, laisser agir quelques secondes, essuyer.',
   'valeur_unique', 100, null, '% (pur ou dilué à 80-90% dans l''eau)', 'Ambiante', '10-20 secondes', false, 1);

  -- ------------------------------------------------------------
  -- Butylène glycol (1,3-butanediol)
  -- ------------------------------------------------------------
  v_material_id := '6b55b999-a36e-42d0-b457-00a83da03f1e'::uuid;

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
    '1,3-butanediol (C₄H₁₀O₂)',
    'BG, butane-1,3-diol',
    'Cosmétique',
    'Liquide incolore, légèrement sirupeux, inodore',
    'Neutre (6-7)',
    'Totalement miscible à l''eau et à l''alcool',
    1.00, 121,
    'Point d''éclair très élevé, non volatil. Humectant et solvant doux, bien toléré par la peau. Améliore la sensation d''hydratation sans toucher collant.',
    'Moins visqueux que le propylène glycol et toucher moins collant. Meilleure sensation cutanée que le glycérol pour les textures légères.',
    'Faible',
    array[]::text[],
    'Aucun obligatoire. Éviter le contact prolongé avec les yeux.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger à faible dose.',
    'Oxydants forts.',
    'Bidon hermétique en PEHD, à température ambiante, à l''abri du gel.',
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Humectant et solvant cosmétique',
   'Incorporer 2 à 10% dans la phase aqueuse du produit. Facilite la solubilisation des extraits et parfums.',
   'plage', 2, 10, '% du produit fini', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Carbonate de propylène
  -- ------------------------------------------------------------
  v_material_id := 'd6288ccc-ef87-4e81-ae89-11ad4a8321db'::uuid;

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
    '4-méthyl-1,3-dioxolan-2-one (C₄H₆O₃)',
    'PC, carbonate de propylène',
    'Cosmétique',
    'Liquide incolore, mobile, inodore',
    'Neutre',
    'Miscible à l''eau et à la plupart des solvants organiques',
    1.20, 135,
    'Point d''éclair très élevé. Biodégradable, classé solvant vert. Faible toxicité, non irritant. Excellent solvant des polymères et nettoyant doux.',
    'Moins volatil que l''acétone et plus écologique que les solvants pétroliers. Alternative douce au DMSO pour la peau.',
    'Faible',
    array['lunettes'],
    'Lunettes de protection pour éviter les projections.',
    'Yeux : rincer 15 min. Peau : laver. Ingestion : boire de l''eau.',
    'Acides forts, bases fortes.',
    'Bidon en plastique ou verre, bien fermé, à température ambiante.',
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
  (v_academie_id, 'Démaquillant et solvant doux cosmétique',
   'Appliquer pur sur un coton, nettoyer le visage. Rinçage facultatif. Bonne tolérance cutanée.',
   'valeur_unique', 100, null, '% (pur)', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Cyclohexane
  -- ------------------------------------------------------------
  v_material_id := 'f86c1ca0-4aaa-433c-b0ce-b243defcbcfc'::uuid;

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
    'Cyclohexane (C₆H₁₂)',
    'Hexaméthylène',
    'Technique',
    'Liquide incolore, odeur de solvant légèrement sucrée',
    'Non applicable (insoluble)',
    'Insoluble dans l''eau, miscible avec la plupart des solvants organiques',
    0.78, -18,
    'Très inflammable. Bon solvant des cires, huiles et résines. Moins toxique que le benzène.',
    'Comparé au n-hexane, point d''ébullition plus élevé, dissout mieux les résines. Solvant de choix pour les cires.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Gants en nitrile, lunettes, masque à vapeurs organiques.',
    'Inhalation : air frais. Peau : laver. Yeux : rincer 15 min. Ingestion : ne pas faire vomir, appeler un médecin.',
    'Oxydants forts.',
    'Bidon en acier, local frais et ventilé, à l''abri des flammes.',
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
  select v_academie_id, id from public.phrases_h where code in ('H225', 'H304', 'H315', 'H319', 'H336', 'H410')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P261', 'P273', 'P280', 'P301+P310', 'P331')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Solvant de cires et résines',
   'Dissoudre les cires (abeille, carnauba) dans le cyclohexane à 30-40°C sous agitation. Appliquer et laisser évaporer.',
   'valeur_unique', 100, null, '% (solvant pur)', '30-40 °C', '15-30 min', false, 0);

  -- ------------------------------------------------------------
  -- D-Limonène (terpène d'agrumes)
  -- ------------------------------------------------------------
  v_material_id := 'afabeac4-4b27-4a77-97c8-f993bd7b2a40'::uuid;

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
    '(R)-p-mentha-1,8-diène (C₁₀H₁₆)',
    'Terpène d''orange, limonène',
    'Technique',
    'Liquide incolore à jaune pâle, odeur puissante d''agrumes',
    'Non applicable (insoluble)',
    'Insoluble dans l''eau, miscible avec les huiles et solvants organiques',
    0.84, 48,
    'Solvant écologique extrait des écorces d''agrumes. Biodégradable, non toxique, excellent dégraissant. Odeur agréable mais peut devenir allergisant après oxydation à l''air.',
    'Contrairement au white spirit, il est d''origine renouvelable, moins toxique et laisse une odeur fraîche. Plus puissant que l''essence de térébenthine pour dégraisser.',
    'Modéré',
    array['gants','lunettes','ventilation'],
    'Gants en nitrile, éviter l''inhalation prolongée. Peut irriter la peau à l''état pur.',
    'Inhalation : air frais. Peau : laver à l''eau et au savon. Yeux : rincer 15 min. Ingestion : ne pas faire vomir (risque de pneumonie), appeler un médecin.',
    'Oxydants forts, acides forts. Attaque certains plastiques (polystyrène, caoutchouc).',
    'Bidon en acier inox ou PEHD, bien fermé, à l''abri de la lumière et de l''air pour éviter l''oxydation.',
    5, 30, false, true, 12, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H226', 'H304', 'H315', 'H317', 'H319', 'H411')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P261', 'P273', 'P280', 'P301+P310', 'P331')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Dégraissant écologique',
   'Appliquer pur ou dilué (5-20% dans un solvant porteur), frotter, rincer à l''eau ou laisser évaporer.',
   'plage', 5, 100, '% (pur ou dilué selon besoin)', 'Ambiante', '5-10 min', false, 0),
  (v_academie_id, 'Nettoyant ménager multi-usage',
   'Formuler un spray avec 3-5% de D-limonène, 2-5% de tensioactif doux, eau qsp. Agiter avant emploi.',
   'plage', 3, 5, '% du produit fini', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Dipropylène glycol
  -- ------------------------------------------------------------
  v_material_id := '6273d611-d596-4b08-afcd-b23feff65a72'::uuid;

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
    'Mélange d''isomères d''oxybispropanol (C₆H₁₄O₃)',
    'DPG, oxybispropanol',
    'Cosmétique',
    'Liquide incolore, visqueux, inodore ou très légère odeur',
    'Neutre (6-7)',
    'Miscible à l''eau, à l''alcool et à de nombreux solvants organiques',
    1.02, 138,
    'Point d''éclair très élevé, pratiquement non volatile. Fixateur de parfum puissant en cosmétique. Toucher sec et non gras.',
    'Par rapport au butylène glycol, il est plus lipophile et fixe mieux les parfums lourds. Moins hygroscopique que le propylène glycol. Idéal pour les parfums sans alcool.',
    'Faible',
    array[]::text[],
    'Aucun obligatoire. Éviter le contact prolongé.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts.',
    'Bidon en plastique, à l''abri du gel, dans un endroit propre.',
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Fixateur et solvant de fragrances',
   'Prémélanger les huiles essentielles avec le DPG (ratio 1:1 à 1:4) avant incorporation dans la phase aqueuse ou alcoolique.',
   'plage', 1, 20, '% du produit fini', 'Ambiante', 'Quelques minutes', false, 0);

  -- ------------------------------------------------------------
  -- DMSO (diméthylsulfoxyde)
  -- ------------------------------------------------------------
  v_material_id := 'df21eaf0-98f3-4c59-9e41-011cd06abffc'::uuid;

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
    'Diméthylsulfoxyde (C₂H₆OS)',
    'Sulfoxyde de diméthyle',
    'Technique',
    'Liquide incolore, légèrement visqueux, odeur ailée caractéristique',
    'Neutre',
    'Miscible à l''eau et à de nombreux solvants organiques',
    1.10, 88,
    'Point d''éclair élevé. Pénètre facilement à travers la peau et entraîne avec lui les substances dissoutes. Cryoprotecteur et excellent solvant d''extraction.',
    'Contrairement au carbonate de propylène, pénètre très rapidement la peau. Solvant de nombreux polymères. Le contact cutané doit être évité avec des substances toxiques dissoutes.',
    'Faible',
    array['gants'],
    'Gants en nitrile, éviter le contact cutané prolongé (effet de transport à travers la peau).',
    'Peau : laver abondamment à l''eau. Yeux : rincer 15 min. Ingestion : boire de l''eau.',
    'Acides forts, bases fortes, oxydants puissants, chlorures d''acides.',
    'Flacon en verre ou PEHD, bien fermé, à l''abri de l''humidité et de la chaleur excessive.',
    15, 30, true, false, 36, 'a_valider'
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
  (v_academie_id, 'Solvant d''extraction et promoteur de pénétration',
   'Diluer l''actif dans le DMSO avant application externe (attention : utiliser pur et propre, sans contaminants).',
   'plage', 10, 50, '% de la solution appliquée', 'Ambiante', 'Immédiat', true, 0);

  -- ------------------------------------------------------------
  -- Essence de térébenthine
  -- ------------------------------------------------------------
  v_material_id := 'a66c0f52-f615-4bd2-9e47-f7687cf13725'::uuid;

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
    'Mélange de terpènes, principalement α- et β-pinène (C₁₀H₁₆ majoritaire)',
    'Térébenthine, huile de térébenthine, essence de pin',
    'Technique',
    'Liquide incolore à jaune pâle, odeur caractéristique de pin, résineuse',
    'Non applicable (insoluble)',
    'Insoluble dans l''eau, miscible avec les huiles, résines, cires et solvants organiques',
    0.86, 35,
    'Solvant naturel issu de la distillation de résine de pin. Excellent diluant pour les peintures à l''huile et les vernis. S''oxyde à l''air en formant un résidu collant.',
    'Plus volatil que le white spirit, mais d''origine végétale. Pouvoir dissolvant supérieur pour les résines naturelles. Remplacé par le white spirit dans de nombreux usages en raison de son coût et de son odeur.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Gants en nitrile, lunettes, masque à cartouche pour vapeurs organiques, ventilation.',
    'Inhalation : air frais. Peau : laver à l''eau et au savon, retirer les vêtements contaminés. Yeux : rincer 15 min. Ingestion : ne pas faire vomir, appeler un médecin.',
    'Oxydants forts, acides forts, chlore.',
    'Bidon en métal ou verre brun, bien fermé, à l''abri de la lumière, dans un local frais et ventilé. Éviter l''exposition à l''air.',
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
  select v_academie_id, id from public.phrases_h
  where code in ('H226', 'H302', 'H304', 'H312', 'H315', 'H317', 'H319', 'H332', 'H411')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P261', 'P273', 'P280', 'P301+P310', 'P331')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Diluant pour peinture à l''huile',
   'Ajouter 5-20% d''essence de térébenthine à la peinture pour fluidifier et améliorer le brossage.',
   'plage', 5, 20, '% du volume de peinture', 'Ambiante', 'Immédiat', false, 0),
  (v_academie_id, 'Décapage de cires et résines sur bois',
   'Appliquer pure avec un chiffon, frotter pour dissoudre la cire, laisser sécher.',
   'valeur_unique', 100, null, '% (pur)', 'Ambiante', '5-15 min', false, 1);

  -- ------------------------------------------------------------
  -- White spirit (naphta lourd)
  -- ------------------------------------------------------------
  v_material_id := '4136bc85-4f38-4e03-8050-fb23d9ca2d65'::uuid;

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
    'Naphta lourd hydrodésulfuré (mélange d''alcanes, cycloalcanes et aromatiques C7-C12)',
    'Essence minérale, naphta de pétrole, Stoddard solvent',
    'Technique',
    'Liquide clair incolore, odeur caractéristique de pétrole',
    'Non applicable (insoluble)',
    'Insoluble dans l''eau, miscible avec les huiles, graisses et la plupart des solvants organiques',
    0.78, 40,
    'Mélange d''hydrocarbures à évaporation moyenne. Excellent solvant des peintures glycérophtaliques, graisses et huiles. Disponible en version désaromatisée (moins toxique).',
    'Moins volatil que l''essence de térébenthine, moins odorant que le xylène. Le grade désaromatisé est préféré pour réduire les risques santé.',
    'Élevé',
    array['gants','lunettes','ventilation'],
    'Gants en PVA ou nitrile, lunettes de sécurité, ventilation adéquate, éviter l''inhalation prolongée. Ne pas fumer.',
    'Inhalation : air frais. Peau : laver au savon et à l''eau. Yeux : rincer 15 min. Ingestion : ne pas faire vomir, risque de pneumonie chimique, appeler un médecin.',
    'Oxydants forts, acides forts.',
    'Bidon en acier ou PEHD, local frais et ventilé, à l''abri des sources d''inflammation. Conserver hermétiquement fermé.',
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
  select v_academie_id, id from public.phrases_h
  where code in ('H226', 'H304', 'H315', 'H319', 'H336', 'H411')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P261', 'P280', 'P301+P310', 'P331')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Dilution de peintures glycérophtaliques et nettoyage des pinceaux',
   'Ajouter 5-15% au volume de peinture. Pour le nettoyage, faire tremper les pinceaux puis rincer au white spirit.',
   'plage', 5, 15, '% du volume de peinture', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Méthyléthylcétone (MEK, butanone)
  -- ------------------------------------------------------------
  v_material_id := '17ba8215-44cf-4237-81cd-5c98af82478f'::uuid;

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
    'Butan-2-one (C₄H₈O)',
    'MEK, butanone',
    'Technique',
    'Liquide incolore, mobile, odeur d''acétone prononcée',
    'Neutre',
    'Partiellement miscible à l''eau (27 g/100 mL), miscible avec les solvants organiques usuels',
    0.80, -9,
    'Excellent solvant des résines, vernis, colles et matières plastiques. S''évapore très rapidement. Très inflammable.',
    'Pouvoir solvant supérieur à l''acétone pour les résines époxy et polyuréthanes. Plus toxique que l''acétone par inhalation.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Gants en caoutchouc butyle ou nitrile, lunettes étanches, masque à cartouche pour vapeurs organiques (type A). Travailler loin des flammes.',
    'Inhalation : air frais, consulter si gêne. Peau : laver à l''eau et au savon. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas vomir, appeler un médecin.',
    'Oxydants forts, bases fortes, amines, chlore.',
    'Bidon métallique, dans un local frais, sec et très bien ventilé, à l''écart des sources d''inflammation.',
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
  (v_academie_id, 'Solvant de résines et colles',
   'Utiliser pur ou en mélange avec d''autres solvants pour dissoudre ou diluer avant application.',
   'valeur_unique', 100, null, '% (pur)', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Propylène glycol monométhyl éther (PGME)
  -- ------------------------------------------------------------
  v_material_id := 'dc01e276-c38e-4dc8-8630-13dd5891d6b7'::uuid;

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
    '1-méthoxypropan-2-ol (C₄H₁₀O₂)',
    'PGME, méthoxypropanol',
    'Technique',
    'Liquide incolore, odeur douce et éthérée',
    'Neutre',
    'Miscible à l''eau et à de nombreux solvants organiques',
    0.92, 32,
    'Éther de glycol modérément volatil, bon solvant de nettoyage, utilisé dans les peintures, encres et nettoyants industriels. Faible toxicité par rapport aux éthers de la série E.',
    'Moins toxique que les éthers de glycol de type éthylène. Alternative plus sûre au MEK pour certaines applications.',
    'Modéré',
    array['gants','lunettes','ventilation'],
    'Gants en caoutchouc, lunettes de sécurité, éviter l''inhalation.',
    'Inhalation : air frais. Peau : laver. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas faire vomir, consulter un médecin.',
    'Oxydants forts, acides forts.',
    'Bidon en acier ou PEHD, local ventilé, à l''abri de la chaleur.',
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
  select v_academie_id, id from public.phrases_h where code in ('H226', 'H319', 'H336')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P261', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Nettoyant et diluant pour peintures et encres',
   'Ajouter 5-10% au produit à diluer, bien mélanger.',
   'plage', 5, 10, '% du volume de peinture/encre', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Isoparaffine (C10-C13)
  -- ------------------------------------------------------------
  v_material_id := '026243da-9abb-4713-a9e7-9e14f18b5e91'::uuid;

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
    'Hydrocarbures aliphatiques ramifiés C10-C13, isoparaffines (mélange d''isoparaffines C10-C13)',
    'Isopar, solvant isoparaffinique',
    'Cosmétique',
    'Liquide incolore, très fluide, inodore ou très légère odeur',
    'Non applicable (insoluble)',
    'Insoluble dans l''eau, miscible avec les huiles, silicones et la plupart des solvants organiques',
    0.76, 65,
    'Point d''éclair élevé, très peu volatil. Solvant doux pour la peau, non comédogène. Excellente alternative au white spirit ou au xylène pour les cosmétiques.',
    'Hautement purifié, sans aromatiques, adapté aux cosmétiques. Toucher sec similaire aux silicones volatils.',
    'Faible',
    array[]::text[],
    'Aucun obligatoire en utilisation normale. Éviter l''inhalation de vapeurs en milieu confiné.',
    'Yeux : rincer. Peau : laver. Ingestion : ne pas faire vomir, consulter un médecin si grande quantité ingérée.',
    'Oxydants forts.',
    'Bidon en PEHD, local propre, à l''abri de la chaleur excessive.',
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
  (v_academie_id, 'Solvant et agent d''étalement en maquillage',
   'Incorporer 5-20% dans la phase huileuse, avec les pigments et les cires, pour améliorer la texture et la sensation sur la peau.',
   'plage', 5, 20, '% de la phase grasse', 'Ambiante ou à chaud (70-80 °C)', 'Pendant le mélange', false, 0);

  -- ------------------------------------------------------------
  -- Xylène (diméthylbenzène, xylol) — PRODUIT SENSIBLE
  -- Reprotoxique / usage réglementé. Grade strict Technique,
  -- avertissements renforcés (décision explicite de l'utilisatrice).
  -- ------------------------------------------------------------
  v_material_id := '52056e4b-34e5-4ed2-b346-aa9c530f02bc'::uuid;

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
    'Diméthylbenzène, mélange d''isomères (C₈H₁₀)',
    'Xylol, diméthylbenzène',
    'Technique',
    'Liquide incolore, odeur aromatique caractéristique',
    'Non applicable (insoluble)',
    'Insoluble dans l''eau, miscible avec la plupart des solvants organiques',
    0.86, 27,
    'Excellent solvant des résines, peintures, vernis et encres. Toxique à long terme (reprotoxique, atteintes neurologiques). Usage réservé à un personnel formé, avec ventilation renforcée. Proscrire pour une personne enceinte. Substitution recommandée dès que possible.',
    'Plus puissant que le white spirit pour dissoudre les résines alkydes. Beaucoup plus toxique que le PGME. Incontournable dans les diluants professionnels pour peintures, mais à manipuler avec une extrême prudence.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Gants en PVA ou nitrile, lunettes de sécurité, ventilation forcée obligatoire, masque à cartouche pour vapeurs organiques (type A). Interdit aux femmes enceintes. Substitution à étudier.',
    'Inhalation : air frais, consulter. Peau : laver à l''eau et au savon, retirer les vêtements contaminés. Yeux : rincer 15 min. Ingestion : ne pas faire vomir, appeler un médecin.',
    'Oxydants forts (acide nitrique), acides forts.',
    'Bidon en acier, local frais et bien ventilé, à l''écart des sources d''inflammation et des oxydants. Conserver dans un endroit verrouillé.',
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
  select v_academie_id, id from public.phrases_h
  where code in ('H226', 'H304', 'H312+H332', 'H315', 'H319', 'H335', 'H373')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P260', 'P280', 'P301+P310', 'P331')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Diluant professionnel pour peintures et résines',
   'Ajouter 5-15% sous agitation, uniquement dans un local équipé d''une ventilation mécanique et par du personnel formé.',
   'plage', 5, 15, '% du volume de peinture', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- n-Hexane — PRODUIT SENSIBLE
  -- Neurotoxique, restreint (REACH). Grade strict Technique,
  -- avertissements renforcés (décision explicite de l'utilisatrice).
  -- ------------------------------------------------------------
  v_material_id := 'd6aa52e7-18a3-40ee-ab6e-fcf7be4c3769'::uuid;

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
    'n-Hexane (C₆H₁₄)',
    'Hexane, hexane normal',
    'Technique',
    'Liquide incolore, très mobile, odeur d''essence légère',
    'Non applicable (insoluble)',
    'Insoluble dans l''eau (0,01 g/100 mL), miscible avec les huiles, graisses et solvants organiques',
    0.66, -22,
    'Très volatil et très inflammable. Neurotoxique en cas d''exposition chronique (atteinte du système nerveux périphérique). Usage strictement encadré : durée d''exposition minimisée, ventilation renforcée, proscrire pour une personne enceinte. Substitution recommandée dès que possible.',
    'Point d''ébullition plus bas que le cyclohexane ou le white spirit. Très bon pour l''extraction sélective, mais remplacé dans l''industrie agroalimentaire par l''hexane alimentaire (mélange d''isomères) moins riche en n-hexane.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Gants en nitrile, lunettes de sécurité, ventilation forcée obligatoire. Masque à cartouche pour vapeurs organiques. Interdit aux femmes enceintes. Éviter tout contact cutané répété.',
    'Inhalation : air frais, consulter. Peau : laver. Yeux : rincer 15 min. Ingestion : ne pas faire vomir, appeler un médecin.',
    'Oxydants forts, chlore, fluor.',
    'Bidon en acier, local frais et très bien ventilé, à l''écart des sources d''inflammation. Armoires antidéflagrantes recommandées. Quantité stockée limitée au strict besoin.',
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
  select v_academie_id, id from public.phrases_h
  where code in ('H225', 'H304', 'H315', 'H319', 'H336', 'H361f', 'H373')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P260', 'P280', 'P301+P310', 'P331')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Extraction d''huiles végétales (usage professionnel très contrôlé)',
   'Macérer la matière végétale broyée dans l''hexane, filtrer, évaporer le solvant sous vide à basse température. Opérer sous hotte avec ventilation renforcée.',
   'texte_libre', null, null, 'Volume suffisant pour couvrir la matière', '20-25°C', 'Plusieurs heures', true, 0);

  -- ------------------------------------------------------------
  -- Éther diéthylique (éther éthylique) — PRODUIT SENSIBLE
  -- Extrêmement inflammable, peroxydes explosifs. Grade strict
  -- Technique, avertissements renforcés (décision explicite de
  -- l'utilisatrice).
  -- ------------------------------------------------------------
  v_material_id := 'a3e3777b-75e0-4781-ac26-3909c40cc038'::uuid;

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
    'Éthoxyéthane ((C₂H₅)₂O)',
    'Éther éthylique, éther',
    'Technique',
    'Liquide incolore, très mobile, odeur douce et pénétrante',
    'Neutre',
    'Partiellement soluble dans l''eau (8 g/100 mL), miscible avec alcools, hydrocarbures',
    0.71, -45,
    'Extrêmement inflammable et volatil. Forme des peroxydes explosifs au contact de l''air et de la lumière. Usage sous hotte uniquement. Quantité stockée limitée au strict besoin. Contrôle périodique des peroxydes obligatoire.',
    'Plus volatil que l''hexane. Pouvoir extractif élevé pour les composés polaires et apolaires. Très dangereux (inflammabilité, explosivité). Utilisation en milieu confiné interdite.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Gants en nitrile, lunettes de sécurité, travailler impérativement sous hotte. Éviter toute source d''ignition (étincelles, électricité statique). Conserver avec inhibiteur de peroxydes (BHT). Vérifier l''absence de peroxydes avant chaque utilisation.',
    'Inhalation : air frais. Peau : laver. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas faire vomir.',
    'Oxydants forts, acides forts, peroxydes. Risque de formation de peroxydes explosifs au contact de l''air.',
    'Flacon en verre brun avec stabilisateur (BHT), dans un local frais et ventilé, à l''abri de la lumière. Quantité limitée au strict besoin. Vérifier régulièrement l''absence de peroxydes.',
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
  select v_academie_id, id from public.phrases_h where code in ('H224', 'H302', 'H336')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P233', 'P261', 'P280', 'P301+P312')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Solvant d''extraction pour principes actifs (usage professionnel)',
   'Utiliser en laboratoire, sous hotte, pour extraire des composés végétaux. Évaporer sous vide. Manipulation experte requise.',
   'texte_libre', null, null, 'Volume suffisant', 'Ambiante', 'Variable', true, 0);

  -- ------------------------------------------------------------
  -- Éthoxydiglycol (Transcutol)
  -- ------------------------------------------------------------
  v_material_id := '39636868-f5b7-45ea-b4be-3004af565112'::uuid;

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
    '2-(2-éthoxyéthoxy)éthanol (C₆H₁₄O₃)',
    'Transcutol, diéthylène glycol monoéthyl éther',
    'Cosmétique',
    'Liquide incolore, peu visqueux, odeur douce',
    'Neutre',
    'Miscible à l''eau et à de nombreux solvants organiques',
    0.99, 96,
    'Point d''éclair élevé. Promoteur de pénétration cutanée, utilisé pour améliorer la biodisponibilité des actifs cosmétiques. Solvant de parfums et d''huiles essentielles.',
    'Contrairement au dipropylène glycol, favorise la pénétration des actifs à travers la peau. Plus fluide que le butylène glycol.',
    'Faible',
    array[]::text[],
    'Aucun obligatoire. Éviter le contact avec les yeux.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Oxydants forts.',
    'Bidon fermé, à l''abri de la lumière, dans un endroit propre et sec.',
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Solvant et promoteur de pénétration en cosmétique',
   'Incorporer 1 à 10% dans la phase aqueuse ou alcoolique, avant ajout des actifs.',
   'plage', 1, 10, '% du produit fini', 'Ambiante', 'Incorporation directe', false, 0);
end $$;
