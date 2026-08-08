-- ============================================================
-- AkoraHub - Patch Phase 129 : fiches Académie pour les 15 produits
-- déjà présents dans le catalogue "Conservateurs & Antioxydants"
-- avant la campagne — contenu DeepSeek, vérifié par l'utilisatrice.
--
-- Termine la catégorie "Conservateurs & Antioxydants" (44/44 : 30
-- nouveaux en phases 125-128 + ces 14 produits déjà existants,
-- documentés en 15 fiches car "Acide ascorbique / Ascorbate Na
-- (E300/E301)" est un mélange combo distinct des deux produits
-- simples déjà présents).
--
-- "Salpêtre (Nitrate de potassium KNO₃ E252)" et "Salpêtre / Nitrate
-- de potassium (E252)" sont deux entrées quasi-identiques du
-- catalogue existant, documentées séparément avec un contenu
-- cohérent (ce n'est pas à l'IA de fusionner le catalogue existant).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Acide ascorbique (Vitamine C)
  -- ------------------------------------------------------------
  v_material_id := '4358cd56-345d-4d35-bf4c-45c537ccd214'::uuid;

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
    'Acide L-ascorbique (C₆H₈O₆)',
    'E300, Vitamine C, acide ascorbique, antioxydant alimentaire',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche à jaune pâle, odeur d''agrumes, saveur acide',
    '2,4-2,8 (solution à 1 %)',
    'Très soluble dans l''eau (33 g/100 mL à 20°C), soluble dans l''alcool, insoluble dans les huiles',
    1.65, null,
    'Antioxydant hydrosoluble puissant, piégeur d''oxygène et de radicaux libres. Protège les aliments et les cosmétiques contre l''oxydation. Également utilisé comme acidifiant et complément vitaminique. Limite UE : quantum satis dans la plupart des aliments. En cosmétique, jusqu''à 1 % comme antioxydant, jusqu''à 10 % comme actif.',
    'Par rapport à l''ascorbate de sodium (E301), il est acide et non salifié, ce qui abaisse le pH des formulations. Contrairement au palmitate d''ascorbyle (E304), il est hydrosoluble et ne protège pas les phases grasses.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter le contact avec les yeux (irritant léger).',
    'Yeux : rincer à l''eau. Peau : laver. Ingestion sans danger.',
    'Oxydants forts, métaux lourds (fer, cuivre), bases fortes.',
    'Récipient étanche, au frais, à l''abri de la lumière et de l''humidité. Sensible à la chaleur et à l''air.',
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Antioxydant et acidifiant pour boissons, conserves, pâtes de fruits',
   'Dissoudre 0,05-0,2 % dans la phase aqueuse en fin de préparation pour préserver l''activité vitaminique.',
   'plage', 0.05, 0.2, '% du produit fini', 'Ambiante à 40°C', 'Immédiat', false, 0),
  (v_academie_id, 'Actif éclaircissant et antioxydant en cosmétique (sérums, crèmes)',
   'Ajouter 1 à 5 % dans la phase aqueuse froide (pH < 4). Protéger de la lumière et de l''air.',
   'plage', 1.0, 5.0, '% du produit fini', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Acide ascorbique / Ascorbate Na (E300/E301)
  -- ------------------------------------------------------------
  v_material_id := '95dbde83-98f0-4a50-86b6-89fd3bf1cf8b'::uuid;

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
    'Mélange d''acide L-ascorbique (E300) et d''ascorbate de sodium (E301)',
    'Combo vitamine C + sel de sodium, antioxydant mixte',
    'Alimentaire, Cosmétique',
    'Poudre blanche à jaune pâle, odeur d''agrumes, saveur acide-salée',
    '5-6 (solution à 1 %)',
    'Très soluble dans l''eau, insoluble dans les huiles',
    null, null,
    'Mélange équilibré d''acide ascorbique et de son sel de sodium. Combine le pouvoir antioxydant et acidifiant de l''E300 avec la meilleure tolérance gastrique et le pH plus doux de l''E301. Utilisé comme antioxydant polyvalent et complément vitaminique. Limite UE : quantum satis dans les aliments.',
    'Par rapport à l''acide ascorbique seul (E300), ce mélange est moins acide et mieux toléré en usage direct. Comparé à l''ascorbate de sodium seul (E301), il apporte une acidité résiduelle bénéfique pour la conservation.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts, métaux lourds.',
    'Récipient étanche, au frais, à l''abri de la lumière et de l''humidité.',
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Antioxydant pour charcuteries, salaisons, plats préparés',
   'Ajouter 0,1-0,5 % dans la préparation. Accélère la formation de la couleur et prévient le rancissement.',
   'plage', 0.1, 0.5, '% du produit fini', 'Ambiante à 60°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Acide sorbique (E200)
  -- ------------------------------------------------------------
  v_material_id := '61b6a875-e7d8-4708-867c-011227ec1ec1'::uuid;

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
    'Acide 2,4-hexadiénoïque (C₆H₈O₂)',
    'Sorbic Acid, E200, conservateur alimentaire',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche à blanc cassé, odeur neutre à légèrement piquante',
    '3-4 (solution saturée)',
    'Faible dans l''eau (0,16 % à 20°C), soluble dans l''alcool, les glycols et les huiles chaudes',
    1.20, 127.0,
    'Conservateur actif sur les moisissures, levures et certaines bactéries. Efficace à pH < 6,5 (forme acide non dissociée). Largement utilisé en agroalimentaire (fromages, pâtisseries, boissons) et en cosmétique. Limite UE : 300-2000 mg/kg selon l''aliment. En cosmétique, 0,1-0,6 %. Souvent utilisé sous forme de sorbate de potassium (E202) pour sa meilleure solubilité.',
    'Par rapport au benzoate de sodium, il est actif à pH plus élevé (jusqu''à 6,5 contre 4,5) et a une meilleure image consommateur. Contrairement au propionate, il inhibe aussi les levures.',
    'Faible',
    array['gants','lunettes','masque'],
    'Gants en nitrile, lunettes, masque anti-poussière. Irritant pour les yeux et les voies respiratoires à l''état pur.',
    'Yeux : rincer 15 min. Peau : laver. Ingestion : boire de l''eau.',
    'Oxydants forts, bases fortes.',
    'Récipient étanche, au frais, à l''abri de la lumière et de l''humidité.',
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
  (v_academie_id, 'Conservateur antifongique pour fromages, pâtisseries, boissons',
   'Dissoudre dans l''eau chaude ou prémélanger à l''alcool/glycol. Ajouter 0,05-0,2 %. Efficace à pH < 6,5.',
   'plage', 0.05, 0.2, '% du produit fini', 'Ambiante à 70°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Ascorbate de sodium (E301)
  -- ------------------------------------------------------------
  v_material_id := 'cec3b8f9-6c7d-4a40-81ac-168f0767d445'::uuid;

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
    'L-ascorbate de sodium (C₆H₇NaO₆)',
    'Sodium Ascorbate, E301, vitamine C sodique, antioxydant alimentaire',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche à jaune très pâle, odeur d''agrumes, saveur salée',
    '6,5-7,5 (solution à 10 %)',
    'Très soluble dans l''eau (62 g/100 mL à 20°C), insoluble dans les huiles',
    1.65, null,
    'Sel de sodium de l''acide ascorbique. Mêmes propriétés antioxydantes que la vitamine C, mais moins acide et mieux toléré par l''estomac. Utilisé comme antioxydant, synergiste de conservation et source de vitamine C. Limite UE : quantum satis dans la plupart des aliments.',
    'Par rapport à l''acide ascorbique (E300), il est moins acide et ne modifie pas le pH des préparations. Contrairement à l''ascorbate de calcium (E302), il n''apporte pas de calcium et est plus soluble. Idéal pour les préparations liquides neutres.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts, métaux lourds.',
    'Récipient étanche, au frais, à l''abri de la lumière et de l''humidité.',
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Antioxydant pour charcuteries, salaisons, conserves',
   'Ajouter 0,1-0,5 % dans la préparation. Maintient la couleur rouge des viandes et prévient le rancissement.',
   'plage', 0.1, 0.5, '% du produit fini', 'Ambiante à 60°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Benzoate de sodium
  -- ------------------------------------------------------------
  v_material_id := '1fd84639-85c7-4eb0-85a4-ed601bc8b153'::uuid;

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
    'Benzoate de sodium (NaC₇H₅O₂)',
    'Sodium Benzoate, E211, conservateur alimentaire et cosmétique',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche, inodore ou très légère odeur d''amande',
    '7-8 (solution à 10 %)',
    'Très soluble dans l''eau (63 g/100 mL à 20°C), peu soluble dans l''alcool',
    1.50, null,
    'Sel de sodium de l''acide benzoïque. Conservateur antimicrobien actif sur les levures, moisissures et certaines bactéries. Efficace uniquement à pH < 4,5. Très utilisé dans les boissons acides, confitures, sauces et cosmétiques. Limite UE : 150-500 mg/kg selon l''aliment (exprimé en acide benzoïque). En cosmétique, 0,5 % en acide benzoïque (soit ~0,6 % de benzoate).',
    'Par rapport à l''acide benzoïque (E210), il est plus soluble dans l''eau. Comparé au sorbate de potassium (E202), il est moins efficace contre les moisissures mais plus actif contre les bactéries à pH très acide.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour la manipulation de grandes quantités. Peut être irritant pour les yeux.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Acides forts (libération d''acide benzoïque), oxydants forts, bases fortes.',
    'Récipient étanche, au sec, à l''abri de l''humidité.',
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
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Conservateur pour boissons gazeuses, sirops, confitures',
   'Dissoudre 0,05-0,1 % dans l''eau avant ajout aux autres ingrédients. Ajuster le pH en dessous de 4,5.',
   'plage', 0.05, 0.1, '% du produit fini', 'Ambiante à 70°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Benzoate de sodium + Sorbate de K (combo conserves)
  -- ------------------------------------------------------------
  v_material_id := 'ee47c00d-d7f0-422f-984f-6a923578242e'::uuid;

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
    'Mélange de benzoate de sodium (E211) et de sorbate de potassium (E202)',
    'Combo conservateur universel, benzoate/sorbate, conservateur de conserves',
    'Alimentaire',
    'Poudre blanche à blanc cassé, odeur neutre',
    '7-8 (solution aqueuse à 5 %)',
    'Très soluble dans l''eau (mélange des deux sels)',
    null, null,
    'Mélange synergique des deux conservateurs les plus utilisés. Le sorbate agit sur les moisissures et levures, le benzoate sur les bactéries et levures. Couverture à large spectre, efficace à pH 3-5. Utilisé dans les conserves de légumes, fruits, sauces, etc. Limites UE : respecter les doses maximales individuelles de chaque composant (E211 et E202).',
    'Par rapport à chaque conservateur utilisé seul, ce combo offre un spectre plus large et une meilleure efficacité à pH intermédiaire. Il est la solution prête à l''emploi pour les artisans conserviers.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Acides forts, oxydants forts.',
    'Récipient étanche, au sec, à l''abri de l''humidité.',
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
  (v_academie_id, 'Conservateur universel pour conserves de légumes, fruits, sauces',
   'Dissoudre 0,1-0,3 % dans la saumure ou le sirop avant remplissage des bocaux. Efficace à pH < 5.',
   'plage', 0.1, 0.3, '% du produit fini', 'Ambiante à 80°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Lysozyme (E1105)
  -- ------------------------------------------------------------
  v_material_id := '5725286b-6bfd-4a41-88e2-b560eab2e9cf'::uuid;

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
    'Enzyme muramidase (protéine de blanc d''œuf, famille des glycoside hydrolases)',
    'E1105, Lysozyme, muramidase, conservateur naturel fromager',
    'Alimentaire (fromager), Pharmaceutique',
    'Poudre blanche à crème, inodore, hygroscopique',
    'Actif à pH 3,5-6,5 (optimum 5,5)',
    'Soluble dans l''eau, insoluble dans l''alcool et les solvants organiques',
    1.20, null,
    'Enzyme naturelle extraite du blanc d''œuf. Lyse la paroi des bactéries Gram-positives (Clostridium, Listeria). Utilisé pour prévenir le gonflement tardif des fromages à pâte pressée cuite (Emmental, Comté). Inefficace contre les moisissures et bactéries Gram-négatives. Limite UE : quantum satis dans les fromages. Allergène : doit être mentionné sur l''étiquetage.',
    'Contrairement à la nisine (E234), il cible spécifiquement les bactéries Gram-positives sporulées et n''est pas un antibiotique polycyclique. Par rapport au nitrate (E252), il agit par lyse enzymatique et non par inhibition chimique. Il ne génère pas de nitrosamines.',
    'Faible',
    array['masque','gants'],
    'Porter un masque anti-poussière et des gants pour éviter l''inhalation de la poudre enzymatique (sensibilisant respiratoire potentiel). Allergène œuf.',
    'Inhalation : air frais, consulter si gêne respiratoire. Peau : laver. Yeux : rincer 15 min. Ingestion : boire de l''eau.',
    'Températures > 65°C (dénaturation), alcool fort, agents oxydants, détergents anioniques.',
    'Récipient étanche, au frais (2-8°C), à l''abri de l''humidité et de la chaleur.',
    2, 8, true, false, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H319', 'H335', 'H334')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P280', 'P304+P340', 'P305+P351+P338', 'P342+P311')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Anti-gonflement pour fromages à pâte pressée cuite (Emmental, Comté)',
   'Ajouter 0,2-0,5 g pour 100 L de lait de fromagerie avant emprésurage. Agir avant cuisson (< 65°C).',
   'valeur_unique', 0.25, null, 'g/100 L de lait', '30-50°C (avant chauffage)', 'Action enzymatique pendant la maturation', false, 0);

  -- ------------------------------------------------------------
  -- Métabisulfite de potassium (E224) — 'Meta K'
  -- ------------------------------------------------------------
  v_material_id := '060dc596-27c3-4c30-ad77-8a0664b45be2'::uuid;

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
    'Disulfite de potassium (K₂S₂O₅)',
    'Potassium Metabisulfite, E224, Meta K, sulfite de potassium, antioxydant œnologique',
    'Œnologique, Alimentaire',
    'Poudre cristalline blanche à jaunâtre, odeur piquante de SO₂',
    '3,5-4,5 (solution à 1 %)',
    'Très soluble dans l''eau (45 g/100 mL à 20°C), insoluble dans l''alcool',
    1.20, null,
    'Sel de potassium libérant du dioxyde de soufre (SO₂) en milieu acide. Antioxydant, antiseptique et agent de conservation en vinification. Protège contre l''oxydation, les bactéries et les levures sauvages. Limite UE dans les vins : 150-400 mg/L de SO₂ total selon le type. Allergène : doit être étiqueté (sulfites > 10 mg/kg).',
    'Par rapport au métabisulfite de sodium (E223), il apporte du potassium plutôt que du sodium, bénéfique pour la fermentation. Contrairement à l''anhydride sulfureux gazeux, il est solide et facile à peser. C''est le sulfite de choix en œnologie haut de gamme.',
    'Modéré',
    array['gants','lunettes','masque','ventilation'],
    'Gants en nitrile, lunettes de sécurité, masque anti-poussière. Dégage du SO₂ au contact des acides ou à la chaleur. Travailler dans un local ventilé.',
    'Inhalation : air frais. Peau : laver. Yeux : rincer 15 min. Ingestion : rincer la bouche, boire de l''eau, appeler un médecin.',
    'Acides (dégagement rapide de SO₂), oxydants forts, bases fortes.',
    'Récipient étanche, au frais, à l''abri de l''humidité et des acides. Bien refermer après usage.',
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

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319', 'H335', 'H400')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P273', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Antioxydant et antiseptique en vinification (sulfitage)',
   'Dissoudre 0,1-0,3 g/L dans le moût ou le vin. Ajuster en fonction de l''analyse du SO₂ libre. Éviter le surdosage.',
   'plage', 0.1, 0.3, 'g/L de vin', '10-20°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Nisine (E234)
  -- ------------------------------------------------------------
  v_material_id := 'e8e8ca5c-67ec-4aed-9311-5df76a17d65a'::uuid;

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
    'Polypeptide antibiotique (C₁₄₃H₂₃₀N₄₂O₃₇S₇, peptide de fermentation de Lactococcus lactis)',
    'E234, Nisine, conservateur naturel laitier, antibiotique alimentaire',
    'Alimentaire (laitier)',
    'Poudre blanche à crème, inodore, hygroscopique',
    'Stable en milieu acide (pH < 5), inactivée à pH > 7',
    'Soluble dans l''eau acidulée, peu soluble dans l''eau pure, insoluble dans les solvants organiques',
    1.10, null,
    'Bactériocine produite par fermentation. Inhibe les bactéries Gram-positives (Clostridium, Listeria, Bacillus) en formant des pores dans la membrane cellulaire. Inefficace contre les Gram-négatives, levures et moisissures. Utilisé pour la conservation des fromages fondus, yaourts, crèmes dessert. Limite UE : 10-12,5 mg/kg selon le produit. Considéré comme un additif sûr, sans résistance croisée avec les antibiotiques médicaux.',
    'Contrairement au lysozyme (E1105), elle est produite par fermentation bactérienne et non extraite d''œuf. Par rapport au nitrate/nitrite, elle ne génère pas de nitrosamines. C''est le seul antibiotique alimentaire autorisé en UE.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière. Peut être sensibilisant par inhalation.',
    'Inhalation : air frais. Peau : laver. Yeux : rincer 15 min. Ingestion : boire de l''eau.',
    'Milieu alcalin (inactivation), oxydants forts, chaleur > 100°C prolongée.',
    'Récipient étanche, au frais (2-8°C), à l''abri de l''humidité et de la chaleur.',
    2, 8, true, false, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H319', 'H335')
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
  (v_academie_id, 'Conservateur pour fromages fondus, crèmes dessert, yaourts',
   'Dissoudre 10-12,5 mg/kg dans une petite quantité d''eau acidulée avant incorporation. Ajouter en fin de préparation.',
   'valeur_unique', 10.0, 12.5, 'mg/kg de produit fini', '40-60°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Nitrite de sodium / Sel nitrité (E250)
  -- ------------------------------------------------------------
  v_material_id := 'b8c60ae0-7d2a-4cb2-89a5-4c05f173f7c9'::uuid;

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
    'Nitrite de sodium (NaNO₂)',
    'Sodium Nitrite, E250, sel nitrité, conservateur de charcuterie',
    'Alimentaire (charcuterie, usage strict)',
    'Poudre cristalline blanche à jaunâtre, inodore ou très légère odeur nitreuse',
    'Neutre à légèrement alcalin (7-8 en solution)',
    'Très soluble dans l''eau (82 g/100 mL à 20°C)',
    2.17, null,
    'Conservateur de charcuterie, agent de couleur (fixe la myoglobine en rouge rose). Inhibe le développement de Clostridium botulinum (botulisme). Très toxique à l''état pur : provoque une méthémoglobinémie (sang incapable de transporter l''oxygène). Dangereux pour les enfants. En cuisson à haute température, peut former des nitrosamines cancérigènes. Limite UE stricte : 100-150 mg/kg de produit fini selon le type de charcuterie. Doit être utilisé en mélange avec du sel (sel nitrité 0,6 %) pour éviter les surdosages accidentels.',
    'Par rapport au nitrate de potassium (E252), il agit directement sans réduction préalable et est donc plus rapide mais plus dangereux à manipuler. Contrairement au sel nitrité (mélange), il est le composé pur et ne doit jamais être utilisé tel quel en cuisine artisanale sans balance de précision.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Gants en nitrile, lunettes de sécurité, masque anti-poussière. Ne jamais laisser à portée des enfants. Utiliser exclusivement dans un cadre professionnel avec des équipements de pesée de précision. Ne pas ingérer pur.',
    'Ingestion : appeler immédiatement un centre antipoison ou un médecin. Rincer la bouche. Ne pas faire vomir. Peau : rincer 15 min, retirer les vêtements contaminés. Yeux : rincer 15 min. Inhalation : air frais. En cas de suspicion de méthémoglobinémie (lèvres bleues, difficulté respiratoire), transport d''urgence à l''hôpital.',
    'Acides (dégagement de vapeurs nitreuses toxiques), amines (formation de nitrosamines), matières combustibles (peut aggraver un incendie).',
    'Récipient étanche, sous clé, à l''écart des acides, des amines et des sources de chaleur. Ne pas stocker avec des aliments non destinés à la transformation.',
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
  select v_academie_id, id from public.phrases_h where code in ('H272', 'H301', 'H315', 'H319', 'H400')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P220', 'P264', 'P270', 'P280', 'P301+P310', 'P305+P351+P338', 'P330', 'P370+P378')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Conservateur de charcuterie (jambon, saucisson, pâté)',
   'Utiliser exclusivement en mélange dilué (sel nitrité à 0,6 % de NaNO₂). Ne jamais utiliser le nitrite pur directement dans les préparations. Respecter strictement la dose maximale de 150 mg/kg de produit fini.',
   'valeur_unique', 100, 150, 'mg/kg de produit fini', 'Ambiante à 80°C (éviter la cuisson > 120°C qui favorise les nitrosamines)', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Salpêtre (Nitrate de potassium KNO₃ E252)
  -- ------------------------------------------------------------
  v_material_id := '1ab67e5d-279a-4ac8-ae8b-78c0e0d5fa69'::uuid;

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
    'Nitrate de potassium (KNO₃)',
    'Saltpetre, Potassium Nitrate, E252, salpêtre, conservateur de charcuterie',
    'Alimentaire (charcuterie, usage réglementé), Technique',
    'Poudre cristalline blanche ou cristaux incolores, inodore, saveur salée et fraîche',
    'Neutre (7 en solution)',
    'Très soluble dans l''eau (32 g/100 mL à 20°C), peu soluble dans l''alcool',
    2.11, null,
    'Conservateur traditionnel de charcuterie, agent de couleur. Le nitrate est réduit en nitrite par les bactéries de la viande, puis réagit avec la myoglobine. À utiliser exclusivement dans les salaisons à maturation longue (> 4 semaines). Risque de formation de nitrosamines cancérigènes en cuisson à haute température. Limite UE : 250-500 mg/kg de produit fini selon le type. Moins toxique que le nitrite pur, mais à manipuler avec précaution.',
    'Par rapport au nitrite de sodium (E250), il agit plus lentement (nécessite une réduction bactérienne) et est donc réservé aux longues maturations. C''est le salpêtre historique, remplacé en partie par le nitrite pour les productions rapides.',
    'Modéré',
    array['gants','lunettes','masque'],
    'Gants en nitrile, lunettes de sécurité, masque anti-poussière. Ne pas ingérer pur. Tenir hors de portée des enfants. Ne pas fumer.',
    'Ingestion : rincer la bouche, boire de l''eau, appeler un médecin si grande quantité. Peau : laver. Yeux : rincer 15 min. Inhalation : air frais.',
    'Acides forts (dégagement de vapeurs nitreuses), matières combustibles (comburant), amines (nitrosamines).',
    'Récipient étanche, sous clé, à l''écart des acides et des matières combustibles. Local frais et sec.',
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
  select v_academie_id, id from public.phrases_h where code in ('H272', 'H315', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P220', 'P264', 'P280', 'P305+P351+P338', 'P370+P378')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Conservateur de salaisons traditionnelles (saucisson sec, jambon cru)',
   'Ajouter 0,25-0,5 g/kg de viande en mélange avec le sel de salaison. Réservé aux produits à maturation longue (> 4 semaines). Ne pas dépasser 500 mg/kg de produit fini.',
   'plage', 250, 500, 'mg/kg de produit fini', 'Ambiante pendant la salaison, maturation à 10-15°C', 'Plusieurs semaines de maturation', false, 0);

  -- ------------------------------------------------------------
  -- Salpêtre / Nitrate de potassium (E252)
  -- ------------------------------------------------------------
  v_material_id := '480a890b-366a-4d8d-94f3-f200d1c5d9fb'::uuid;

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
    'Nitrate de potassium (KNO₃)',
    'Saltpetre, Potassium Nitrate, E252, salpêtre, conservateur de charcuterie',
    'Alimentaire (charcuterie), Technique',
    'Poudre cristalline blanche ou cristaux incolores, inodore',
    'Neutre (7)',
    'Très soluble dans l''eau (32 g/100 mL), peu soluble dans l''alcool',
    2.11, null,
    'Conservateur traditionnel, agent de couleur pour salaisons longues. Le nitrate se transforme lentement en nitrite sous l''action des bactéries. Risque de formation de nitrosamines en cuisson à haute température. Limite UE : 250-500 mg/kg. À manipuler avec précaution (comburant). Entrée équivalente à "Salpêtre (Nitrate de potassium KNO₃ E252)" déjà documentée séparément dans le catalogue.',
    'Identique au salpêtre documenté séparément dans le catalogue — deuxième entrée existante pour ce même produit.',
    'Modéré',
    array['gants','lunettes','masque'],
    'Gants en nitrile, lunettes, masque anti-poussière. Ne pas ingérer pur.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau, appeler un médecin si grande quantité.',
    'Acides, matières combustibles, amines.',
    'Récipient étanche, sous clé, à l''écart des acides et combustibles.',
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
  select v_academie_id, id from public.phrases_h where code in ('H272', 'H315', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P220', 'P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Salaisons traditionnelles longue durée',
   'Ajouter 0,25-0,5 g/kg de viande en mélange avec le sel de salaison. Réservé aux produits à maturation longue.',
   'plage', 250, 500, 'mg/kg', '10-15°C', 'Plusieurs semaines', false, 0);

  -- ------------------------------------------------------------
  -- Sel nitrité (0.6% NaNO₂ dans NaCl)
  -- ------------------------------------------------------------
  v_material_id := '8b52a7b3-8706-43eb-bbe8-e22484108cdd'::uuid;

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
    'Mélange de chlorure de sodium (NaCl) et de nitrite de sodium (NaNO₂) à 0,6 %',
    'Sel nitrité, sel de salaison, Pökelsalz, sel rose de Prague',
    'Alimentaire (charcuterie)',
    'Poudre cristalline blanche à légèrement rosée (coloré pour identification), odeur neutre',
    'Neutre (solution de NaCl légèrement alcaline)',
    'Très soluble dans l''eau (sel NaCl avec NaNO₂)',
    null, null,
    'Mélange prêt à l''emploi de sel fin et de nitrite de sodium (0,6 % de NaNO₂). Évite la manipulation dangereuse du nitrite pur. Assure une répartition homogène du conservateur dans la viande. Limite UE : respecter un dosage tel que la teneur en nitrite résiduel ne dépasse pas 100-150 mg/kg de produit fini. Le colorant rose (E127 ou E120) est ajouté pour distinguer ce sel du sel de table classique.',
    'Par rapport au nitrite de sodium pur (E250), il est sécurisé pour un usage artisanal car il est prédilué. Comparé au salpêtre (nitrate), il agit plus rapidement car il contient directement du nitrite. C''est le conservateur de charcuterie le plus utilisé en boucherie artisanale.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en nitrile, éviter l''inhalation de poudre. Ne pas confondre avec le sel de table (risque d''intoxication au nitrite). Tenir hors de portée des enfants.',
    'Ingestion accidentelle en grande quantité : appeler un médecin (risque de méthémoglobinémie). Yeux : rincer. Peau : laver.',
    'Acides (dégagement de vapeurs nitreuses), amines (nitrosamines).',
    'Récipient étanche, au sec, hors de portée des enfants. Ne pas stocker à proximité du sel de table non étiqueté.',
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
  (v_academie_id, 'Salaison de charcuterie (saucisses, jambon cuit, pâté)',
   'Utiliser 20-30 g de sel nitrité par kg de viande (soit 120-180 mg de NaNO₂/kg de viande). Mélanger intimement à la mêlée.',
   'valeur_unique', 25, null, 'g de sel nitrité par kg de viande', '4-8°C pendant malaxage', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Sorbate de potassium
  -- ------------------------------------------------------------
  v_material_id := '0b2a7297-273d-4236-a452-8c067df2eec7'::uuid;

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
    'Sorbate de potassium (KC₆H₇O₂)',
    'Potassium Sorbate, E202, conservateur alimentaire et cosmétique',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche à blanc cassé, inodore ou très légère odeur',
    '7-8 (solution à 10 %)',
    'Très soluble dans l''eau (58 g/100 mL à 20°C), peu soluble dans l''alcool',
    1.36, null,
    'Sel de potassium de l''acide sorbique. Conservateur antifongique et antilevure, très efficace en milieu acide (pH < 6,5). Largement utilisé en agroalimentaire (fromages, pâtisseries, boissons, conserves) et en cosmétique (crèmes, lotions, y compris en usage œnologique pour stabiliser les vins moelleux). Limite UE : 300-2000 mg/kg selon l''aliment. En cosmétique, 0,1-0,6 %.',
    'Par rapport à l''acide sorbique (E200), il est plus soluble dans l''eau et plus facile à manipuler. Contrairement au benzoate de sodium (E211), il est actif à pH plus élevé et ne génère pas de problème de benzène.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour la manipulation de grandes quantités. Peut être légèrement irritant pour les yeux.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Acides forts (libération d''acide sorbique), oxydants forts.',
    'Récipient étanche, au frais, à l''abri de l''humidité.',
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
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Conservateur antifongique pour fromages, yaourts, pâtisseries, boissons',
   'Dissoudre 0,1-0,3 % dans la phase aqueuse. Efficace à pH < 6,5.',
   'plage', 0.1, 0.3, '% du produit fini', 'Ambiante à 70°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Sulfite de sodium / Métabisulfite de sodium (E221/E223)
  -- ------------------------------------------------------------
  v_material_id := 'af36d762-426c-403a-a526-82423e5bb7db'::uuid;

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
    'Sulfite de sodium (Na₂SO₃) et disulfite de sodium (Na₂S₂O₅) — mélange ou individuel',
    'Sodium Sulfite, Sodium Metabisulfite, E221/E223, antioxydant œnologique',
    'Œnologique, Alimentaire',
    'Poudre cristalline blanche à jaunâtre, odeur piquante de SO₂',
    '3,5-5 (solution aqueuse)',
    'Très soluble dans l''eau (30-50 g/100 mL), peu soluble dans l''alcool',
    1.20, null,
    'Agents libérant du dioxyde de soufre (SO₂) en milieu acide. Antioxydants, antiseptiques et conservateurs en œnologie, cidrerie, fruits secs. Protègent contre le brunissement enzymatique, les bactéries et les levures sauvages. Limite UE dans les vins : 150-400 mg/L de SO₂ total. Allergènes (sulfites > 10 mg/kg). Le métabisulfite est la forme la plus concentrée en SO₂ (65 % de SO₂ libérable).',
    'Par rapport au métabisulfite de potassium (E224), il apporte du sodium au lieu du potassium, ce qui est parfois moins favorable pour la fermentation. Le métabisulfite (E223) est plus riche en SO₂ que le sulfite simple (E221).',
    'Modéré',
    array['gants','lunettes','masque','ventilation'],
    'Gants en nitrile, lunettes, masque anti-poussière. Dégage du SO₂ au contact des acides ou à la chaleur. Travailler dans un local ventilé.',
    'Inhalation : air frais. Peau : laver. Yeux : rincer 15 min. Ingestion : rincer la bouche, boire de l''eau, appeler un médecin.',
    'Acides (dégagement rapide de SO₂), oxydants forts, bases fortes.',
    'Récipient étanche, au frais, à l''abri de l''humidité et des acides.',
    5, 25, true, false, 18, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319', 'H335', 'H400')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P273', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Antioxydant et antiseptique en vinification, cidrerie, fruits secs',
   'Dissoudre 0,1-0,3 g/L dans le moût ou le vin (sulfitage). Pour les fruits secs, tremper dans une solution à 1-2 % pendant quelques minutes.',
   'plage', 0.1, 0.3, 'g/L de vin', '10-20°C', 'Immédiat', false, 0);
end $$;
