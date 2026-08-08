-- ============================================================
-- AkoraHub - Patch Phase 116 : fiches Académie pour les 13 colorants
-- déjà présents dans le catalogue avant la campagne (9 substances
-- spécifiques + 4 fiches de synthèse par famille) — contenu
-- DeepSeek, vérifié par l'utilisatrice.
--
-- Termine la catégorie "Colorants" (39/39 : 26 nouveaux en phase
-- 114/115 + ces 13 produits déjà existants).
--
-- Les 4 fiches génériques (Colorants alimentaires certifiés,
-- Colorants cosmétiques, Colorants industriels, Pigments oxydes de
-- fer/TiO2) sont des vues d'ensemble de famille plutôt que des
-- fiches mono-substance, sur décision de l'utilisatrice.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Bétacarotène (E160a)
  -- ------------------------------------------------------------
  v_material_id := '05da05cc-577d-4733-bf8d-fc374a6e68fd'::uuid;

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
    'β,β-carotène (E160a) (C₄₀H₅₆)',
    'E160a, provitamine A, carotène, Natural Yellow 26',
    'Alimentaire',
    'Poudre rouge-orangé à brun-rouge, ou suspension huileuse, odeur végétale légère',
    'Stable entre pH 3 et 9',
    'Insoluble dans l''eau, soluble dans les huiles et les solvants organiques. Disponible en version microencapsulée hydrosoluble.',
    0.80, null,
    'Caroténoïde naturel à double fonction : colorant jaune à orange et provitamine A. Sensible à l''oxydation, à la lumière et à la chaleur prolongée. Utilisé comme colorant et complément alimentaire.',
    'Plus jaune que le lycopène (E160d) et plus orangé que la lutéine (E161b). Contrairement à la curcumine, il est insensible au pH mais moins résistant à l''oxydation.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. Éviter l''inhalation de poudre.',
    'Yeux : rincer à l''eau. Peau : laver. Ingestion sans danger.',
    'Oxydants forts, lumière, oxygène (décoloration).',
    'Récipient étanche sous atmosphère inerte, au frais, à l''abri de la lumière et de l''air.',
    5, 20, false, true, 12, 'a_valider'
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
  (v_academie_id, 'Coloration jaune à orange de margarines, fromages, boissons, glaces et compléments alimentaires',
   'Utiliser la forme huileuse pour les corps gras, ou la poudre dispersible pour les applications aqueuses. Ajouter en fin de cuisson si possible.',
   'plage', 0.01, 0.2, '% du produit fini', '20-80°C (éviter les hautes températures prolongées)', 'Immédiat', false, 0),
  (v_academie_id, 'Colorant cosmétique (savons, beurres corporels, baumes à lèvres)',
   'Disperser dans la phase grasse chaude avant refroidissement. Protéger de la lumière après conditionnement.',
   'plage', 0.1, 1, '% du poids des huiles', '40-70°C', 'Mélange', false, 1);

  -- ------------------------------------------------------------
  -- Bleu brillant FCF (E133)
  -- ------------------------------------------------------------
  v_material_id := 'ca499b25-d195-47dd-89a9-c7ba442cdb6e'::uuid;

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
    'Sel de sodium de l''acide α-[(4-sulfophényl)(4-sulfophényl)méthylidène]-4-(N-éthyl-N-(3-sulfophényl)méthylammonio)-2,5-cyclohexadién-1-ylidène] (C₃₇H₃₄N₂Na₂O₉S₃)',
    'E133, FD&C Blue 1, CI 42090',
    'Alimentaire',
    'Poudre bleu roi à reflets métalliques, inodore',
    'Stable sur une large gamme de pH (3-10)',
    'Très soluble dans l''eau, insoluble dans les huiles',
    0.85, null,
    'Colorant triarylméthane synthétique bleu vif. Excellente stabilité à la chaleur, à la lumière et aux milieux alcalins. Le plus utilisé des colorants bleus alimentaires.',
    'Par rapport au bleu patenté V (E131), il est plus stable et plus foncé. Contrairement à l''indigotine (E132), il est moins sujet à la décoloration par les réducteurs. Très utilisé en association avec la tartrazine pour obtenir du vert.',
    'Faible',
    array[]::text[],
    'Aucun obligatoire. Éviter l''inhalation de poudre.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Agents réducteurs forts (décoloration), certains tensioactifs cationiques.',
    'Récipient étanche, au sec, à l''abri de la lumière directe.',
    5, 35, true, false, 60, 'a_valider'
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
  (v_academie_id, 'Colorant pour confiseries, glaces, boissons, produits laitiers aromatisés',
   'Dissoudre dans l''eau ou la phase aqueuse à n''importe quel stade de fabrication.',
   'plage', 0.005, 0.05, '% du produit fini', 'Ambiante à 120°C', 'Immédiat', false, 0),
  (v_academie_id, 'Colorant bleu pour savons, bains moussants, bombes de bain',
   'Ajouter à la trace ou dans la phase aqueuse.',
   'plage', 0.05, 0.5, '% du produit', '30-50°C', 'Incorporation', false, 1);

  -- ------------------------------------------------------------
  -- Caramel alimentaire (E150a — classe I)
  -- ------------------------------------------------------------
  v_material_id := '8fb0d566-7ba4-4dcf-927f-308f6e6234ac'::uuid;

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
    'Caramel, sucre chauffé sans catalyseur chimique (mélange complexe de polymères bruns, Classe I)',
    'E150a, caramel simple, caramel Classe I, caramel naturel',
    'Alimentaire',
    'Liquide sirupeux brun foncé, ou poudre brune, odeur caractéristique de caramel',
    '4-5 (solution aqueuse)',
    'Très soluble dans l''eau, partiellement soluble dans l''alcool',
    1.30, null,
    'Obtenu par simple chauffage de sucres alimentaires sans additif. Coloration brune douce, sans amertume. Pas de limite de dose journalière admissible (DJA non spécifiée).',
    'Contrairement au caramel E150d (ammoniacal-sulfite), il est produit sans catalyseur, ce qui le rend clean label et autorisé dans les produits biologiques. Plus clair que le E150d, il convient aux boissons alcoolisées, colas, pains de mie.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. Éviter le contact prolongé avec la peau (collant).',
    'Yeux : rincer abondamment. Peau : laver à l''eau. Ingestion sans danger.',
    'Oxydants forts.',
    'Bidon fermé, à température ambiante, à l''abri du gel. La poudre doit être conservée au sec.',
    5, 30, true, false, 24, 'a_valider'
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
  (v_academie_id, 'Coloration de boissons (colas, bières), pains de mie, sauces, confiseries',
   'Ajouter le caramel liquide ou dissoudre la poudre dans l''eau et incorporer directement dans la formulation.',
   'plage', 0.5, 3, '% du produit fini', 'Ambiante à 100°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Colorant caramel ammoniacal-sulfite (Classe IV — E150d)
  -- ------------------------------------------------------------
  v_material_id := 'fb3d3ed6-ed58-4fc1-889b-32d28875bded'::uuid;

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
    'Caramel, sucre chauffé avec sels d''ammonium et sulfites (mélange complexe de polymères bruns, Classe IV)',
    'E150d, caramel sulfitique, caramel Classe IV, caramel ammoniacal',
    'Alimentaire',
    'Liquide sirupeux brun très foncé à noir, ou poudre noire, odeur légèrement piquante',
    '2-3 (solution aqueuse, acide)',
    'Très soluble dans l''eau, partiellement dans l''alcool',
    1.32, null,
    'Obtenu par chauffage de sucres en présence de sels d''ammonium et de sulfites. Couleur très intense, bonne stabilité en milieu acide et en présence d''alcool. Charge négative en solution.',
    'Beaucoup plus foncé et intense que le caramel E150a. Sa charge négative le rend compatible avec les boissons acides type cola (tanins, phosphates). Peut contenir des traces de 4-MEI (réglementé).',
    'Faible',
    array[]::text[],
    'Éviter l''inhalation de vapeurs lors de la manipulation de la poudre ou du liquide chaud. Peut tacher.',
    'Yeux : rincer abondamment. Peau : laver à l''eau. Ingestion : boire de l''eau.',
    'Oxydants forts, bases fortes (précipitation).',
    'Bidon en acier inox ou PEHD, à l''abri du gel. La poudre au sec.',
    5, 30, true, false, 24, 'a_valider'
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
  (v_academie_id, 'Coloration de boissons gazeuses (colas), sauces brunes, bières foncées',
   'Diluer dans l''eau ou ajouter directement le liquide dans la formulation. Dosage précis selon la teinte désirée.',
   'plage', 0.1, 2, '% du produit fini', '20-100°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Colorant rouge ponceau 4R (E124)
  -- ------------------------------------------------------------
  v_material_id := '2b3d2c21-82c0-4544-9440-dc6393edc51e'::uuid;

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
    'Sel trisodique de l''acide 1-(4-sulfo-1-naphtylazo)-2-naphtol-6,8-disulfonique (C₂₀H₁₁N₂Na₃O₁₀S₃)',
    'E124, rouge ponceau, Ponceau 4R, CI 16255',
    'Alimentaire',
    'Poudre rouge vif, inodore',
    'Stable en milieu acide à neutre',
    'Très soluble dans l''eau',
    0.85, null,
    'Colorant azoïque rouge framboise. Bonne stabilité thermique. Mention obligatoire sur l''étiquetage en UE (peut causer des troubles de l''attention chez les enfants).',
    'Plus bleuté que le rouge allura AC (E129), moins orangé que le jaune orangé S (E110). Teinte proche du rouge carmoisine (E122) mais plus stable.',
    'Faible',
    array[]::text[],
    'Éviter l''inhalation de poudre.',
    'Yeux : rincer. Peau : laver.',
    'Agents réducteurs (décoloration), oxydants forts.',
    'Récipient étanche, au sec, à l''abri de la lumière.',
    5, 35, true, false, 60, 'a_valider'
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
  (v_academie_id, 'Coloration de confiseries, sirops, desserts lactés, charcuteries',
   'Dissoudre dans l''eau avant incorporation. Stable à la pasteurisation.',
   'plage', 0.01, 0.05, '% du produit fini', 'Jusqu''à 100°C', 'Immédiat', false, 0),
  (v_academie_id, 'Colorant pour cosmétiques (bains moussants, savons)',
   'Ajouter dans la phase aqueuse.',
   'plage', 0.05, 0.3, '% du produit', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Colorant rouge vin / anthocyanes (E163)
  -- ------------------------------------------------------------
  v_material_id := '666abfbc-4c20-4164-a33d-52c7d62d1d2c'::uuid;

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
    'Anthocyanes, extraits de raisins, baies, chou rouge etc. (mélange de glycosides d''anthocyanidines)',
    'E163, anthocyanes, colorant raisin, rouge vin',
    'Alimentaire',
    'Poudre rouge-violet à pourpre, ou liquide concentré, odeur fruitée discrète',
    'Couleur variable : rouge en milieu acide (pH<3), violet (pH 4-5), bleu puis incolore en milieu alcalin',
    'Soluble dans l''eau, l''alcool, peu soluble dans les huiles',
    0.80, null,
    'Colorants naturels extraits de fruits et légumes. Très sensibles au pH, au SO₂, à la chaleur et à la lumière. Excellente image clean label. Propriétés antioxydantes.',
    'Par rapport au rouge de betterave (E162), ils couvrent une plus large gamme de teintes selon le pH. Contrairement aux colorants azoïques, ils sont naturels mais moins stables aux traitements thermiques sévères.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire. Protéger les vêtements (taches).',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'SO₂ (décoloration), pH alcalin, chaleur prolongée, lumière.',
    'Récipient étanche, au frais, à l''abri de la lumière.',
    5, 20, true, true, 12, 'a_valider'
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
  (v_academie_id, 'Coloration de boissons, confitures, yaourts, glaces, produits de boulangerie',
   'Dissoudre dans la phase aqueuse acide. Ajuster le pH pour obtenir la teinte désirée.',
   'plage', 0.1, 1, '% du produit fini', '20-70°C (éviter la surchauffe)', 'Immédiat', false, 0),
  (v_academie_id, 'Colorant naturel pour savons et cosmétiques (phase aqueuse)',
   'Ajouter à la phase aqueuse avant saponification ou incorporation. La couleur peut évoluer avec le pH du savon.',
   'plage', 0.5, 3, '% du produit', '30-50°C', 'Incorporation', false, 1);

  -- ------------------------------------------------------------
  -- Dioxyde de titane (E171)
  -- ------------------------------------------------------------
  v_material_id := '7ae1f059-611e-4e5a-a7a3-843a4b85bf76'::uuid;

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
    'Dioxyde de titane (TiO₂)',
    'E171, CI 77891, blanc de titane, oxyde de titane',
    'Cosmétique',
    'Poudre blanche très fine, inodore',
    'Neutre (insoluble)',
    'Insoluble dans l''eau et les solvants organiques. Se disperse dans les huiles et l''eau.',
    4.20, null,
    'Pigment blanc minéral à très haut pouvoir opacifiant et couvrant. Suspendu en alimentaire dans l''UE depuis 2022 (E171 interdit comme additif alimentaire). Reste autorisé en cosmétique et dans certains pays.',
    'Par rapport au carbonate de calcium, il est beaucoup plus couvrant, plus blanc et plus lourd. Contrairement à l''oxyde de zinc, il n''a pas de propriétés UV significatives dans le visible mais il est plus blanc.',
    'Modéré',
    array['masque','lunettes','ventilation'],
    'Porter un masque anti-poussière (FFP2) pour éviter l''inhalation de poudre fine. Classé cancérogène possible (catégorie 2B) par inhalation de poudre uniquement. Sans danger dans les produits finis.',
    'Inhalation : air frais. Peau : laver. Yeux : rincer 15 min. Ingestion : boire de l''eau.',
    'Acides forts (dissolution lente), oxydants puissants.',
    'Récipient étanche, au sec, à l''abri de la lumière.',
    5, 40, true, false, 60, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319', 'H335', 'H351')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P201', 'P261', 'P280', 'P305+P351+P338', 'P308+P313')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Pigment blanc pour cosmétiques (crèmes solaires, fonds de teint, vernis à ongles)',
   'Disperser dans la phase grasse ou la poudre. Broyer pour une bonne homogénéité.',
   'plage', 2, 25, '% du produit fini', 'Ambiante à 80°C', 'Mélange', false, 0);

  -- ------------------------------------------------------------
  -- Jaune orangé S (E110)
  -- ------------------------------------------------------------
  v_material_id := 'a7875ef5-5c66-459a-9938-485f815c36e8'::uuid;

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
    'Sel disodique de l''acide 6-hydroxy-5-((4-sulfophényl)azo)-2-naphtalènesulfonique (C₁₆H₁₀N₂Na₂O₇S₂)',
    'E110, jaune soleil FCF, Sunset Yellow FCF, CI 15985',
    'Alimentaire',
    'Poudre orange vif, inodore',
    'Stable sur une large gamme de pH',
    'Très soluble dans l''eau',
    0.80, null,
    'Colorant azoïque orangé. Excellente stabilité. Mention particulière sur l''étiquetage en UE (peut causer des troubles de l''attention chez les enfants).',
    'Plus orangé que la tartrazine (E102). Par rapport au rouge ponceau 4R (E124), il est nettement plus jaune. Souvent associé à la tartrazine pour des teintes intermédiaires.',
    'Faible',
    array[]::text[],
    'Aucun obligatoire.',
    'Yeux : rincer. Peau : laver.',
    'Agents réducteurs forts.',
    'Récipient étanche, au sec.',
    5, 35, true, false, 60, 'a_valider'
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
  (v_academie_id, 'Colorant pour confiseries, snacks, boissons, glaces, desserts',
   'Dissoudre dans l''eau avant ajout.',
   'plage', 0.01, 0.1, '% du produit fini', 'Jusqu''à 120°C', 'Immédiat', false, 0),
  (v_academie_id, 'Colorant jaune-orangé pour savons et bains',
   'Dissoudre dans la phase aqueuse.',
   'plage', 0.05, 0.5, '% du produit', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Tartrazine jaune citron (E102)
  -- ------------------------------------------------------------
  v_material_id := 'c106a68d-7955-4f24-867b-ec5f7ecbbba4'::uuid;

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
    'Sel trisodique de l''acide 5-hydroxy-1-(4-sulfonatophényl)-4-[(4-sulfonatophényl)azo]-1H-pyrazole-3-carboxylique (C₁₆H₉N₄Na₃O₉S₂)',
    'E102, tartrazine, FD&C Yellow 5, CI 19140',
    'Alimentaire',
    'Poudre jaune citron vif, inodore',
    'Stable sur une large gamme de pH',
    'Très soluble dans l''eau',
    0.80, null,
    'Colorant azoïque jaune vif. Le plus utilisé des jaunes synthétiques. Mention particulière sur l''étiquetage en UE (peut causer des troubles de l''attention chez les enfants). Souvent mélangé au bleu brillant FCF pour obtenir du vert.',
    'Plus citron que le jaune orangé S (E110) et le jaune de quinoléine (E104). Plus sensible aux réducteurs que le jaune orangé S.',
    'Faible',
    array[]::text[],
    'Aucun obligatoire.',
    'Yeux : rincer. Peau : laver.',
    'Agents réducteurs (décoloration), oxydants forts.',
    'Récipient étanche, au sec.',
    5, 35, true, false, 60, 'a_valider'
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
  (v_academie_id, 'Colorant pour confiseries, boissons, glaces, moutarde, cosmétiques',
   'Dissoudre dans l''eau avant incorporation.',
   'plage', 0.005, 0.1, '% du produit fini', 'Jusqu''à 120°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Colorants alimentaires certifiés (fiche de synthèse par famille)
  -- ------------------------------------------------------------
  v_material_id := '4459b390-45ba-4793-92ff-f7796139d095'::uuid;

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
    'Vue d''ensemble de famille — colorants de synthèse certifiés pour usage alimentaire (codes E / FD&C)',
    'Colorants E, colorants FD&C, colorants alimentaires de synthèse',
    'Alimentaire',
    'Variable selon le colorant (poudre, liquide, pastilles...)',
    'Variable selon le colorant',
    'Variable selon le colorant (généralement hydrosolubles, parfois liposolubles ou sous forme de laques)',
    null, null,
    'Famille regroupant les colorants de synthèse certifiés pour un usage alimentaire, identifiés par des codes E (UE) ou FD&C (USA). Exemples typiques déjà présents dans le catalogue ou à commander au cas par cas : E102 tartrazine, E104 jaune de quinoléine, E110 jaune orangé S, E122 carmoisine, E124 rouge ponceau 4R, E129 rouge allura AC, E133 bleu brillant FCF, E142 vert S, E151 noir brillant BN, E154 brun FK, E155 brun HT. Certains sont disponibles en version laque (fixés sur alumine) pour les applications grasses.',
    'Contrairement aux colorants naturels (anthocyanes, curcumine, etc.), ces colorants offrent une stabilité et une intensité supérieures, mais leur étiquetage peut comporter des avertissements réglementaires (troubles de l''attention). Ils sont distincts des colorants cosmétiques (codes CI) par leur certification alimentaire stricte.',
    'Faible',
    array['masque','lunettes'],
    'Recommandations générales pour la manipulation de poudres colorantes : porter un masque anti-poussière et des lunettes de protection, éviter l''inhalation.',
    'En cas de contact avec les yeux, rincer abondamment. En cas d''ingestion accidentelle, boire de l''eau. Consulter la fiche spécifique du colorant effectivement utilisé.',
    'Agents réducteurs forts, oxydants puissants. Conserver à l''écart des produits incompatibles.',
    'Stocker dans un endroit sec, frais et ventilé, à l''abri de la lumière directe, dans des récipients bien fermés.',
    5, 30, true, true, 36, 'a_valider'
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
  -- Pas de phrases H/P : fiche de synthèse par famille, variable selon le colorant sélectionné.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Coloration des denrées alimentaires (confiserie, boissons, glaces, boulangerie, etc.)',
   'Consulter la fiche technique du colorant spécifique choisi pour le dosage exact.',
   'texte_libre', null, null, 'Variable selon le colorant et l''application', 'Variable selon le colorant', 'Variable', false, 0);

  -- ------------------------------------------------------------
  -- Colorants cosmétiques (fiche de synthèse par famille)
  -- ------------------------------------------------------------
  v_material_id := 'a09fb083-f0bd-4494-afc3-1b566bee0e92'::uuid;

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
    'Vue d''ensemble de famille — pigments et colorants identifiés par code Colour Index (CI) pour usage cosmétique',
    'Pigments CI, colorants CI, colorants cosmétiques certifiés',
    'Cosmétique',
    'Variable selon le colorant (poudre, liquide, laque...)',
    'Variable selon le colorant',
    'Variable selon le colorant (certains hydrosolubles, d''autres liposolubles ou sous forme de pigments dispersibles)',
    null, null,
    'Famille regroupant les colorants et pigments autorisés dans les produits cosmétiques, identifiés par leur code Colour Index (CI). Exemples déjà présents au catalogue ou à commander au cas par cas : CI 15850 (rouge lithol), CI 19140 (tartrazine), CI 42090 (bleu brillant FCF), CI 45410 (éosine), CI 47005 (jaune de quinoléine), CI 61570 (vert D&C), CI 77007 (outremer bleu), CI 77289 (oxyde de chrome vert), CI 77491/77492/77499 (oxydes de fer rouge/jaune/noir), CI 77742 (violet de manganèse), CI 77891 (dioxyde de titane). Certains sont des laques (colorants adsorbés sur substrat) pour une meilleure dispersion dans les phases grasses.',
    'Par rapport aux colorants alimentaires, ils ne sont pas systématiquement de qualité alimentaire mais répondent aux critères de pureté spécifiques aux cosmétiques (règlement européen 1223/2009). Ils sont plus nombreux que les colorants alimentaires et incluent des teintes vives non autorisées dans l''alimentaire.',
    'Faible',
    array['masque','lunettes'],
    'Recommandations générales pour la manipulation de poudres colorantes : masque anti-poussière, lunettes de protection. Certains pigments peuvent être irritants ; consulter la FDS du colorant effectivement utilisé.',
    'En cas de projection oculaire, rincer abondamment. En cas d''inhalation massive, déplacer la personne à l''air frais. Consulter un médecin si irritation persistante.',
    'Éviter les agents oxydants ou réducteurs forts. Conserver à l''écart des matières combustibles.',
    'Stocker dans un endroit frais, sec et ventilé, à l''abri de la lumière. Maintenir les récipients fermés.',
    5, 30, true, true, 36, 'a_valider'
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
  -- Pas de phrases H/P : fiche de synthèse par famille, variable selon le colorant sélectionné.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Coloration de produits cosmétiques (maquillage, soins, savons, bains, etc.)',
   'Consulter la fiche technique du colorant spécifique choisi pour le dosage exact et la compatibilité avec la formulation.',
   'texte_libre', null, null, 'Variable selon le colorant et le produit fini', 'Variable', 'Variable', false, 0);

  -- ------------------------------------------------------------
  -- Colorants industriels (fiche de synthèse par famille)
  -- ------------------------------------------------------------
  v_material_id := '11a9fc6a-f4d2-4f40-ad97-4335a8473a80'::uuid;

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
    'Vue d''ensemble de famille — colorants et pigments à usage technique/industriel',
    'Colorants techniques, colorants textiles, pigments industriels',
    'Technique',
    'Variable selon le colorant (poudre, granulés, liquide, pâte)',
    'Variable selon le colorant',
    'Variable selon le type de colorant (soluble dans l''eau, les solvants, ou insoluble pour les pigments)',
    null, null,
    'Famille regroupant les colorants destinés à des applications industrielles : textiles, peintures, encres, plastiques, construction, etc. Exemples typiques : colorants azoïques (Rouge Réactif, Jaune Acide), phtalocyanines (Bleu de phtalocyanine CI 74160, Vert de phtalocyanine CI 74260), pigments organiques (Pigment Red 170, Pigment Yellow 83), noir de carbone, pigments inorganiques (oxydes de fer, oxyde de chrome). Ces colorants ne sont pas certifiés pour un usage alimentaire ou cosmétique.',
    'Par rapport aux colorants alimentaires ou cosmétiques, ils ne sont pas soumis aux mêmes exigences de pureté. Ils sont souvent plus économiques et disponibles en une plus large gamme de nuances, mais peuvent contenir des impuretés ou des métaux lourds.',
    'Modéré',
    array['masque','lunettes','gants'],
    'Utilisation de gants, lunettes de sécurité et masque anti-poussière recommandée. Certains colorants peuvent être sensibilisants ou toxiques. Consulter impérativement la FDS du colorant effectivement utilisé avant toute manipulation.',
    'En cas de contact avec la peau, laver à l''eau et au savon. En cas d''inhalation, respirer de l''air frais. En cas d''ingestion, rincer la bouche et consulter un médecin. Suivre les instructions de la FDS spécifique.',
    'Agents oxydants ou réducteurs puissants, acides forts, bases fortes. Éviter la contamination croisée avec des produits alimentaires.',
    'Stocker dans des récipients bien fermés, dans un local sec, frais et ventilé, à l''écart des denrées alimentaires et des sources de chaleur.',
    5, 30, true, true, 36, 'a_valider'
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
  -- Pas de phrases H/P : fiche de synthèse par famille, variable selon le colorant sélectionné.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Teinture textile, coloration de peintures, encres, plastiques, construction',
   'Consulter la fiche technique du colorant spécifique choisi pour le dosage exact, la méthode d''incorporation et les conditions de mise en œuvre.',
   'texte_libre', null, null, 'Variable selon l''application (g/L, %, etc.)', 'Variable', 'Variable', false, 0);

  -- ------------------------------------------------------------
  -- Pigments (oxydes de fer, TiO2) (fiche de synthèse par famille)
  -- ------------------------------------------------------------
  v_material_id := '6072a0cf-f724-462b-b2c9-dbeb60b94466'::uuid;

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
    'Vue d''ensemble de famille — pigments minéraux opaques (oxydes de fer principalement ; TiO₂ documenté séparément sous E171)',
    'Oxydes de fer, pigments minéraux, CI 77491 (rouge), CI 77492 (jaune), CI 77499 (noir), CI 77891 (blanc, TiO2)',
    'Cosmétique',
    'Poudres très fines de couleur respective (rouge, jaune, noir, brun pour les mélanges)',
    'Insolubles, inertes',
    'Insolubles dans l''eau et les solvants, se dispersent',
    null, null,
    'Famille de pigments minéraux opaques. Le dioxyde de titane (TiO₂, E171, CI 77891) est déjà documenté séparément en tant que colorant blanc dans ce catalogue. Les oxydes de fer (CI 77491 rouge, CI 77492 jaune, CI 77499 noir) sont obtenus par synthèse ou à partir de minéraux naturels. Mélangés, ils produisent des bruns et ocres. Utilisés en cosmétique (maquillage, savons), peinture, construction. Très stables à la chaleur, à la lumière et aux agents chimiques.',
    'Contrairement aux colorants organiques, les oxydes de fer sont minéraux, très opaques et couvrants, et ne migrent pas. Ils sont autorisés en cosmétique (y compris sur les lèvres) mais pas en alimentaire (sauf exception). Le TiO2, seul membre de cette famille autorisé un temps comme additif alimentaire (E171), est aujourd''hui suspendu à ce titre en UE — voir la fiche "Dioxyde de titane (E171)" séparée pour ses spécificités et avertissements propres.',
    'Modéré',
    array['masque','lunettes'],
    'Porter un masque anti-poussière (FFP2) pour manipuler ces poudres très fines. Lunettes de protection recommandées.',
    'En cas d''inhalation, déplacer la personne à l''air frais. En cas de contact avec les yeux, rincer abondamment. Consulter un médecin si irritation persistante.',
    'Acides forts (dissolution lente des oxydes de fer). Éviter l''exposition à des températures extrêmement élevées avec matières oxydantes.',
    'Récipients étanches, au sec. Tenir à l''écart des acides forts. Stocker à l''abri de la lumière pour conserver la teinte d''origine.',
    5, 40, true, true, 60, 'a_valider'
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
  -- Pas de phrases H/P : fiche de synthèse par famille, variable selon le pigment sélectionné.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Pigments pour cosmétiques (fards, blush, fonds de teint, rouges à lèvres, savons colorés) et peintures/enduits',
   'Consulter la fiche technique du pigment spécifique choisi pour le dosage exact. Généralement dispersés dans la phase grasse ou broyés avec un liant.',
   'texte_libre', null, null, 'Variable selon l''intensité souhaitée (quelques % à plus de 30% du produit fini)', 'Ambiante à 200°C (stables)', 'Incorporation', false, 0);
end $$;
