-- ============================================================
-- AkoraHub - Patch Phase 195 : complète le pilier "Akor'Eau" avec 3
-- nouveaux produits + rattrape un oubli de la Phase 189 — demande
-- explicite de la propriétaire le 04/09/2026 (liste structurée de ~40
-- produits de traitement de l'eau, dont une "gamme professionnelle de
-- base" de 15 produits à prioriser).
--
-- Sur les 15 produits de la gamme de base, la plupart existaient déjà
-- (soit déjà dans Akor'Eau depuis les phases 188-190, soit ailleurs en
-- tant que produits multi-usages qui restent dans leur catégorie
-- d'origine, conformément à la règle du 04/09/2026 : "ne déplacer que
-- les produits spécifiques à l'eau"). Décisions prises avec la
-- propriétaire pour les cas restants :
--
-- 1) "Chaux eteinte" (Ca(OH)₂, pilier Akora Pro / Acides & Bases) a une
--    fiche dont l'usage décrit est UNIQUEMENT "traitement de l'eau et
--    correction du pH" — aucun autre usage, contrairement à la soude,
--    l'acide chlorhydrique, le carbonate de sodium, etc. Elle aurait dû
--    être déplacée dès la Phase 189 avec l'Alun/Polymères/TCCA, mais
--    avait été oubliée. Corrigé ici : déplacée vers Akor'Eau (pas de
--    duplication — un seul produit, un seul usage, pas de grade
--    distinct à justifier une fiche séparée).
--
-- 2) STPP (anti-tartre) et Charbon actif (filtration) existent déjà au
--    catalogue, mais sous un grade différent (STPP alimentaire E451
--    pour texturer viande/fromage ; Charbon actif "vrac" générique
--    eau/air). Contrairement à la Chaux, ce sont des produits qui ont
--    un usage RÉEL et distinct ailleurs — donc pas d'oubli à corriger,
--    mais suit le même principe déjà utilisé pour "Soude caustique" /
--    "Soude caustique (grade alimentaire)" ou "Charbon actif (vrac)" /
--    "Charbon actif œnologique" : une fiche technique séparée par
--    grade/application, chacune dans sa catégorie. Résultat demandé
--    ("visible des deux côtés") obtenu ainsi, sans dupliquer le même
--    stock sous deux pilliers.
--    -> Nouvelles fiches Akor'Eau : "STPP — grade traitement de l'eau"
--       et "Charbon actif granulaire (GAC)". Les fiches existantes
--       (grade alimentaire / vrac) restent inchangées sous Akora Pro.
--
-- 3) Polyacrylamide (PAM) : n'existait sous aucun nom (le catalogue n'a
--    que "Polymeres floculants", générique, déjà dans Akor'Eau) —
--    nouvelle fiche dédiée, plus précise que l'entrée générique.
--
-- Contenu rédigé à partir de connaissances générales de chimie (CAS,
-- propriétés, dangers GHS), À VÉRIFIER PAR LA PROPRIÉTAIRE avant
-- diffusion (statut_verification = 'a_valider'), comme tout le reste du
-- catalogue.
--
-- Comme pour la Phase 190 : les nouveaux produits sont créés par le
-- trigger phase159 avec le business_unit_id d'Akora Pro (celui de leur
-- fiche raw_materials, qui reste toujours rattachée à Akora Pro par
-- convention — seul l'axe `products` bascule vers un autre pilier).
-- Ce script bascule donc explicitement products.business_unit_id vers
-- Akor'Eau pour ces 3 nouveaux produits, comme la Phase 191 l'avait
-- fait en bloc pour les 9 produits historiques.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do nothing sur raw_materials,
-- on conflict do update sur l'academie par matiere_premiere_id).
-- ============================================================

do $$
declare
  v_akora_pro_id uuid;
  v_akoreau_id uuid;
  v_material_id uuid;
  v_academie_id uuid;
