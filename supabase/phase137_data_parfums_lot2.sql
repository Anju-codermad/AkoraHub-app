-- ============================================================
-- AkoraHub - Patch Phase 137 : fiches Académie pour le lot 2 (8
-- produits) des nouveaux produits "Parfums & Additifs" — contenu
-- DeepSeek, vérifié par l'utilisatrice.
-- Azodicarbonamide (E927a) documenté avec avertissements renforcés
-- (interdit comme additif alimentaire en UE depuis 2005, usage
-- informatif/hors-UE uniquement, sensibilisant respiratoire connu).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Azodicarbonamide (E927a)
  -- ------------------------------------------------------------
  v_material_id := 'dc5335c8-4f99-45c5-8da0-e69647876323'::uuid;

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
    'Azodicarbonamide (C₂H₄N₄O₂)',
    'E927a, ADA, agent de blanchiment de farine (usage hors UE), améliorant de panification (plastifiant de pâte)',
    'Technique (usage alimentaire interdit en UE, autorisé ailleurs)',
    'Poudre cristalline jaune-orangé, inodore',
    'Non applicable (se décompose à la chaleur)',
    'Insoluble dans l''eau et la plupart des solvants',
    1.65, null,
    'Additif alimentaire autrefois utilisé comme agent de blanchiment de farine et améliorant de panification. Il se décompose à la cuisson en semicarbazide (SEM), un composé suspecté cancérogène et génotoxique. Son usage dans les denrées alimentaires est INTERDIT dans l''Union européenne depuis 2005 (directive 2004/46/CE). Il reste autorisé dans certains pays tiers (États-Unis, Canada) avec des limites strictes. Il est également utilisé comme agent gonflant dans la production de mousses plastiques. En milieu professionnel, c''est un sensibilisant respiratoire reconnu, provoquant de l''asthme chez les travailleurs exposés (meunerie, boulangerie industrielle). Ajout au catalogue à but informatif uniquement pour les clients hors UE ; ne pas utiliser dans l''UE.',
    'Contrairement à la L-cystéine (E920, agent de traitement de la farine autorisé en UE), l''azodicarbonamide est interdit en UE. Par rapport au carbonate acide d''ammonium (E503, poudre à lever), il ne dégage pas de gaz mais modifie le gluten et blanchit.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Porter impérativement un masque anti-poussière FFP3 et des gants en nitrile. Manipuler sous hotte aspirante ou avec ventilation localisée. Éviter toute inhalation de poudre. Produit interdit en usage alimentaire dans l''UE.',
    'Inhalation : transporter la victime à l''air frais, consulter immédiatement un médecin (risque d''asthme). Peau : laver à l''eau. Yeux : rincer 15 min. Ingestion : rincer la bouche, boire de l''eau, appeler un centre antipoison.',
    'Acides forts, bases fortes, agents réducteurs, chaleur (décomposition).',
    'Récipient étanche, dans un local frais, sec et bien ventilé, à l''abri des sources de chaleur.',
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
  select v_academie_id, id from public.phrases_h where code in ('H228', 'H315', 'H319', 'H334', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P261', 'P280', 'P284', 'P304+P340', 'P305+P351+P338', 'P342+P311')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Améliorant de farine (usage hors UE uniquement)',
   'Dosage typique 10-45 ppm par rapport à la farine. Ne pas utiliser dans l''UE.',
   'plage', 10, 45, 'ppm (mg/kg de farine)', 'Ambiante, réaction activée à la cuisson > 180 °C', 'Pendant la cuisson', false, 0);

  -- ------------------------------------------------------------
  -- Benjoin (résine)
  -- ------------------------------------------------------------
  v_material_id := '446e2dec-6099-4e7c-a918-5a869fa78962'::uuid;

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
    'Résine naturelle exsudée de Styrax tonkinensis (benjoin du Siam) ou Styrax benzoin (benjoin de Sumatra), contenant de l''acide benzoïque, des esters de coniféryle, de la vanilline',
    'Benzoin, résine de benjoin, gomme benjoin, Styrax benzoin resin',
    'Cosmétique, Alimentaire (usage limité comme arôme)',
    'Masse solide cassante, brun-rouge à brun ambré, odeur chaude, balsamique, vanillée. Point de ramollissement 70-85 °C.',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau, partiellement soluble dans l''alcool, soluble dans les solvants organiques (acétone, toluène)',
    1.15, 150.0,
    'Résine naturelle très utilisée en parfumerie comme fixateur et note de fond chaude, amandée, vanillée. En cosmétique, elle apporte un parfum doux et des propriétés antiseptiques douces. Utilisée traditionnellement en encens et dans les baumes. La forme "teinture de benjoin" (dissoute dans l''alcool) est la plus pratique.',
    'Par rapport à la myrrhe ou à l''oliban (encens), le benjoin a une odeur plus douce et vanillée. Contrairement à l''ambre gris synthétique, il est d''origine végétale, moins puissant, mais apporte un caractère chaleureux naturel. Il est le fixateur résineux de référence.',
    'Faible',
    array['gants','masque'],
    'Porter des gants et un masque anti-poussière si manipulation de la poudre. La résine solide peut être coupante.',
    'Peau : laver au savon. Yeux : rincer 15 min. Ingestion : rincer la bouche, boire de l''eau, consulter un médecin si symptômes.',
    'Oxydants forts.',
    'Récipient étanche, au frais, à l''abri de la lumière. Conserver dans un endroit sec.',
    5, 25, false, true, 48, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H317', 'H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P272', 'P280', 'P302+P352', 'P305+P351+P338', 'P333+P313')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Fixateur de parfum en cosmétique, savonnerie et parfumerie',
   'Dissoudre la résine broyée dans l''alcool à chaud (50 °C) pendant plusieurs heures, filtrer. Utiliser la teinture à 1-5 % dans la composition parfumée.',
   'plage', 1, 5, '% du concentré parfumé', 'Dissolution à 50 °C', 'Plusieurs heures de macération', false, 0),
  (v_academie_id, 'Arôme alimentaire (note vanillée/amandée) pour pâtisserie, confiserie',
   'Utiliser la teinture de benjoin diluée. Ajouter 0,01-0,1 % du produit fini. Respecter les réglementations locales (usage limité en alimentaire).',
   'plage', 0.01, 0.1, '% du produit fini', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Benzaldéhyde (arôme amande amère)
  -- ------------------------------------------------------------
  v_material_id := '933f7ea9-e100-4c63-a055-1e5e6affc626'::uuid;

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
    'Benzaldéhyde (C₆H₅CHO)',
    'Benzaldehyde, aldéhyde benzoïque, essence d''amande amère, arôme amande',
    'Alimentaire, Cosmétique',
    'Liquide incolore à jaune pâle, odeur intense d''amande amère, amande grillée',
    'Non applicable (faible solubilité dans l''eau)',
    'Faible dans l''eau (0,6 g/100 mL), miscible à l''alcool, aux huiles, aux solvants organiques',
    1.04, 62.0,
    'Arôme principal de l''amande amère, également présent dans les noyaux d''abricot et de pêche. Le benzaldéhyde de synthèse est purifié et ne contient pas d''acide cyanhydrique (HCN), contrairement au benzaldéhyde issu de l''hydrolyse de l''amygdaline (glycoside cyanogène toxique présent dans les noyaux d''amande amère brute). Le benzaldéhyde alimentaire est totalement sûr. Il s''oxyde lentement à l''air en acide benzoïque.',
    'Par rapport à l''extrait naturel d''amande amère, il est exempt de cyanure. Comparé à l''anéthol (anis), il a une note amande et non anisée. C''est l''un des arômes les plus utilisés en pâtisserie (frangipane, massepain).',
    'Modéré',
    array['gants','lunettes','ventilation'],
    'Gants en nitrile, lunettes de sécurité. Travailler dans un local ventilé (odeur forte). Éviter l''inhalation prolongée.',
    'Yeux : rincer 15 min. Peau : laver au savon. Ingestion : rincer la bouche, boire de l''eau, appeler un médecin si symptômes. Inhalation : air frais.',
    'Oxydants forts (formation d''acide benzoïque), bases fortes.',
    'Bidon en verre ou métal, bien fermé, dans un local frais et ventilé, à l''abri de la lumière et de l''air. Protéger de l''oxydation.',
    5, 25, false, true, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H315', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P270', 'P280', 'P301+P312', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Arôme amande amère pour pâtisserie, confiserie, massepain, frangipane',
   'Diluer à 1-10 % dans de l''alcool ou du propylène glycol. Ajouter 10-100 ppm dans le produit fini. Ne pas surchauffer.',
   'plage', 10, 100, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 60 °C', 'Immédiat', false, 0),
  (v_academie_id, 'Parfumerie et savonnerie (note amande, cerise, cuir)',
   'Utiliser pur ou en solution dans la composition parfumée à 0,1-2 %.',
   'plage', 0.1, 2.0, '% du concentré parfumé', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Carbonate acide d'ammonium / Bicarbonate d'ammonium (E503)
  -- ------------------------------------------------------------
  v_material_id := '1052762d-e171-4748-a48a-ecacc2e0c57b'::uuid;

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
    'Hydrogénocarbonate d''ammonium (NH₄HCO₃) — mélange avec carbonate d''ammonium (E503i/E503ii)',
    'E503, bicarbonate d''ammonium, poudre à lever ammoniaque, sel volatil, ammonium bicarbonate',
    'Alimentaire',
    'Poudre cristalline blanche ou cristaux incolores, odeur ammoniacale caractéristique',
    '8-9 (solution aqueuse légèrement alcaline)',
    'Très soluble dans l''eau (22 g/100 mL à 20 °C), insoluble dans l''alcool',
    1.58, null,
    'Poudre à lever traditionnelle se décomposant entièrement à la cuisson en gaz (ammoniac, dioxyde de carbone, vapeur d''eau), sans laisser de résidu salin. Utilisée pour les biscuits secs, crackers, gaufrettes, spéculoos. Ne convient pas pour les gâteaux épais (l''ammoniac ne s''échappe pas complètement). Ne doit pas être confondue avec le bicarbonate de sodium (E500).',
    'Par rapport au bicarbonate de sodium (E500), elle ne contient pas de sodium et ne laisse aucun goût résiduel si la cuisson est suffisante. Contrairement à la levure chimique (mélange de bicarbonate et d''acide), elle ne nécessite pas d''agent acide pour réagir, la chaleur suffit.',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes recommandés. Dégage de l''ammoniac au chauffage : utiliser dans un espace ventilé. Irritant.',
    'Yeux : rincer 15 min. Peau : laver. Ingestion : rincer la bouche, boire de l''eau. Inhalation des vapeurs : air frais.',
    'Acides (réaction vive avec dégagement de CO₂), bases fortes.',
    'Récipient étanche, au frais et au sec. Protéger de la chaleur et de l''humidité. Conserver à l''écart des acides.',
    5, 25, true, false, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Poudre à lever pour biscuits secs, crackers, gaufrettes, spéculoos',
   'Ajouter 1-3 % du poids de farine directement dans la pâte. La chaleur du four (> 60 °C) la décompose et fait lever le produit. Utiliser exclusivement pour des produits fins et bien cuits pour éviter toute odeur résiduelle.',
   'plage', 1.0, 3.0, '% du poids de farine', 'Cuisson > 180 °C', 'Pendant la cuisson', false, 0);

  -- ------------------------------------------------------------
  -- Chlorure de magnésium (E511)
  -- ------------------------------------------------------------
  v_material_id := '27100823-d598-468b-87b2-31964517bac4'::uuid;

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
    'Chlorure de magnésium hexahydraté (MgCl₂·6H₂O)',
    'E511, magnésium chloride, nigari (sel de magnésium pour tofu)',
    'Alimentaire, Technique',
    'Paillettes ou cristaux blancs à translucides, très hygroscopiques, inodore, saveur amère-salée',
    '6-7 (solution aqueuse neutre)',
    'Très soluble dans l''eau (54 g/100 mL à 20 °C)',
    1.57, null,
    'Source de magnésium, utilisé comme coagulant pour la fabrication du tofu (nigari), affermissant, régulateur d''acidité. Abaisse le point de congélation de l''eau (saumure). En cosmétique, il est utilisé dans les sels de bain relaxants. Très hygroscopique, il capte l''humidité ambiante.',
    'Par rapport au chlorure de sodium (sel de table), il apporte du magnésium et non du sodium, avec une saveur amère. Contrairement au chlorure de calcium (E509), il ne réagit pas avec les alginates. Il est le coagulant traditionnel du tofu.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter le contact prolongé avec la peau (effet déshydratant).',
    'Yeux : rincer abondamment. Peau : laver. Ingestion : boire de l''eau (effet laxatif à haute dose).',
    'Acides forts, bases fortes, sulfates (précipitation de sulfate de magnésium).',
    'Récipient étanche, au sec, à l''abri de l''humidité (très hygroscopique).',
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

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Coagulant pour tofu (fromage de soja)',
   'Dissoudre 2-3 % de chlorure de magnésium dans un peu d''eau. Ajouter au lait de soja chaud (70-75 °C), remuer doucement et laisser coaguler.',
   'valeur_unique', 2.5, 2.5, '% du poids de lait de soja', '70-75 °C', '10-15 min de coagulation', false, 0),
  (v_academie_id, 'Sels de bain relaxants et reminéralisants',
   'Dissoudre 100-500 g dans un bain chaud. Apporte du magnésium, favorise la relaxation musculaire.',
   'plage', 100, 500, 'g par bain', '35-38 °C', '15-20 min', false, 1);

  -- ------------------------------------------------------------
  -- Chlorure de potassium (E508)
  -- ------------------------------------------------------------
  v_material_id := '031424d5-f928-42d6-a7b3-352fde412bba'::uuid;

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
    'Chlorure de potassium (KCl)',
    'E508, potassium chloride, sel de potassium, substitut du sel',
    'Alimentaire, Technique',
    'Poudre cristalline blanche ou cristaux incolores, inodore, saveur salée légèrement amère',
    'Neutre (7)',
    'Très soluble dans l''eau (34 g/100 mL à 20 °C), insoluble dans l''alcool',
    1.98, null,
    'Substitut partiel du sel de table (NaCl) pour les régimes hyposodés. Apporte du potassium plutôt que du sodium. Utilisé à 30-50 % en mélange avec le NaCl. En technique, il sert d''électrolyte pour solutions de remplissage et engrais.',
    'Par rapport au chlorure de sodium, il a une saveur moins pure et légèrement métallique/amère, et il ne provoque pas d''hypertension. Comparé au chlorure de magnésium, il est moins amer et a un goût plus salé.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter l''inhalation de poussières. Une ingestion massive peut provoquer une hyperkaliémie dangereuse chez les personnes insuffisantes rénales.',
    'Yeux : rincer. Peau : laver. Ingestion excessive : boire de l''eau, consulter un médecin si antécédents rénaux.',
    'Acides forts, oxydants forts.',
    'Récipient étanche, au sec, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Substitut du sel de table (régime pauvre en sodium)',
   'Remplacer 30 à 50 % du sel de cuisine par du chlorure de potassium. Utiliser en mélange pour masquer l''amertume.',
   'plage', 30, 50, '% du mélange salé (KCl/NaCl)', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Citral (arôme citron)
  -- ------------------------------------------------------------
  v_material_id := 'c52c3ba7-6adb-439e-8859-a13b4a8e50e0'::uuid;

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
    'Mélange de deux isomères : géranial (trans) et néral (cis), formule C₁₀H₁₆O',
    'Citral, arôme citron, essence de citron naturelle',
    'Alimentaire, Cosmétique',
    'Liquide jaune pâle, odeur puissante et fraîche de citron, de zeste',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau, soluble dans l''alcool, les huiles, les glycols',
    0.89, 100.0,
    'Principal composant odorant de l''huile essentielle de citron, de citronnelle et de verveine. Arôme citron intense, utilisé en confiserie, boissons, pâtisserie. En cosmétique, utilisé pour les parfums frais et hespéridés. Sensible à l''oxydation et à la lumière.',
    'Par rapport au limonène D, il est moins abondant dans l''huile de citron mais plus représentatif de l''odeur du zeste. Contrairement au linalol (fleurie), il est exclusivement citronné. Il est l''arôme citron de référence pour les bonbons et sodas.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité. Éviter le contact cutané prolongé (sensibilisant possible).',
    'Peau : laver au savon. Yeux : rincer 15 min. Ingestion : rincer la bouche, boire de l''eau, consulter un médecin si symptômes.',
    'Oxydants forts, acides forts (isomérisation), chaleur prolongée.',
    'Bidon en verre ambré ou métal, bien fermé, au frais, à l''abri de la lumière et de l''air.',
    5, 25, false, true, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H317', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P272', 'P280', 'P302+P352', 'P305+P351+P338', 'P333+P313')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Arôme citron pour confiseries, boissons gazeuses, sirops, pâtisseries',
   'Diluer à 1-5 % dans de l''alcool ou du propylène glycol. Ajouter 10-100 ppm dans le produit fini. Incorporer en fin de cuisson si possible.',
   'plage', 10, 100, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 50 °C', 'Immédiat', false, 0),
  (v_academie_id, 'Parfumerie et savonnerie (note hespéridée fraîche)',
   'Utiliser pur ou en solution dans la composition parfumée à 0,5-3 %. Ajouter en phase finale pour éviter l''oxydation.',
   'plage', 0.5, 3.0, '% du concentré parfumé', 'Ambiante', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Civettone (musc synthétique macrocyclique)
  -- ------------------------------------------------------------
  v_material_id := '49679b63-131e-4ab9-a685-68466b099e96'::uuid;

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
    'Cycloheptadéc-9-én-1-one (C₁₇H₃₀O)',
    'Civettone, musc civette synthétique, macrocyclic musk',
    'Cosmétique (parfumerie fine)',
    'Cristaux blancs à légèrement jaunâtres, odeur musquée, chaude, animale, très puissante et persistante',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau, soluble dans l''alcool, les huiles et la plupart des solvants organiques',
    0.92, 170.0,
    'Substitut synthétique de la civettone naturelle extraite des glandes de la civette. Macrocycle à 17 chaînons, il possède l''odeur musquée la plus proche des muscs naturels. Utilisé en parfumerie de luxe comme fixateur et note de fond animale. Très puissant, détectable à l''état de traces. Biodégradable et non bioaccumulable contrairement à certains muscs polycycliques.',
    'Par rapport à l''ambroxide (ambre), la civettone a une odeur musquée animale, chaude, cuirée. Contrairement aux muscs polycycliques (galaxolide), elle est macrocyclique, plus sûre pour l''environnement, mais plus coûteuse. C''est le standard du musc animal synthétique.',
    'Faible',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité. Éviter l''inhalation de poudre. Manipuler avec précaution (très puissant, risque de contamination olfactive).',
    'Yeux : rincer 15 min. Peau : laver au savon. Ingestion : boire de l''eau.',
    'Oxydants forts.',
    'Récipient étanche, au frais, à l''abri de la lumière. Tenir à l''écart des matières odorantes pour éviter les contaminations croisées.',
    5, 25, false, true, 60, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Fixateur musqué en parfumerie fine, savons haut de gamme',
   'Diluer à 1-10 % dans de l''alcool. Utiliser 0,1-2 % dans le concentré parfumé. Souvent utilisée en trace (0,01-0,1 %) pour fixer et arrondir.',
   'plage', 0.01, 2.0, '% du concentré parfumé', 'Ambiante', 'Immédiat', false, 0);
end $$;
