-- ============================================================
-- AkoraHub - Patch Phase 201 : ajoute "Hypochlorite de calcium — grade
-- traitement de l'eau" sous le pilier Akor'Eau — demande explicite de
-- la propriétaire le 04/09/2026.
--
-- "Hypochlorite de calcium 70%" existe déjà au catalogue (pilier Akora
-- Pro / Désinfectants), mais sa fiche a 2 usages : piscine ET
-- désinfection de surfaces (sols, murs, matériel) — donc vraiment
-- multi-usage, pas eau-exclusif. Conformément au principe déjà utilisé
-- pour "STPP" et "Charbon actif granulaire (GAC)" (phase195) : une
-- fiche technique séparée par application, plutôt que déplacer ou
-- dupliquer le même stock — la fiche existante reste inchangée sous
-- Akora Pro, cette nouvelle fiche est spécifique au traitement de
-- l'eau et vit sous Akor'Eau.
--
-- (Le "Charbon actif" est déjà couvert côté Akor'Eau depuis la phase
-- 195 sous le nom "Charbon actif granulaire (GAC)" — rien à ajouter.)
--
-- Contenu rédigé à partir de connaissances générales de chimie (CAS,
-- propriétés, dangers GHS), À VÉRIFIER PAR LA PROPRIÉTAIRE avant
-- diffusion (statut_verification = 'a_valider').
--
-- Comme pour la phase 195 : le produit est créé par le trigger
-- phase159 avec le business_unit_id d'Akora Pro (celui de sa fiche
-- raw_materials, toujours rattachée à Akora Pro par convention). Ce
-- script bascule ensuite explicitement products.business_unit_id vers
-- Akor'Eau.
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

  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_akora_pro_id, 'Akor''Eau', 'Hypochlorite de calcium — grade traitement de l''eau', 'rupture', null)
  on conflict do nothing
  returning id into v_material_id;

  if v_material_id is null then
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_akora_pro_id and name = 'Hypochlorite de calcium — grade traitement de l''eau';
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
    'Hypochlorite de calcium (Ca(ClO)₂), CAS 7778-54-3',
    'HTH, chlorure de chaux, pastilles de chlore sans stabilisant, calcium hypochlorite',
    'Technique',
    'Poudre, granulés ou pastilles blanches, forte odeur de chlore',
    '10-11 (solution à 1 %)',
    'Bonne solubilité (21 g/100 mL à 20 °C), un léger trouble de carbonate de calcium peut persister',
    2.35,
    'Contient environ 65-70 % de chlore actif disponible. Fort pouvoir oxydant et alcalinisant, augmente le pH de l''eau traitée contrairement au TCCA. Grade dédié au traitement de l''eau (potabilisation, piscine) — la fiche générique "Hypochlorite de calcium 70%" (catalogue Akora Pro) reste utilisée pour la désinfection de surfaces.',
    'Contrairement au TCCA (pastilles stabilisées), l''hypochlorite de calcium n''apporte pas d''acide cyanurique. Par rapport à l''eau de Javel liquide, il est plus concentré, plus stable au stockage et plus économique pour le transport.',
    'Corrosif',
    array['gants','lunettes','masque','ventilation'],
    'Gants en caoutchouc, lunettes de sécurité étanches, masque anti-poussière et anti-chlore, manipuler dans un endroit bien ventilé.',
    'Peau : rincer 15 min, retirer vêtements. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas vomir, boire de l''eau, médecin. Inhalation : air frais, consulter si gêne.',
    'Acides (dégagement violent de chlore gazeux), ammoniaque, matières organiques, produits chlorés stabilisés (TCCA), métaux.',
    'Récipient étanche dans un local frais, sec et très bien ventilé. Tenir rigoureusement à l''écart des acides et des matières combustibles.',
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
  select v_academie_id, id from public.phrases_h where code in ('H272', 'H302', 'H314', 'H400')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P220', 'P260', 'P280', 'P301+P330+P331', 'P303+P361+P353', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Potabilisation et désinfection de l''eau (traitement choc ou régulier)',
   'Pré-dissoudre les granulés dans un seau d''eau avant injection ou versement dans le bassin/réservoir, filtration ou brassage en marche. Pour un traitement régulier, viser 1 à 2 ppm de chlore libre.',
   'valeur_unique', 15, null, 'g de produit à 70 % par 10 m³ d''eau (augmente le chlore de 1 ppm)', 'Ambiante', 'Dissolution rapide, filtration 2-4 h', true, 0);

  update public.products
    set business_unit_id = v_akoreau_id
    where business_unit_id = v_akora_pro_id
      and category = 'Akor''Eau'
      and name = 'Hypochlorite de calcium — grade traitement de l''eau';
end $$;

-- Vérification :
-- select bu.name as pilier, p.category, p.name, p.visibility
-- from public.products p
-- join public.business_units bu on bu.id = p.business_unit_id
-- where bu.slug = 'akor-eau'
-- order by p.name;
