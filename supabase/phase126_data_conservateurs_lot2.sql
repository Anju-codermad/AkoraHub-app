-- ============================================================
-- AkoraHub - Patch Phase 126 : fiches Académie pour le lot 2 (8
-- conservateurs naturels et alimentaires) des nouveaux produits
-- "Conservateurs & Antioxydants" — contenu DeepSeek, vérifié par
-- l'utilisatrice.
--
-- Lot 2/4 : Extrait de radis fermenté (Leucidal), Gluconolactone,
-- Acide lévulinique + Acide p-anisique, Acide salicylique (usage
-- conservateur cosmétique), Propionate de calcium (E282), Propionate
-- de sodium (E281), Acide propionique (E280), Natamycine (E235).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Extrait de radis fermenté (Leucidal)
  -- ------------------------------------------------------------
  v_material_id := '59503506-eeb2-44c6-892e-8490bb7a0da1'::uuid;

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
    'Mélange de peptides antimicrobiens issus de la fermentation de Leuconostoc kimchii (radis)',
    'Leuconostoc/Radish Root Ferment Filtrate, Leucidal, conservateur naturel fermenté',
    'Cosmétique',
    'Liquide jaune pâle à ambré, odeur caractéristique de fermentation légèrement acidulée',
    '3-4 (solution commerciale)',
    'Miscible à l''eau',
    1.05, null,
    'Conservateur naturel obtenu par fermentation de radis avec une bactérie lactique. Les peptides antimicrobiens produits agissent contre les bactéries Gram-positives, Gram-négatives, les levures et moisissures. Autorisé par les labels bio (Ecocert, Cosmos). Efficacité variable selon le pH et la formulation. Limite d''usage recommandée : 2-4 %. Doit être validé par un challenge test dans chaque formule.',
    'Contrairement au phénoxyéthanol ou aux parabènes, il est 100 % naturel et labelisable bio. Par rapport à la gluconolactone, il est un conservateur actif plutôt qu''un simple booster. Son efficacité est moins prédictible que les conservateurs synthétiques, nécessitant des tests systématiques.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Tensioactifs très alcalins (dénaturation des peptides), températures supérieures à 60°C prolongées.',
    'Bidon fermé, au frais (idéalement < 25°C), à l''abri de la lumière. Éviter la congélation.',
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
  (v_academie_id, 'Conservateur naturel pour crèmes, lotions, masques',
   'Ajouter 2 à 4 % en phase aqueuse en fin de formulation (température < 40°C). Ne pas chauffer au-dessus de 60°C. Valider par challenge test.',
   'plage', 2.0, 4.0, '% du produit fini', 'Ambiante à 40°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Gluconolactone
  -- ------------------------------------------------------------
  v_material_id := 'ffdfadb1-edb7-4ced-b82b-5f566c501589'::uuid;

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
    'D-glucono-1,5-lactone (C₆H₁₀O₆)',
    'Gluconolactone, GDL, E575, acide gluconique lactone, Geogard (en combinaison)',
    'Cosmétique, Alimentaire',
    'Poudre cristalline blanche, fine, inodore',
    'S''hydrolyse lentement en acide gluconique (pH 2-3 en solution)',
    'Très soluble dans l''eau (59 g/100 mL), s''hydrolyse en acide gluconique',
    0.80, null,
    'Conservateur doux et booster de conservation. S''hydrolyse lentement en acide gluconique qui abaisse le pH et chélate les métaux, créant un environnement défavorable aux micro-organismes. Autorisé par les labels bio. Efficacité modérée, souvent combiné avec le benzoate de sodium (Geogard). Limite d''usage : 0,5-2,0 %.',
    'Par rapport au DHA (acide déhydroacétique), il est plus doux et nécessite souvent un co-conservateur. Contrairement à l''extrait de radis fermenté, il agit par acidification et chélation plutôt que par peptides. Il est aussi utilisé comme acidulant doux.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter l''inhalation de poudre.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Bases fortes (neutralisation), milieux très alcalins.',
    'Récipient étanche, au sec, à l''abri de l''humidité (s''hydrolyse en présence d''eau).',
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
  (v_academie_id, 'Conservateur doux pour cosmétiques naturels (en combinaison)',
   'Ajouter 0,5-2,0 % en phase aqueuse. Pour une efficacité optimale, associer au benzoate de sodium (0,5-1,0 %). Le pH final doit être acide (4-5,5).',
   'plage', 0.5, 2.0, '% du produit fini', 'Ambiante à 50°C', 'Hydrolyse lente sur plusieurs heures', false, 0),
  (v_academie_id, 'Affineur de pâte en boulangerie et panification',
   'Ajouter 0,1-0,3 % dans la pâte. Acidifie progressivement la pâte et améliore la conservation.',
   'valeur_unique', 0.2, null, '% du poids de farine', 'Ambiante', 'Pendant la fermentation', false, 1);

  -- ------------------------------------------------------------
  -- Acide lévulinique + Acide p-anisique (blend conservateur naturel)
  -- ------------------------------------------------------------
  v_material_id := '4af7e949-9930-427d-b376-e890aea5bf39'::uuid;

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
    'Acide 4-oxopentanoïque (C₅H₈O₃) + Acide 4-méthoxybenzoïque (C₈H₈O₃)',
    'Levulinic Acid + p-Anisic Acid, Geogard 221, conservateur naturel sans donneurs de formaldéhyde',
    'Cosmétique',
    'Poudre blanche à blanc cassé (ou liquide selon la formulation), odeur neutre à légèrement acide',
    'Acide (3-4 en solution)',
    'Soluble dans l''eau chaude, les glycols, l''alcool. Faible solubilité dans l''eau froide.',
    1.10, null,
    'Combinaison synergique de deux acides organiques faibles. L''acide lévulinique est un acide cétonique dérivé de la cellulose, l''acide p-anisique est un dérivé de l''anis. Spectre large (bactéries, levures, moisissures). Efficace à pH < 5,5. Limite d''usage : 1-2 % pour le mélange. Accepté par les labels bio (Ecocert, Cosmos).',
    'Par rapport au benzoate de sodium + gluconolactone (Geogard), il est sans benzoate, ce qui évite les problèmes d''étiquetage (benzène). Contrairement à l''extrait de radis fermenté, il a une composition définie et une efficacité plus reproductible. Il n''est pas un peptide mais un mélange d''acides organiques.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière lors de la manipulation de la poudre.',
    'Yeux : rincer 15 min. Peau : laver. Ingestion : boire de l''eau, consulter un médecin si symptômes.',
    'Bases fortes (neutralisation), oxydants forts.',
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
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Conservateur naturel pour crèmes, gels, laits (label bio)',
   'Ajouter 1-2 % dans la phase aqueuse chaude (> 60°C) pour dissoudre. Ajuster le pH en dessous de 5,5 avec de l''acide citrique si nécessaire.',
   'plage', 1.0, 2.0, '% du produit fini', '60-70°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Acide salicylique (usage conservateur cosmétique)
  -- ------------------------------------------------------------
  v_material_id := '04f3545e-7c08-4fc8-9bd0-f4a5aa28e97a'::uuid;

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
    'Acide 2-hydroxybenzoïque (C₇H₆O₃)',
    'Salicylic Acid, acide salicylique, conservateur antimicrobien, BHA naturel',
    'Cosmétique',
    'Poudre cristalline blanche à aiguilles, inodore',
    'Acide (2,4 en solution saturée)',
    'Faible dans l''eau (0,2 % à 20°C), soluble dans l''alcool, les glycols, les huiles',
    1.44, 157.0,
    'Conservateur antimicrobien et ingrédient actif multifonctionnel. Actif sur les bactéries, levures et certaines moisissures. Efficace uniquement à pH acide (< 4). Limite réglementaire en cosmétique UE : 0,5 % (en tant que conservateur). Au-delà, il est considéré comme un ingrédient actif (kératolytique, exfoliant) et peut être utilisé jusqu''à 2 % selon le type de produit.',
    'Par rapport à l''acide benzoïque (E210), il a un groupe hydroxyle en position ortho qui lui confère des propriétés kératolytiques et anti-inflammatoires uniques. Contrairement au benzoate de sodium, il est plus actif mais nécessite un pH plus bas. Il est le seul conservateur qui est aussi un actif anti-acné reconnu.',
    'Modéré',
    array['gants','lunettes','masque'],
    'Gants en nitrile, lunettes, masque anti-poussière. Irritant pour la peau et les muqueuses à l''état pur.',
    'Yeux : rincer 15 min, consulter un ophtalmologue. Peau : laver à l''eau et au savon. Ingestion : rincer la bouche, boire de l''eau, appeler un médecin. Inhalation : air frais.',
    'Bases fortes, oxydants forts, sels de fer (coloration violette), iode.',
    'Récipient étanche, au sec, à l''abri de la lumière et de la chaleur.',
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H315', 'H318', 'H361d')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P201', 'P264', 'P280', 'P301+P312', 'P305+P351+P338', 'P308+P313')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Conservateur et actif anti-acné pour crèmes et lotions',
   'Dissoudre 0,2-0,5 % dans l''alcool ou le glycol avant incorporation dans la phase aqueuse chaude (60-70°C). Ajuster le pH en dessous de 4.',
   'plage', 0.2, 0.5, '% du produit fini (conservateur)', '60-70°C', 'Immédiat', false, 0),
  (v_academie_id, 'Conservateur pour produits bucco-dentaires (bains de bouche, dentifrices)',
   'Ajouter 0,1-0,3 % dans la phase alcoolique ou aqueuse. Efficace contre les bactéries buccales.',
   'valeur_unique', 0.2, null, '% du produit fini', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Propionate de calcium (E282)
  -- ------------------------------------------------------------
  v_material_id := '0d0bcc9e-c9fe-4a4e-bd1c-e0900cb825fb'::uuid;

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
    'Propanoate de calcium (Ca(C₃H₅O₂)₂)',
    'E282, Calcium Propionate, conservateur pour pain, inhibiteur de moisissures',
    'Alimentaire',
    'Poudre cristalline blanche, inodore ou très légère odeur acide',
    '7-8 (solution aqueuse à 10 %)',
    'Très soluble dans l''eau (49 g/100 mL à 20°C)',
    1.25, null,
    'Conservateur alimentaire de référence pour la panification industrielle et artisanale (usage majeur en boulangerie). Inhibe la croissance des moisissures et de Bacillus mesentericus (responsable du pain filant). Efficace à pH acide à neutre. N''altère pas le goût du pain à la dose recommandée. Limite UE : 1000-2000 mg/kg selon le produit.',
    'Par rapport au propionate de sodium (E281), il apporte du calcium (avantage nutritionnel, renforce la pâte) au lieu du sodium. Contrairement au sorbate de potassium, il n''inhibe pas les levures de boulangerie (Saccharomyces cerevisiae), ce qui le rend idéal pour le pain. Il ne bloque pas la fermentation.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière lors de la manipulation de grandes quantités. Peut être légèrement irritant pour les yeux.',
    'Yeux : rincer 15 min. Peau : laver. Ingestion : boire de l''eau.',
    'Acides forts (libération d''acide propionique volatil), sels de magnésium.',
    'Récipient étanche, au sec, à l''abri de l''humidité (hygroscopique).',
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
  (v_academie_id, 'Anti-moisissure pour pain de mie, pâtisserie, boulangerie',
   'Ajouter 0,1-0,3 % du poids de farine lors du pétrissage. Ne bloque pas la levée de la pâte. Efficace contre le pain filant.',
   'plage', 0.1, 0.3, '% du poids de farine', 'Ambiante', 'Pendant le pétrissage', false, 0);

  -- ------------------------------------------------------------
  -- Propionate de sodium (E281)
  -- ------------------------------------------------------------
  v_material_id := 'f99d617b-af1b-4225-b345-aee5a30b3c2e'::uuid;

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
    'Propanoate de sodium (NaC₃H₅O₂)',
    'E281, Sodium Propionate, conservateur anti-moisissure',
    'Alimentaire',
    'Poudre cristalline blanche, légère odeur d''acide propionique, hygroscopique',
    '8-9 (solution aqueuse à 10 %)',
    'Très soluble dans l''eau (99 g/100 mL à 20°C)',
    1.10, null,
    'Sel de sodium de l''acide propionique, conservateur alimentaire inhibant les moisissures et Bacillus mesentericus (pain filant), utilisé notamment en panification/boulangerie industrielle. Plus soluble que le propionate de calcium, mais apporte du sodium (attention au profil nutritionnel). Limite UE : identique au E282 (1000-2000 mg/kg). Efficace à pH acide à neutre. N''inhibe pas les levures de boulangerie.',
    'Par rapport au propionate de calcium (E282), il est plus soluble mais n''apporte pas de calcium. Il est préféré dans les préparations liquides ou lorsque le calcium pourrait interagir avec d''autres ingrédients (phosphates, alginates).',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière. Hygroscopique : éviter l''humidité.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Acides forts (libération d''acide propionique), sels de calcium.',
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
  (v_academie_id, 'Conservateur pour produits de boulangerie, snacks, fromages',
   'Ajouter 0,1-0,3 % du poids de la préparation. Dissoudre dans l''eau ou incorporer directement dans la pâte.',
   'plage', 0.1, 0.3, '% du produit fini', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Acide propionique (E280)
  -- ------------------------------------------------------------
  v_material_id := 'ba7769d6-df28-4c03-a300-e54ce8888515'::uuid;

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
    'Acide propanoïque (C₃H₆O₂)',
    'E280, Propionic Acid, acide propanoïque, conservateur alimentaire',
    'Alimentaire',
    'Liquide incolore, odeur piquante et âcre caractéristique (odeur de fromage)',
    'Très acide (pH 2,5 en solution à 1 %)',
    'Miscible à l''eau, à l''alcool et à l''éther en toutes proportions',
    0.99, 54.0,
    'Acide carboxylique court, conservateur alimentaire efficace contre les moisissures et certaines bactéries (Bacillus spp). Naturellement présent dans certains fromages (Emmental). Utilisé principalement en panification/boulangerie industrielle pour prévenir le pain filant (Bacillus mesentericus). Limite UE : 1000-3000 mg/kg selon l''aliment. N''inhibe pas les levures de boulangerie. Odeur forte qui peut limiter son usage.',
    'Par rapport à l''acide sorbique (E200), il est plus volatil et son odeur est plus marquée. Contrairement au benzoate, il ne nécessite pas un pH très bas (< 4) pour être actif. Il est le seul acide organique à ne pas inhiber Saccharomyces cerevisiae, ce qui le rend irremplaçable en boulangerie.',
    'Modéré',
    array['gants','lunettes','ventilation'],
    'Gants en nitrile, lunettes de sécurité, travailler dans un local ventilé. L''odeur est très forte et irritante pour les voies respiratoires.',
    'Inhalation : air frais. Peau : rincer 15 min, retirer les vêtements contaminés. Yeux : rincer 15 min, consulter un ophtalmologue. Ingestion : rincer la bouche, ne pas faire vomir, appeler un médecin.',
    'Bases fortes (neutralisation violente), oxydants forts, amines.',
    'Bidon en acier inoxydable ou PEHD, bien fermé, dans un local frais et ventilé, à l''écart des sources de chaleur et des bases.',
    5, 30, false, false, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H226', 'H314', 'H318', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P260', 'P280', 'P301+P330+P331', 'P303+P361+P353', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Anti-filant pour pain de mie et boulangerie industrielle',
   'Ajouter 0,1-0,2 % du poids de farine. Neutraliser partiellement avec de la soude ou utiliser directement les sels (E281/E282) pour masquer l''odeur.',
   'plage', 0.1, 0.2, '% du poids de farine', 'Ambiante', 'Pendant le pétrissage', false, 0);

  -- ------------------------------------------------------------
  -- Natamycine (E235)
  -- ------------------------------------------------------------
  v_material_id := '2d101d7a-9803-4d31-9316-3924ab0b5e73'::uuid;

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
    'Polyène macrolide antifongique (C₃₃H₄₇NO₁₃)',
    'E235, Natamycin, Pimaricine, fongicide de surface pour fromages et charcuteries',
    'Alimentaire',
    'Poudre cristalline blanche à blanc cassé, inodore',
    'Insoluble (se disperse en suspension colloïdale, pH neutre)',
    'Très faible dans l''eau (0,005 %), insoluble dans les huiles et la plupart des solvants. Se disperse en suspension aqueuse.',
    1.20, null,
    'Antifongique naturel produit par Streptomyces natalensis. Efficace contre les levures et moisissures (Aspergillus, Penicillium, Candida). Inefficace contre les bactéries. Utilisé exclusivement en traitement de surface des fromages et charcuteries (pulvérisation, trempage, badigeonnage). Ne pénètre pas dans la masse du produit. Limite UE : 1 mg/dm² de surface, profondeur de pénétration < 5 mm. Ne pas ingérer en grande quantité.',
    'Contrairement au sorbate de potassium ou au propionate, il est spécifiquement un fongicide de surface et ne peut pas être mélangé à la pâte. Par rapport au lysozyme (E1105), il cible les moisissures, pas les bactéries. Il est le seul antibiotique antifongique autorisé en alimentaire dans l''UE, avec des restrictions très strictes.',
    'Faible',
    array['masque','gants'],
    'Porter un masque anti-poussière et des gants. Éviter l''inhalation de la poudre et le contact prolongé avec la peau. Peut être sensibilisant.',
    'Inhalation : air frais, consulter si gêne respiratoire. Peau : laver au savon. Yeux : rincer 15 min. Ingestion : boire de l''eau.',
    'Agents oxydants forts, acides forts (dégradation).',
    'Récipient étanche, au frais, à l''abri de la lumière et de l''humidité.',
    2, 8, true, true, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H317', 'H334')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P272', 'P280', 'P302+P352', 'P304+P340', 'P342+P311')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Traitement de surface antifongique pour fromages et saucissons secs',
   'Préparer une suspension aqueuse à 0,1-0,2 %. Pulvériser, tremper ou badigeonner la surface du produit en fin d''affinage. Ne pas incorporer dans la masse. Respecter la limite de 1 mg/dm².',
   'valeur_unique', 0.15, null, '% de suspension aqueuse pour pulvérisation', '10-15°C (chambre d''affinage)', 'Séchage de surface après application', false, 0);
end $$;
