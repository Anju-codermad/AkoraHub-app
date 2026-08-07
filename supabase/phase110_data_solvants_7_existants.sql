-- ============================================================
-- AkoraHub - Patch Phase 110 : fiches Académie pour les 7 solvants
-- déjà présents dans le catalogue avant la campagne — contenu
-- DeepSeek, vérifié par l'utilisatrice.
--
-- Termine la catégorie "Solvants" (23/23 : 16 nouveaux en phase
-- 108/109 + ces 7 produits déjà existants).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Alcool benzylique
  -- ------------------------------------------------------------
  v_material_id := '48ebdfce-b40d-42fc-9851-e433340a090f'::uuid;

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
    'Phénylméthanol (C₇H₈O)',
    'Alcool benzylique, benzyl alcohol',
    'Cosmétique',
    'Liquide incolore, odeur florale légère',
    'Neutre (6-7)',
    'Partiellement soluble dans l''eau (4 g/100 mL), miscible avec l''éthanol, les huiles essentielles et les solvants organiques',
    1.04, 93,
    'Point d''éclair modéré. Bon solvant des résines, colorants et parfums. Utilisé comme solvant de dilution doux et conservateur en cosmétique.',
    'Moins volatil que l''éthanol, il est préféré pour solubiliser les parfums dans les produits cosmétiques sans évaporation trop rapide. Solvant plus doux que le propylène glycol pour les extraits.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité. Éviter l''inhalation prolongée.',
    'Inhalation : air frais. Peau : laver à l''eau et au savon. Yeux : rincer 15 min. Ingestion : rincer la bouche, appeler un médecin si symptômes.',
    'Oxydants forts, acides forts.',
    'Bidon en PEHD ou verre, bien fermé, à l''abri de la lumière et de la chaleur.',
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H315', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P280', 'P301+P312', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Solvant de parfums et conservateur en cosmétique',
   'Incorporer 0,5 à 5% dans la formulation, mélanger avec la phase huileuse ou alcoolique.',
   'plage', 0.5, 5, '% du produit fini', 'Ambiante', 'Incorporation immédiate', false, 0);

  -- ------------------------------------------------------------
  -- Alcool cétylique
  -- ------------------------------------------------------------
  v_material_id := '6034248b-1f6a-40f5-ad37-6ecdea7911e1'::uuid;

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
    'Hexadécan-1-ol (C₁₆H₃₄O)',
    '1-hexadécanol, alcool palmitique',
    'Cosmétique',
    'Solide cireux, paillettes ou pastilles blanches, odeur grasse très faible',
    'Non applicable (insoluble)',
    'Insoluble dans l''eau, soluble dans les huiles, l''éthanol chaud et la plupart des solvants organiques',
    0.81, 160,
    'Alcool gras à longue chaîne. Utilisé comme co-émulsifiant, agent de consistance et opacifiant dans les crèmes. Point de fusion 49°C. N''est pas un solvant liquide mais un solvant solide pour les phases grasses.',
    'Par rapport aux alcools légers (éthanol), il est solide et insoluble dans l''eau. Il structure les émulsions et apporte un toucher doux, contrairement aux solvants volatils.',
    'Faible',
    array[]::text[],
    'Aucun obligatoire. Éviter l''inhalation de poussières lors de la manipulation de la poudre.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger à faible dose.',
    'Oxydants forts.',
    'Récipient fermé, au frais et au sec, à l''abri de la chaleur excessive.',
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
  (v_academie_id, 'Co-émulsifiant et agent de texture en cosmétique',
   'Faire fondre 1 à 5% dans la phase grasse à 70°C avant émulsification avec la phase aqueuse.',
   'plage', 1, 5, '% de la phase grasse', '70°C (fusion)', 'Pendant l''émulsification', false, 0);

  -- ------------------------------------------------------------
  -- Alcool dénaturé
  -- ------------------------------------------------------------
  v_material_id := '6cfb0479-1ae1-4e22-b652-108683bd44de'::uuid;

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
    'Éthanol dénaturé, mélange d''éthanol et d''agents dénaturants (C₂H₅OH + adjuvants)',
    'Alcool à brûler, éthanol dénaturé',
    'Technique',
    'Liquide incolore, mobile, odeur d''alcool caractéristique',
    'Neutre',
    'Miscible à l''eau et à la plupart des solvants organiques',
    0.79, 13,
    'Éthanol rendu impropre à la consommation par ajout de dénaturants (amertume, odeur). Très inflammable. Excellent solvant de dilution, nettoyant et dégraissant. Coût inférieur à l''éthanol pur.',
    'Identique à l''éthanol pur comme solvant, mais ne peut pas être utilisé pour des applications alimentaires ou pharmaceutiques. Plus économique pour le nettoyage technique.',
    'Élevé',
    array['gants','lunettes','ventilation'],
    'Gants résistants aux solvants (nitrile), lunettes de sécurité. Manipuler loin des flammes.',
    'Inhalation : air frais. Peau : laver. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas faire vomir, appeler un médecin.',
    'Oxydants forts, acides forts, bases fortes.',
    'Bidon métallique ou PEHD, local ventilé, à l''écart des flammes et sources de chaleur.',
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
  (v_academie_id, 'Solvant de nettoyage et dilution de peintures/vernis',
   'Appliquer pur sur un chiffon pour dégraisser, ou ajouter 5-20% au produit à diluer.',
   'plage', 5, 100, '% (pur ou dilué selon besoin)', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Alcool isopropylique (IPA)
  -- ------------------------------------------------------------
  v_material_id := '54c65b90-6d80-46bd-869b-d2983d52bd04'::uuid;

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
    'Propan-2-ol (C₃H₈O)',
    'IPA, isopropanol, alcool à friction',
    'Technique',
    'Liquide incolore, mobile, odeur d''alcool prononcée',
    'Neutre',
    'Miscible à l''eau, à l''éthanol et à la plupart des solvants organiques',
    0.79, 12,
    'Très inflammable. Excellent dégraissant et solvant de nettoyage rapide. S''évapore sans laisser de résidu. Moins réglementé que l''éthanol (pas de droit d''accise).',
    'Dégraisse mieux que l''éthanol. Plus toxique que l''éthanol, ne doit pas être utilisé pour les gels hydroalcooliques pour les mains. Point d''éclair plus bas que le carbonate de propylène.',
    'Élevé',
    array['gants','lunettes','ventilation'],
    'Gants en nitrile, lunettes de sécurité. Manipuler loin des flammes. Ventilation adéquate.',
    'Inhalation : air frais. Peau : laver. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas vomir, appeler un médecin.',
    'Oxydants forts, acides forts.',
    'Bidon métallique ou PEHD, local ventilé, à l''écart des flammes.',
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
  where code in ('P210', 'P233', 'P261', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Dégraissant et solvant de nettoyage technique',
   'Appliquer l''IPA pur avec un chiffon non pelucheux sur la surface à dégraisser. Laisser sécher à l''air.',
   'valeur_unique', 100, null, '% (pur)', 'Ambiante', 'Quelques secondes', false, 0),
  (v_academie_id, 'Solvant de dilution pour résines et vernis',
   'Ajouter 5 à 20% au produit à diluer, bien agiter.',
   'plage', 5, 20, '% du volume du produit', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Éthanol (alcool éthylique)
  -- ------------------------------------------------------------
  v_material_id := '2acf4ee8-3aaf-4491-96b2-136e78f712a3'::uuid;

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
    'Éthanol, alcool éthylique (C₂H₅OH)',
    'Alcool éthylique, alcool pur, éthanol 96%',
    'Alimentaire',
    'Liquide incolore, mobile, odeur alcoolisée caractéristique',
    'Neutre',
    'Miscible à l''eau, à l''éther, au glycérol et à la plupart des solvants organiques',
    0.79, 13,
    'Très inflammable. Solvant polaire le plus utilisé en extraction végétale, parfumerie et formulation cosmétique. Le grade alimentaire/pharmaceutique est exempt de dénaturants.',
    'Par rapport à l''IPA, il est moins toxique et autorisé en alimentaire. Moins efficace pour dégraisser que l''acétone, mais indispensable pour les teintures mères et extraits hydroalcooliques.',
    'Élevé',
    array['gants','lunettes','ventilation'],
    'Gants résistants aux solvants (nitrile), lunettes de sécurité. Manipuler loin des flammes.',
    'Inhalation : air frais. Peau : laver. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas faire vomir.',
    'Oxydants forts, acides forts, bases fortes.',
    'Bidon métallique ou verre, local ventilé, à l''écart des flammes et sources de chaleur.',
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
  (v_academie_id, 'Solvant d''extraction pour teintures mères et extraits végétaux',
   'Macérer la plante dans un mélange eau/éthanol (30 à 90% d''alcool) pendant plusieurs jours, filtrer.',
   'plage', 60, 90, '% d''alcool dans le mélange d''extraction', 'Ambiante', 'Plusieurs jours', false, 0),
  (v_academie_id, 'Solvant de formulation en parfumerie et cosmétique',
   'Ajouter 10 à 90% comme base solvante pour les parfums, lotions et sprays.',
   'plage', 10, 90, '% du produit fini', 'Ambiante', 'Pendant la formulation', false, 1);

  -- ------------------------------------------------------------
  -- Méthanol
  -- ------------------------------------------------------------
  v_material_id := '0485caa0-b4b4-4f49-9442-b608eafbc762'::uuid;

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
    'Méthanol, alcool méthylique (CH₃OH)',
    'Alcool de bois, carbinol',
    'Technique',
    'Liquide incolore, mobile, odeur alcoolisée légèrement piquante',
    'Neutre',
    'Miscible à l''eau, à l''éthanol et à la plupart des solvants organiques',
    0.79, 11,
    'Très inflammable. Extrêmement toxique par ingestion, inhalation ou contact cutané prolongé (cécité, atteinte du système nerveux). Usage strictement technique, interdit en cosmétique et alimentaire.',
    'Solvant plus polaire que l''éthanol, dissout mieux certains sels et résines. Beaucoup plus toxique : ne doit en aucun cas remplacer l''éthanol pour un usage autre qu''industriel confiné.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Gants en caoutchouc butyle, lunettes étanches, masque à vapeurs organiques. Ventilation forcée obligatoire. Interdit aux femmes enceintes.',
    'Inhalation : air frais, consulter immédiatement. Peau : rincer 15 min, retirer les vêtements contaminés. Yeux : rincer 15 min, consulter un ophtalmologue. Ingestion : appeler immédiatement un centre antipoison, ne pas faire vomir si la personne est inconsciente.',
    'Oxydants forts, acides forts, métaux alcalins.',
    'Bidon en acier ou verre, local frais et très bien ventilé, à l''écart des sources d''inflammation. Conserver sous clé.',
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
  select v_academie_id, id from public.phrases_h where code in ('H225', 'H301+H311+H331', 'H370')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P260', 'P280', 'P301+P310', 'P311')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Solvant technique de laboratoire et décapant',
   'Utiliser sous hotte comme solvant de réaction ou diluant. Ne jamais laisser à portée du public.',
   'texte_libre', null, null, 'Volume selon protocole', 'Ambiante', 'Variable', true, 0);

  -- ------------------------------------------------------------
  -- Propylène glycol
  -- ------------------------------------------------------------
  v_material_id := '4a7c57df-b773-4b85-a436-b65172a470c2'::uuid;

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
    'Propane-1,2-diol (C₃H₈O₂)',
    'PG, 1,2-propanediol, propylène glycol',
    'Alimentaire',
    'Liquide incolore, visqueux, inodore ou très légère odeur',
    'Neutre (6-7)',
    'Miscible à l''eau, à l''alcool et à de nombreux solvants organiques',
    1.04, 107,
    'Point d''éclair élevé, non volatil. Excellent humectant et solvant pour les arômes, colorants et conservateurs. Large gamme d''applications : alimentaire, cosmétique, technique.',
    'Par rapport au glycérol, il est moins visqueux et a un toucher moins collant. Solvant plus efficace que le butylène glycol pour certains conservateurs. Utilisé comme antigel alimentaire contrairement à l''éthylène glycol (toxique).',
    'Faible',
    array[]::text[],
    'Aucun obligatoire. Éviter le contact prolongé avec les yeux.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger aux doses usuelles.',
    'Oxydants forts, acides forts.',
    'Bidon en PEHD ou acier inox, local propre et sec, à l''abri du gel et de la chaleur excessive.',
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
  (v_academie_id, 'Solvant d''arômes et colorants alimentaires',
   'Prémélanger l''arôme ou le colorant dans 10-50% de propylène glycol avant incorporation dans la préparation.',
   'plage', 10, 50, '% du prémélange', 'Ambiante', 'Quelques minutes', false, 0),
  (v_academie_id, 'Humectant et solvant en cosmétique',
   'Incorporer 2 à 10% dans la phase aqueuse du produit.',
   'plage', 2, 10, '% du produit fini', 'Ambiante', 'Immédiat', false, 1);
end $$;
