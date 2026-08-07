-- ============================================================
-- AkoraHub - Patch Phase 92 : fiches Académie "Acide citrique",
-- "Acide phosphorique", "Acide acétique" — contenu DeepSeek appliqué
-- À TOUTES les variantes existant dans le catalogue pour chaque
-- produit chimique (y compris celles déjà achetées par des clients —
-- documenter n'affecte jamais les achats, contrairement à supprimer).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  r record;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Acide citrique — 4 variantes du catalogue
  -- ------------------------------------------------------------
  for r in
    select * from (values
      ('f07fa996-6f50-4432-9323-5f95ce2d4f2f'::uuid, null::text),      -- Acide citrique
      ('3a552035-427a-4db0-9ecb-f5b94808f561'::uuid, 'Alimentaire'),   -- Acide citrique alimentaire
      ('cfcc7059-a094-4842-908d-4d9740caeb95'::uuid, 'Alimentaire'),   -- Acide citrique anhydre (E330)
      ('61902ac8-bdd1-4eb3-9f5d-3834be479fc6'::uuid, 'Alimentaire')    -- Acide citrique monohydraté (E330)
    ) as t(material_id, grade)
  loop
    insert into public.matieres_premieres_academie (
      matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
      ph_solution, solubilite, particularite, difference_produit_similaire,
      niveau_danger, epi_requis, notes_epi, premiers_secours,
      incompatibilites, consignes_stockage, temperature_stockage_min,
      temperature_stockage_max, sensible_humidite, sensible_lumiere,
      duree_conservation_mois, statut_verification
    ) values (
      r.material_id,
      'Acide citrique (C₆H₈O₇)',
      'Acide citrique monohydraté, E330',
      r.grade,
      'Poudre ou cristaux blancs',
      '2-3 (solution à 1 %)',
      'Très soluble (60 g/100 mL)',
      'Agent antioxydant et chélateur naturel. Densité 1,54 g/cm³.',
      'Plus doux que l''acide acétique, sans odeur piquante.',
      'Modéré',
      array['lunettes'],
      'Lunettes de sécurité pour éviter les projections.',
      'Yeux : rincer abondamment. Peau : laver à l''eau. Ingestion : boire de l''eau.',
      'Oxydants forts, bases.',
      'Récipient étanche, au sec.',
      5, 30, true, false, 36, 'a_valider'
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
    (v_academie_id, 'Détartrant écologique',
     'Dissoudre 2 cuillères à soupe dans 1 L d''eau tiède, appliquer sur le tartre.',
     'valeur_unique', 30, null, 'g/L', '30-40 °C', '30 min', false, 0),
    (v_academie_id, 'Cosmétique (ajusteur pH)',
     'Ajouter progressivement une solution à 10 % à la lotion.',
     'plage', 0.1, 1, '% du produit', 'Ambiante', null, true, 1),
    (v_academie_id, 'Alimentaire (acidulant boissons)',
     'Ajouter selon le goût désiré.',
     'valeur_unique', 1, null, 'g/L', null, null, false, 2);
  end loop;

  -- ------------------------------------------------------------
  -- Acide phosphorique — 3 variantes du catalogue
  -- ------------------------------------------------------------
  for r in
    select * from (values
      ('e6aa7c14-2fa6-4cea-8ec0-e0aca7774452'::uuid, null::text),         -- Acide phosphorique
      -- ⚠️ grade laissé à null (au lieu de 'Technique') : le nom catalogue
      -- porte "(E338)", qui est justement le code additif alimentaire de
      -- l'acide phosphorique — impossible de trancher "technique" sans
      -- voir la fiche fournisseur complète. À vérifier/corriger manuellement.
      ('ddb2f46f-bfc8-4fbc-b682-734cb4f71498'::uuid, null::text),         -- H₃PO₄ (E338) — grade à confirmer
      ('01fd47c2-551b-41e6-a44c-9249f5f730c0'::uuid, 'Alimentaire')       -- H₃PO₄ alimentaire (E338)
    ) as t(material_id, grade)
  loop
    insert into public.matieres_premieres_academie (
      matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
      ph_solution, solubilite, particularite, difference_produit_similaire,
      niveau_danger, epi_requis, notes_epi, premiers_secours,
      incompatibilites, consignes_stockage, temperature_stockage_min,
      temperature_stockage_max, sensible_humidite, sensible_lumiere,
      duree_conservation_mois, statut_verification
    ) values (
      r.material_id,
      'Acide phosphorique (H₃PO₄)',
      'Acide orthophosphorique',
      r.grade,
      'Liquide visqueux incolore',
      '1,5 (solution à 1 %)',
      'Totalement soluble',
      'Non volatil, moins agressif que HCl ou H₂SO₄. Densité 1,68 g/cm³ (solution à 85 %).',
      'Moins dangereux que l''acide chlorhydrique, utilisé en alimentaire (E338).',
      'Corrosif',
      array['gants','lunettes','tablier'],
      'Gants nitrile, lunettes de sécurité.',
      'Rincer abondamment à l''eau. Consulter un médecin si irritation.',
      'Bases fortes, métaux légers.',
      'Récipient en plastique, local sec, à l''écart des bases.',
      5, 35, false, false, 24, 'a_valider'
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
    select v_academie_id, id from public.phrases_p where code in ('P264', 'P280', 'P305+P351+P338')
    on conflict (academie_id, phrase_p_id) do nothing;

    insert into public.matieres_premieres_usages (
      academie_id, domaine_application, technique_methode, dosage_type,
      dosage_min, dosage_max, unite_dosage, dosage_texte,
      temperature_utilisation, temps_action, a_verifier_labo, ordre
    ) values
    (v_academie_id, 'Détartrant',
     'Appliquer pur ou dilué à 10 % sur les surfaces, laisser agir, rincer.',
     'dilution', null, null, '(v/v)', '1 volume d''acide pour 1 à 10 volumes d''eau',
     'Ambiante', '15-30 min', false, 0),
    (v_academie_id, 'Alimentaire (acidulant)',
     'Ajouter selon la recette, diluer dans l''eau.',
     'plage', 0.05, 0.5, '% du produit fini', null, null, null, true, 1);
  end loop;

  -- ------------------------------------------------------------
  -- Acide acétique — 3 variantes du catalogue
  -- ------------------------------------------------------------
  for r in
    select * from (values
      ('16fb1c24-b1e8-4705-8cd9-9fecc625f8ec'::uuid, null::text),           -- Acide acetique
      ('a71d5fe2-4c65-4536-a0bb-2c0efccd2f50'::uuid, 'Alimentaire'),        -- Acide acétique / Vinaigre blanc (E260)
      ('bb3a6594-5621-467a-a552-ea63a47aa19a'::uuid, 'Alimentaire')         -- Vinaigre blanc (acidification conserves)
    ) as t(material_id, grade)
  loop
    insert into public.matieres_premieres_academie (
      matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
      ph_solution, solubilite, particularite, difference_produit_similaire,
      niveau_danger, epi_requis, notes_epi, premiers_secours,
      incompatibilites, consignes_stockage, point_eclair,
      temperature_stockage_min, temperature_stockage_max,
      sensible_humidite, sensible_lumiere, duree_conservation_mois,
      statut_verification
    ) values (
      r.material_id,
      'Acide acétique (CH₃COOH)',
      'Vinaigre (dilué), acide éthanoïque',
      r.grade,
      'Liquide incolore, odeur piquante',
      '2-3 (vinaigre à 5 %)',
      'Totalement miscible à l''eau',
      'Agent conservateur et antimicrobien naturel. Densité 1,05 g/cm³ (produit pur).',
      'Plus agressif que l''acide citrique, mais moins que l''acide chlorhydrique.',
      'Modéré',
      array['gants','lunettes'],
      'Gants de ménage, lunettes de sécurité.',
      'Rincer abondamment à l''eau. Consulter un médecin en cas de brûlure.',
      'Oxydants, bases fortes, peroxydes.',
      'Local ventilé, à l''écart des flammes.',
      39,
      5, 35, false, false, 36, 'a_valider'
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
      point_eclair = excluded.point_eclair,
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
    select v_academie_id, id from public.phrases_h where code in ('H315', 'H319', 'H226')
    on conflict (academie_id, phrase_h_id) do nothing;

    insert into public.academie_phrases_p (academie_id, phrase_p_id)
    select v_academie_id, id from public.phrases_p where code in ('P210', 'P280')
    on conflict (academie_id, phrase_p_id) do nothing;

    insert into public.matieres_premieres_usages (
      academie_id, domaine_application, technique_methode, dosage_type,
      dosage_min, dosage_max, unite_dosage, temperature_utilisation,
      temps_action, a_verifier_labo, ordre
    ) values
    (v_academie_id, 'Détartrant',
     'Utiliser le vinaigre blanc pur ou dilué, laisser agir, frotter.',
     'valeur_unique', 10, null, '% d''acide acétique', 'Ambiante', '30 min', false, 0),
    (v_academie_id, 'Conservateur alimentaire',
     'Ajouter selon recette, généralement 0,5-2 % du poids.',
     'plage', 0.5, 2, '% du produit', null, null, false, 1);
  end loop;
end $$;
