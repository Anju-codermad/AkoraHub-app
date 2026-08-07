-- ============================================================
-- AkoraHub - Patch Phase 93 : fiches Académie "Acide nitrique",
-- "Acide oxalique", "Acide lactique", "Hydroxyde de calcium (chaux
-- éteinte)", "Silicate de sodium" — contenu DeepSeek, vérifié par
-- l'utilisatrice. Appliqué à toutes les variantes catalogue trouvées.
--
-- ⚠️ "Carbonate de potassium" (K₂CO₃) proposé par DeepSeek n'existe
-- PAS dans le catalogue actuel — volontairement omis ici (à ne pas
-- confondre avec "Potasse caustique" qui est un produit différent,
-- hydroxyde de potassium KOH).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  r record;
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Acide nitrique — 2 variantes du catalogue
  -- ------------------------------------------------------------
  for r in
    select * from (values
      ('5619e2d3-e9c2-4a3d-92d5-e209e047d64a'::uuid), -- Acide nitrique
      ('13735c7f-8039-4b41-9b7e-76a78b5efdb5'::uuid)  -- Acide nitrique dilué HNO₃ (nettoyage inox)
    ) as t(material_id)
  loop
    insert into public.matieres_premieres_academie (
      matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
      ph_solution, solubilite, densite, point_eclair, particularite,
      difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
      premiers_secours, incompatibilites, consignes_stockage,
      temperature_stockage_min, temperature_stockage_max,
      sensible_humidite, sensible_lumiere, duree_conservation_mois,
      statut_verification
    ) values (
      r.material_id,
      'Acide nitrique (HNO₃)',
      'Eau forte',
      'Technique',
      'Liquide incolore à jaunâtre, vapeurs rousses',
      '1 (solution à 1 %)',
      'Totalement miscible à l''eau',
      1.42,
      null,
      'Densité donnée pour la solution commerciale à 68 %. Oxydant puissant, peut provoquer l''inflammation de matières combustibles.',
      'Plus oxydant que l''acide chlorhydrique, attaque la plupart des métaux ; utilisé pour la gravure et le décapage.',
      'Corrosif',
      array['gants','lunettes','masque','ventilation','tablier','bottes'],
      'Gants en caoutchouc butyle, écran facial, masque anti-gaz acides (type B ou ABEK).',
      'Peau : rincer 15 min. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas faire vomir, boire un peu d''eau, consulter immédiatement. Inhalation : air frais.',
      'Matières organiques, solvants, métaux, poudres métalliques, bases fortes.',
      'Local ventilé, frais, à l''écart des combustibles, récipient en acier inoxydable ou PEHD.',
      10, 30, false, true, 24, 'a_valider'
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
    select v_academie_id, id from public.phrases_h where code in ('H272', 'H314')
    on conflict (academie_id, phrase_h_id) do nothing;

    insert into public.academie_phrases_p (academie_id, phrase_p_id)
    select v_academie_id, id from public.phrases_p
    where code in ('P280', 'P301+P330+P331', 'P303+P361+P353', 'P305+P351+P338', 'P310')
    on conflict (academie_id, phrase_p_id) do nothing;

    insert into public.matieres_premieres_usages (
      academie_id, domaine_application, technique_methode, dosage_type,
      dosage_min, dosage_max, unite_dosage, temperature_utilisation,
      temps_action, a_verifier_labo, ordre
    ) values
    (v_academie_id, 'Décapage métaux',
     'Utiliser une solution à 10-20 %, appliquer au pinceau ou par trempage, surveiller le dégagement de vapeurs rousses.',
     'dilution', 1, 4, 'volumes d''eau pour 1 volume d''acide', 'Ambiante', '5-15 min', false, 0);
  end loop;

  -- ------------------------------------------------------------
  -- Acide oxalique
  -- ------------------------------------------------------------
  v_material_id := '79ad5def-a289-493e-bd94-adf19e82a2d3'::uuid;

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
    'Acide oxalique (C₂H₂O₄)',
    'Sel d''oseille',
    'Technique',
    'Cristaux blancs ou poudre',
    '1,5 (solution saturée)',
    '10 g/100 mL à 20 °C',
    1.65,
    null,
    'Agent réducteur, toxique par ingestion ; forme des complexes insolubles avec le calcium.',
    'Plus spécifique pour la rouille et les taches tenaces que l''acide citrique.',
    'Modéré (nocif)',
    array['gants','lunettes'],
    'Gants nitrile, éviter de respirer les poussières.',
    'Peau : laver à l''eau. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas faire vomir, consulter immédiatement.',
    'Oxydants, bases, métaux lourds.',
    'Récipient étanche, au sec, à l''écart des aliments.',
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H312', 'H315', 'H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280', 'P301+P312', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, unite_dosage, temperature_utilisation, temps_action,
    a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Détachant rouille',
   'Dissoudre 50 g dans 1 L d''eau chaude, appliquer sur la tache, laisser agir, rincer.',
   'valeur_unique', 50, 'g/L', '50-60 °C', '10-20 min', false, 0);

  -- ------------------------------------------------------------
  -- Acide lactique
  -- ------------------------------------------------------------
  v_material_id := 'ec3c13d1-6f92-4726-850d-c08e3a0f37d7'::uuid;

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
    'Acide lactique (C₃H₆O₃)',
    'Acide lactique, E270',
    'Alimentaire',
    'Liquide visqueux incolore à jaune pâle',
    '2-3 (solution à 1 %)',
    'Totalement soluble dans l''eau',
    1.21,
    110,
    'Densité typique pour une solution à 80 %. Acide alpha-hydroxylé (AHA), utilisé en cosmétique pour l''hydratation et l''exfoliation douce.',
    'Moins irritant que l''acide glycolique, convient aux peaux sensibles.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en PVC ou nitrile, éviter le contact avec les yeux.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Oxydants forts.',
    'Récipient étanche, température ambiante.',
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

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Cosmétique (ajusteur pH, AHA)',
   'Incorporer dans la phase aqueuse, ajuster le pH final.',
   'plage', 0.5, 5, '% du produit', 'Ambiante', true, 0),
  (v_academie_id, 'Alimentaire (acidulant, conservateur)',
   'Ajouter selon la recette, généralement 0,1-0,5 %.',
   'plage', 0.1, 0.5, '% du poids', null, false, 1);

  -- ------------------------------------------------------------
  -- Hydroxyde de calcium (Ca(OH)₂) — catalogue sous "Chaux eteinte"
  -- ------------------------------------------------------------
  v_material_id := 'a218c575-ce9d-4350-afe2-1fb4f3dddb9f'::uuid;

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
    'Hydroxyde de calcium (Ca(OH)₂)',
    'Chaux éteinte, chaux hydratée',
    'Technique',
    'Poudre blanche fine',
    '12-13 (solution saturée, eau de chaux)',
    'Faible (0,16 g/100 mL à 20 °C)',
    2.24,
    null,
    'Densité du solide anhydre. Suspension laiteuse dans l''eau, réagit avec le CO₂ de l''air pour former du carbonate.',
    'Moins alcalin et moins soluble que la soude caustique, souvent utilisé en construction et traitement de l''eau.',
    'Élevé (irritant sévère)',
    array['gants','lunettes','masque'],
    'Gants étanches, lunettes étanches, éviter d''inhaler les poussières.',
    'Yeux : rincer 15 min, consulter. Peau : laver à l''eau. Ingestion : rincer la bouche, boire de l''eau, consulter.',
    'Acides, métaux légers en présence d''humidité.',
    'Au sec, dans un récipient étanche, à l''écart des acides.',
    5, 40, true, false, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H318', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p where code in ('P261', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Traitement de l''eau (chaulage)',
   'Préparer un lait de chaux, ajouter progressivement jusqu''à pH désiré.',
   'plage', 0.1, 1, 'g/L', 'Ambiante', 'Instantané', true, 0);

  -- ------------------------------------------------------------
  -- Silicate de sodium — 2 variantes du catalogue
  -- ------------------------------------------------------------
  for r in
    select * from (values
      ('5dab488b-d403-4478-b1ac-4c43895a4da6'::uuid), -- Metasilicate de sodium
      ('d125538c-6dd3-4b3a-8c71-18f5f20bf862'::uuid)  -- Silicate de sodium
    ) as t(material_id)
  loop
    insert into public.matieres_premieres_academie (
      matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
      ph_solution, solubilite, densite, point_eclair, particularite,
      difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
      premiers_secours, incompatibilites, consignes_stockage,
      temperature_stockage_min, temperature_stockage_max,
      sensible_humidite, sensible_lumiere, duree_conservation_mois,
      statut_verification
    ) values (
      r.material_id,
      'Silicate de sodium (Na₂SiO₃)',
      'Verre liquide, silicate de soude',
      'Technique',
      'Liquide visqueux incolore à légèrement trouble',
      '11-13 (solution diluée)',
      'Totalement soluble dans l''eau',
      1.40,
      null,
      'Densité typique pour une solution commerciale à 40 %. Durcit au contact du CO₂ de l''air.',
      'Forme un film protecteur alcalin, contrairement à la soude pure qui ne laisse pas de couche résiduelle.',
      'Modéré',
      array['gants','lunettes'],
      'Gants en caoutchouc, éviter le contact avec la peau.',
      'Rincer abondamment à l''eau.',
      'Acides, sels acides, métaux légers.',
      'Bidon bien fermé, à l''abri de l''humidité et du froid.',
      5, 35, false, false, 12, 'a_valider'
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
    select v_academie_id, id from public.phrases_p where code in ('P264', 'P280')
    on conflict (academie_id, phrase_p_id) do nothing;

    insert into public.matieres_premieres_usages (
      academie_id, domaine_application, technique_methode, dosage_type,
      dosage_min, dosage_max, unite_dosage, temperature_utilisation,
      a_verifier_labo, ordre
    ) values
    (v_academie_id, 'Détergent / nettoyant alcalin',
     'Diluer à 2-5 % dans l''eau de lavage, utilisé comme inhibiteur de corrosion et agent de suspension.',
     'plage', 2, 5, '% (v/v) dans l''eau', '40-60 °C', false, 0);
  end loop;
end $$;
