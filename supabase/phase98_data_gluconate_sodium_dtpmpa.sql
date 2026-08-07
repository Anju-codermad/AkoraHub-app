-- ============================================================
-- AkoraHub - Patch Phase 98 : fiches Académie "Gluconate de sodium
-- (E576)" et "DTPMPA" — contenu DeepSeek, vérifié par l'utilisatrice.
-- Termine la catégorie "Chélatants" (12/12).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Gluconate de sodium (E576)
  -- ------------------------------------------------------------
  v_material_id := '057091ec-05f9-4a8c-846b-62a1c4cd35ed'::uuid;

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
    'Gluconate de sodium (C₆H₁₁NaO₇)',
    'E576, sel de sodium de l''acide gluconique, gluconate de soude',
    'Alimentaire',
    'Poudre cristalline blanche à légèrement jaunâtre, ou granulés, inodore',
    '7-8 (solution à 1 %)',
    'Très soluble dans l''eau (59 g/100 mL à 20 °C)',
    1.54, null,
    'Chélatant doux biodégradable, stable en milieu alcalin ; excellent pour le nettoyage en place (CIP) et les formulations compatibles alimentaires. Chélate préférentiellement le calcium, le fer et l''aluminium.',
    'Moins puissant que l''EDTA mais sans risque écotoxicologique ; privilégié en agroalimentaire et cosmétique naturelle. Contrairement à l''acide gluconique (E574), il n''acidifie pas le milieu.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire ; masque anti-poussière recommandé pour les manipulations de grands volumes.',
    'Yeux : rincer à l''eau. Peau : laver à l''eau. Ingestion sans danger aux doses usuelles. Inhalation : air frais.',
    'Oxydants forts, acides forts.',
    'Récipient étanche, au sec, à température ambiante, à l''écart des acides.',
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Détergence alcaline (nettoyant en place CIP, lessive)',
   'Incorporer 1 à 5 % dans la formulation alcaline pour éviter la précipitation des sels de calcium et améliorer le rinçage.',
   'plage', 1, 5, '% du produit fini', '20-80 °C', 'Incorporation immédiate', false, 0),
  (v_academie_id, 'Cosmétique (stabilisant, humectant)',
   'Ajouter 0,1 à 0,5 % dans la phase aqueuse pour chélater les ions métalliques et renforcer l''efficacité des conservateurs.',
   'plage', 0.1, 0.5, '% du produit fini', 'Ambiante', 'Dissolution rapide', false, 1),
  (v_academie_id, 'Traitement de l''eau (anticalcaire doux)',
   'Doser en continu dans l''eau d''appoint à raison de 5 à 15 g/m³ pour séquestrer le fer et le calcium.',
   'plage', 5, 15, 'g/m³ d''eau', 'Ambiante', 'Action immédiate', true, 2);

  -- ------------------------------------------------------------
  -- DTPMPA
  -- ------------------------------------------------------------
  v_material_id := '3c6c510e-ea47-4264-8a27-559ae833a4a3'::uuid;

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
    'Acide diéthylènetriaminepentakis(méthylènephosphonique) (C₉H₂₈N₃O₁₅P₅)',
    'DTPMPA, DTPMP, sel pentasodique de DTPMPA',
    'Technique',
    'Liquide clair ambré à brun (solution aqueuse à 50 %)',
    '<2 (solution concentrée) ; après neutralisation partielle, 10-12',
    'Totalement miscible à l''eau',
    1.38, null,
    'Densité donnée pour la solution commerciale à 50 %. Phosphonate extrêmement puissant, capable de chélater une large gamme de métaux même à très faible dose. Très stable thermiquement et résistant à l''hydrolyse.',
    'Plus performant que l''ATMP et l''HEDP pour inhiber la précipitation des sels de baryum et de strontium. Coût élevé, réservé aux applications industrielles sévères où les autres phosphonates sont inefficaces.',
    'Corrosif',
    array['gants','lunettes','ventilation','tablier'],
    'Gants en caoutchouc butyle ou néoprène, écran facial, manipuler sous hotte ou avec ventilation adéquate.',
    'Peau : rincer 15 min, retirer vêtements. Yeux : rincer 15 min, consulter ophtalmologue. Ingestion : rincer bouche, ne pas vomir, boire un verre d''eau, appeler médecin. Inhalation : air frais.',
    'Bases fortes (réaction violente), agents oxydants puissants, métaux alcalins.',
    'Récipient en PEHD ou acier inoxydable, local ventilé, à l''abri du gel et des bases fortes.',
    5, 40, false, false, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H314', 'H290')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P260', 'P280', 'P301+P330+P331', 'P303+P361+P353', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Traitement de l''eau des chaudières haute pression',
   'Injecter en continu à raison de 2 à 10 ppm dans l''eau d''appoint pour prévenir les dépôts de tartre et la corrosion.',
   'plage', 2, 10, 'g/m³ d''eau', 'Jusqu''à 200 °C', 'Action continue', true, 0),
  (v_academie_id, 'Stabilisant dans les fluides de fracturation pétrolière',
   'Diluer dans la saumure à raison de 0,5 à 2 % pour inhiber la précipitation des sels métalliques.',
   'plage', 0.5, 2, '% du fluide', 'Ambiante à 150 °C', 'Permanent dans le fluide', true, 1);
end $$;
