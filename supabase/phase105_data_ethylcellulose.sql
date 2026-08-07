-- ============================================================
-- AkoraHub - Patch Phase 105 : fiche Académie "Éthylcellulose (E462)"
-- — contenu DeepSeek, vérifié par l'utilisatrice. Termine la
-- catégorie "Épaississants" (33/33).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid := '27056e3a-a3cb-4213-9115-69ca5d080cbc'::uuid;
  v_academie_id uuid;
begin
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
    'Éthylcellulose ((C₁₂H₂₂O₅)n)',
    'Éther éthylique de cellulose, E462',
    'Technique',
    'Poudre granuleuse blanche à crème, inodore',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau ; soluble dans de nombreux solvants organiques (éthanol, acétate d''éthyle, toluène, etc.)',
    1.14, null,
    'Éther de cellulose hydrophobe, thermoplastique et filmogène, formant des pellicules transparentes, résistantes à l''eau et aux graisses.',
    'Contrairement à l''HPMC, à la méthylcellulose et à la CMC qui sont hydrosolubles, l''éthylcellulose est insoluble dans l''eau et soluble dans les solvants organiques. Utilisée pour ses propriétés filmogènes hydrofuges, alors que les autres sont des épaississants ou gélifiants aqueux.',
    'Aucun',
    array['masque'],
    'Porter un masque anti-poussières lors de la manipulation de la poudre pour éviter l''inhalation de particules fines.',
    'Yeux : rincer abondamment à l''eau. Peau : laver à l''eau. Inhalation : air frais. Ingestion : boire de l''eau.',
    'Oxydants forts.',
    'Récipient étanche, au sec, à l''abri de l''humidité, dans un endroit bien ventilé.',
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
  (v_academie_id, 'Technique (liant pour peintures, vernis, encres)',
   'Dissoudre 5 à 10 % d''éthylcellulose dans un solvant organique approprié (éthanol, acétate d''éthyle) sous agitation, puis incorporer les pigments ou charges.',
   'plage', 5, 10, '% en poids de la formulation totale', '15-30 °C', '30-60 min de dissolution', false, 0),
  (v_academie_id, 'Cosmétique (filmogène pour vernis à ongles, fixateur capillaire)',
   'Dissoudre 8 à 15 % d''éthylcellulose dans un mélange éthanol/acétate d''éthyle, ajouter plastifiants et actifs. Appliquer au pinceau et laisser sécher.',
   'plage', 8, 15, '% de la formule (base filmogène)', 'Ambiante', 'Séchage à l''air : 2-5 min', false, 1);
end $$;