begin
  select id into v_akora_pro_id from public.business_units where slug = 'matieres-premieres';
  select id into v_akoreau_id from public.business_units where slug = 'akor-eau';

  if v_akora_pro_id is null then
    raise exception 'Aucun pilier avec le slug "matieres-premieres" trouvé — arrêt.';
  end if;
  if v_akoreau_id is null then
    raise exception 'Aucun pilier avec le slug "akor-eau" trouvé — exécuter d''abord la phase 191.';
  end if;

  -- ============================================================
  -- 0) Rattrapage : déplace "Chaux eteinte" vers Akor'Eau (oubliée en
  --    phase 189 — son usage décrit est exclusivement eau/pH)
  -- ============================================================
  update public.raw_materials
    set category_name = 'Akor''Eau'
    where business_unit_id = v_akora_pro_id and name = 'Chaux eteinte';

  update public.products
    set category = 'Akor''Eau', business_unit_id = v_akoreau_id
    where business_unit_id = v_akora_pro_id and name = 'Chaux eteinte';

  -- ============================================================
  -- 1) Charbon actif granulaire (GAC)
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_akora_pro_id, 'Akor''Eau', 'Charbon actif granulaire (GAC)', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;

  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_akora_pro_id and name = 'Charbon actif granulaire (GAC)';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Charbon actif granulaire (charbon activé), CAS 7440-44-0',
    'GAC (Granular Activated Carbon), charbon activé granulé',
    'Technique',
    'Granulés/grains noirs irréguliers, poreux, secs',
    'Non applicable (matériau solide insoluble)',
    'Insoluble dans l''eau',
    0.45,
    'Très grande surface spécifique (500 à 1500 m²/g) qui adsorbe le chlore résiduel, les composés organiques, les pesticides, les mauvais goûts et odeurs. Format granulé : s''utilise en lit filtrant fixe (colonne), remplaçable ou régénérable moins souvent qu''une poudre à usage unique.',
    'Contrairement au "Charbon actif (vrac)" déjà au catalogue (format non précisé, usage général eau/air), le format granulaire (GAC) est calibré spécifiquement pour un lit filtrant en colonne de traitement d''eau — mieux adapté à une installation de filtration permanente qu''à un traitement ponctuel.',
    'Faible',
    array['gants','masque anti-poussière'],
    'Poussière de charbon pouvant irriter les voies respiratoires en grande quantité ; masque anti-poussière recommandé lors du chargement/déchargement des colonnes.',
    'Inhalation de poussière : air frais. Yeux : rincer à l''eau en cas de contact avec la poussière.',
    'Oxydants forts (risque d''inflammation en présence d''oxygène concentré ou d''oxydants puissants).',
    'Sac ou fût fermé, local sec, à l''écart de toute source de chaleur et d''oxydants forts.',
    true, false, 24, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_texte, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Filtration et adsorption en colonne (eau potable, eau de process, déchloration)',
   'Charger en lit filtrant fixe dans une colonne ou un filtre dédié ; l''eau traverse le lit de charbon qui adsorbe chlore, composés organiques et odeurs. Remplacer ou régénérer le charbon une fois saturé.',
   'texte_libre', 'Durée de vie du lit variable selon le débit et la qualité de l''eau brute — voir spécifications du fabricant', true, 0);

  update public.products
    set business_unit_id = v_akoreau_id
    where business_unit_id = v_akora_pro_id
      and category = 'Akor''Eau'
      and name = 'Charbon actif granulaire (GAC)';

  -- ============================================================
  -- 2) STPP (Tripolyphosphate de sodium) — grade traitement de l'eau
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_akora_pro_id, 'Akor''Eau', 'STPP — grade traitement de l''eau (anti-tartre)', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;

  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_akora_pro_id and name = 'STPP — grade traitement de l''eau (anti-tartre)';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Tripolyphosphate de sodium (Na₅P₃O₁₀), CAS 7758-29-4',
    'STPP, TPP, pentasodium triphosphate',
    'Technique',
    'Poudre ou granulés blancs, inodores',
    '9-10 (solution à 1 %)',
    'Soluble dans l''eau',
    2.5,
    'Séquestrant et anti-tartre : forme des complexes solubles avec le calcium et le magnésium, empêchant la formation de dépôts calcaires dans les canalisations et équipements. Dosage bien inférieur à l''usage alimentaire (texturant viande/fromage).',
    'Chimiquement identique au STPP alimentaire (E451) déjà au catalogue, mais ce grade technique est destiné au traitement de l''eau (anti-tartre/séquestrant), pas à un usage alimentaire — à ne pas utiliser de manière interchangeable pour des raisons de traçabilité et de pureté.',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes recommandés pour éviter l''irritation lors de la manipulation de la poudre concentrée.',
    'Yeux : rincer à l''eau 15 min. Peau : laver à l''eau et au savon. Ingestion : rincer la bouche, boire de l''eau.',
    'Acides forts (libère de l''acide phosphorique), oxydants forts.',
    'Sac fermé, local sec, à l''abri de l''humidité (produit hygroscopique).',
    true, false, 24, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
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
    dosage_min, dosage_max, unite_dosage, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Anti-tartre / séquestrant du calcium et magnésium (traitement de l''eau, chaudières, circuits de refroidissement)',
   'Doser en continu ou par choc dans l''eau à traiter pour maintenir le calcium et le magnésium en solution et prévenir les dépôts calcaires.',
   'plage', 2, 10, 'mg/L, selon la dureté de l''eau et le débit', true, 0);

  update public.products
    set business_unit_id = v_akoreau_id
    where business_unit_id = v_akora_pro_id
      and category = 'Akor''Eau'
      and name = 'STPP — grade traitement de l''eau (anti-tartre)';

  -- ============================================================
  -- 3) Polyacrylamide (PAM)
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_akora_pro_id, 'Akor''Eau', 'Polyacrylamide (PAM)', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;

  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_akora_pro_id and name = 'Polyacrylamide (PAM)';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Polyacrylamide (PAM), CAS 9003-05-8',
    'PAM, poly(2-propénamide)',
    'Technique',
    'Poudre blanche ou granulés, ou émulsion liquide selon la forme commerciale',
    '6-8 (solution à 0,5 %)',
    'Soluble dans l''eau (forme des solutions visqueuses à faible concentration)',
    'Floculant de synthèse à très haut poids moléculaire, existe en version anionique, cationique ou non ionique selon l''application. Agit en pontant les particules fines déjà déstabilisées par un coagulant, pour former de gros flocs qui décantent rapidement. Utilisé à très faible dose (quelques ppm) car très efficace.',
    'Plus spécifique et plus puissant à faible dose que le produit générique "Polymeres floculants" déjà au catalogue — le choix entre anionique/cationique/non-ionique dépend de la charge des particules à traiter et doit être testé en laboratoire (jar-test) avant utilisation en continu.',
    'Faible',
    array['gants','masque anti-poussière'],
    'Poudre très fine et extrêmement glissante une fois humide — masque anti-poussière et gants recommandés ; nettoyer immédiatement tout déversement (sol glissant en présence d''eau).',
    'Yeux/peau : rincer à l''eau. Inhalation de poussière : air frais.',
    'Oxydants forts.',
    'Sac fermé, local sec, à l''abri de l''humidité et de la lumière directe (peut se dégrader).',
    true, true, 24, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger, epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi, premiers_secours = excluded.premiers_secours,
    incompatibilites = excluded.incompatibilites,
    consignes_stockage = excluded.consignes_stockage,
    sensible_humidite = excluded.sensible_humidite,
    sensible_lumiere = excluded.sensible_lumiere,
    duree_conservation_mois = excluded.duree_conservation_mois,
    updated_at = now()
  returning id into v_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Floculation (formation de gros flocs après coagulation) — eau potable, eaux usées, déshydratation des boues',
   'Préparer une solution mère diluée (0,1 à 0,5 %) et injecter en aval du coagulant, sous agitation lente pour ne pas casser les flocs formés.',
   'plage', 0.1, 2, 'mg/L (ppm), à valider par test au laboratoire (jar-test) selon le type de PAM et l''eau traitée', true, 0);

  update public.products
    set business_unit_id = v_akoreau_id
    where business_unit_id = v_akora_pro_id
      and category = 'Akor''Eau'
      and name = 'Polyacrylamide (PAM)';

end $$;

-- Vérification : produits maintenant sous le pilier Akor'Eau
-- select bu.name as pilier, p.category, p.name, p.visibility
-- from public.products p
-- join public.business_units bu on bu.id = p.business_unit_id
-- where bu.slug = 'akor-eau'
-- order by p.name;
