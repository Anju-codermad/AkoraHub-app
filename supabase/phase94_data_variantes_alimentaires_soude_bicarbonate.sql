-- ============================================================
-- AkoraHub - Patch Phase 94 : duplique le contenu Académie déjà
-- vérifié de "Soude caustique" et "Bicarbonate de sodium (E500ii)"
-- vers leurs variantes catalogue "grade alimentaire" — même substance,
-- pas besoin de redemander du contenu à DeepSeek. Grade forcé à
-- 'Alimentaire' sur la copie.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_source_academie_id uuid;
  v_new_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Soude caustique NaOH (grade alimentaire)
  -- source : Soude caustique (fe71d1cb...) -> cible : b54a91e0...
  -- ------------------------------------------------------------
  select id into v_source_academie_id
  from public.matieres_premieres_academie
  where matiere_premiere_id = 'fe71d1cb-6af9-4c80-ae72-840f8b358725'::uuid;

  if v_source_academie_id is null then
    raise exception 'Fiche source "Soude caustique" introuvable.';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  )
  select
    'b54a91e0-e67f-4753-a311-4f4d6dfcb32f'::uuid, nom_chimique, synonymes,
    'Alimentaire', aspect, ph_solution, solubilite, densite, point_eclair,
    particularite, difference_produit_similaire, niveau_danger, epi_requis,
    notes_epi, premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max, sensible_humidite,
    sensible_lumiere, duree_conservation_mois, statut_verification
  from public.matieres_premieres_academie
  where id = v_source_academie_id
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
  returning id into v_new_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_new_academie_id;
  delete from public.academie_phrases_h where academie_id = v_new_academie_id;
  delete from public.academie_phrases_p where academie_id = v_new_academie_id;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, dosage_texte,
    temperature_utilisation, temps_action, a_verifier_labo, ordre
  )
  select v_new_academie_id, domaine_application, technique_methode, dosage_type,
         dosage_min, dosage_max, unite_dosage, dosage_texte,
         temperature_utilisation, temps_action, a_verifier_labo, ordre
  from public.matieres_premieres_usages
  where academie_id = v_source_academie_id;

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_new_academie_id, phrase_h_id
  from public.academie_phrases_h where academie_id = v_source_academie_id
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_new_academie_id, phrase_p_id
  from public.academie_phrases_p where academie_id = v_source_academie_id
  on conflict (academie_id, phrase_p_id) do nothing;

  -- ------------------------------------------------------------
  -- Bicarbonate de soude alimentaire
  -- source : Bicarbonate de sodium NaHCO₃ E500ii (09a5e4e8...)
  -- -> cible : 1ec3cf87...
  -- ------------------------------------------------------------
  select id into v_source_academie_id
  from public.matieres_premieres_academie
  where matiere_premiere_id = '09a5e4e8-a776-478c-916b-83fdb441a0f9'::uuid;

  if v_source_academie_id is null then
    raise exception 'Fiche source "Bicarbonate de sodium (E500ii)" introuvable.';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, point_eclair, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  )
  select
    '1ec3cf87-8e06-4b77-8330-cf0d9e163522'::uuid, nom_chimique, synonymes,
    'Alimentaire', aspect, ph_solution, solubilite, densite, point_eclair,
    particularite, difference_produit_similaire, niveau_danger, epi_requis,
    notes_epi, premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max, sensible_humidite,
    sensible_lumiere, duree_conservation_mois, statut_verification
  from public.matieres_premieres_academie
  where id = v_source_academie_id
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
  returning id into v_new_academie_id;

  delete from public.matieres_premieres_usages where academie_id = v_new_academie_id;
  delete from public.academie_phrases_h where academie_id = v_new_academie_id;
  delete from public.academie_phrases_p where academie_id = v_new_academie_id;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, dosage_texte,
    temperature_utilisation, temps_action, a_verifier_labo, ordre
  )
  select v_new_academie_id, domaine_application, technique_methode, dosage_type,
         dosage_min, dosage_max, unite_dosage, dosage_texte,
         temperature_utilisation, temps_action, a_verifier_labo, ordre
  from public.matieres_premieres_usages
  where academie_id = v_source_academie_id;

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_new_academie_id, phrase_h_id
  from public.academie_phrases_h where academie_id = v_source_academie_id
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_new_academie_id, phrase_p_id
  from public.academie_phrases_p where academie_id = v_source_academie_id
  on conflict (academie_id, phrase_p_id) do nothing;
end $$;
