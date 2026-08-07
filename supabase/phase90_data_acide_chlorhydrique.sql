-- ============================================================
-- AkoraHub - Patch Phase 90 : fiche Académie complète "Acide
-- chlorhydrique" (HCl) à partir du contenu généré avec DeepSeek,
-- vérifié par l'utilisatrice
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Upsert (comme phase89 corrigé) — fonctionne que la fiche existe déjà
-- ou non pour cette matière.
-- ============================================================

do $$
declare
  v_material_id uuid := 'd44af091-72d9-426f-a375-5f7f2fbf61d2'::uuid; -- Acide chlorhydrique
  v_academie_id uuid;
begin
  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, particularite, difference_produit_similaire,
    niveau_danger, epi_requis, notes_epi, premiers_secours,
    incompatibilites, consignes_stockage, temperature_stockage_min,
    temperature_stockage_max, sensible_humidite, sensible_lumiere,
    duree_conservation_mois, statut_verification
  ) values (
    v_material_id,
    'Acide chlorhydrique (HCl)',
    'Acide chlorhydrique',
    null,
    'Liquide incolore à légèrement jaunâtre, très volatil, dégageant des vapeurs piquantes de chlorure d''hydrogène.',
    'Fortement acide – solution à 1 % → pH ≈ 0 ; solution 0,1 M → pH = 1.',
    'Totalement miscible à l''eau en toutes proportions (dégagement de chaleur modéré, toujours verser l''acide dans l''eau).',
    'Très volatil – émet des vapeurs acides irritantes même à température ambiante ; la solution concentrée fume à l''air humide. Densité 1,18 g/cm³ (solution commerciale à 37 % massique, dite « acide chlorhydrique fumant »).',
    'Par rapport à l''acide sulfurique, l''acide chlorhydrique est moins agressif vis-à-vis des aciers inoxydables et ne forme pas de précipités insolubles avec le calcium, ce qui le rend idéal pour le détartrage. Il est toutefois plus volatil et ses vapeurs sont très irritantes.',
    'Corrosif',
    array['gants','lunettes','masque','tablier','bottes','ventilation'],
    'Gants en caoutchouc butyle ou PVC, lunettes de protection étanches ou écran facial, masque filtrant anti-gaz acides (type B ou ABEK) dès que la ventilation est insuffisante, tablier anti-acide, bottes de sécurité.',
    'Contact peau : retirer les vêtements contaminés, rincer immédiatement à grande eau pendant au moins 15 minutes. Ne pas neutraliser. Consulter un médecin. Contact yeux : rincer à l''eau courante en maintenant les paupières écartées pendant 15 minutes. Appeler immédiatement un médecin. Ingestion : rincer la bouche, ne pas faire vomir, faire boire un peu d''eau. Appeler immédiatement un centre antipoison ou un médecin. Inhalation : transporter la personne à l''air libre, en position semi-assise. En cas de gêne respiratoire persistante, consulter un médecin.',
    'Bases (réaction violente), oxydants forts (eau de Javel → dégagement de chlore gazeux toxique), métaux légers et leurs alliages (aluminium, zinc, magnésium → hydrogène inflammable), amines.',
    'Conserver dans un récipient étanche en plastique résistant (PEHD, PVC) ou en acier inoxydable. Stocker debout dans un local frais, sec, bien ventilé, à l''abri des bases, des oxydants et des sources de chaleur. Munir le local d''une rétention adaptée.',
    5,
    30,
    false,
    false,
    24,
    'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique,
    synonymes = excluded.synonymes,
    aspect = excluded.aspect,
    ph_solution = excluded.ph_solution,
    solubilite = excluded.solubilite,
    particularite = excluded.particularite,
    difference_produit_similaire = excluded.difference_produit_similaire,
    niveau_danger = excluded.niveau_danger,
    epi_requis = excluded.epi_requis,
    notes_epi = excluded.notes_epi,
    premiers_secours = excluded.premiers_secours,
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
  select v_academie_id, id from public.phrases_p
  where code in ('P260', 'P280', 'P301+P330+P331', 'P303+P361+P353', 'P305+P351+P338', 'P310', 'P403+P233')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, dosage_texte,
    temperature_utilisation, temps_action, a_verifier_labo, ordre
  ) values
  (
    v_academie_id,
    'Détartrage',
    'Diluer l''acide à 10-20 % (1 volume d''acide du commerce + 2 à 5 volumes d''eau). Appliquer par trempage ou circulation sur les surfaces entartrées. Laisser agir, puis rincer abondamment à l''eau claire. Ne pas utiliser sur aluminium, zinc, marbre ou laiton.',
    'dilution',
    null, null,
    '% (v/v)',
    '1 pour 2 à 1 pour 5 (acide/eau), soit environ 7-18 %',
    'Ambiante (20-25 °C) ; un léger chauffage (< 40 °C) accélère la réaction mais dégage plus de vapeurs',
    '10 à 30 minutes selon l''épaisseur du tartre',
    false,
    0
  ),
  (
    v_academie_id,
    'Ajustement pH',
    'Ajouter lentement une solution d''acide dilué (5-10 %) sous agitation, en contrôlant le pH en continu. Utiliser une pompe doseuse pour un réglage fin.',
    'plage',
    0.1, 2,
    '% (soit 1 à 20 g/L)',
    null,
    'Ambiante (20-25 °C)',
    'Immédiat (ajuster progressivement)',
    true,
    1
  ),
  (
    v_academie_id,
    'Désoxydation métaux (avant peinture)',
    'Préparer un bain d''acide chlorhydrique à 5-10 %. Immerger ou frotter la pièce métallique (acier, fer) jusqu''à élimination de la rouille et des oxydes. Rincer immédiatement à grande eau puis sécher et appliquer un primaire antirouille sans délai.',
    'plage',
    5, 10,
    '%',
    null,
    '20-30 °C',
    '5 à 15 minutes (surveiller pour éviter l''attaque du métal de base)',
    true,
    2
  ),
  (
    v_academie_id,
    'Traitement de l''Eau',
    'Injecter l''acide dilué (10 %) dans le flux d''eau à traiter, en amont d''un mélangeur statique. Asservir la pompe à une sonde de pH pour un ajustement automatique.',
    'plage',
    0.05, 1,
    'g/L',
    null,
    'Ambiante',
    'Instantané',
    true,
    3
  );
end $$;
