-- ============================================================
-- AkoraHub - Patch Phase 144 : fiches Académie pour les 37 nouveaux
-- produits de la catégorie "Tensioactifs" — contenu DeepSeek,
-- vérifié par l'utilisatrice.
-- Tensioactifs éthoxylés (Laureth, Ceteareth, PEG-40/PEG-7,
-- Polysorbate, Poloxamer, sulfosuccinates laureth) documentés avec
-- avertissement sur le risque de contamination résiduelle en
-- 1,4-dioxane et recommandation d'exiger un certificat d'analyse
-- du fournisseur. Tensioactifs cationiques de type ammonium
-- quaternaire documentés avec avertissement sur l'irritation
-- oculaire/muqueuses et les propriétés biocides à forte dose ;
-- Distearyldimonium Chloride documenté avec note sur sa
-- biodégradabilité limitée face aux esterquats (Quaternium-87).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Sodium Cocoyl Isethionate (SCI)
  -- ------------------------------------------------------------
  v_material_id := '560e8d9b-35b1-4d29-b3f1-158e2ae652ca'::uuid;

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
    'Sel de sodium de l''ester iséthionique d''acides gras de noix de coco',
    'SCI, Sodium Cocoyl Isethionate, tensioactif solide doux',
    'Cosmétique',
    'Paillettes ou poudre blanche à crème, odeur caractéristique faible',
    '5-7 (solution à 1 %)',
    'Soluble dans l''eau chaude, partiellement soluble à froid',
    null, null,
    'Tensioactif anionique très doux, souvent utilisé dans les savons syndets sans savon et les shampoings solides. Excellent pouvoir moussant, tolérance cutanée exceptionnelle. Non éthoxylé, pas de risque 1,4-dioxane.',
    'Comparé au SLSA (Sodium Lauryl Sulfoacetate), le SCI est plus doux, mousse plus crémeusement et laisse un toucher moins rêche. Il est considéré comme le tensioactif solide de référence pour les peaux sensibles.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour la manipulation de la poudre.',
    'Yeux : rincer 15 min. Peau : laver à l''eau. Inhalation : air frais.',
    'Oxydants forts, acides forts (hydrolyse de l''ester).',
    'Récipient étanche, au sec, à température ambiante.',
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
  (v_academie_id, 'Savons syndets solides et shampoings solides',
   'Faire fondre le SCI dans un bain-marie (70-80 °C) avec un peu d''eau ou de glycérine, ajouter les autres ingrédients et couler en moule. Ne pas surchauffer. Utiliser 30-70 % de la formule.',
   'plage', 30, 70, '% de la formule solide', '70-80 °C', 'Solidification en 1-2 h', false, 0);

  -- ------------------------------------------------------------
  -- Disodium Laureth Sulfosuccinate
  -- ------------------------------------------------------------
  v_material_id := '8268cf1e-414f-4e14-b070-1199a1d42c65'::uuid;

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
    'Sel disodique du sulfosuccinate d''alcool laurique éthoxylé',
    'Disodium Laureth Sulfosuccinate, tensioactif doux pour bébé',
    'Cosmétique',
    'Liquide visqueux incolore à jaune pâle, odeur neutre',
    '6-7 (solution à 1 %)',
    'Miscible à l''eau',
    1.05, null,
    'Tensioactif anionique très doux, bien toléré par les muqueuses. Utilisé dans les gels douche et shampoings pour bébé. Contient des motifs éthoxylés : risque potentiel de contamination résiduelle en 1,4-dioxane (cancérogène possible). Exiger un certificat d''analyse du fournisseur garantissant une teneur en 1,4-dioxane inférieure aux seuils réglementaires (10 ppm).',
    'Comparé au Disodium Lauryl Sulfosuccinate, la version laureth (éthoxylée) est plus soluble dans l''eau et donne une mousse plus abondante, mais avec le risque 1,4-dioxane. Le SLES est plus détergent mais moins doux.',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes recommandés pour la manipulation du concentré.',
    'Yeux : rincer abondamment. Peau : laver.',
    'Oxydants forts, acides forts.',
    'Bidon hermétique, à température ambiante, à l''abri du gel.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Shampoings et gels douche très doux (adultes, bébés)',
   'Incorporer 5 à 15 % dans la phase aqueuse sous agitation. Efficace seul ou en combinaison avec des tensioactifs plus moussants.',
   'plage', 5, 15, '% du produit fini', 'Ambiante à 40 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Disodium Lauryl Sulfosuccinate
  -- ------------------------------------------------------------
  v_material_id := 'e6733990-bc96-4c7c-9da5-f71e7969d90d'::uuid;

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
    'Sel disodique du sulfosuccinate d''alcool laurique',
    'Disodium Lauryl Sulfosuccinate, tensioactif doux sans éthoxylation',
    'Cosmétique',
    'Liquide visqueux incolore à jaune très pâle, ou poudre blanche, odeur neutre',
    '6-7 (solution à 1 %)',
    'Soluble dans l''eau',
    1.05, null,
    'Tensioactif anionique doux, non éthoxylé : pas de risque 1,4-dioxane. Bonne tolérance cutanée et oculaire. Faible pouvoir détergent mais excellente douceur. Souvent utilisé dans les formulations "sans sulfates" ou "sans SLES".',
    'Comparé au Disodium Laureth Sulfosuccinate, il est plus sûr (pas de 1,4-dioxane) mais peut être moins soluble. Il est plus doux que le SCI mais produit une mousse moins crémeuse.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver.',
    'Acides forts, oxydants forts.',
    'Bidon hermétique, à température ambiante. Protéger du gel.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Gels douche et shampoings "sans sulfates"',
   'Incorporer 5 à 15 % dans la phase aqueuse sous agitation douce. Peut être associé à un alkyl polyglucoside pour améliorer la viscosité.',
   'plage', 5, 15, '% du produit fini', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Sodium Methyl Cocoyl Taurate
  -- ------------------------------------------------------------
  v_material_id := 'fdd9aaeb-1175-471c-84f8-cff4e79d67d7'::uuid;

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
    'Sel de sodium du N-méthyl N-cocoyl taurate',
    'Sodium Methyl Cocoyl Taurate, taurate de coco, tensioactif doux',
    'Cosmétique',
    'Pâte blanche à crème, ou poudre, odeur caractéristique faible',
    '6-8 (solution à 1 %)',
    'Soluble dans l''eau chaude',
    null, null,
    'Tensioactif anionique dérivé de la taurine, très doux, bonne biodégradabilité. Mousse crémeuse et stable, même en eau dure. Non éthoxylé, pas de risque 1,4-dioxane. Stable sur une large plage de pH (3-10).',
    'Comparé au SCI, le taurate donne une mousse plus dense et plus stable. Il est plus doux que le SLS mais moins moussant. Apprécié dans les formules haut de gamme "sans sulfates".',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour la manipulation de la poudre.',
    'Yeux : rincer. Peau : laver.',
    'Acides forts, oxydants forts.',
    'Récipient étanche, au sec, à température ambiante.',
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319')
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
  (v_academie_id, 'Shampoings, gels douche et nettoyants visage doux',
   'Incorporer 10 à 30 % dans la phase aqueuse, chauffer doucement pour dissoudre. Peut être utilisé seul ou en combinaison.',
   'plage', 10, 30, '% du produit fini', '40-60 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Sodium Cocoyl Glycinate
  -- ------------------------------------------------------------
  v_material_id := '3d7e6c87-61b6-4b80-8243-0864cdef2bd5'::uuid;

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
    'Sel de sodium du N-cocoyl glycinate',
    'Sodium Cocoyl Glycinate, glycinate de coco, tensioactif doux sans sulfate',
    'Cosmétique',
    'Liquide visqueux incolore à jaune pâle, odeur neutre',
    '7-8 (solution à 1 %)',
    'Miscible à l''eau',
    1.05, null,
    'Tensioactif anionique très doux, dérivé de l''acide aminé glycine. Mousse fine et crémeuse. Non éthoxylé, pas de risque 1,4-dioxane. Excellente tolérance cutanée et oculaire. Utilisé dans les formules "sans sulfates" et pour bébés.',
    'Comparé au Sodium Lauroyl Sarcosinate, le glycinate est plus doux et produit une mousse moins abondante mais plus crémeuse. Il est plus doux que le SCI mais moins moussant.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Acides forts, oxydants forts.',
    'Bidon hermétique, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Nettoyants visage, gels douche et shampoings doux',
   'Incorporer 5 à 20 % dans la phase aqueuse. Peut être utilisé seul ou avec d''autres tensioactifs doux.',
   'plage', 5, 20, '% du produit fini', 'Ambiante à 40 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Potassium Cocoate
  -- ------------------------------------------------------------
  v_material_id := '7d6547dc-8079-4f65-a17e-83b75c67a7f5'::uuid;

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
    'Sel de potassium des acides gras de noix de coco',
    'Savon potassique de coco, Potassium Cocoate, savon liquide naturel',
    'Cosmétique',
    'Liquide visqueux jaune pâle à ambré, ou pâte molle, odeur de savon',
    '9-10 (solution à 1 %)',
    'Très soluble dans l''eau',
    1.05, null,
    'Savon naturel obtenu par saponification de l''huile de coco avec de la potasse (KOH). Très soluble, mousse abondante en eau douce. pH alcalin (9-10). Mousse moins stable en eau dure (précipitation de savons calciques). 100 % biodégradable.',
    'Comparé au Sodium Cocoate (savon sodique), le savon potassique est liquide ou pâteux, alors que le sodique est solide. Le potassium donne un savon plus soluble et plus moussant. Très utilisé dans les savons liquides artisanaux.',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes pour manipuler le concentré alcalin.',
    'Yeux : rincer 15 min. Peau : laver.',
    'Acides (déstabilisation), eau dure (précipitation de savons calciques).',
    'Bidon hermétique, à température ambiante. Protéger du gel.',
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319')
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
  (v_academie_id, 'Savons liquides et gels douche naturels',
   'Utiliser pur ou dilué jusqu''à 20-40 % dans l''eau. Ajuster le pH avec de l''acide citrique si nécessaire (pH 8-9).',
   'plage', 20, 100, '% du produit fini', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Sodium Cocoate
  -- ------------------------------------------------------------
  v_material_id := 'dfbda587-9376-4611-8c39-5e1552f1ea2c'::uuid;

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
    'Sel de sodium des acides gras de noix de coco',
    'Savon sodique de coco, Sodium Cocoate, base pour savon solide',
    'Cosmétique',
    'Solide blanc à jaune pâle, cassant, odeur de savon',
    '9-10 (solution à 1 %)',
    'Soluble dans l''eau chaude, forme un gel en refroidissant',
    null, null,
    'Savon naturel obtenu par saponification de l''huile de coco avec de la soude (NaOH). Excellent pouvoir moussant et détergent. Très dur. pH alcalin. Inconvénient : peut être asséchant s''il est utilisé pur. Souvent mélangé à d''autres savons ou surgras.',
    'Comparé au Potassium Cocoate, le savon sodique est solide et moins soluble. Il est plus dur et plus moussant que le Sodium Palmate. Le Sodium Cocoate est le savon de référence pour la mousse en savonnerie.',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes pour manipuler le solide alcalin.',
    'Yeux : rincer. Peau : laver.',
    'Acides, eau dure.',
    'Récipient étanche, au sec.',
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

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319')
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
  (v_academie_id, 'Base pour savons solides (saponification à froid ou à chaud)',
   'Incorporer 15 à 40 % dans la formule de savon. Apporte dureté et mousse abondante. Toujours surgras ou mélanger avec des huiles plus douces pour éviter le dessèchement.',
   'plage', 15, 40, '% du poids des huiles', '30-50 °C', 'Saponification en 24-48 h', false, 0);

  -- ------------------------------------------------------------
  -- Sodium Stearate
  -- ------------------------------------------------------------
  v_material_id := '7b67628f-b251-4dc2-8eec-6e9db47812c2'::uuid;

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
    'Sel de sodium de l''acide stéarique',
    'Savon sodique d''acide stéarique, Sodium Stearate, agent de dureté',
    'Cosmétique',
    'Poudre blanche ou paillettes, cireuses, odeur faible',
    '9-10 (solution à 1 %)',
    'Soluble dans l''eau chaude, insoluble à froid',
    null, null,
    'Savon sodique issu de l''acide stéarique. Très peu moussant, il apporte dureté et résistance à l''eau aux savons solides. Sert également d''opacifiant et d''épaississant dans les crèmes et les détergents.',
    'Comparé au Sodium Palmate, le stéarate donne un savon plus dur mais mousse moins. Il est souvent utilisé en complément pour durcir les savons mous (ricin, olive).',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière.',
    'Yeux : rincer. Peau : laver.',
    'Acides, eau dure.',
    'Récipient étanche, au sec.',
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
  (v_academie_id, 'Agent de dureté dans les savons solides',
   'Incorporer 5 à 10 % du poids des huiles dans la formule de savon. Apporte dureté, résistance et un toucher sec.',
   'plage', 5, 10, '% du poids des huiles', '40-60 °C', 'Pendant la saponification', false, 0);

  -- ------------------------------------------------------------
  -- Sodium Palmate
  -- ------------------------------------------------------------
  v_material_id := '69e840ff-d738-4346-a7f4-26f30cf39980'::uuid;

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
    'Sel de sodium des acides gras de palme',
    'Savon sodique de palme, Sodium Palmate, base pour savon solide',
    'Cosmétique',
    'Paillettes ou pains solides blancs à jaune pâle, odeur de savon',
    '9-10 (solution à 1 %)',
    'Soluble dans l''eau chaude',
    null, null,
    'Savon sodique obtenu à partir d''huile de palme. Bon équilibre entre dureté et mousse. Moins moussant que le cocoate, mais plus doux pour la peau. Le plus utilisé dans les savons industriels.',
    'Comparé au Sodium Cocoate, le palmate est moins moussant mais plus doux et moins asséchant. Il est souvent le savon de base majoritaire dans les formulations.',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes pour manipuler le solide alcalin.',
    'Yeux : rincer. Peau : laver.',
    'Acides, eau dure.',
    'Récipient étanche, au sec.',
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

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319')
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
  (v_academie_id, 'Base majoritaire pour savons solides',
   'Incorporer 20 à 60 % dans la formule de savon. Apporte un bon équilibre entre dureté et douceur.',
   'plage', 20, 60, '% du poids des huiles', '30-50 °C', 'Saponification en 24-48 h', false, 0);

  -- ------------------------------------------------------------
  -- Ammonium Lauryl Sulfate
  -- ------------------------------------------------------------
  v_material_id := '968b9545-92ca-47cf-a5a8-c5a49555b34d'::uuid;

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
    'Sel d''ammonium du sulfate d''alcool laurique',
    'ALS, Ammonium Lauryl Sulfate, tensioactif moussant',
    'Cosmétique',
    'Liquide visqueux incolore à jaune pâle, odeur caractéristique',
    '6-7 (solution à 1 %)',
    'Miscible à l''eau',
    1.00, null,
    'Tensioactif anionique moussant, alternative au SLS. Bon rapport qualité/prix. Mousse abondante et dense. Peut être légèrement plus doux que le SLS, mais reste irritant pour les muqueuses à haute concentration. Non éthoxylé, pas de risque 1,4-dioxane.',
    'Comparé au SLS (sodium), l''ALS (ammonium) a une meilleure solubilité et peut être formulé à des concentrations plus élevées sans gélifier. Il est moins irritant que le SLS mais plus que le SLES.',
    'Modéré',
    array['gants','lunettes'],
    'Gants et lunettes pour manipuler le concentré. Éviter le contact avec les yeux.',
    'Yeux : rincer 15 min, consulter. Peau : laver. Inhalation : air frais.',
    'Tensioactifs cationiques, acides forts.',
    'Bidon hermétique, à température ambiante. Protéger du gel.',
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H318', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P280', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Shampoings, gels douche et savons liquides',
   'Incorporer 10 à 30 % dans la phase aqueuse sous agitation. Peut être combiné avec des tensioactifs doux pour réduire l''irritation.',
   'plage', 10, 30, '% du produit fini', 'Ambiante à 40 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Magnesium Laureth Sulfate
  -- ------------------------------------------------------------
  v_material_id := '5d0a4137-3863-42ff-a19d-0e14b73352be'::uuid;

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
    'Sel de magnésium du sulfate d''alcool laurique éthoxylé',
    'Magnesium Laureth Sulfate, tensioactif moussant doux',
    'Cosmétique',
    'Liquide visqueux incolore à jaune pâle, odeur neutre',
    '6-7 (solution à 1 %)',
    'Miscible à l''eau',
    1.00, null,
    'Tensioactif anionique éthoxylé, proche du SLES mais avec un contre-ion magnésium. Mousse abondante, toucher plus doux que le SLES sodique. Contient des motifs éthoxylés : risque potentiel de contamination résiduelle en 1,4-dioxane. Exiger un certificat d''analyse du fournisseur garantissant une teneur en 1,4-dioxane inférieure aux seuils réglementaires.',
    'Comparé au SLES (sodium), le Magnesium Laureth Sulfate est plus doux, moins irritant et donne un toucher plus soyeux. Il est souvent préféré dans les shampoings haut de gamme.',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes pour manipuler le concentré.',
    'Yeux : rincer. Peau : laver.',
    'Tensioactifs cationiques, acides forts.',
    'Bidon hermétique, à température ambiante.',
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319')
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
  (v_academie_id, 'Shampoings et gels douche premium',
   'Incorporer 10 à 25 % dans la phase aqueuse. Peut être utilisé seul ou en combinaison avec des amphotères.',
   'plage', 10, 25, '% du produit fini', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Sodium Lauryl Glucose Carboxylate
  -- ------------------------------------------------------------
  v_material_id := 'ea78a99b-43a2-42da-a142-3ebc050fa2fc'::uuid;

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
    'Sel de sodium du carboxylate de lauryl glucose',
    'Sodium Lauryl Glucose Carboxylate, tensioactif vert doux',
    'Cosmétique',
    'Liquide visqueux jaune pâle, odeur neutre',
    '7-8 (solution à 1 %)',
    'Miscible à l''eau',
    1.10, null,
    'Tensioactif anionique dérivé du glucose et d''alcool laurique. Extrêmement doux, non éthoxylé, pas de risque 1,4-dioxane. Certifié Ecocert / Cosmos. Utilisé dans les formules bio et pour peaux sensibles.',
    'Comparé au Sodium Lauryl Sulfate, il est infiniment plus doux et ne dessèche pas la peau. Proche du Coco Glucoside en termes de douceur, mais avec un caractère anionique plus marqué.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Tensioactifs cationiques, acides forts.',
    'Bidon hermétique, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Gels douche et shampoings bio / peaux sensibles',
   'Incorporer 5 à 20 % dans la phase aqueuse. Peut être utilisé seul ou en combinaison.',
   'plage', 5, 20, '% du produit fini', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Cetrimonium Chloride
  -- ------------------------------------------------------------
  v_material_id := 'f83e887f-9eba-4f9c-966e-e5d4ca0274a0'::uuid;

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
    'Chlorure de cétyltriméthylammonium',
    'Cetrimonium Chloride, CTAC, tensioactif cationique conditionneur',
    'Cosmétique',
    'Liquide incolore à jaune pâle, ou poudre blanche, odeur aminée',
    '6-8 (solution à 1 %)',
    'Soluble dans l''eau et l''alcool',
    0.97, null,
    'Tensioactif cationique, excellent conditionneur capillaire. Propriétés antimicrobiennes et biocides à forte concentration. Irritant pour les yeux et les muqueuses à l''état concentré. Dépôt sur la fibre capillaire pour un effet démêlant et antistatique.',
    'Comparé au Behentrimonium Methosulfate, le Cetrimonium Chloride a une chaîne carbonée plus courte (C16 vs C22), ce qui le rend plus irritant mais plus efficace comme biocide. Il est le cationique de référence pour les après-shampoings.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en nitrile et lunettes de sécurité. Éviter le contact avec les yeux et les muqueuses.',
    'Yeux : rincer 15 min, consulter un ophtalmologue. Peau : laver au savon. Ingestion : rincer la bouche, boire de l''eau, appeler un médecin.',
    'Tensioactifs anioniques (précipitation), oxydants forts.',
    'Bidon hermétique, à température ambiante. Protéger du gel.',
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H315', 'H318', 'H319', 'H335', 'H400')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P273', 'P280', 'P301+P312', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Après-shampoings, masques et démêlants',
   'Incorporer 0,5 à 2 % dans la phase aqueuse chaude (60-70 °C) de la crème de soin. Ne pas mélanger directement avec des anioniques.',
   'plage', 0.5, 2.0, '% du produit fini', '60-70 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Behentrimonium Methosulfate
  -- ------------------------------------------------------------
  v_material_id := '11ebc712-98ce-41b2-9f9d-b084410b40a2'::uuid;

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
    'Méthosulfate de béhényltriméthylammonium',
    'Behentrimonium Methosulfate, BTMS, conditionneur cationique doux',
    'Cosmétique',
    'Paillettes ou pastilles blanches, cireuses, fond vers 60 °C, odeur faible',
    '6-8 (solution à 1 %)',
    'Soluble dans l''eau chaude et les huiles chaudes',
    null, null,
    'Tensioactif cationique à longue chaîne (C22), très doux et excellent conditionneur. Il est aussi auto-émulsifiant : permet de créer des émulsions sans autre émulsifiant. Propriétés biocides modérées. Irritant pour les yeux à l''état concentré, mais beaucoup moins que le Cetrimonium Chloride.',
    'Comparé au Cetrimonium Chloride (C16), le BTMS a une chaîne plus longue, ce qui le rend plus doux, moins irritant et plus efficace comme conditionneur. Il est le cationique de référence pour les après-shampoings solides et les crèmes coiffantes.',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes pour manipuler à chaud.',
    'Yeux : rincer. Peau : laver.',
    'Tensioactifs anioniques (précipitation).',
    'Récipient étanche, au frais, à l''abri de l''humidité.',
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
  (v_academie_id, 'Après-shampoings solides et crèmes coiffantes',
   'Faire fondre 2 à 8 % avec les huiles et beurres à 65-70 °C. Ajouter la phase aqueuse chaude et émulsionner.',
   'plage', 2, 8, '% du produit fini', '65-70 °C', 'Refroidissement', false, 0);

  -- ------------------------------------------------------------
  -- Distearyldimonium Chloride
  -- ------------------------------------------------------------
  v_material_id := '1e713dec-d891-4640-b972-89d86513b0b0'::uuid;

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
    'Chlorure de distéaryldiméthylammonium',
    'Distearyldimonium Chloride, tensioactif cationique adoucissant',
    'Cosmétique, Technique',
    'Pâte molle ou paillettes jaunâtres, odeur aminée',
    '6-8 (dispersion à 1 %)',
    'Dispersible dans l''eau chaude, soluble dans les huiles chaudes',
    null, null,
    'Tensioactif cationique à deux chaînes grasses, excellent agent adoucissant et antistatique pour le linge et les cheveux. Potentiel irritant pour les yeux/muqueuses à l''état concentré. Sa biodégradabilité est limitée en raison de la structure dialkylée : il est progressivement remplacé par des esterquats (comme le Quaternium-87) plus biodégradables sur certains marchés.',
    'Comparé au Behentrimonium Methosulfate (mono-chaîne), le distearyldimonium est plus adoucissant mais moins conditionneur capillaire. Il est le cationique historique des adoucissants textiles.',
    'Modéré',
    array['gants','lunettes'],
    'Gants et lunettes pour manipuler le concentré. Irritant pour les muqueuses.',
    'Yeux : rincer 15 min, consulter. Peau : laver. Ingestion : boire de l''eau, appeler un médecin.',
    'Anioniques, oxydants forts.',
    'Récipient étanche, au frais, à l''abri de l''humidité.',
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H318', 'H319', 'H400')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P273', 'P280', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Adoucissants textiles et après-shampoings épais',
   'Disperser 3 à 8 % dans l''eau chaude (70 °C) sous agitation. Ajouter des silicones ou des huiles pour un toucher soyeux.',
   'plage', 3, 8, '% du produit fini', '70 °C', 'Refroidissement', false, 0);

  -- ------------------------------------------------------------
  -- Stearamidopropyl Dimethylamine
  -- ------------------------------------------------------------
  v_material_id := '748d094c-06ea-48ff-b3ba-a0fd5ac7ce14'::uuid;

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
    'N,N-diméthyl-3-(stéaramido)propylamine',
    'Stearamidopropyl Dimethylamine, conditionneur cationique non quaternaire',
    'Cosmétique',
    'Paillettes blanches à crème, cireuses, fond vers 50-60 °C, odeur aminée faible',
    'Alcalin (9-10 en dispersion)',
    'Insoluble dans l''eau (il est lipophile), soluble dans les huiles chaudes et les alcools gras',
    null, null,
    'Conditionneur cationique sans ammonium quaternaire, il s''active en milieu acide (pH 4-5) où il devient cationique. Très utilisé dans les après-shampoings pour son excellent démêlage et sa douceur. Contrairement aux quats, il n''est pas persistant dans l''environnement.',
    'Comparé au BTMS, il est plus doux et plus facile à manipuler (il fond plus bas). Il ne s''auto-émulsionne pas, il doit être formulé avec un émulsifiant. Il est préféré dans les formulations "quat-free".',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes pour manipuler le solide alcalin.',
    'Yeux : rincer. Peau : laver.',
    'Acides forts, bases fortes.',
    'Récipient étanche, au frais, à l''abri de l''humidité.',
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
  (v_academie_id, 'Après-shampoings et masques capillaires',
   'Faire fondre 1 à 4 % dans la phase grasse à 60-70 °C. Après émulsification, ajuster le pH à 4-5 avec de l''acide citrique pour activer le caractère cationique.',
   'plage', 1, 4, '% du produit fini', '60-70 °C', 'Refroidissement', false, 0);

  -- ------------------------------------------------------------
  -- Dicetyldimonium Chloride
  -- ------------------------------------------------------------
  v_material_id := 'a63dd949-1164-42ff-bed2-761c753e1886'::uuid;

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
    'Chlorure de dicétyldiméthylammonium',
    'Dicetyldimonium Chloride, tensioactif cationique à double chaîne',
    'Cosmétique',
    'Pâte blanche à jaune pâle, odeur aminée',
    '6-8 (dispersion à 1 %)',
    'Dispersible dans l''eau chaude, soluble dans les huiles',
    null, null,
    'Tensioactif cationique à deux chaînes cétyles (C16). Excellent conditionneur et agent antistatique. Potentiel irritant pour les yeux et muqueuses à l''état concentré. Propriétés biocides modérées. Biodégradabilité limitée mais meilleure que les dialkyl quats à chaînes plus longues.',
    'Similaire au Distearyldimonium Chloride mais avec des chaînes plus courtes (C16 vs C18), donc légèrement moins visqueux et un peu plus biodégradable. Utilisé principalement dans les soins capillaires.',
    'Modéré',
    array['gants','lunettes'],
    'Gants et lunettes. Éviter le contact avec les yeux.',
    'Yeux : rincer 15 min, consulter. Peau : laver.',
    'Anioniques, oxydants forts.',
    'Récipient étanche, au frais.',
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H318', 'H319', 'H400')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P273', 'P280', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Soins capillaires et adoucissants textiles',
   'Disperser 2 à 6 % dans l''eau chaude (70 °C). Ajouter des silicones pour un toucher soyeux.',
   'plage', 2, 6, '% du produit fini', '70 °C', 'Refroidissement', false, 0);

  -- ------------------------------------------------------------
  -- Quaternium-87
  -- ------------------------------------------------------------
  v_material_id := '0032acdc-b783-48e8-b085-3b5b3bd176ca'::uuid;

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
    'Esterquat de type diester de triéthanolamine, sel d''ammonium quaternaire',
    'Quaternium-87, esterquat, adoucissant biodégradable',
    'Cosmétique, Technique',
    'Pâte molle jaune pâle, fond vers 40-50 °C, odeur aminée faible',
    '6-8 (dispersion à 1 %)',
    'Dispersible dans l''eau chaude',
    null, null,
    'Esterquat biodégradable, développé pour remplacer les dialkyl quats (Distearyldimonium Chloride) dans les adoucissants. Il possède une liaison ester hydrolysable qui se rompt après usage, ce qui le rend facilement biodégradable. Excellent conditionneur et adoucissant, plus respectueux de l''environnement. Propriétés biocides modérées, irritant pour les yeux à l''état concentré.',
    'Comparé au Distearyldimonium Chloride, le Quaternium-87 est biodégradable et moins écotoxique. Il est légèrement moins efficace comme adoucissant mais représente la nouvelle génération de cationiques "verts".',
    'Modéré',
    array['gants','lunettes'],
    'Gants et lunettes pour manipuler le concentré. Éviter le contact avec les yeux.',
    'Yeux : rincer 15 min, consulter. Peau : laver.',
    'Anioniques, oxydants forts.',
    'Récipient étanche, au frais.',
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H318', 'H319', 'H400')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P273', 'P280', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Adoucissants textiles écologiques et après-shampoings',
   'Faire fondre 3 à 10 % dans l''eau chaude (60-70 °C) sous agitation. Formule un gel opaque ou une crème.',
   'plage', 3, 10, '% du produit fini', '60-70 °C', 'Refroidissement', false, 0);

  -- ------------------------------------------------------------
  -- Disodium Cocoamphodiacetate
  -- ------------------------------------------------------------
  v_material_id := 'e018047f-5556-4a1f-84e0-e38ebdc6a145'::uuid;

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
    'Sel disodique du N-[2-(N-(2-carboxylatoéthyl)-N-(2-hydroxyéthyl)amino)éthyl]cocamide',
    'Disodium Cocoamphodiacetate, tensioactif amphotère doux',
    'Cosmétique',
    'Liquide visqueux jaune pâle à ambré, odeur neutre',
    '8-9 (solution à 1 %)',
    'Miscible à l''eau',
    1.10, null,
    'Tensioactif amphotère extrêmement doux, bien toléré par la peau et les muqueuses. Stable en milieu acide et alcalin. Souvent utilisé dans les produits pour bébés et les nettoyants intimes. Mousse fine et stable, même en eau dure.',
    'Comparé à la Cocamidopropyl Betaine (CAPB), le cocoamphodiacetate est plus doux, moins moussant, mais mieux toléré par les muqueuses. Il est souvent préféré dans les formules ultra-douces "no tears".',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Cationiques à forte dose.',
    'Bidon hermétique, à température ambiante. Protéger du gel.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Shampoings et gels douche ultra-doux (bébés, peaux sensibles)',
   'Incorporer 5 à 15 % dans la phase aqueuse. Peut être utilisé seul ou en combinaison avec d''autres tensioactifs doux.',
   'plage', 5, 15, '% du produit fini', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Sodium Cocoamphoacetate
  -- ------------------------------------------------------------
  v_material_id := '1327513f-0a82-4dbc-bcac-eaffff88c8ed'::uuid;

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
    'Sel de sodium du N-[2-(N-(2-carboxylatoéthyl)-N-(2-hydroxyéthyl)amino)éthyl]cocamide',
    'Sodium Cocoamphoacetate, tensioactif amphotère doux',
    'Cosmétique',
    'Liquide visqueux jaune pâle, odeur neutre',
    '8-9 (solution à 1 %)',
    'Miscible à l''eau',
    1.05, null,
    'Amphotère très doux, similaire au disodium cocoamphodiacetate, mais avec un contre-ion sodium et un seul groupe carboxylate. Bonne tolérance cutanée, mousse fine et stable. Efficace même en eau dure.',
    'Comparé au Disodium Cocoamphodiacetate, la forme mono-sodique a un pH légèrement moins alcalin et peut être un peu plus moussante. Les deux sont interchangeables pour des formules ultra-douces.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Cationiques à forte dose.',
    'Bidon hermétique, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Nettoyants doux visage et corps',
   'Incorporer 5 à 15 % dans la phase aqueuse. Efficace seul ou en combinaison.',
   'plage', 5, 15, '% du produit fini', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Lauramidopropyl Betaine
  -- ------------------------------------------------------------
  v_material_id := '01cd1de6-bfe8-4d15-a1ef-9c8d22104263'::uuid;

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
    'N-(carboxylatométhyl)-N,N-diméthyl-3-(lauramido)propan-1-aminium',
    'Lauramidopropyl Betaine, tensioactif amphotère à chaîne laurique',
    'Cosmétique',
    'Liquide visqueux incolore à jaune pâle, odeur neutre',
    '5-7 (solution à 1 %)',
    'Miscible à l''eau',
    1.05, null,
    'Amphotère dérivé de l''acide laurique (C12). Mousse plus abondante que la CAPB (Coco), mais potentiel légèrement plus irritant en raison de la chaîne plus courte. Très utilisé pour booster la viscosité et la mousse des formules anioniques.',
    'Comparé à la Cocamidopropyl Betaine (CAPB, mélange de chaînes), la Lauramidopropyl Betaine a une mousse plus abondante mais est un peu moins douce. Elle est idéale pour les shampoings très moussants.',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes pour manipuler le concentré.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Bidon hermétique, à température ambiante.',
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319')
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
  (v_academie_id, 'Shampoings et gels douche à haute mousse',
   'Incorporer 5 à 15 % dans la phase aqueuse avec des tensioactifs anioniques. Aide à épaissir la formule.',
   'plage', 5, 15, '% du produit fini', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Coco-Betaine
  -- ------------------------------------------------------------
  v_material_id := '2a4088e9-746e-4a2d-8b59-b0b99a8df590'::uuid;

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
    'N-(carboxylatométhyl)-N,N-diméthyl-cocamidoalkylammonium',
    'Coco-Betaine, tensioactif amphotère économique',
    'Cosmétique',
    'Liquide visqueux jaune pâle à incolore, odeur neutre',
    '5-7 (solution à 1 %)',
    'Miscible à l''eau',
    1.05, null,
    'Amphotère proche de la CAPB, mais avec une distribution de chaînes grasses légèrement différente. Bon rapport qualité/prix. Mousse et propriétés épaississantes correctes, mais douceur légèrement inférieure à la CAPB.',
    'Comparé à la Cocamidopropyl Betaine, la Coco-Betaine a une structure sans le groupe amide propyle, ce qui la rend plus stable en milieu très alcalin mais un peu moins douce. Souvent utilisée comme alternative économique.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Bidon hermétique, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Shampoings et gels douche économiques',
   'Incorporer 5 à 15 % dans la phase aqueuse. Efficace en combinaison avec des anioniques.',
   'plage', 5, 15, '% du produit fini', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Cocamide MEA
  -- ------------------------------------------------------------
  v_material_id := '1c793150-0bc8-4e75-88bc-d818b9e727dd'::uuid;

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
    'Monoéthanolamide d''acide gras de noix de coco',
    'Cocamide MEA, monoéthanolamide de coco, épaississant moussant',
    'Cosmétique',
    'Paillettes ou pâte blanche à crème, fond vers 60-70 °C, odeur douce',
    'Alcalin (9-10 en dispersion)',
    'Dispersible dans l''eau chaude, soluble dans les tensioactifs',
    null, null,
    'Alcanolamide non ionique, utilisé comme agent épaississant et stabilisateur de mousse dans les shampoings et gels douche. Il améliore la viscosité et donne une mousse crémeuse. Non éthoxylé, pas de risque 1,4-dioxane. Considéré comme plus sûr que le Cocamide DEA.',
    'Comparé au Cocamide DEA, le Cocamide MEA est plus sûr (pas de formation de nitrosamines suspectées) et donne une texture plus solide. Il est le remplaçant moderne du DEA dans les formulations.',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes pour manipuler à chaud.',
    'Yeux : rincer. Peau : laver.',
    'Acides forts, oxydants forts.',
    'Récipient étanche, au sec, à l''abri de l''humidité.',
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
  (v_academie_id, 'Épaississant et stabilisateur de mousse en shampoings',
   'Faire fondre 1 à 4 % dans la phase tensioactive chaude (60-70 °C). Ajouter au reste de la formule sous agitation.',
   'plage', 1, 4, '% du produit fini', '60-70 °C', 'Refroidissement', false, 0);

  -- ------------------------------------------------------------
  -- Cocamide MIPA
  -- ------------------------------------------------------------
  v_material_id := 'c75f19df-f5c7-409b-bbf8-f493f9875c9f'::uuid;

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
    'Monoisopropanolamide d''acide gras de noix de coco',
    'Cocamide MIPA, monoisopropanolamide de coco, épaississant moussant',
    'Cosmétique',
    'Paillettes ou pâte blanche à crème, fond vers 50-60 °C, odeur douce',
    'Alcalin (9-10)',
    'Dispersible dans l''eau chaude',
    null, null,
    'Alcanolamide non ionique similaire au Cocamide MEA, mais fabriqué avec de l''isopropanolamine. Il est légèrement plus soluble et donne des formulations plus transparentes. Non éthoxylé, pas de risque 1,4-dioxane. Il est également exempt des préoccupations liées aux nitrosamines du DEA.',
    'Comparé au Cocamide MEA, le MIPA est plus facile à incorporer et donne des gels plus clairs. Il est légèrement moins efficace comme épaississant. Les deux sont interchangeables selon la clarté désirée.',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes pour manipuler à chaud.',
    'Yeux : rincer. Peau : laver.',
    'Acides forts, oxydants forts.',
    'Récipient étanche, au sec.',
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
  (v_academie_id, 'Épaississant et stabilisateur de mousse pour gels douche transparents',
   'Faire fondre 1 à 4 % dans la phase tensioactive chaude. Idéal pour les formules claires.',
   'plage', 1, 4, '% du produit fini', '50-60 °C', 'Refroidissement', false, 0);

  -- ------------------------------------------------------------
  -- Polysorbate 20
  -- ------------------------------------------------------------
  v_material_id := '55338f39-9cda-43e1-a228-eb2a70dac79b'::uuid;

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
    'Mono-laurate de sorbitane polyoxyéthyléné (20 OE)',
    'Polysorbate 20, Tween 20, émulsifiant non ionique',
    'Cosmétique, Alimentaire',
    'Liquide visqueux jaune, odeur caractéristique',
    '6-7 (solution à 1 %)',
    'Soluble dans l''eau et l''alcool',
    1.10, 150.0,
    'Tensioactif non ionique éthoxylé, utilisé comme solubilisant d''huiles essentielles et émulsifiant léger. HLB 16,7. Risque potentiel de contamination résiduelle en 1,4-dioxane. Exiger un certificat d''analyse du fournisseur.',
    'Comparé au Polysorbate 80 (oléate), le Polysorbate 20 (laurate) a une chaîne plus courte, ce qui le rend plus efficace pour solubiliser les huiles essentielles légères (agrumes). Il est aussi moins visqueux.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Bidon hermétique, à l''abri de la lumière.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Solubilisant d''huiles essentielles en cosmétique',
   'Mélanger 1 partie d''huile essentielle avec 4-8 parties de Polysorbate 20. Ajouter à la phase aqueuse sous agitation.',
   'plage', 4, 8, 'parties pour 1 partie d''huile essentielle', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Polysorbate 80
  -- ------------------------------------------------------------
  v_material_id := '3524a366-ea26-4632-bf0a-bf45be88629c'::uuid;

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
    'Mono-oléate de sorbitane polyoxyéthyléné (20 OE)',
    'Polysorbate 80, Tween 80, émulsifiant non ionique',
    'Cosmétique, Alimentaire',
    'Liquide visqueux jaune à ambré, odeur caractéristique',
    '6-7 (solution à 1 %)',
    'Soluble dans l''eau et l''alcool',
    1.08, 150.0,
    'Tensioactif non ionique éthoxylé, utilisé comme solubilisant, émulsifiant et dispersant. HLB 15. Large spectre d''applications cosmétiques et alimentaires. Risque potentiel de contamination résiduelle en 1,4-dioxane. Exiger un certificat d''analyse du fournisseur.',
    'Comparé au Polysorbate 20, le Polysorbate 80 est plus adapté aux huiles plus lourdes (olive, amande) et a un toucher plus émollient. Il est le solubilisant de référence pour les bains moussants.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Bidon hermétique, à l''abri de la lumière.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Solubilisant et émulsifiant en cosmétique et alimentaire',
   'Mélanger 1 partie d''huile avec 5-10 parties de Polysorbate 80. Ajouter à la phase aqueuse.',
   'plage', 5, 10, 'parties pour 1 partie d''huile', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Sorbitan Oleate (Span 80)
  -- ------------------------------------------------------------
  v_material_id := '4048fd97-dfb8-4512-852c-a607ef5ce1a6'::uuid;

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
    'Mono-oléate de sorbitane',
    'Sorbitan Oleate, Span 80, émulsifiant non ionique lipophile',
    'Cosmétique, Technique',
    'Liquide visqueux ambré, odeur grasse',
    'Non applicable (insoluble)',
    'Soluble dans les huiles, insoluble dans l''eau',
    1.00, 200.0,
    'Tensioactif non ionique lipophile (HLB 4,3). Utilisé comme émulsifiant pour les émulsions eau-dans-huile (E/H). Souvent combiné avec un polysorbate pour ajuster le HLB. Non éthoxylé, pas de risque 1,4-dioxane.',
    'Comparé au Sorbitan Stearate (Span 60, HLB 4,7), le Span 80 est liquide et plus adapté aux émulsions froides. Il est le co-émulsifiant de choix avec le Polysorbate 80.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Bidon hermétique, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Co-émulsifiant pour crèmes et baumes (E/H)',
   'Incorporer 1 à 5 % dans la phase grasse à 60-70 °C. Utiliser avec un polysorbate pour un système équilibré.',
   'plage', 1, 5, '% de la phase grasse', '60-70 °C', 'Pendant l''émulsification', false, 0);

  -- ------------------------------------------------------------
  -- Sorbitan Stearate (Span 60)
  -- ------------------------------------------------------------
  v_material_id := '6d8b7287-78c1-49ae-a001-090efe7ff0c7'::uuid;

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
    'Monostéarate de sorbitane',
    'Sorbitan Stearate, Span 60, émulsifiant non ionique lipophile',
    'Cosmétique',
    'Paillettes ou poudre blanche à crème, cireuse, fond vers 50-60 °C',
    'Non applicable (insoluble)',
    'Soluble dans les huiles chaudes, insoluble dans l''eau',
    null, null,
    'Tensioactif non ionique lipophile (HLB 4,7), solide à température ambiante. Utilisé comme émulsifiant E/H ou comme co-émulsifiant pour stabiliser les crèmes. Non éthoxylé, pas de risque 1,4-dioxane.',
    'Comparé au Span 80 (liquide), le Span 60 est solide et apporte plus de corps aux crèmes. Il est souvent associé au Polysorbate 60 pour un système HLB équilibré.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Récipient étanche, au frais.',
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
  (v_academie_id, 'Co-émulsifiant pour crèmes épaisses',
   'Faire fondre 1 à 4 % dans la phase grasse à 65-70 °C. Utiliser avec un polysorbate.',
   'plage', 1, 4, '% de la phase grasse', '65-70 °C', 'Pendant l''émulsification', false, 0);

  -- ------------------------------------------------------------
  -- Sorbitan Laurate (Span 20)
  -- ------------------------------------------------------------
  v_material_id := 'd2583557-0fa3-4a55-bc53-fa3d2c96494a'::uuid;

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
    'Monolaurate de sorbitane',
    'Sorbitan Laurate, Span 20, émulsifiant non ionique',
    'Cosmétique',
    'Liquide visqueux jaune pâle à ambré, odeur grasse',
    'Non applicable',
    'Soluble dans les huiles, dispersible dans l''eau chaude',
    1.00, null,
    'Tensioactif non ionique lipophile (HLB 8,6), ce qui le rend auto-dispersible dans l''eau. Utilisé comme co-émulsifiant et solubilisant doux. Non éthoxylé, pas de risque 1,4-dioxane.',
    'Comparé au Span 80, le Span 20 a un HLB plus élevé (8,6 vs 4,3), ce qui lui permet d''être utilisé seul pour certaines émulsions huile-dans-eau. Sa chaîne laurique le rend plus proche des tensioactifs classiques.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Bidon hermétique, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Co-émulsifiant et solubilisant doux',
   'Incorporer 1 à 5 % dans la phase grasse. Peut être utilisé seul pour des émulsions légères.',
   'plage', 1, 5, '% de la phase grasse', 'Ambiante à 60 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Laureth-4
  -- ------------------------------------------------------------
  v_material_id := '052995f5-d2e9-4baf-8350-3f351577c326'::uuid;

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
    'Alcool laurique éthoxylé (4 moles d''OE)',
    'Laureth-4, éther laurique polyoxyéthyléné, tensioactif non ionique',
    'Cosmétique',
    'Liquide incolore à jaune pâle, légèrement visqueux, odeur caractéristique',
    'Neutre (6-7 en dispersion aqueuse)',
    'Dispersible dans l''eau, soluble dans les huiles',
    0.95, 150.0,
    'Tensioactif non ionique éthoxylé à chaîne courte. Faiblement moussant, il est surtout utilisé comme co-émulsifiant, solubilisant de parfums et agent de consistance. Contient des motifs éthoxylés : risque potentiel de contamination résiduelle en 1,4-dioxane. Exiger un certificat d''analyse du fournisseur.',
    'Comparé au Laureth-7 (7 OE), le Laureth-4 est plus lipophile et moins soluble dans l''eau. Il est utilisé comme émulsifiant secondaire dans les crèmes et les huiles de bain.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Bidon hermétique, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Co-émulsifiant et solubilisant de parfums en cosmétique',
   'Incorporer 1 à 3 % dans la phase grasse ou le concentré de parfum. Efficace pour les huiles de bain et les émulsions légères.',
   'plage', 1, 3, '% du produit fini', 'Ambiante à 50 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Laureth-7
  -- ------------------------------------------------------------
  v_material_id := '9a40ad80-d2b2-4a7e-bfbd-2f86847a8966'::uuid;

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
    'Alcool laurique éthoxylé (7 moles d''OE)',
    'Laureth-7, éther laurique POE-7, tensioactif non ionique doux',
    'Cosmétique',
    'Liquide incolore à jaune pâle, visqueux, odeur caractéristique',
    'Neutre (6-7)',
    'Soluble dans l''eau, les huiles et l''alcool',
    0.98, 160.0,
    'Tensioactif non ionique éthoxylé, plus hydrophile que le Laureth-4 grâce aux 7 moles d''OE. Bon émulsifiant et dispersant. Contient des motifs éthoxylés : risque potentiel de contamination résiduelle en 1,4-dioxane. Exiger un certificat d''analyse.',
    'Comparé au Laureth-4, le Laureth-7 est soluble dans l''eau et peut servir d''émulsifiant principal pour des crèmes fluides. Il est l''intermédiaire entre le Laureth-4 et les Ceteareth plus lourds.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Bidon hermétique, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Émulsifiant et dispersant pour crèmes et lotions',
   'Incorporer 2 à 5 % dans la phase grasse. Efficace seul ou avec un co-émulsifiant.',
   'plage', 2, 5, '% du produit fini', '60-70 °C', 'Pendant l''émulsification', false, 0);

  -- ------------------------------------------------------------
  -- Ceteareth-20
  -- ------------------------------------------------------------
  v_material_id := '557fe587-342b-4e4f-b796-d80471f97cb8'::uuid;

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
    'Alcool cétylstéarylique éthoxylé (20 moles d''OE)',
    'Ceteareth-20, émulsifiant non ionique, Eumulgin B2',
    'Cosmétique',
    'Paillettes ou pastilles blanches, cireuses, fond vers 40-50 °C, odeur neutre',
    'Neutre (6-7 en dispersion)',
    'Soluble dans l''eau chaude, les huiles et l''alcool',
    null, null,
    'Tensioactif non ionique éthoxylé, très utilisé comme émulsifiant pour les crèmes huile-dans-eau (HLB ~15). Il apporte texture et stabilité. Contient des motifs éthoxylés : risque potentiel de contamination résiduelle en 1,4-dioxane. Exiger un certificat d''analyse du fournisseur.',
    'Comparé au Ceteareth-25, le Ceteareth-20 a une chaîne POE légèrement plus courte, ce qui le rend un peu moins épaississant mais plus facile à incorporer. C''est l''émulsifiant non ionique de référence pour les crèmes épaisses.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Émulsifiant pour crèmes épaisses et laits corporels',
   'Faire fondre 2 à 6 % dans la phase grasse à 65-70 °C. Verser la phase aqueuse chaude et émulsionner vigoureusement.',
   'plage', 2, 6, '% du produit fini', '65-70 °C', 'Refroidissement', false, 0);

  -- ------------------------------------------------------------
  -- Ceteareth-25
  -- ------------------------------------------------------------
  v_material_id := 'dd966737-fcf2-4c8f-affd-0a4d4306f480'::uuid;

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
    'Alcool cétylstéarylique éthoxylé (25 moles d''OE)',
    'Ceteareth-25, émulsifiant non ionique, Cremophor A25',
    'Cosmétique',
    'Paillettes ou pastilles blanches, cireuses, fond vers 45-55 °C',
    'Neutre (6-7)',
    'Soluble dans l''eau chaude et les huiles chaudes',
    null, null,
    'Tensioactif non ionique éthoxylé, très hydrophile (HLB ~16). Émulsifiant puissant pour les crèmes H/E, il donne des textures riches et onctueuses. Contient des motifs éthoxylés : risque de 1,4-dioxane. Exiger un certificat d''analyse.',
    'Comparé au Ceteareth-20, le Ceteareth-25 est plus hydrophile, ce qui donne des crèmes plus stables mais parfois plus collantes. Il est souvent utilisé en combinaison pour ajuster le HLB.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Récipient étanche, au frais.',
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
  (v_academie_id, 'Émulsifiant pour crèmes très stables',
   'Faire fondre 2 à 6 % dans la phase grasse à 65-70 °C. Émulsionner avec la phase aqueuse chaude.',
   'plage', 2, 6, '% du produit fini', '65-70 °C', 'Refroidissement', false, 0);

  -- ------------------------------------------------------------
  -- PEG-40 Hydrogenated Castor Oil
  -- ------------------------------------------------------------
  v_material_id := 'b8d21af3-1c77-4af8-9abd-a05d5cdbce45'::uuid;

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
    'Huile de ricin hydrogénée éthoxylée (40 moles d''OE)',
    'PEG-40 Hydrogenated Castor Oil, solubilisant non ionique',
    'Cosmétique',
    'Liquide visqueux jaune pâle à ambré, ou pâte molle, odeur caractéristique',
    'Neutre (6-7 en dispersion)',
    'Soluble dans l''eau et l''alcool',
    1.05, 200.0,
    'Tensioactif non ionique éthoxylé, excellent solubilisant pour les huiles essentielles, les parfums et les vitamines liposolubles dans les phases aqueuses. HLB 14-16. Contient des motifs éthoxylés : risque de 1,4-dioxane. Exiger un certificat d''analyse.',
    'Comparé au Polysorbate 20, le PEG-40 HCO est plus efficace pour les parfums complexes et les huiles essentielles lourdes. Il est également plus doux et plus hydratant.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Bidon hermétique, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Solubilisant d''huiles essentielles pour brumes et lotions aqueuses',
   'Mélanger 1 partie d''huile essentielle avec 5-10 parties de PEG-40 HCO. Ajouter à l''eau sous agitation.',
   'plage', 5, 10, 'parties pour 1 partie d''huile', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- PEG-7 Glyceryl Cocoate
  -- ------------------------------------------------------------
  v_material_id := 'a1783cb9-d8e9-4d31-ab4a-124006d1934e'::uuid;

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
    'Glycérides de noix de coco éthoxylés (7 moles d''OE)',
    'PEG-7 Glyceryl Cocoate, émollient hydrosoluble',
    'Cosmétique',
    'Liquide jaune pâle, visqueux, odeur grasse légère',
    'Neutre (6-7)',
    'Soluble dans l''eau et l''alcool',
    1.00, null,
    'Tensioactif non ionique éthoxylé, utilisé comme agent relipidant et solubilisant doux. Apporte un toucher soyeux et améliore la douceur des formules lavantes. Contient des motifs éthoxylés : risque de 1,4-dioxane. Exiger un certificat d''analyse.',
    'Comparé au PEG-40 HCO, le PEG-7 Glyceryl Cocoate a une chaîne POE plus courte, il est donc moins hydrophile mais plus relipidant. Il est souvent utilisé dans les gels douche pour compenser l''effet desséchant des sulfates.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Bidon hermétique, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Agent relipidant pour gels douche et shampoings',
   'Incorporer 1 à 5 % dans la phase tensioactive. Réduit le pouvoir desséchant des sulfates.',
   'plage', 1, 5, '% du produit fini', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Poloxamer 407
  -- ------------------------------------------------------------
  v_material_id := '3a3670f8-7ccd-489a-921e-56234b19e486'::uuid;

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
    'Copolymère bloc polyoxyéthylène-polyoxypropylène (POE₁₀₁-POP₅₆-POE₁₀₁)',
    'Poloxamer 407, Lutrol F127, Pluronic F127, gélifiant thermoréversible',
    'Cosmétique, Technique',
    'Poudre blanche ou granulés, inodore, fond vers 56 °C',
    'Neutre (6-7, solution à 10 %)',
    'Très soluble dans l''eau froide (forme un gel à température ambiante > 20 %), soluble dans l''alcool',
    1.05, null,
    'Copolymère non ionique éthoxylé/propoxylé. Propriété unique de gélification thermoréversible : liquide à froid, gel à température corporelle (concentration > 18 %). Utilisé pour les gels topiques, les bains de bouche et les formes pharmaceutiques. Contient des motifs éthoxylés : risque de 1,4-dioxane. Exiger un certificat d''analyse.',
    'Comparé au Poloxamer 188, le Poloxamer 407 a un poids moléculaire plus élevé et une température de gélification plus basse, ce qui le rend idéal pour les gels à température ambiante. Le 188 reste liquide à température corporelle.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts.',
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
  (v_academie_id, 'Gels topiques thermoréversibles et bains de bouche',
   'Dissoudre 15 à 25 % dans l''eau froide (5-10 °C) sous agitation. La solution se gélifiera en se réchauffant. Ajouter les actifs avant gélification.',
   'plage', 15, 25, '% du produit fini', '5-10 °C (dissolution)', 'Gélification à 20-30 °C', false, 0);

  -- ------------------------------------------------------------
  -- Poloxamer 188
  -- ------------------------------------------------------------
  v_material_id := '0ca57056-ece8-4ba9-ab20-f6089140d6c0'::uuid;

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
    'Copolymère bloc polyoxyéthylène-polyoxypropylène (POE₈₀-POP₂₇-POE₈₀)',
    'Poloxamer 188, Lutrol F68, Pluronic F68, tensioactif non ionique',
    'Cosmétique, Pharmaceutique',
    'Poudre blanche ou granulés, inodore',
    'Neutre (6-7, solution à 10 %)',
    'Très soluble dans l''eau froide',
    1.06, null,
    'Copolymère non ionique éthoxylé/propoxylé. Très doux, utilisé comme solubilisant, stabilisateur d''émulsion et agent mouillant. Ne gélifie pas à température corporelle (contrairement au 407), reste liquide. Contient des motifs éthoxylés : risque de 1,4-dioxane. Exiger un certificat d''analyse.',
    'Comparé au Poloxamer 407, le 188 a un poids moléculaire plus faible et reste liquide à toute température. Il est le tensioactif de choix pour les solutions injectables (grade pharmaceutique) en raison de sa biocompatibilité.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Récipient étanche, au sec.',
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
  (v_academie_id, 'Solubilisant et stabilisateur d''émulsions en cosmétique',
   'Dissoudre 1 à 5 % dans l''eau froide. Ajouter les huiles ou actifs sous agitation.',
   'plage', 1, 5, '% du produit fini', 'Ambiante', 'Immédiat', false, 0);
end $$;
