-- ============================================================
-- AkoraHub - Patch Phase 91 : fiches Académie "Carbonate de sodium",
-- "Bicarbonate de sodium (E500ii)" et "Ammoniaque" — lot généré avec
-- DeepSeek au format JSON structuré, vérifié par l'utilisatrice
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Carbonate de sodium (Na₂CO₃)
  -- ------------------------------------------------------------
  v_material_id := 'aded3334-7584-4ede-8e07-5078a80832d8'::uuid;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, particularite, difference_produit_similaire,
    niveau_danger, epi_requis, notes_epi, premiers_secours,
    incompatibilites, consignes_stockage, temperature_stockage_min,
    temperature_stockage_max, sensible_humidite, sensible_lumiere,
    duree_conservation_mois, statut_verification
  ) values (
    v_material_id,
    'Carbonate de sodium (Na₂CO₃)',
    'Cristaux de soude, carbonate de sodium anhydre',
    'Technique',
    'Poudre ou cristaux blancs',
    '11-12 (solution à 1 %)',
    'Facilement soluble (30 g/100 mL à 20 °C)',
    'Absorbe l''humidité et le CO₂ de l''air pour former du bicarbonate. Densité 2,54 g/cm³.',
    'Moins agressif que la soude caustique, plus dégraissant que le bicarbonate.',
    'Modéré',
    array['gants','lunettes','masque'],
    'Gants de ménage suffisants, éviter l''inhalation de poussières.',
    'Yeux : rincer à l''eau 15 min. Peau : laver au savon. Ingestion : rincer la bouche, boire de l''eau.',
    'Acides, aluminium, zinc.',
    'Récipient étanche, au sec.',
    5, 40, true, false, 36, 'a_valider'
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
  select v_academie_id, id from public.phrases_p where code in ('P264', 'P280')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Nettoyage (lessive)',
   'Ajouter 2-3 cuillères à soupe par litre d''eau chaude, laisser tremper le linge, frotter.',
   'valeur_unique', 30, null, 'g/L', '40-60 °C', '1h de trempage', false, 0),
  (v_academie_id, 'Ajustement pH',
   'Ajouter progressivement sous agitation, contrôler le pH.',
   'plage', 0.5, 5, 'g/L', 'Ambiante', 'Instantané', true, 1);

  -- ------------------------------------------------------------
  -- Bicarbonate de sodium (NaHCO₃) — matière déjà en catalogue sous
  -- "Bicarbonate de sodium NaHCO₃ (E500ii)"
  -- ------------------------------------------------------------
  v_material_id := '09a5e4e8-a776-478c-916b-83fdb441a0f9'::uuid;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, particularite, difference_produit_similaire,
    niveau_danger, epi_requis, notes_epi, premiers_secours,
    incompatibilites, consignes_stockage, temperature_stockage_min,
    temperature_stockage_max, sensible_humidite, sensible_lumiere,
    duree_conservation_mois, statut_verification
  ) values (
    v_material_id,
    'Bicarbonate de sodium (NaHCO₃)',
    'Bicarbonate de soude, bicarbonate alimentaire',
    'Alimentaire',
    'Poudre blanche fine',
    '8-9 (solution saturée)',
    'Facilement soluble (10 g/100 mL à 20 °C)',
    'Léger dégagement de CO₂ au contact d''un acide (effervescence). Densité 2,20 g/cm³.',
    'Beaucoup plus doux que le carbonate de sodium, sans danger alimentaire.',
    'Aucun',
    array[]::text[],
    'Aucun équipement obligatoire.',
    'Rincer à l''eau en cas de contact oculaire.',
    'Acides (effervescence), sels d''aluminium en cosmétique.',
    'Au sec, à l''abri de l''humidité.',
    5, 30, true, false, 36, 'verifie'
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
  -- Pas de phrases H/P : produit alimentaire courant, sans danger.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, unite_dosage, dosage_texte, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Nettoyage doux',
   'Saupoudrer sur une éponge humide, frotter les surfaces.',
   'valeur_unique', 10, 'g', null, 'Ambiante', 'Quelques minutes', false, 0),
  (v_academie_id, 'Désodorisant',
   'Placer une coupelle au frigo ou saupoudrer dans les chaussures.',
   'texte_libre', null, null, 'Quelques grammes suffisent', null, null, false, 1);

  -- ------------------------------------------------------------
  -- Ammoniaque (NH₃ aq)
  -- ------------------------------------------------------------
  v_material_id := '9a98af95-0337-4a98-9bd1-0f29ec6726eb'::uuid;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, particularite, difference_produit_similaire,
    niveau_danger, epi_requis, notes_epi, premiers_secours,
    incompatibilites, consignes_stockage, temperature_stockage_min,
    temperature_stockage_max, sensible_humidite, sensible_lumiere,
    duree_conservation_mois, statut_verification
  ) values (
    v_material_id,
    'Ammoniaque (NH₃ aq)',
    'Ammoniac, ammoniaque',
    'Technique',
    'Liquide incolore, odeur très piquante',
    '11-12 (solution à 5 %)',
    'Totalement miscible à l''eau',
    'Très volatil, vapeurs suffocantes. Densité 0,90 g/cm³ (pour une solution à 25 %).',
    'Base plus faible que NaOH, mais très irritante par inhalation.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Masque anti-gaz alcalins, gants nitrile, travailler sous hotte.',
    'Inhalation : air frais. Peau : rincer 15 min. Yeux : rincer 15 min.',
    'Acides, oxydants, chlore.',
    'Local ventilé, récipient étanche, à l''écart des acides.',
    5, 30, false, false, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H314', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p where code in ('P260', 'P280')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_texte, temperature_utilisation, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Nettoyant ménager',
   'Diluer 1 volume d''ammoniaque dans 10 volumes d''eau, nettoyer les surfaces grasses.',
   'dilution', '1 volume pour 10 volumes d''eau', 'Ambiante', false, 0);
end $$;
