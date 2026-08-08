-- ============================================================
-- AkoraHub - Patch Phase 127 : fiches Académie pour le lot 3 (8
-- antioxydants + 1 conservateur alimentaire restant) des nouveaux
-- produits "Conservateurs & Antioxydants" — contenu DeepSeek,
-- vérifié par l'utilisatrice.
--
-- Lot 3/4 : Hexaméthylènetétramine (E239), Tocophérols (vitamine E
-- naturelle), Extrait de romarin (acide rosmarinique), Palmitate
-- d'ascorbyle (E304), BHA (E320), BHT (E321), Gallate de propyle
-- (E310), Gallate d'octyle (E311).
--
-- Hexaméthylènetétramine (E239) et BHA/BHT inclus avec
-- avertissements renforcés sur décision de l'utilisatrice suivant
-- la recommandation (voir phase124) : libération de formaldéhyde
-- (CIRC groupe 1) pour l'hexamine, classification CIRC 2B pour le
-- BHA.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Hexaméthylènetétramine (E239)
  -- ------------------------------------------------------------
  v_material_id := 'f691dd45-66eb-4997-90cf-6c1398e01022'::uuid;

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
    '1,3,5,7-tétraazatricyclo[3.3.1.1³,⁷]décane (C₆H₁₂N₄)',
    'Hexamine, méthénamine, E239, conservateur de fromage',
    'Alimentaire (usage très restreint), Technique',
    'Poudre cristalline blanche, inodore ou légère odeur d''amine',
    '8-9 (solution aqueuse)',
    'Très soluble dans l''eau (85 g/100 mL à 20°C), soluble dans l''alcool',
    1.33, 250.0,
    'Conservateur qui agit par libération lente de formaldéhyde (classé cancérogène CIRC groupe 1) en milieu acide. Utilisée uniquement en UE pour la conservation de la croûte du fromage Provolone (E239), à une dose résiduelle maximale de 25 mg/kg exprimée en formaldéhyde. La substance est classée comme sensibilisante et peut dégager du formaldéhyde lors de la manipulation à chaud.',
    'Contrairement au lysozyme ou à la natamycine, l''hexamine ne cible pas spécifiquement les bactéries ou moisissures mais stérilise par dégagement de formol. Son usage est extrêmement restreint par rapport aux autres conservateurs alimentaires en raison de la toxicité du formaldéhyde.',
    'Modéré',
    array['gants','lunettes','masque','ventilation'],
    'Porter des gants en nitrile, des lunettes de sécurité et un masque anti-poussière (type FFP2). Utiliser sous hotte ou avec une ventilation forcée en cas de chauffage. Éviter l''inhalation de poussières et le contact cutané. Ne pas fumer.',
    'Inhalation : air frais, consulter un médecin en cas de gêne respiratoire. Peau : laver à l''eau et au savon, retirer les vêtements contaminés. Yeux : rincer 15 min, consulter un ophtalmologue. Ingestion : rincer la bouche, ne pas faire vomir, appeler immédiatement un centre antipoison ou un médecin.',
    'Acides (décomposition rapide en formaldéhyde), oxydants forts, sels métalliques.',
    'Récipient étanche, dans un local frais, sec et bien ventilé, à l''écart des acides et des sources de chaleur.',
    5, 30, true, false, 48, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H228', 'H315', 'H317', 'H319', 'H334', 'H350')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P201', 'P210', 'P261', 'P280', 'P304+P340', 'P308+P313', 'P342+P311')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Conservateur de croûte de fromage Provolone (usage exclusif UE)',
   'La solution aqueuse d''hexamine est appliquée en surface de la meule (badigeonnage ou immersion) avant affinage. Le dosage doit respecter la limite résiduelle de 25 mg/kg de formaldéhyde. Réservé à un usage professionnel strict.',
   'texte_libre', null, null, 'Selon la réglementation (max 25 mg/kg résiduels)', 'Ambiante à froide (10-15°C)', 'Plusieurs semaines d''affinage', false, 0);

  -- ------------------------------------------------------------
  -- Tocophérols (vitamine E naturelle)
  -- ------------------------------------------------------------
  v_material_id := '23490a63-1efa-416b-95b8-5f1a47efd57a'::uuid;

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
    'Mélange de tocophérols (α, β, γ, δ) extraits d''huiles végétales (E306)',
    'Mixed Tocopherols, E306, vitamine E naturelle, antioxydant naturel',
    'Alimentaire, Cosmétique',
    'Liquide huileux jaune-brun à brun clair, odeur végétale douce',
    'Non applicable (liposoluble)',
    'Insoluble dans l''eau, soluble dans les huiles, les graisses et les solvants organiques',
    0.93, 240.0,
    'Antioxydant liposoluble naturel qui agit en piégeant les radicaux libres (donneur d''hydrogène phénolique). Protège les huiles, beurres et corps gras contre le rancissement oxydatif. Le γ-tocophérol est le plus antioxydant, l''α-tocophérol a la plus forte activité vitaminique. Limite d''usage : aucune restriction alimentaire (E306) ; en cosmétique, ajouté jusqu''à 0,5 %.',
    'Par rapport au BHA/BHT, il est 100 % naturel, sans controverse toxicologique, mais moins puissant et plus coûteux. Contrairement à l''extrait de romarin, il est liposoluble et ne colore pas. Il peut également servir d''additif vitaminique (vitamine E).',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter le contact prolongé avec la peau en usage pur (peut être légèrement irritant pour les muqueuses).',
    'Yeux : rincer. Peau : laver au savon. Ingestion sans danger aux doses usuelles.',
    'Oxydants forts, métaux pro-oxydants (fer, cuivre), lumière UV (dégradation).',
    'Bidon ou flacon hermétique, à l''abri de la lumière, de la chaleur et de l''air. Conserver au frais.',
    10, 25, false, true, 24, 'a_valider'
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
  (v_academie_id, 'Antioxydant pour huiles végétales, beurres cosmétiques et savons',
   'Incorporer 0,1 à 0,5 % dans la phase grasse avant chauffage ou à froid. Protège les huiles fragiles (chanvre, onagre, bourrache) du rancissement.',
   'plage', 0.1, 0.5, '% du poids de la phase grasse', 'Ambiante à 70°C', 'Action antioxydante immédiate et durable', false, 0);

  -- ------------------------------------------------------------
  -- Extrait de romarin (acide rosmarinique)
  -- ------------------------------------------------------------
  v_material_id := 'e84acf68-091d-437d-921a-b09d47f80a42'::uuid;

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
    'Extrait de Rosmarinus officinalis standardisé en acide rosmarinique et diterpènes phénoliques',
    'Rosmarinus Officinalis Leaf Extract, E392, antioxydant naturel, extrait de romarin',
    'Alimentaire, Cosmétique',
    'Poudre beige à brun clair, ou liquide huileux vert-brun, odeur herbacée caractéristique',
    'Variable selon la forme (4-6 pour une poudre en suspension)',
    'La poudre est partiellement soluble dans l''eau et l''alcool ; le liquide est miscible aux huiles',
    0.80, null,
    'Antioxydant naturel extrait des feuilles de romarin. Les principes actifs (acide rosmarinique, carnosol, acide carnosique) piègent les radicaux libres et chélatent les métaux pro-oxydants. Efficace à haute température (friture, cuisson). Limite UE : E392 autorisé dans de nombreux aliments jusqu''à 300 mg/kg. En cosmétique, utilisable sans restriction de dosage.',
    'Par rapport aux tocophérols, il est plus efficace à haute température et dans les corps gras solides. Contrairement au BHA/BHT, il est naturel, labelisable bio, et ne présente pas de suspicion toxicologique. Il peut parfumer légèrement le produit.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter l''inhalation de poudre.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts, bases fortes.',
    'Récipient étanche, au frais, à l''abri de la lumière et de l''humidité.',
    5, 25, true, true, 18, 'a_valider'
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
  (v_academie_id, 'Antioxydant pour huiles de friture, snacks, chips, biscuits',
   'Ajouter 0,02 à 0,05 % du poids de l''huile de friture. Résiste aux hautes températures (jusqu''à 180°C).',
   'plage', 0.02, 0.05, '% du poids de l''huile', 'Jusqu''à 180°C', 'Pendant la friture', false, 0),
  (v_academie_id, 'Antioxydant naturel pour cosmétiques (crèmes, baumes, savons)',
   'Incorporer 0,1 à 0,5 % dans la phase grasse. Apporte une légère note herbacée et protège du rancissement.',
   'plage', 0.1, 0.5, '% du poids de la phase grasse', 'Ambiante à 70°C', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Palmitate d'ascorbyle (E304)
  -- ------------------------------------------------------------
  v_material_id := '7f8b6459-d6a1-4158-88d6-f102549cea42'::uuid;

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
    'Palmitate de L-ascorbyle (C₂₂H₃₈O₇)',
    'Ascorbyl Palmitate, E304, vitamine C liposoluble, antioxydant',
    'Alimentaire, Cosmétique',
    'Poudre blanche à jaune pâle, odeur caractéristique d''agrumes',
    '5-6 (suspension dans l''eau)',
    'Insoluble dans l''eau (0,02 %), soluble dans les huiles chaudes, l''alcool et les glycols',
    1.15, null,
    'Ester liposoluble de la vitamine C. Antioxydant qui piège l''oxygène et protège les corps gras du rancissement. Libère de l''acide ascorbique et de l''acide palmitique après hydrolyse. Synergique avec les tocophérols (vitamine E). Limite UE : 200-500 mg/kg selon l''aliment. En cosmétique, usage jusqu''à 1 % comme antioxydant.',
    'Par rapport à l''acide ascorbique (E300), il est liposoluble et protège les phases huileuses, alors que l''acide ascorbique est hydrosoluble. Contrairement au BHA/BHT, il est d''origine naturelle (huile de palme + acide ascorbique) et non controversé.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts, métaux lourds (fer, cuivre), bases fortes.',
    'Récipient étanche, au frais, à l''abri de la lumière. Éviter l''humidité.',
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
  (v_academie_id, 'Antioxydant pour huiles, margarines, biscuits, snacks',
   'Dissoudre 0,02-0,05 % dans la matière grasse chaude (50-60°C). Souvent utilisé en synergie avec les tocophérols (E306).',
   'plage', 0.02, 0.05, '% du poids de la matière grasse', '50-60°C pour dissolution', 'Immédiat', false, 0),
  (v_academie_id, 'Antioxydant pour cosmétiques (crèmes, baumes, rouges à lèvres)',
   'Incorporer 0,5-1,0 % dans la phase grasse chaude (60-70°C). Protège les huiles fragiles et améliore la stabilité.',
   'valeur_unique', 0.5, 1.0, '% du produit fini', '60-70°C', 'Pendant le mélange', false, 1);

  -- ------------------------------------------------------------
  -- BHA (Butylhydroxyanisole, E320)
  -- ------------------------------------------------------------
  v_material_id := 'a68b6d59-1d23-4970-8158-93082d4883d0'::uuid;

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
    'Mélange de 2-tert-butyl-4-hydroxyanisole et 3-tert-butyl-4-hydroxyanisole (C₁₁H₁₆O₂)',
    'Butylated Hydroxyanisole, E320, BHA, antioxydant de synthèse',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche à blanc cassé, ou paillettes, odeur phénolique faible',
    'Non applicable (liposoluble)',
    'Insoluble dans l''eau, soluble dans les huiles, les graisses, l''alcool et le propylène glycol',
    1.05, 130.0,
    'Antioxydant synthétique puissant qui protège les corps gras contre le rancissement oxydatif. Agit comme donneur d''hydrogène phénolique. Classé cancérogène possible pour l''homme (CIRC groupe 2B). Limite UE stricte : 200 mg/kg dans les graisses et huiles, 40 mg/kg dans les snacks. Usage décroissant au profit des antioxydants naturels.',
    'Par rapport au BHT (E321), il est plus stable à haute température mais plus controversé. Contrairement aux tocophérols, il est synthétique, sans valeur vitaminique, et soumis à des restrictions réglementaires et à une surveillance toxicologique. Il est souvent remplacé par l''extrait de romarin.',
    'Modéré',
    array['gants','lunettes','masque'],
    'Porter des gants en nitrile, des lunettes de sécurité et un masque anti-poussière. Éviter l''inhalation et le contact prolongé avec la peau. Cancérogène possible (CIRC groupe 2B).',
    'Inhalation : air frais. Peau : laver au savon. Yeux : rincer 15 min. Ingestion : rincer la bouche, boire de l''eau, appeler un médecin.',
    'Oxydants forts, bases fortes (décomposition), métaux lourds.',
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H315', 'H319', 'H335', 'H351')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P201', 'P261', 'P264', 'P280', 'P301+P312', 'P305+P351+P338', 'P308+P313')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Antioxydant pour huiles et graisses industrielles (friture, snacks)',
   'Dissoudre 0,01-0,02 % dans la matière grasse avant chauffage. Respecter les limites légales UE. Souvent synergisé avec le BHT ou l''acide citrique.',
   'plage', 0.01, 0.02, '% du poids de la matière grasse', 'Ambiante à 150°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- BHT (Butylhydroxytoluène, E321)
  -- ------------------------------------------------------------
  v_material_id := 'd0db8400-ce50-4cf6-9f63-3f2458d04616'::uuid;

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
    '2,6-di-tert-butyl-4-méthylphénol (C₁₅H₂₄O)',
    'Butylated Hydroxytoluene, E321, BHT, antioxydant de synthèse',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche ou paillettes, odeur phénolique faible',
    'Non applicable (liposoluble)',
    'Insoluble dans l''eau, soluble dans les huiles, l''alcool, l''acétone et le propylène glycol',
    1.05, 127.0,
    'Antioxydant synthétique donneur d''hydrogène phénolique. Moins controversé que le BHA, mais classé comme perturbateur endocrinien suspecté. Limite UE : 100 mg/kg dans les graisses, 25 mg/kg dans les snacks. Efficace en synergie avec le BHA. Encore très utilisé en raison de son faible coût et de sa stabilité.',
    'Par rapport au BHA (E320), il est moins stable à haute température mais présente un profil toxicologique légèrement moins préoccupant (pas classé CIRC 2B). Il est toutefois de plus en plus remplacé par les antioxydants naturels pour des raisons d''image.',
    'Modéré',
    array['gants','lunettes','masque'],
    'Gants en nitrile, lunettes de sécurité, masque anti-poussière. Éviter l''inhalation et le contact prolongé.',
    'Inhalation : air frais. Peau : laver. Yeux : rincer 15 min. Ingestion : rincer la bouche, boire de l''eau, appeler un médecin.',
    'Oxydants forts, bases fortes, métaux lourds.',
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
  select v_academie_id, id from public.phrases_h where code in ('H302', 'H315', 'H319', 'H335', 'H410')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P261', 'P264', 'P273', 'P280', 'P301+P312', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Antioxydant pour huiles, graisses, snacks, cosmétiques (rouges à lèvres)',
   'Dissoudre 0,01-0,02 % dans la phase grasse. Souvent utilisé en combinaison avec le BHA (ratio 1:1) pour un effet synergique.',
   'valeur_unique', 0.02, null, '% du poids de la phase grasse', 'Ambiante à 70°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Gallate de propyle (E310)
  -- ------------------------------------------------------------
  v_material_id := '655b1144-0af4-40ee-9d17-7d631d966089'::uuid;

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
    '3,4,5-trihydroxybenzoate de propyle (C₁₀H₁₂O₅)',
    'Propyl Gallate, E310, antioxydant phénolique',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche à blanc cassé, inodore',
    'Non applicable (liposoluble, légèrement soluble dans l''eau chaude)',
    'Peu soluble dans l''eau (0,35 %), soluble dans les huiles, l''alcool, le propylène glycol',
    1.20, 190.0,
    'Antioxydant phénolique tri-hydroxylé, très efficace pour protéger les huiles végétales et les corps gras contre l''oxydation. Souvent synergisé avec l''acide citrique ou le BHA/BHT. Limite UE : 200 mg/kg dans les graisses, 100 mg/kg dans les snacks. Peut provoquer une irritation cutanée et est suspecté de perturber le système endocrinien.',
    'Par rapport au BHA/BHT, il est moins liposoluble et moins stable à la chaleur, mais plus efficace dans les systèmes aqueux et les émulsions. Il est moins utilisé aujourd''hui en raison de son potentiel sensibilisant.',
    'Modéré',
    array['gants','lunettes','masque'],
    'Gants en nitrile, lunettes de sécurité, masque anti-poussière. Éviter le contact cutané (sensibilisant possible).',
    'Inhalation : air frais. Peau : laver au savon. Yeux : rincer 15 min. Ingestion : rincer la bouche, boire de l''eau, appeler un médecin.',
    'Oxydants forts, bases fortes, sels de fer (coloration bleue).',
    'Récipient étanche, au frais, à l''abri de la lumière et de l''humidité.',
    5, 25, true, true, 36, 'a_valider'
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
  (v_academie_id, 'Antioxydant pour huiles végétales, snacks, chewing-gum',
   'Dissoudre 0,01-0,02 % dans la matière grasse chaude (60-70°C). Ajouter de l''acide citrique (0,005 %) pour un effet synergique.',
   'valeur_unique', 0.02, null, '% du poids de la matière grasse', '60-70°C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Gallate d'octyle (E311)
  -- ------------------------------------------------------------
  v_material_id := '824f6755-b873-432e-90e2-c354baab8abe'::uuid;

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
    '3,4,5-trihydroxybenzoate d''octyle (C₁₅H₂₂O₅)',
    'Octyl Gallate, E311, antioxydant liposoluble',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche à blanc cassé, inodore',
    'Non applicable (liposoluble)',
    'Insoluble dans l''eau, soluble dans les huiles, les graisses, l''alcool et le propylène glycol',
    1.10, null,
    'Ester d''acide gallique à chaîne plus longue que le gallate de propyle, donc plus liposoluble. Antioxydant phénolique efficace, souvent synergisé avec le BHA/BHT. Limite UE : 200 mg/kg dans les graisses, 100 mg/kg dans les snacks. Moins utilisé que le gallate de propyle en raison de son coût plus élevé.',
    'Par rapport au gallate de propyle (E310), il est plus liposoluble et plus stable en température. Il partage le même profil toxicologique (sensibilisant, perturbateur endocrinien suspecté).',
    'Modéré',
    array['gants','lunettes','masque'],
    'Gants en nitrile, lunettes, masque anti-poussière. Sensibilisant possible.',
    'Inhalation : air frais. Peau : laver. Yeux : rincer 15 min. Ingestion : rincer la bouche, boire de l''eau, appeler un médecin.',
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
  (v_academie_id, 'Antioxydant pour huiles et graisses industrielles, snacks',
   'Dissoudre 0,01-0,02 % dans la matière grasse à 60-70°C. Utilisé lorsque la solubilité du gallate de propyle est insuffisante.',
   'valeur_unique', 0.02, null, '% du poids de la matière grasse', '60-70°C', 'Immédiat', false, 0);
end $$;
