-- ============================================================
-- AkoraHub - Patch Phase 95 : fiches Académie pour les 13 dernières
-- substances "Acides & Bases" — contenu DeepSeek, vérifié par
-- l'utilisatrice. Termine la documentation complète de la catégorie.
-- "Chlorure de calcium" appliqué à ses 3 variantes catalogue.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  r record;
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Acide benzoïque
  -- ------------------------------------------------------------
  v_material_id := '9d46ae9c-d9b3-4ffc-8f63-4207dbd1df58'::uuid;

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
    'Benzoate d''hydrogène, E210',
    'Alimentaire',
    'Poudre cristalline blanche, légèrement odorante',
    '2,8 (solution saturée à 20 °C)',
    'Faible dans l''eau froide (0,3 g/100 mL à 20 °C), bonne dans l''eau chaude et l''éthanol',
    1.32, 121,
    'Conservateur antimicrobien naturellement présent dans certaines baies ; se sublime facilement à chaud.',
    'Moins soluble que le benzoate de sodium (son sel), mais plus efficace à pH acide (pH < 4,5).',
    'Modéré',
    array['gants','lunettes','masque'],
    'Gants nitrile, éviter l''inhalation de poussières, lunettes de protection.',
    'Yeux : rincer 15 min. Peau : laver à l''eau et au savon. Ingestion : rincer la bouche, boire de l''eau, consulter un médecin. Inhalation : air frais.',
    'Oxydants forts, bases fortes.',
    'Récipient étanche, au sec, à température ambiante, à l''écart des sources de chaleur.',
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
  (v_academie_id, 'Conservateur cosmétique',
   'Dissoudre dans la phase chaude (huiles ou alcool) avant incorporation. Efficace uniquement à pH < 4,5.',
   'valeur_unique', 0.5, null, '% du produit fini', '70-80 °C', 'Incorporation immédiate', false, 0),
  (v_academie_id, 'Conservateur alimentaire',
   'Ajouter directement dans la préparation acide (confiture, boisson).',
   'plage', 0.05, 0.1, '% du poids total', 'Ambiante', 'Effet immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Acide borique
  -- ------------------------------------------------------------
  v_material_id := '4af101f7-ef72-4556-94d0-aa1022690d90'::uuid;

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
    'Acide borique (H₃BO₃)',
    'Borax acide, acide orthoborique',
    'Technique',
    'Poudre blanche ou cristaux incolores, légèrement onctueux au toucher',
    '5,1 (solution à 0,1 %)',
    '5 g/100 mL à 20 °C, très soluble dans l''eau chaude',
    1.44, null,
    'Insecticide et antifongique naturel ; très faible toxicité aiguë pour l''homme mais toxique par ingestion répétée.',
    'Moins alcalin que le borax (tétraborate de sodium), souvent préféré pour les solutions ophtalmiques diluées.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en latex ou nitrile, éviter le contact prolongé avec la peau.',
    'Yeux : rincer 15 min. Peau : laver. Ingestion : rincer la bouche, appeler un médecin. Ne pas utiliser sur une peau lésée.',
    'Oxydants forts, alcalis, métaux alcalins.',
    'Récipient étanche, au sec, hors de portée des enfants, ne pas stocker avec des aliments.',
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

  -- ⚠️ H360FD (reprotoxique) n'existe probablement pas dans le seed
  -- phase86 (phrases rares) — insert conditionnel, ne bloque pas si absent.
  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H360FD', 'H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P201', 'P280', 'P305+P351+P338', 'P308+P313')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, unite_dosage, temperature_utilisation, temps_action,
    a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Insecticide (fourmis, blattes)',
   'Mélanger avec du sucre glace et de l''eau pour former une pâte, placer dans les zones de passage.',
   'valeur_unique', 5, 'g par appât', 'Ambiante', 'Plusieurs jours', false, 0);

  -- ------------------------------------------------------------
  -- Acide fumarique (E297)
  -- ------------------------------------------------------------
  v_material_id := 'a73e112a-edbd-4df7-83d7-0e7300e31249'::uuid;

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
    'Acide fumarique (C₄H₄O₄)',
    'E297, acide trans-butènedioïque',
    'Alimentaire',
    'Poudre cristalline blanche, inodore',
    '2,1 (solution à 0,1 %)',
    'Faible dans l''eau froide (0,6 g/100 mL à 25 °C), meilleure dans l''eau chaude et l''alcool',
    1.64, null,
    'Acidulant plus fort que l''acide citrique à poids égal, goût plus persistant ; peu hygroscopique.',
    'Plus acide que l''acide citrique (pKa plus bas), souvent utilisé en mélange pour prolonger la perception acide.',
    'Modéré',
    array['lunettes'],
    'Lunettes de sécurité recommandées, éviter l''inhalation de poussières.',
    'Yeux : rincer 15 min. Peau : laver. Ingestion : boire de l''eau.',
    'Oxydants forts, bases fortes.',
    'Récipient étanche, au sec, température ambiante.',
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
  select v_academie_id, id from public.phrases_h where code in ('H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, unite_dosage, temperature_utilisation, temps_action,
    a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Acidulant boissons en poudre',
   'Incorporer directement au mélange sec, apporte une acidité longue en bouche.',
   'valeur_unique', 1, 'g/L de boisson reconstituée', 'Ambiante', 'Dissolution immédiate', false, 0);

  -- ------------------------------------------------------------
  -- Acide gluconique (E574)
  -- ------------------------------------------------------------
  v_material_id := '998b55d0-6158-481a-8b0d-ab44e252ff68'::uuid;

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
    'Acide gluconique (C₆H₁₂O₇)',
    'Gluconate d''hydrogène, E574',
    'Alimentaire',
    'Liquide visqueux incolore à jaune pâle (solution à 50 %), ou poudre cristalline blanche',
    '2,5 (solution à 1 %)',
    'Très soluble dans l''eau (forme acide), la solution à 50 % est la forme commerciale courante',
    1.23, null,
    'Densité donnée pour la solution aqueuse à 50 %. Chélateur doux biodégradable, excellent détartrant sans danger pour les surfaces sensibles.',
    'Moins agressif que l''acide citrique ou phosphorique, il est utilisé quand la corrosion doit être minimisée (inox, aluminium).',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire pour la solution à 50 %, mais le port de gants est recommandé pour un usage prolongé.',
    'Yeux : rincer à l''eau. Peau : laver. Ingestion : boire de l''eau.',
    'Oxydants forts.',
    'Bidon en plastique (PEHD), à température ambiante, éviter le gel.',
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Détartrant doux (machines à café, surfaces inox)',
   'Utiliser pur ou dilué à 20-30 % dans l''eau, faire circuler, rincer.',
   'dilution', 20, 30, '% (v/v) de solution commerciale dans l''eau', '20-60 °C', '15-30 min', false, 0),
  (v_academie_id, 'Nettoyant alcalin (chélateur)',
   'Ajouter 1-5 % dans une formulation alcaline pour empêcher la précipitation des sels de calcium.',
   'plage', 1, 5, '% du produit fini', 'Ambiante', 'Incorporation immédiate', true, 1);

  -- ------------------------------------------------------------
  -- Acide malique DL (E296)
  -- ------------------------------------------------------------
  v_material_id := '9ee7ae26-e46f-4cd3-a3f4-fe7df174aafe'::uuid;

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
    'Acide malique DL (C₄H₆O₅)',
    'E296, acide hydroxybutanedioïque',
    'Alimentaire',
    'Poudre cristalline blanche, légèrement hygroscopique',
    '2,3 (solution à 0,1 %)',
    'Très soluble (55 g/100 mL à 20 °C)',
    1.60, null,
    'Goût acidulé doux et persistant, moins agressif que l''acide citrique ; présent naturellement dans les pommes.',
    'Profil gustatif plus rond que l''acide citrique, souvent utilisé en association pour un goût plus naturel.',
    'Modéré',
    array['lunettes'],
    'Lunettes de sécurité, éviter l''inhalation de poussières.',
    'Yeux : rincer 15 min. Peau : laver. Ingestion : boire de l''eau.',
    'Oxydants forts, bases fortes.',
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

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Acidulant boissons et confiseries',
   'Ajouter directement à la préparation, souvent combiné avec l''acide citrique (ratio 1:1 ou 1:2).',
   'plage', 0.5, 3, 'g/L de boisson ou % du poids en confiserie', 'Ambiante', 'Dissolution immédiate', false, 0);

  -- ------------------------------------------------------------
  -- Acide sulfamique
  -- ------------------------------------------------------------
  v_material_id := '28602665-ecb6-4b6c-8672-8c296ff4bbe1'::uuid;

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
    'Acide sulfamique (H₃NSO₃)',
    'Acide amidosulfonique',
    'Technique',
    'Poudre cristalline blanche, inodore',
    '1,5 (solution à 1 %)',
    'Très soluble (17 g/100 mL à 20 °C, 37 g/100 mL à 80 °C)',
    2.15, null,
    'Détartrant puissant non volatil, sans vapeurs irritantes contrairement à HCl ; attaque le tartre sans corroder l''inox.',
    'Plus sûr que l''acide chlorhydrique (pas de vapeurs), mais plus cher ; idéal pour le détartrage de précision (échangeurs, chaudières).',
    'Modéré',
    array['gants','lunettes','ventilation'],
    'Gants nitrile ou PVC, lunettes de sécurité, bonne ventilation recommandée.',
    'Yeux : rincer 15 min. Peau : laver à l''eau. Ingestion : rincer la bouche, boire de l''eau, consulter.',
    'Oxydants forts, bases fortes, chlore.',
    'Récipient étanche, au sec, à l''écart des produits chlorés.',
    5, 40, false, false, 36, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Détartrage chaudières et échangeurs',
   'Préparer une solution à 5-10 %, faire circuler à chaud, rincer abondamment. Ajouter un inhibiteur de corrosion si nécessaire.',
   'plage', 5, 10, '% (m/v) dans l''eau', '40-60 °C', '2-6 heures', true, 0),
  (v_academie_id, 'Détartrant ménager (WC, salle de bain)',
   'Saupoudrer directement sur les surfaces mouillées, laisser agir, frotter, rincer.',
   'valeur_unique', 30, null, 'g par application', 'Ambiante', '10-15 min', false, 1);

  -- ------------------------------------------------------------
  -- Acide tartrique L(+) (E334)
  -- ------------------------------------------------------------
  v_material_id := '5966f22c-b44e-4792-8349-cd41c81a1730'::uuid;

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
    'Acide tartrique L(+) (C₄H₆O₆)',
    'E334, acide 2,3-dihydroxybutanedioïque',
    'Alimentaire',
    'Poudre cristalline blanche, inodore',
    '2,2 (solution à 0,1 %)',
    'Très soluble (133 g/100 mL à 20 °C)',
    1.76, null,
    'Acide naturel du raisin et du tamarin ; forme des sels (tartrates) peu solubles avec le calcium et le potassium.',
    'Plus fort que l''acide citrique, avec un goût plus astringent ; utilisé comme stabilisant naturel dans les vins.',
    'Modéré',
    array['lunettes'],
    'Lunettes de sécurité, éviter le contact prolongé avec la peau.',
    'Yeux : rincer 15 min. Peau : laver. Ingestion : boire de l''eau.',
    'Oxydants forts, bases fortes.',
    'Récipient étanche, au sec, température ambiante.',
    5, 30, false, false, 48, 'a_valider'
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
  select v_academie_id, id from public.phrases_p where code in ('P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, unite_dosage, temperature_utilisation, temps_action,
    a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Stabilisant de blanc d''œuf (pâtisserie)',
   'Ajouter une pincée dans les blancs avant de les monter en neige.',
   'valeur_unique', 0.5, 'g pour 4 blancs d''œufs', 'Ambiante', 'Effet immédiat', false, 0),
  (v_academie_id, 'Acidulant boissons',
   'Dissoudre dans l''eau avant ajout, apporte une acidité vive.',
   'valeur_unique', 1, 'g/L', 'Ambiante', 'Dissolution immédiate', false, 1);

  -- ------------------------------------------------------------
  -- Carbonate de calcium (E170)
  -- ------------------------------------------------------------
  v_material_id := 'decd2f65-7b22-4bf3-9bdb-12f33b9e982b'::uuid;

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
    'Carbonate de calcium (CaCO₃)',
    'E170, calcite, craie',
    'Alimentaire',
    'Poudre blanche fine, inodore',
    '9-10 (suspension saturée dans l''eau)',
    'Très faible (0,0013 g/100 mL à 25 °C) ; soluble dans les acides avec effervescence',
    2.71, null,
    'Additif alimentaire blanc (E170), charge minérale, abrasif doux et anti-acide gastrique ; non toxique.',
    'Moins alcalin que le carbonate de sodium, ne se dissout pas dans l''eau pure, idéal comme charge neutre.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire, masque anti-poussière recommandé pour les manipulations de grands volumes.',
    'Yeux : rincer à l''eau. Peau : laver. Ingestion sans danger à faible dose (anti-acide).',
    'Acides (effervescence et dégagement de CO₂).',
    'Récipient étanche, au sec, n''importe quelle température ambiante.',
    5, 40, false, false, 60, 'a_valider'
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
  (v_academie_id, 'Dentifrice (abrasif doux)',
   'Incorporer dans la pâte dentifrice maison à raison de 20-30 % du poids total.',
   'plage', 20, 30, '% du poids du dentifrice', 'Ambiante', 'Incorporation immédiate', false, 0),
  (v_academie_id, 'Charge pour peinture et mastic',
   'Ajouter progressivement sous agitation pour ajuster la consistance et l''opacité.',
   'plage', 10, 40, '% du poids total', 'Ambiante', 'Incorporation lente', true, 1);

  -- ------------------------------------------------------------
  -- Chlorure de calcium (E509) — 3 variantes du catalogue
  -- ------------------------------------------------------------
  for r in
    select * from (values
      ('b038e2f9-4c15-48c3-89db-0aec1a380f0d'::uuid), -- Chlorure de calcium
      ('2eea5216-5363-4ab0-89a4-c22e8d4d587f'::uuid), -- CaCl₂ (texturation conserves)
      ('c5442457-5468-41ef-8c9e-23226621f29d'::uuid)  -- CaCl₂ alimentaire
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
      'Chlorure de calcium (CaCl₂)',
      'E509, sel de calcium',
      'Alimentaire',
      'Granulés ou paillettes blanches, très hygroscopiques',
      '7-8 (solution neutre à légèrement basique)',
      'Très soluble (74 g/100 mL à 20 °C), dissolution exothermique',
      2.15, null,
      'Très hygroscopique et déliquescent ; utilisé comme agent raffermissant, déshydratant et source de calcium.',
      'Contrairement au carbonate de calcium, il est très soluble et ne précipite pas ; il abaisse le point de congélation de l''eau (saumure).',
      'Modéré',
      array['gants','lunettes'],
      'Gants étanches, éviter le contact avec la peau (chaleur de dissolution), lunettes de sécurité.',
      'Yeux : rincer 15 min. Peau : laver à l''eau. Ingestion : boire de l''eau.',
      'Acides forts (dégagement de HCl gazeux), sulfates (précipitation de CaSO₄).',
      'Récipient hermétique, au sec (très hygroscopique), à l''écart des acides.',
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
    select v_academie_id, id from public.phrases_h where code in ('H319')
    on conflict (academie_id, phrase_h_id) do nothing;

    insert into public.academie_phrases_p (academie_id, phrase_p_id)
    select v_academie_id, id from public.phrases_p where code in ('P264', 'P280', 'P305+P351+P338')
    on conflict (academie_id, phrase_p_id) do nothing;

    insert into public.matieres_premieres_usages (
      academie_id, domaine_application, technique_methode, dosage_type,
      dosage_min, unite_dosage, temperature_utilisation, temps_action,
      a_verifier_labo, ordre
    ) values
    (v_academie_id, 'Raffermissant alimentaire (conserves, fromages)',
     'Ajouter dissous dans l''eau de saumure pour les conserves de légumes, ou dans le bain de caillage pour le fromage.',
     'valeur_unique', 0.5, 'g/L de saumure ou de lait', 'Ambiante', 'Effet immédiat', false, 0),
    (v_academie_id, 'Déshydratant / absorbeur d''humidité',
     'Placer dans un récipient ouvert dans la pièce à assécher, remplacer quand le produit est liquéfié.',
     'valeur_unique', 500, 'g par pièce de 20 m²', 'Ambiante', 'Plusieurs jours', false, 1);
  end loop;

  -- ------------------------------------------------------------
  -- Citrate de sodium / Citrate de potassium (E331/E332)
  -- ------------------------------------------------------------
  v_material_id := '2788c5e9-b77b-4465-8968-bd8804eb45cc'::uuid;

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
    'Citrate de sodium / Citrate de potassium (Na₃C₆H₅O₇ / K₃C₆H₅O₇)',
    'E331 (citrate de sodium), E332 (citrate de potassium), citrate trisodique, citrate tripotassique',
    'Alimentaire',
    'Poudre cristalline blanche ou granulés, inodore',
    '7,5-8,5 (solution à 5 %)',
    'Très soluble dans l''eau (citrate de sodium : 42 g/100 mL à 20 °C ; citrate de potassium : 60 g/100 mL)',
    1.70, null,
    'Densité donnée pour le citrate trisodique anhydre. Agent tampon et chélateur, régulateur d''acidité et sel de fonte.',
    'Contrairement à l''acide citrique, il n''acidifie pas le milieu mais le tamponne ; le sel de potassium est préféré pour les régimes pauvres en sodium.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire, masque anti-poussière pour les manipulations de grands volumes.',
    'Yeux : rincer à l''eau. Peau : laver. Ingestion sans danger aux doses usuelles.',
    'Oxydants forts.',
    'Récipient étanche, au sec, température ambiante.',
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
  (v_academie_id, 'Sel de fonte (fromages fondus)',
   'Ajouter 2-3 % au fromage râpé avec un peu d''eau, chauffer doucement en remuant jusqu''à fonte homogène.',
   'valeur_unique', 2.5, null, '% du poids du fromage', '70-80 °C', '5-10 min', false, 0),
  (v_academie_id, 'Tampon pH et antioxydant (boissons, cosmétiques)',
   'Dissoudre dans la phase aqueuse avant assemblage, ajuste et stabilise le pH.',
   'plage', 0.1, 1, '% du produit fini', 'Ambiante', 'Incorporation immédiate', true, 1);

  -- ------------------------------------------------------------
  -- Potasse caustique (Hydroxyde de potassium, KOH)
  -- ------------------------------------------------------------
  v_material_id := '9c499f1e-e209-4c00-bda8-c804665975ad'::uuid;

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
    'Hydroxyde de potassium (KOH)',
    'Potasse caustique, KOH',
    'Technique',
    'Pastilles ou paillettes blanches, très hygroscopiques',
    '14 (solution à 1 %)',
    'Très soluble dans l''eau (110 g/100 mL à 20 °C), dissolution très exothermique',
    2.04, null,
    'Base forte, très hygroscopique et déliquescente ; réaction encore plus exothermique que la soude avec l''eau.',
    'Donne des savons plus mous et plus solubles que la soude (NaOH) ; idéale pour les savons liquides et les shampoings.',
    'Corrosif',
    array['gants','lunettes','masque','ventilation','tablier','bottes'],
    'Gants en nitrile ou néoprène (pas de latex), écran facial, masque anti-poussière, vêtements résistants aux alcalis.',
    'Peau : rincer 15 min, retirer les vêtements contaminés. Yeux : rincer 15 min, consulter un ophtalmologue. Ingestion : rincer la bouche, ne pas vomir, boire un verre d''eau, appeler un médecin.',
    'Acides, métaux légers (aluminium, zinc, magnésium → dégagement d''hydrogène inflammable), eau (ajouter la potasse à l''eau, jamais l''inverse).',
    'Récipient hermétique en PEHD ou acier inoxydable, local sec, frais, ventilé, à l''écart des acides.',
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
  select v_academie_id, id from public.phrases_h where code in ('H314', 'H290')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P280', 'P301+P330+P331', 'P303+P361+P353', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Savonnerie (savons liquides et mous)',
   'Dissoudre la potasse dans l''eau (toujours ajouter KOH à l''eau). Chauffer les huiles à 70-80 °C, verser la solution de potasse, mixer jusqu''à la pâte transparente. Diluer ensuite dans l''eau pour obtenir la consistance souhaitée.',
   'plage', 18, 25, '% du poids des huiles (selon indice de saponification)', '70-80 °C', '1-3 heures de cuisson', false, 0),
  (v_academie_id, 'Ajusteur pH (cosmétique, nettoyant)',
   'Préparer une solution à 10 %, ajouter goutte à goutte sous agitation, contrôler le pH.',
   'plage', 0.05, 1, '% du produit fini (solution à 10 %)', 'Ambiante', 'Instantané', true, 1);

  -- ------------------------------------------------------------
  -- Sel de Glauber (sulfate de sodium décahydraté)
  -- ------------------------------------------------------------
  v_material_id := '8bd3c353-262c-43a6-b58e-802afd042a05'::uuid;

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
    'Sulfate de sodium décahydraté (Na₂SO₄·10H₂O)',
    'Sel de Glauber, sulfate de soude décahydraté',
    'Technique',
    'Cristaux incolores ou poudre cristalline blanche, légèrement efflorescente à l''air sec',
    '6-7 (solution neutre)',
    'Très soluble dans l''eau chaude (42 g/100 mL à 100 °C), solubilité variable avec la température (max 49 g/100 mL à 32 °C)',
    1.46, null,
    'Fond dans son eau de cristallisation à 32,4 °C ; utilisé comme charge inerte, régulateur de détergence et laxatif osmotique.',
    'Contrairement au sel de table (NaCl), il n''est pas corrosif et abaisse peu le point de congélation ; utilisé comme agent de remplissage dans les lessives en poudre.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire.',
    'Yeux : rincer à l''eau. Peau : laver. Ingestion : boire de l''eau, effet laxatif à forte dose.',
    'Acides forts.',
    'Récipient étanche, au sec (risque d''efflorescence ou de prise en masse), température modérée.',
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
  (v_academie_id, 'Charge pour lessive en poudre',
   'Mélanger à sec avec les autres ingrédients (tensioactifs, carbonate de sodium), permet de standardiser le volume des doses.',
   'plage', 20, 50, '% du poids total de la lessive', 'Ambiante', 'Mélange à sec', false, 0);

  -- ------------------------------------------------------------
  -- Sulfate d'aluminium (Alun)
  -- ------------------------------------------------------------
  v_material_id := 'be128953-81b0-4740-94b3-8a571497ad12'::uuid;

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
    'Sulfate d''aluminium (Al₂(SO₄)₃)',
    'Alun, alun de potassium (si KAl(SO₄)₂), sulfate d''alumine',
    'Technique',
    'Poudre ou cristaux blancs à légèrement grisâtres, inodore',
    '2,5-3 (solution à 1 %, dû à l''hydrolyse acide de Al³⁺)',
    'Très soluble dans l''eau chaude, soluble dans l''eau froide (36 g/100 mL à 20 °C)',
    1.62, null,
    'Densité donnée pour le sulfate d''aluminium hydraté. Agent floculant et coagulant, acidifie légèrement l''eau par hydrolyse.',
    'Contrairement au chlorure de fer(III), autre coagulant, il ne colore pas l''eau et est préféré pour la potabilisation et la piscine.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en caoutchouc, lunettes de sécurité, éviter l''inhalation de poussières.',
    'Yeux : rincer 15 min. Peau : laver à l''eau. Ingestion : rincer la bouche, boire de l''eau, consulter.',
    'Bases fortes, oxydants, métaux alcalins.',
    'Récipient étanche, au sec, à l''écart des bases et de l''humidité.',
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
  (v_academie_id, 'Coagulant / floculant (traitement de l''eau, piscine)',
   'Dissoudre au préalable dans un seau d''eau (solution à 5-10 %), répartir sur la surface du bassin ou dans le flux d''eau à traiter.',
   'plage', 5, 20, 'g/m³ d''eau', 'Ambiante', '12-24 h de décantation', true, 0),
  (v_academie_id, 'Fixateur de colorant (teinture textile artisanale)',
   'Dissoudre dans l''eau chaude, immerger le tissu préalablement teint, laisser agir puis rincer.',
   'valeur_unique', 10, null, 'g/L d''eau', '50-60 °C', '30-60 min', false, 1);
end $$;
