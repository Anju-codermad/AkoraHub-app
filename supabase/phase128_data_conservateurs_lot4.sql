-- ============================================================
-- AkoraHub - Patch Phase 128 : fiches Académie pour le lot 4 (dernier
-- lot — 6 antioxydants restants + conservateurs œnologiques) des
-- nouveaux produits "Conservateurs & Antioxydants" — contenu
-- DeepSeek, vérifié par l'utilisatrice.
--
-- Lot 4/4 (dernier lot) : Gallate de dodécyle (E312), Citrate de
-- sodium (E331), Tartrate de sodium (E335), Ascorbate de calcium
-- (E302), Anhydride sulfureux (SO₂), Dicarbonate de diméthyle
-- (DMDC, E242).
--
-- Anhydride sulfureux et DMDC documentés avec avertissements
-- renforcés (gaz toxique corrosif par inhalation pour le premier ;
-- produit corrosif oculaire/cutané sévère avant hydrolyse pour le
-- second), niveau_danger 'Élevé' pour les deux.
-- Termine les 30 nouveaux produits de la catégorie "Conservateurs &
-- Antioxydants" (phases 125-128).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Gallate de dodécyle (E312)
  -- ------------------------------------------------------------
  v_material_id := '83da80b1-610e-4fee-91c1-ead4dfb52d45'::uuid;

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
    '3,4,5-trihydroxybenzoate de dodécyle (C₁₉H₃₀O₅)',
    'Dodecyl Gallate, E312, antioxydant liposoluble à longue chaîne',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche à blanc cassé, inodore',
    'Non applicable (liposoluble)',
    'Insoluble dans l''eau, très soluble dans les huiles, les graisses et l''alcool chaud',
    1.05, null,
    'Ester d''acide gallique à très longue chaîne alkyle (C12), le plus liposoluble des gallates. Antioxydant phénolique efficace pour protéger les huiles et graisses contre le rancissement oxydatif. Souvent synergisé avec le BHA, le BHT ou l''acide citrique pour une protection renforcée. Limite UE : 200 mg/kg dans les graisses, 100 mg/kg dans les snacks. En cosmétique, utilisé à faible dose (< 0,1 %) comme antioxydant pour les formules anhydres.',
    'Par rapport au gallate de propyle (E310) et au gallate d''octyle (E311), il est beaucoup plus liposoluble grâce à sa chaîne dodécyle, ce qui le rend idéal pour les corps gras très saturés. Il est moins sensible à l''hydrolyse que les gallates à chaîne courte. Son coût plus élevé le réserve aux applications techniques spécifiques.',
    'Modéré',
    array['gants','lunettes','masque'],
    'Gants en nitrile, lunettes de sécurité, masque anti-poussière. Éviter le contact cutané (sensibilisant possible) et l''inhalation de poudre.',
    'Inhalation : air frais. Peau : laver au savon. Yeux : rincer 15 min. Ingestion : rincer la bouche, boire de l''eau, appeler un médecin si symptômes.',
    'Oxydants forts, bases fortes, sels de fer (coloration).',
    'Récipient étanche, au frais, à l''abri de la lumière et de l''humidité.',
    5, 30, false, true, 36, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H315', 'H317', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P272', 'P280', 'P301+P312', 'P305+P351+P338', 'P333+P313')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Antioxydant pour huiles industrielles, graisses techniques et snacks',
   'Dissoudre 0,01-0,02 % dans la matière grasse chaude (70-80°C). Utiliser en combinaison avec de l''acide citrique (0,005 %) pour un effet synergique.',
   'valeur_unique', 0.02, null, '% du poids de la matière grasse', '70-80°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Citrate de sodium (E331)
  -- ------------------------------------------------------------
  v_material_id := '79701954-6657-464d-8301-6bfeaaa60b8e'::uuid;

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
    'Citrate trisodique (Na₃C₆H₅O₇)',
    'Sodium Citrate, E331, sel de sodium de l''acide citrique, tampon et synergiste antioxydant',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche, inodore, saveur salée et acidulée',
    '7,5-8,5 (solution à 5 %)',
    'Très soluble dans l''eau (42 g/100 mL à 20°C), insoluble dans l''alcool',
    1.70, null,
    'Sel de sodium de l''acide citrique, utilisé comme tampon, régulateur d''acidité et synergiste antioxydant. Chélate les métaux pro-oxydants (fer, cuivre) et renforce l''action des antioxydants phénoliques (BHA, BHT, gallates) en piégeant les traces métalliques. Limite UE : quantum satis dans la plupart des aliments. En cosmétique, utilisé comme chélatant et ajusteur de pH jusqu''à 1 %.',
    'Par rapport au citrate de potassium (E332), il apporte du sodium plutôt que du potassium. Contrairement à l''EDTA, il est un chélatant doux, alimentaire et labelisable bio, mais moins puissant. Il est souvent le synergiste de choix pour les formulations "clean label".',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter l''inhalation de poudre en grande quantité.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts, acides forts (libération d''acide citrique).',
    'Récipient étanche, au sec, à l''abri de l''humidité.',
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
  (v_academie_id, 'Synergiste antioxydant pour huiles et graisses alimentaires',
   'Dissoudre 0,01-0,05 % dans la phase aqueuse ou disperser dans l''huile en mélange avec un antioxydant primaire (tocophérols, extrait de romarin).',
   'plage', 0.01, 0.05, '% du produit fini', 'Ambiante', 'Immédiat', false, 0),
  (v_academie_id, 'Tampon et chélatant en cosmétique (crèmes, lotions)',
   'Incorporer 0,1 à 1,0 % dans la phase aqueuse. Améliore la stabilité des antioxydants et ajuste le pH.',
   'plage', 0.1, 1.0, '% du produit fini', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Tartrate de sodium (E335)
  -- ------------------------------------------------------------
  v_material_id := '27350ab4-68c5-4731-8c94-92582352570e'::uuid;

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
    'Tartrate disodique (Na₂C₄H₄O₆)',
    'Sodium Tartrate, E335, sel de sodium de l''acide tartrique, synergiste antioxydant',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche, inodore, saveur légèrement saline',
    '7-8 (solution à 10 %)',
    'Très soluble dans l''eau (26 g/100 mL à 20°C), insoluble dans l''alcool',
    1.80, null,
    'Sel de sodium de l''acide tartrique, utilisé comme tampon et synergiste antioxydant par chélation des métaux pro-oxydants. Souvent associé aux antioxydants phénoliques dans les corps gras. Limite UE : quantum satis dans la plupart des aliments. En cosmétique, utilisation ponctuelle comme ajusteur de pH et stabilisant d''émulsion.',
    'Par rapport au citrate de sodium (E331), il est moins efficace comme chélatant mais plus performant pour précipiter le calcium. Comparé à l''EDTA, il est naturel, labelisable bio, mais moins puissant.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts, acides forts.',
    'Récipient étanche, au sec, à l''abri de l''humidité.',
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
  (v_academie_id, 'Synergiste antioxydant pour corps gras alimentaires',
   'Ajouter 0,01-0,05 % en solution aqueuse dans l''émulsion ou directement dans la phase grasse avec l''antioxydant primaire.',
   'plage', 0.01, 0.05, '% du produit fini', 'Ambiante', 'Immédiat', false, 0),
  (v_academie_id, 'Ajusteur de pH et stabilisant en cosmétique',
   'Dissoudre 0,1-0,5 % dans la phase aqueuse. Stabilise les formules contenant des sels métalliques.',
   'plage', 0.1, 0.5, '% du produit fini', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Ascorbate de calcium (E302)
  -- ------------------------------------------------------------
  v_material_id := '9693ccfb-6c36-4988-87e3-6c09d2c4856d'::uuid;

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
    'Di-L-ascorbate de calcium (C₁₂H₁₄CaO₁₂)',
    'Calcium Ascorbate, E302, vitamine C minérale, antioxydant alimentaire',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche à jaune très pâle, odeur faible d''agrumes',
    '6,5-7,5 (solution à 10 %)',
    'Très soluble dans l''eau (50 g/100 mL à 20°C), insoluble dans les huiles',
    1.20, null,
    'Sel de calcium de l''acide ascorbique (vitamine C). Antioxydant hydrosoluble qui piège l''oxygène et protège les aliments de l''oxydation. Apporte également du calcium assimilable. Moins acide que l''acide ascorbique (E300), il est mieux toléré par l''estomac et ne modifie pas le pH des préparations. Limite UE : quantum satis dans la plupart des aliments. En cosmétique, utilisé comme source de vitamine C jusqu''à 1 %.',
    'Par rapport à l''acide ascorbique (E300), il est moins acide et apporte du calcium. Contrairement à l''ascorbate de sodium (E301), il est préféré lorsque l''apport en sodium doit être limité. Il est l''alternative douce pour les formulations sensibles au pH.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts, métaux lourds (fer, cuivre), bases fortes.',
    'Récipient étanche, au frais, à l''abri de la lumière et de l''humidité.',
    5, 25, true, true, 24, 'a_valider'
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
  (v_academie_id, 'Antioxydant et source de calcium pour boissons, compotes, aliments infantiles',
   'Dissoudre 0,05-0,2 % dans la phase aqueuse en fin de préparation pour éviter la dégradation thermique.',
   'plage', 0.05, 0.2, '% du produit fini', 'Ambiante à 40°C', 'Immédiat', false, 0),
  (v_academie_id, 'Source de vitamine C douce en cosmétique (sérums, crèmes)',
   'Incorporer 0,5-1,0 % dans la phase aqueuse froide. Ajuster le pH si nécessaire (6,5-7,5).',
   'plage', 0.5, 1.0, '% du produit fini', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Anhydride sulfureux (SO₂)
  -- ------------------------------------------------------------
  v_material_id := '2f3b7d96-b22a-4bd9-aba9-db14bd79aea5'::uuid;

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
    'Dioxyde de soufre (SO₂)',
    'Sulfur Dioxide, E220, acide sulfureux (en solution aqueuse), conservateur œnologique',
    'Œnologique, Alimentaire',
    'Gaz incolore à odeur suffocante et piquante, ou solution aqueuse (acide sulfureux)',
    '2-3 (solution aqueuse d''acide sulfureux)',
    'Très soluble dans l''eau (forme H₂SO₃), soluble dans l''alcool',
    null, null,
    'Gaz très toxique par inhalation, provoquant de graves brûlures des voies respiratoires. Puissant allergène respiratoire, particulièrement dangereux pour les asthmatiques. En œnologie, utilisé comme antioxydant et antiseptique (protège contre l''oxydation et les bactéries). Limite réglementaire UE dans les vins : 150-400 mg/L selon le type. Se manipule impérativement en solution ou en bouteille de gaz avec détendeur.',
    'Contrairement au métabisulfite de potassium (E224) qui est un sel solide libérant du SO₂, l''anhydride sulfureux est le gaz pur. Il est plus difficile à manipuler mais offre un dosage précis en œnologie. Il est le seul gaz de la catégorie conservateurs, les autres étant des solides ou liquides.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Porter impérativement un masque à cartouche filtrante spécifique pour gaz acides (type B ou E) ou un appareil respiratoire isolant — un masque anti-poussière simple est insuffisant. Gants en caoutchouc butyle, lunettes de sécurité étanches, combinaison de protection. Manipuler sous hotte ou en local très ventilé. Interdit aux asthmatiques et insuffisants respiratoires.',
    'Inhalation : transporter la victime à l''air frais, en position semi-assise, consulter immédiatement un médecin. Peau : rincer 15 min, retirer les vêtements contaminés. Yeux : rincer 15 min, consulter un ophtalmologue. Ingestion de la solution : rincer la bouche, ne pas faire vomir, appeler un centre antipoison.',
    'Bases fortes, oxydants forts, ammoniac, amines, métaux alcalins.',
    'Bouteille de gaz comprimé ou liquéfié sous pression, stockée debout, dans un local frais, sec et très bien ventilé, à l''écart des matières combustibles et des bases. Protéger du gel et des températures > 50°C.',
    5, 30, false, false, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H314', 'H318', 'H331', 'H334', 'H370', 'H372')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P260', 'P264', 'P280', 'P284', 'P301+P330+P331', 'P303+P361+P353', 'P304+P340', 'P305+P351+P338', 'P310', 'P342+P311')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Antioxydant et antiseptique en vinification (sulfitage)',
   'Injecter le gaz directement dans le moût ou le vin, ou utiliser une solution aqueuse (acide sulfureux) à 5-10 %. Respecter strictement les doses légales (max 150-400 mg/L selon le type de vin).',
   'plage', 30, 150, 'mg/L de SO₂ libre', '10-20°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Dicarbonate de diméthyle (DMDC, E242)
  -- ------------------------------------------------------------
  v_material_id := '8b3d0a97-eb2e-471e-985f-7a5c33797f2b'::uuid;

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
    'Dicarbonate de diméthyle (C₄H₆O₅)',
    'Dimethyl Dicarbonate, DMDC, E242, Velcorin, conservateur de boissons',
    'Œnologique, Alimentaire',
    'Liquide incolore à jaune très pâle, odeur piquante caractéristique',
    'Se décompose rapidement dans l''eau en CO₂ et méthanol',
    'Peu soluble dans l''eau (se décompose), miscible aux solvants organiques',
    1.25, 85.0,
    'Conservateur de boissons non alcoolisées et de vins sans alcool, agissant par dénaturation des enzymes microbiennes. Se décompose rapidement dans l''eau en CO₂ et méthanol (traces inférieures à la limite réglementaire). Produit très dangereux avant hydrolyse : corrosif oculaire et cutané sévère, vapeurs très toxiques. Manipulation exclusive par du personnel formé, avec équipements de protection étanches, sous hotte aspirante. Limite UE : 250 mg/L dans les boissons.',
    'Contrairement à l''anhydride sulfureux (SO₂), il ne dégage pas de gaz persistant et ne pose pas de problème d''allergie respiratoire après hydrolyse. Par rapport au benzoate ou au sorbate, il est actif à froid, ne modifie pas le goût et ne nécessite pas de pH acide. Son maniement est toutefois extrêmement dangereux avant dilution.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Porter impérativement des gants en caoutchouc butyle étanches, une combinaison de protection anti-acide, un écran facial et un masque à cartouche filtrante pour vapeurs organiques (type A). Manipuler exclusivement sous hotte aspirante ou en zone confinée ventilée. Éviter tout contact avec la peau, les yeux et les muqueuses. Produit réservé aux professionnels formés.',
    'Inhalation : transporter la victime à l''air frais, consulter immédiatement un médecin. Peau : rincer 15 min, retirer les vêtements contaminés, appliquer du polyéthylène glycol 400 si disponible. Yeux : rincer 15 min, consulter un ophtalmologue en urgence. Ingestion : rincer la bouche, ne pas faire vomir, appeler immédiatement un centre antipoison.',
    'Eau (hydrolyse rapide), alcools, amines, bases fortes, acides forts.',
    'Bidon en acier inoxydable ou en verre, au sec, dans un local frais, rigoureusement à l''abri de l''eau et de l''humidité. Stocker sous atmosphère inerte. Protéger du gel et des températures > 40°C.',
    15, 30, true, false, 12, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H226', 'H314', 'H318', 'H330', 'H334', 'H335', 'H400')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P260', 'P264', 'P280', 'P284', 'P301+P330+P331', 'P303+P361+P353', 'P304+P340', 'P305+P351+P338', 'P310', 'P320', 'P403+P233')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Stérilisation à froid des boissons non alcoolisées et vins sans alcool',
   'Ajouter le DMDC pur au flux de boisson à l''aide d''une pompe doseuse étanche, sous agitation vigoureuse. Laisser agir 24 h pour hydrolyse complète. Réservé aux installations industrielles équipées.',
   'valeur_unique', 100, 250, 'mg/L de boisson (dose maximale légale UE : 250 mg/L)', '5-20°C', '24 h pour hydrolyse complète', false, 0);
end $$;
