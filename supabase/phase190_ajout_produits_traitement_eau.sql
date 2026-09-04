-- ============================================================
-- AkoraHub - Patch Phase 190 : 6 nouveaux produits pour "Akor'Eau"
-- (traitement de l'eau), demande explicite du 04/09/2026, suite à
-- Phase 188/189. Contenu rédigé à partir de connaissances générales de
-- chimie (CAS, propriétés physico-chimiques, dangers GHS), À VÉRIFIER
-- PAR LA PROPRIÉTAIRE avant diffusion — comme toutes les fiches
-- Académie de ce catalogue (statut_verification = 'a_valider').
--
-- Nouveaux produits :
--   1. Chlorure ferrique (FeCl₃)         — coagulant eaux usées
--   2. Sulfate ferrique                   — coagulant/clarification
--   3. PAC (polychlorure d'aluminium)     — coagulant moderne
--   4. Hexamétaphosphate de sodium (SHMP) — anti-tartre/séquestrant
--   5. Bisulfate de sodium                — réducteur de pH piscine
--   6. Résine échangeuse de cations       — adoucissement de l'eau
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do nothing sur raw_materials,
-- on conflict do update sur l'academie par matiere_premiere_id).
--
-- CORRECTIF 04/09/2026 : le pilier historiquement nommé "Akora
-- Fanadiovana" a été renommé "Akora Pro" (rebranding "Groupe Akora"
-- fait en parallèle côté site web) — le lookup ci-dessous utilise
-- désormais bu.slug = 'matieres-premieres' (identifiant stable, non
-- affecté par un renommage du libellé) au lieu de bu.name. Cette
-- version corrigée n'a encore jamais été exécutée avec succès.
-- ============================================================

do $$
declare
  v_business_unit_id uuid;
  v_material_id uuid;
  v_academie_id uuid;
begin
  select id into v_business_unit_id
    from public.business_units where slug = 'matieres-premieres';

  if v_business_unit_id is null then
    raise exception 'Aucun pilier avec le slug "matieres-premieres" trouvé — arrêt.';
  end if;

  -- ============================================================
  -- 1) Chlorure ferrique (FeCl₃)
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_business_unit_id, 'Akor''Eau', 'Chlorure ferrique (FeCl₃)', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;

  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_business_unit_id and name = 'Chlorure ferrique (FeCl₃)';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Chlorure ferrique / Chlorure de fer(III) (FeCl₃), CAS 7705-08-0',
    'Trichlorure de fer, perchlorure de fer, Ferric chloride',
    'Technique',
    'Solution aqueuse brun-orangé foncé (forme commerciale ~40 %), corrosive et hygroscopique',
    '1-2 (solution commerciale, fortement acide par hydrolyse)',
    'Totalement miscible à l''eau (dissolution exothermique)',
    1.42,
    'Coagulant très efficace, fonctionne sur une large plage de pH et de température. Corrosif pour la plupart des métaux courants (acier, aluminium) — nécessite des équipements en plastique, verre ou inox spécial.',
    'Plus efficace que le sulfate d''aluminium pour l''élimination du phosphore et sur les eaux froides/troubles, mais colore l''eau traitée (teinte rouille) si surdosé.',
    'Corrosif',
    array['gants','lunettes','ventilation','tablier'],
    'Gants en caoutchouc ou nitrile épais, lunettes étanches, tablier résistant aux acides, éviter tout contact avec la peau (taches et brûlures).',
    'Peau : rincer abondamment 15 min, retirer vêtements souillés. Yeux : rincer 15 min, consulter un médecin. Ingestion : ne pas faire vomir, rincer la bouche, boire de l''eau, consulter. Inhalation : air frais.',
    'Bases fortes (réaction violente), métaux (corrosion, dégagement d''hydrogène), oxydants forts, cyanures.',
    'Récipients en plastique (PEHD/PVC) ou verre, jamais de métal non protégé. Local frais, à l''écart de l''humidité excessive pour limiter la corrosion des installations voisines.',
    5, 30, true, false, 12, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H290', 'H302', 'H315', 'H318')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280', 'P302+P352', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Coagulation eaux usées / élimination du phosphore',
   'Injecter en continu dans l''eau brute avant décantation, sous agitation rapide puis floculation lente.',
   'plage', 5, 150, 'mg/L de produit commercial (40 %), selon turbidité et charge en phosphates', true, 0);

  -- ============================================================
  -- 2) Sulfate ferrique (Fe₂(SO₄)₃)
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_business_unit_id, 'Akor''Eau', 'Sulfate ferrique (Fe₂(SO₄)₃)', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;

  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_business_unit_id and name = 'Sulfate ferrique (Fe₂(SO₄)₃)';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Sulfate de fer(III) (Fe₂(SO₄)₃), CAS 10028-22-5',
    'Sulfate ferrique, Ferric sulfate',
    'Technique',
    'Poudre ou granulés jaune-brun, ou solution brun foncé selon forme commerciale',
    '2-3 (solution diluée, acide par hydrolyse)',
    'Soluble dans l''eau',
    1.55,
    'Coagulant similaire au chlorure ferrique mais moins corrosif pour les métaux et moins agressif sur les canalisations — floc plus dense et se décantant plus vite.',
    'Alternative au chlorure ferrique quand la corrosion des équipements est un problème ; moins concentré en fer actif que le FeCl₃ à masse égale.',
    'Modéré',
    array['gants','lunettes'],
    'Gants et lunettes de protection standard, éviter l''inhalation de poussières pour la forme solide.',
    'Peau : rincer à l''eau. Yeux : rincer 15 min, consulter si irritation persiste. Ingestion : rincer la bouche, boire de l''eau, consulter un médecin.',
    'Bases fortes, oxydants forts, métaux (corrosion lente).',
    'Récipient étanche, local sec et ventilé, à l''écart de l''humidité pour la forme poudre (prise en masse).',
    5, 30, true, false, 18, 'a_valider'
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
    dosage_min, dosage_max, unite_dosage, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Coagulation / clarification de l''eau',
   'Injecter dans l''eau brute avant décantation, agitation rapide puis floculation lente.',
   'plage', 5, 100, 'mg/L de produit commercial, selon turbidité', true, 0);

  -- ============================================================
  -- 3) PAC — Polychlorure d'aluminium
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_business_unit_id, 'Akor''Eau', 'PAC (Polychlorure d''aluminium)', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;

  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_business_unit_id and name = 'PAC (Polychlorure d''aluminium)';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Polychlorure d''aluminium (PAC), CAS 1327-41-9',
    'PAC, Poly Aluminium Chloride, chlorhydrate d''aluminium',
    'Technique',
    'Liquide jaune pâle à ambré, ou poudre selon forme commerciale',
    '3-5 (solution commerciale)',
    'Miscible à l''eau',
    1.2,
    'Coagulant "moderne" pré-hydrolysé : dose efficace nettement plus faible que le sulfate d''aluminium classique, fonctionne sur une plage de pH plus large et produit moins de boues.',
    'Par rapport au sulfate d''aluminium (Alun), le PAC consomme moins d''alcalinité de l''eau et nécessite moins d''ajustement de pH après traitement.',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes de protection standard, rincer immédiatement en cas de projection.',
    'Peau : rincer à l''eau. Yeux : rincer 15 min. Ingestion : rincer la bouche, boire de l''eau, consulter si malaise.',
    'Bases fortes, oxydants forts.',
    'Bidon fermé, local frais à l''abri du gel (peut cristalliser en dessous de 0°C) et de la lumière directe.',
    5, 35, false, true, 12, 'a_valider'
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
    dosage_min, dosage_max, unite_dosage, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Coagulation eau potable / eau industrielle',
   'Injecter dans l''eau brute avant décantation, agitation rapide puis floculation lente.',
   'plage', 2, 50, 'mg/L de produit commercial, selon turbidité (dose plus faible que l''alun)', true, 0);

  -- ============================================================
  -- 4) Hexamétaphosphate de sodium (SHMP)
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_business_unit_id, 'Akor''Eau', 'Hexamétaphosphate de sodium (SHMP)', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;

  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_business_unit_id and name = 'Hexamétaphosphate de sodium (SHMP)';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Hexamétaphosphate de sodium ((NaPO₃)₆), CAS 10124-56-8',
    'SHMP, Calgon, sel de Graham',
    'Technique',
    'Poudre ou granulés vitreux blancs, légèrement hygroscopiques',
    '6-7,5 (solution à 1 %, quasi neutre à légèrement alcalin)',
    'Très soluble dans l''eau',
    null,
    'Séquestrant du calcium/magnésium et du fer : empêche la précipitation du tartre et la formation de dépôts sans adoucir réellement l''eau (contrairement à une résine échangeuse d''ions). Aussi utilisé comme dispersant.',
    'Contrairement au TSPP/STPP, le SHMP reste efficace à plus basse dose pour l''anti-tartre pur, mais est un moins bon détergent/séquestrant général.',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes recommandés pour la manipulation de poudre, éviter l''inhalation prolongée de poussières.',
    'Yeux : rincer à l''eau en cas d''irritation. Peau : rincer à l''eau. Ingestion : rincer la bouche, boire de l''eau.',
    'Acides forts (hydrolyse en orthophosphate), sels de calcium concentrés (peut précipiter à très forte dose).',
    'Récipient hermétique, local sec — hygroscopique, s''agglomère en présence d''humidité.',
    null, null, true, false, 24, 'a_valider'
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
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Anti-tartre / séquestrant sur circuits d''eau',
   'Dissoudre et injecter en continu dans le circuit d''eau à traiter.',
   'plage', 2, 10, 'mg/L en continu selon dureté de l''eau', true, 0);

  -- ============================================================
  -- 5) Bisulfate de sodium (NaHSO₄)
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_business_unit_id, 'Akor''Eau', 'Bisulfate de sodium (NaHSO₄)', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;

  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_business_unit_id and name = 'Bisulfate de sodium (NaHSO₄)';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Sulfate acide de sodium / bisulfate de sodium (NaHSO₄), CAS 7681-38-1',
    'Bisulfate de soude, "acide sec", sodium hydrogen sulfate',
    'Technique',
    'Poudre ou granulés blancs cristallins',
    '1-2 (solution à 1 %)',
    'Très soluble dans l''eau (dissolution endothermique)',
    null,
    'Forme solide et beaucoup plus sûre à manipuler/transporter que l''acide chlorhydrique ou sulfurique liquide pour le même usage de réduction de pH — d''où son surnom "acide sec" pour piscines.',
    'Moins concentré et moins dangereux à doser que l''acide chlorhydrique, mais nécessite une dose plus importante pour le même effet sur le pH.',
    'Modéré',
    array['gants','lunettes','masque'],
    'Gants et lunettes de protection, masque anti-poussière lors de la manipulation de la poudre, ne jamais ajouter d''eau sur le produit concentré (projections).',
    'Peau : rincer 15 min. Yeux : rincer 15 min, consulter. Ingestion : rincer la bouche, boire de l''eau, ne pas faire vomir, consulter un médecin.',
    'Bases fortes (réaction exothermique), carbonates/bicarbonates (dégagement de CO₂), cyanures et sulfures (dégagement de gaz toxiques).',
    'Récipient hermétique, local sec — hygroscopique et corrosif en présence d''humidité.',
    null, null, true, false, 24, 'a_valider'
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
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H318')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_texte, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Réduction du pH de l''eau de piscine',
   'Dissoudre la dose dans un seau d''eau avant de verser dans le bassin, filtration en marche, répartir sur toute la surface.',
   'texte_libre', '10-15 g par m³ pour baisser le pH d''environ 0,1 unité (à ajuster selon TAC de l''eau)', true, 0);

  -- ============================================================
  -- 6) Résine échangeuse de cations (adoucissement)
  -- ============================================================
  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_business_unit_id, 'Akor''Eau', 'Résine échangeuse de cations (adoucissement)', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;

  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_business_unit_id and name = 'Résine échangeuse de cations (adoucissement)';
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
    'Résine copolymère styrène-divinylbenzène sulfoné, forme sodium (échangeuse de cations forte)',
    'Résine adoucissante, résine cationique forte, ion exchange resin (Na-form)',
    'Technique',
    'Billes sphériques humides, jaune-brun à ambré, quelques mm de diamètre',
    'Non applicable (matériau solide insoluble)',
    'Insoluble dans l''eau (matériau solide, gonfle légèrement en milieu aqueux)',
    'Échange les ions calcium/magnésium (dureté) contre des ions sodium au passage de l''eau — adoucit l''eau sans la déminéraliser complètement. S''épuise progressivement et doit être régénérée avec une saumure de sel (NaCl).',
    'Contrairement au SHMP (qui masque le tartre sans le retirer), la résine élimine réellement la dureté de l''eau ; contrairement à une résine anionique/mixte, elle n''agit que sur la dureté, pas sur les autres ions.',
    'Faible',
    array['gants'],
    'Gants recommandés pour éviter le dessèchement de la peau, rincer les résines neuves avant premier usage.',
    'Peau/yeux : rincer à l''eau en cas de contact avec la saumure de régénération (pas la résine elle-même).',
    'Chlore/oxydants forts en continu (dégradation prématurée de la résine), gel (destruction des billes).',
    'Maintenir humide en permanence (ne jamais laisser sécher complètement), à l''abri du gel, dans son emballage d''origine ou immergée dans l''eau.',
    true, false, 60, 'a_valider'
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
  delete from public.academie_phrases_h where academie_id = v_academie_id;
  delete from public.academie_phrases_p where academie_id = v_academie_id;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_texte, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Adoucissement de l''eau (chaudières, domestique, industriel)',
   'Charger la colonne d''adoucisseur avec la résine ; l''eau dure traverse le lit de résine qui capte le calcium/magnésium. Régénérer périodiquement avec une saumure de sel concentrée.',
   'texte_libre', 'Capacité et fréquence de régénération variables selon la dureté de l''eau et le volume traité — voir spécifications du fabricant', true, 0);

end $$;

-- Vérification : les 6 produits doivent apparaître avec category_name/category = 'Akor''Eau'
-- select name, category_name from public.raw_materials where category_name = 'Akor''Eau';
-- select name, category from public.products where category = 'Akor''Eau';
