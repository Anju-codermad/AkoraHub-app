-- ============================================================
-- AkoraHub - Patch Phase 142 : fiches Académie pour les 35 produits
-- déjà présents dans le catalogue "Parfums & Additifs" avant la
-- campagne — contenu DeepSeek, vérifié par l'utilisatrice.
--
-- Termine la catégorie "Parfums & Additifs" (82/82 : 47 nouveaux en
-- phases 136-141 + ces 35 produits déjà existants).
-- 5 entrées génériques de famille (Aromes alimentaires, Épices
-- alimentaires, Fixateurs de parfum, Huiles essentielles, Parfums
-- de synthese) documentées avec le même schéma de "fiche de
-- synthèse par famille" que la catégorie Colorants : densite et
-- point_eclair à null, particularite listant des substances
-- représentatives, un seul usage en dosage_type='texte_libre'.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Acésulfame de potassium (Ace-K / E950)
  -- ------------------------------------------------------------
  v_material_id := '2149d2fc-05ab-4ae4-950a-68713c2f1ecd'::uuid;

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
    'Sel de potassium de l''acésulfame (C₄H₄KNO₄S)',
    'Ace-K, E950, acésulfame K, édulcorant intense',
    'Alimentaire',
    'Poudre cristalline blanche, inodore, saveur sucrée intense (200x le saccharose), avec une légère amertume à haute dose',
    'Neutre (6-7 en solution aqueuse)',
    'Très soluble dans l''eau (27 g/100 mL à 20 °C), insoluble dans les huiles',
    null, null,
    'Édulcorant de synthèse non calorigène, stable à la chaleur et en milieu acide. Souvent utilisé en combinaison avec l''aspartame ou le sucralose pour masquer son arrière-goût amer et obtenir un profil sucré plus rond. Ne provoque pas de caries. DJA : 9 mg/kg de poids corporel.',
    'Par rapport à l''aspartame, il est stable à la cuisson et ne contient pas de phénylalanine. Contrairement au sucralose, il a un pouvoir sucrant moins élevé mais un coût inférieur.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter l''inhalation de poudre.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts.',
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
  (v_academie_id, 'Édulcorant en boissons, confiseries, desserts, produits laitiers',
   'Dissoudre dans la phase aqueuse. Dosage typique 0,02-0,1 % selon le pouvoir sucrant désiré. Peut être associé à d''autres édulcorants.',
   'plage', 0.02, 0.1, '% du produit fini', 'Ambiante à 100 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Acide citrique + Sorbate K — combo conservateur standard
  -- ------------------------------------------------------------
  v_material_id := '1a8b7cbd-2cfe-4947-9ff3-91c2b4adfa0c'::uuid;

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
    'Mélange d''acide citrique (E330) et de sorbate de potassium (E202)',
    'Conservateur universel, combo acidifiant-conservateur, acide citrique + sorbate K',
    'Alimentaire, Cosmétique',
    'Poudre blanche à blanc cassé, odeur neutre',
    'Variable selon le ratio, généralement acide (3-5)',
    'Très soluble dans l''eau',
    null, null,
    'Combinaison synergique d''un acidifiant/antioxydant (acide citrique) et d''un conservateur antifongique (sorbate de potassium). L''acide citrique abaisse le pH, ce qui active le sorbate et lui permet d''être efficace contre les moisissures et levures. Très utilisé dans les conserves, les boissons et les cosmétiques acides.',
    'Comparé au benzoate de sodium + acide citrique, ce combo est plus actif à pH modérément acide (jusqu''à 5,5) et donne un goût moins amer. Idéal pour les préparations où l''acidité est acceptable.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière. Éviter l''inhalation de poudre.',
    'Yeux : rincer 15 min. Peau : laver. Ingestion : boire de l''eau.',
    'Bases fortes, oxydants forts.',
    'Récipient étanche, au sec, à l''abri de l''humidité.',
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

  insert into public.academie_phrases_h (academie_id, phrase_h_id)
  select v_academie_id, id from public.phrases_h where code in ('H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Conservateur pour conserves, sauces, boissons, cosmétiques acides',
   'Dissoudre 0,1-0,3 % du mélange dans la phase aqueuse. Ajuster le pH en dessous de 5,5 pour une efficacité optimale du sorbate.',
   'plage', 0.1, 0.3, '% du produit fini', 'Ambiante à 70 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Arôme naturel de fruits (concentré)
  -- ------------------------------------------------------------
  v_material_id := '49d308ee-be6b-4c84-8ca7-dd4b1982dd7c'::uuid;

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
    'Concentré de substances aromatiques naturelles issues de fruits (esters, aldéhydes, lactones, terpènes...)',
    'Fruit flavor, arôme concentré, arôme naturel de fruits',
    'Alimentaire',
    'Liquide limpide à légèrement trouble, incolore à coloré selon le fruit, odeur caractéristique intense du fruit annoncé',
    'Variable (généralement acide, 3-5)',
    'Soluble dans l''eau (selon le support), miscible à l''alcool et aux glycols',
    null, null,
    'Famille d''arômes obtenus par concentration de jus, distillation ou extraction à partir de fruits. Les principaux types couvrent : agrumes (citron, orange, pamplemousse), fruits rouges (fraise, framboise, cerise), fruits exotiques (mangue, fruit de la passion, ananas), fruits à noyau (pêche, abricot), fruits à pépins (pomme, poire). Ils sont présentés sous forme de concentré liquide, en solution hydroalcoolique ou en poudre microencapsulée. Ne contiennent pas de conservateurs ajoutés, à conserver au frais.',
    'Par rapport aux arômes de synthèse, ils sont issus de matières premières naturelles et bénéficient d''un étiquetage "arôme naturel". Ils sont souvent moins puissants et plus sensibles à la chaleur.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Peut tacher les vêtements.',
    'Yeux : rincer. Peau : laver.',
    'Chaleur excessive (perte d''arôme), oxydants forts.',
    'Flacon hermétique, au frais, à l''abri de la lumière. Réfrigérateur recommandé après ouverture.',
    5, 15, false, true, 12, 'a_valider'
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
  (v_academie_id, 'Arôme fruité pour pâtisserie, confiserie, boissons, glaces',
   'Ajouter 0,1 à 0,5 % du produit fini en fin de préparation. Pour les cuissons, utiliser des arômes résistants à la chaleur (microencapsulés) ou doubler la dose.',
   'plage', 0.1, 0.5, '% du produit fini', 'Ambiante à 80 °C (selon le type)', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Aromes alimentaires (fiche de synthèse par famille)
  -- ------------------------------------------------------------
  v_material_id := '67205743-64a5-4205-a16b-209d8c513d4c'::uuid;

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
    'Vue d''ensemble de la famille des arômes alimentaires',
    'Arômes, flavourings, substances aromatisantes',
    'Alimentaire',
    'Variable selon le produit (liquide, poudre, pâte...)',
    'Variable',
    'Variable (hydrosoluble, liposoluble ou dispersible selon le support)',
    null, null,
    'Cette fiche générique couvre l''ensemble des arômes alimentaires disponibles : naturels (extraits de plantes, huiles essentielles, concentrés), identiques nature (molécules de synthèse copiant la nature, ex : vanilline, citral), artificiels (molécules sans équivalent naturel). Exemples représentatifs : vanilline, éthylvanilline, diacétyle (beurre), acétate d''éthyle (fruité), benzaldéhyde (amande amère), citral (citron), limonène (orange), gamma-undécalactone (pêche), gamma-nonalactone (coco), furfuryl mercaptan (café). Chaque arôme possède sa propre fiche technique pour le dosage précis.',
    'Cette famille se distingue des parfums par son usage exclusivement alimentaire et sa conformité aux normes agroalimentaires (FCC, règlement UE 1334/2008).',
    'Faible',
    array['gants','lunettes','masque'],
    'Recommandations générales : porter des gants, lunettes et un masque pour manipuler des arômes concentrés. Consulter la fiche spécifique pour les dangers particuliers.',
    'Consulter la fiche technique de l''arôme spécifique.',
    'Variable selon la molécule.',
    'Stocker dans un endroit frais, sec et ventilé, à l''abri de la lumière, dans des récipients bien fermés.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Aromatisation des denrées alimentaires (boissons, confiserie, pâtisserie, plats préparés, etc.)',
   'Consulter la fiche technique de l''arôme spécifique choisi pour le dosage exact, la solubilité et les conditions d''incorporation.',
   'texte_libre', null, null, 'Variable selon l''arôme utilisé', 'Variable', 'Variable', false, 0);

  -- ------------------------------------------------------------
  -- Aspartame (E951)
  -- ------------------------------------------------------------
  v_material_id := 'f7c7c5bc-f7d7-436e-bada-b33b2fd7e04e'::uuid;

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
    'Ester méthylique du L-α-aspartyl-L-phénylalanine (C₁₄H₁₈N₂O₅)',
    'Aspartame, E951, édulcorant intense dipeptide',
    'Alimentaire',
    'Poudre cristalline blanche, inodore, saveur sucrée intense (environ 200x le saccharose), sans arrière-goût amer',
    'Faiblement acide (5-6)',
    'Peu soluble dans l''eau (1 g/100 mL à 20 °C), très peu dans l''alcool',
    null, null,
    'Dipeptide sucré (acide aspartique + phénylalanine). Sensible à la chaleur prolongée (> 80 °C) et aux pH extrêmes (hydrolyse). Contient de la phénylalanine : doit porter la mention obligatoire pour les personnes atteintes de phénylcétonurie. DJA : 40 mg/kg de poids corporel.',
    'Par rapport à l''acésulfame K, il a un profil sucré plus naturel, sans amertume, mais il est moins stable à la cuisson. Contrairement au sucralose, il est moins cher mais nécessite une déclaration pour la phénylcétonurie.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière. Mention obligatoire : "Contient une source de phénylalanine".',
    'Yeux : rincer. Peau : laver. Ingestion sans danger sauf pour les phénylcétonuriques.',
    'Chaleur prolongée, acides et bases forts.',
    'Récipient étanche, au sec, à température ambiante. Protéger de la chaleur.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Édulcorant de table et en formulation (boissons, desserts, confiseries)',
   'Incorporer dans la phase aqueuse à température modérée (< 80 °C). Ajuster le goût avec d''autres édulcorants ou polyols pour le volume.',
   'texte_libre', null, null, 'Selon le goût sucré désiré (quelques ppm à 0,05 % du produit fini)', 'Ambiante à 70 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Caféine (anhydre)
  -- ------------------------------------------------------------
  v_material_id := '6a848798-187d-47a5-bdd3-5e9b40e97ec6'::uuid;

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
    '1,3,7-triméthylxanthine (C₈H₁₀N₄O₂)',
    'Caffeine, caféine anhydre, triméthylxanthine, stimulant',
    'Alimentaire, Pharmaceutique',
    'Poudre cristalline blanche, inodore, saveur amère',
    'Neutre à légèrement basique (6-7,5 en solution saturée)',
    'Peu soluble dans l''eau (2,2 g/100 mL à 20 °C), soluble dans l''eau chaude, très peu dans l''alcool',
    1.23, null,
    'Stimulant du système nerveux central, amer. Très utilisé dans les boissons énergisantes, les compléments alimentaires et les cosmétiques (anti-cellulite). Ne pas dépasser les doses journalières recommandées : 200 mg par prise, 400 mg par jour pour un adulte sain. Déconseillée aux enfants, aux femmes enceintes ou allaitantes (max 200 mg/j). Peut provoquer insomnie, nervosité, palpitations en cas de surdosage.',
    'Par rapport à la taurine (autre ingrédient de boissons énergisantes), la caféine a un effet stimulant direct, tandis que la taurine est un acide aminé aux propriétés anti-oxydantes et stabilisatrices de la membrane cellulaire.',
    'Modéré',
    array['gants','masque'],
    'Gants en nitrile, masque anti-poussière. Éviter l''inhalation de poudre et le contact avec les yeux. Manipuler avec précaution car substance active.',
    'Yeux : rincer 15 min. Peau : laver. Ingestion excessive : boire de l''eau, contacter un médecin si symptômes (palpitations, agitation).',
    'Oxydants forts.',
    'Récipient étanche, au sec, à température ambiante. Tenir hors de portée des enfants.',
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
  (v_academie_id, 'Boissons énergisantes, compléments alimentaires, cosmétiques (soins minceur)',
   'Dissoudre la quantité requise dans l''eau chaude pour les boissons, ou dans la phase aqueuse des gels. Respecter les doses légales pour les boissons (max 320 mg/L en UE).',
   'valeur_unique', 100, 100, 'mg par portion (ex : canette 250 mL)', 'Ambiante à 70 °C', 'Effet stimulant après 15-30 min', false, 0);

  -- ------------------------------------------------------------
  -- Caféine anhydre
  -- ------------------------------------------------------------
  v_material_id := '6665cd6c-ce96-41fc-98b5-b53657261689'::uuid;

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
    '1,3,7-triméthylxanthine (C₈H₁₀N₄O₂), forme anhydre',
    'Caffeine anhydrous, caféine pure, caféine déshydratée',
    'Alimentaire, Pharmaceutique',
    'Poudre cristalline blanche très fine, inodore, extrêmement amère',
    'Neutre (6-7)',
    'Peu soluble à froid (2 g/100 mL), plus soluble à chaud',
    1.20, null,
    'Forme déshydratée de la caféine, plus concentrée que la forme monohydratée. Les mêmes précautions s''appliquent : stimulant puissant, à utiliser avec parcimonie. Dose journalière maximale recommandée pour un adulte : 400 mg. Les enfants et les femmes enceintes doivent éviter toute consommation non contrôlée. Stocker dans un endroit sec pour éviter la reprise d''humidité qui entraîne l''agglomération.',
    'Même substance que la caféine "standard", mais la forme anhydre est plus hygroscopique et doit être stockée avec un soin particulier pour éviter la formation de grumeaux.',
    'Modéré',
    array['gants','masque'],
    'Manipuler avec soin : substance active. Éviter la contamination croisée. Porter des gants et un masque.',
    'Yeux : rincer. Peau : laver. Ingestion excessive : contacter un médecin.',
    'Oxydants forts, humidité (prise en masse).',
    'Récipient étanche, au sec, à température ambiante. Tenir hors de portée des enfants.',
    5, 25, true, false, 36, 'a_valider'
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
  where code in ('P261', 'P264', 'P280', 'P301+P312', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Formulation de boissons énergisantes, gommes à mâcher caféinées, compléments alimentaires',
   'Pré-dissoudre dans l''eau chaude pour assurer une bonne dispersion. Dosage précis selon la réglementation en vigueur.',
   'valeur_unique', 80, 80, 'mg par portion', '60-80 °C pour dissolution', 'Effet après ingestion', false, 0);

  -- ------------------------------------------------------------
  -- Crème de tartre (Tartrate acide de potassium E336)
  -- ------------------------------------------------------------
  v_material_id := 'e35e07db-ce0c-4514-a0b2-c2eb055cf2fd'::uuid;

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
    'Hydrogénotartrate de potassium (KC₄H₅O₆)',
    'Cream of tartar, E336(i), bitartrate de potassium, poudre à lever acide',
    'Alimentaire',
    'Poudre cristalline blanche, inodore, saveur acide',
    'Acide (3,5-4 en solution saturée)',
    'Modérément soluble dans l''eau (0,6 g/100 mL à 20 °C), plus soluble à chaud, insoluble dans l''alcool',
    1.05, null,
    'Sel acide naturel présent dans le raisin. Sous-produit de la vinification. Utilisé comme acide de la poudre à lever (avec le bicarbonate de sodium) et pour stabiliser les blancs d''œufs en neige. Il ne contient pas de sodium, contrairement à d''autres acides de poudre à lever.',
    'Par rapport à l''acide citrique, il a un goût moins acide et agit plus lentement. Comparé à la levure chimique complète, il ne contient pas de bicarbonate, c''est juste la partie acide qui doit être dosée avec du bicarbonate de sodium.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Bases fortes, oxydants forts.',
    'Récipient étanche, au sec, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Poudre à lever maison (avec bicarbonate) et stabilisant de blancs d''œufs',
   'Pour la poudre à lever : mélanger 2 parts de crème de tartre pour 1 part de bicarbonate de sodium. Pour les blancs d''œufs : ajouter une pincée (0,5 g) par blanc d''œuf avant de fouetter.',
   'valeur_unique', 0.5, 0.5, 'g par blanc d''œuf', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Dextrose (glucose anhydre pour glaces)
  -- ------------------------------------------------------------
  v_material_id := '746b1ea1-0ef9-43e7-b306-44d559137848'::uuid;

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
    'D-glucose anhydre (C₆H₁₂O₆)',
    'Dextrose monohydraté ou anhydre, glucose solide, sucre de maïs',
    'Alimentaire',
    'Poudre cristalline blanche, fine, inodore, saveur sucrée (70 % du saccharose) et rafraîchissante',
    'Neutre (6-7)',
    'Très soluble dans l''eau (91 g/100 mL à 25 °C), peu soluble dans l''alcool',
    1.54, null,
    'Sucre simple, directement assimilable par l''organisme. Utilisé pour abaisser le point de congélation des glaces et sorbets (pouvoir cryoprotecteur élevé), et comme source de carbone pour les levures en panification. Le dextrose anhydre est plus concentré que la forme monohydratée.',
    'Par rapport au saccharose, le dextrose a un pouvoir sucrant inférieur mais abaisse davantage le point de congélation (excellent pour les glaces). Comparé au fructose, il est moins sucré et moins hygroscopique.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Agent cryoprotecteur en glaces et sorbets artisanaux',
   'Remplacer 15 à 25 % du saccharose par du dextrose pour abaisser le point de congélation et améliorer la texture onctueuse.',
   'plage', 15, 25, '% du sucre total remplacé', 'Pendant la pasteurisation du mix', 'Effet sur la texture après turbinage', false, 0);

  -- ------------------------------------------------------------
  -- Dioxyde de carbone CO₂ alimentaire
  -- ------------------------------------------------------------
  v_material_id := '57fe9a03-0b82-4338-a690-33005be5881c'::uuid;

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
    'Dioxyde de carbone (CO₂)',
    'E290, gaz carbonique, gazéifiant, CO₂ alimentaire',
    'Alimentaire',
    'Gaz incolore, inodore, légèrement acide en solution (acide carbonique)',
    '4-5 (eau gazéifiée)',
    'Soluble dans l''eau (formation d''acide carbonique), soluble dans les corps gras',
    null, null,
    'Gaz alimentaire utilisé pour la gazéification des boissons, la conservation sous atmosphère protectrice, et comme agent de refroidissement (neige carbonique). Non toxique, mais peut provoquer l''asphyxie à haute concentration (plus lourd que l''air). Livré en bouteilles de gaz comprimé liquéfié.',
    'Par rapport à l''azote (N₂), le CO₂ est plus soluble dans l''eau et apporte une acidité pétillante. Contrairement aux gaz inertes, il est réactif (acidification).',
    'Modéré',
    array['gants','lunettes','ventilation'],
    'Manipuler les bouteilles avec des gants de manutention et des lunettes. Stocker dans un local ventilé (risque d''asphyxie en cas de fuite). Ne jamais manipuler la neige carbonique à mains nues (brûlures cryogéniques).',
    'Inhalation : transporter la victime à l''air libre. Contact cutané avec neige carbonique : réchauffer doucement, consulter un médecin. Yeux : rincer.',
    'Bases fortes (formation de carbonates).',
    'Bouteilles de gaz comprimé stockées debout, dans un local frais, sec et ventilé, à l''abri des sources de chaleur (> 50 °C). Protéger du gel.',
    5, 40, false, false, 60, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H280')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P282', 'P336+P315', 'P403')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Gazéification de boissons et conservation sous atmosphère protectrice',
   'Injecter le gaz directement dans la boisson à basse température pour une meilleure dissolution. Utiliser un détendeur adapté.',
   'texte_libre', null, null, 'Selon le niveau de pétillance désiré', '0-10 °C pour carbonatation optimale', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Épices alimentaires (fiche de synthèse par famille)
  -- ------------------------------------------------------------
  v_material_id := '74c5525a-3d38-4f41-b493-cff71b03e968'::uuid;

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
    'Vue d''ensemble de la famille des épices',
    'Épices, condiments, poudres aromatiques',
    'Alimentaire',
    'Poudres ou fragments secs, couleurs et arômes variés',
    'Variable',
    'Partiellement soluble dans l''eau (macération), soluble dans les corps gras (liposoluble pour les arômes)',
    null, null,
    'Famille regroupant des matières végétales séchées à usage aromatique. Exemples représentatifs : Cannelle (écorce de Cinnamomum, contient du cinnamaldéhyde, antioxydante) ; Muscade (noix de Myristica fragrans, contient de la myristicine, toxique à haute dose) ; Gingembre (rhizome de Zingiber officinale, contient du gingérol, anti-inflammatoire) ; Clou de girofle (boutons floraux de Syzygium aromaticum, riche en eugénol, anesthésiant local). Peuvent être allergènes ou contenir des mycotoxines si mal conservées.',
    'Contrairement aux herbes aromatiques, les épices sont généralement des parties dures (écorces, graines, racines) et ont une saveur plus intense. Elles se distinguent des arômes purs par leur complexité et la présence de fibres végétales.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour manipuler des poudres irritantes (clou de girofle, cannelle).',
    'Yeux : rincer. Peau : laver. Ingestion sans danger aux doses culinaires.',
    'Humidité (moisissures), oxydants forts.',
    'Récipient étanche, au sec, à l''abri de la lumière et de la chaleur. Conserver de préférence en grains et moudre au moment de l''emploi.',
    5, 20, true, true, 18, 'a_valider'
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
  (v_academie_id, 'Aromatisation de plats, pâtisseries, boissons',
   'Consulter la fiche technique de l''épice spécifique pour le dosage et les conseils d''utilisation (infusion, macération, ajout direct).',
   'texte_libre', null, null, 'Variable selon la recette', 'Variable', 'Variable', false, 0);

  -- ------------------------------------------------------------
  -- Extrait de malt liquide / poudre
  -- ------------------------------------------------------------
  v_material_id := '542752ff-9f70-40b6-83d3-4f59a35e1a08'::uuid;

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
    'Mélange complexe de sucres (maltose, dextrines), protéines, enzymes et minéraux issus de l''hydrolyse de l''orge maltée',
    'Malt extract, extrait de malt, sirop de malt',
    'Alimentaire',
    'Liquide sirupeux brun à brun foncé (sirop) ou poudre beige à brune, odeur caractéristique de malt, saveur sucrée',
    '5-6 (solution aqueuse)',
    'Liquide miscible à l''eau. Poudre soluble dans l''eau chaude.',
    1.40, null,
    'Extrait concentré de malt d''orge, source de sucres fermentescibles pour les levures (brasserie, boulangerie). Riche en maltose (50-70 %), dextrines, acides aminés et vitamines du groupe B. Apporte couleur, arôme et valeur nutritionnelle. En boulangerie, il améliore la croûte et prolonge la conservation. Le sirop (80 % de matière sèche) est le plus courant.',
    'Par rapport au sirop de glucose, l''extrait de malt a un pouvoir sucrant plus faible mais apporte un goût malté caractéristique. Comparé au sirop de glucose-fructose, il contient moins de fructose et plus de protéines.',
    'Faible',
    array[]::text[],
    'Aucun. Surface collante en cas de déversement.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts.',
    'Récipient hermétique, au frais, à l''abri de la lumière. Le sirop peut cristalliser à basse température.',
    10, 25, true, true, 12, 'a_valider'
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
  (v_academie_id, 'Ingrédient de boulangerie, brasserie artisanale, petit-déjeuner',
   'Incorporer 2 à 5 % du poids de farine dans la pâte à pain. En brasserie, ajouter pendant l''ébullition du moût pour augmenter la densité et la saveur maltée.',
   'plage', 2, 5, '% du poids de farine', 'Ambiante à 100 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Extrait de vanille naturel (Bourbon)
  -- ------------------------------------------------------------
  v_material_id := '4ad6239b-6d71-4c84-b782-c7ec398fd087'::uuid;

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
    'Solution hydroalcoolique concentrée de principes aromatiques de la vanille (vanilline, éthylvanilline, acide vanillique, etc.)',
    'Vanilla extract, extrait de vanille Bourbon, arôme naturel de vanille',
    'Alimentaire',
    'Liquide brun foncé, odeur intense et douce de vanille, saveur sucrée',
    'Légèrement acide (5-6)',
    'Soluble dans l''eau et l''alcool, partiellement liposoluble',
    1.05, null,
    'Extrait obtenu par macération prolongée de gousses de vanille Bourbon (Vanilla planifolia) dans un mélange eau-alcool. Contient plus de 200 composés aromatiques, avec la vanilline comme principal contributeur. Qualité supérieure à la vanilline de synthèse seule, arôme complexe. Sensible à la lumière et à la chaleur.',
    'Par rapport à l''arôme vanille de synthèse, l''extrait naturel a un profil aromatique plus riche et plus subtil. Contrairement à la vanilline pure, il peut apporter des notes boisées, épicées et animales.',
    'Faible',
    array[]::text[],
    'Aucun. Peut tacher les vêtements.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts, chaleur prolongée.',
    'Flacon hermétique, à l''abri de la lumière et de la chaleur. Conserver au frais.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Arôme vanille pour pâtisserie, glaces, crèmes, chocolaterie',
   'Ajouter 1 à 2 cuillères à café par litre de préparation, de préférence en fin de cuisson ou à froid pour préserver les arômes volatils.',
   'valeur_unique', 5, 5, 'mL par litre de produit fini', 'Ambiante à 60 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Fixateurs de parfum (fiche de synthèse par famille)
  -- ------------------------------------------------------------
  v_material_id := '682fd110-b9f8-410d-bbac-b0b33cfb40ac'::uuid;

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
    'Vue d''ensemble de la famille des fixateurs',
    'Fixateurs, bases fixatrices, agents de fond',
    'Cosmétique',
    'Variable (liquides visqueux, résines, poudres cristallines...)',
    'Variable',
    'Variable selon le fixateur (alcool, huile...)',
    null, null,
    'Substances qui ralentissent l''évaporation des notes de tête et prolongent la tenue d''un parfum sur la peau. Exemples représentatifs : benjoin (résine chaude, vanillée), myrrhe (résine balsamique, amère), oliban (encens, boisé-citronné), ambroxide (ambre synthétique, marine), galaxolide (musc polycyclique, doux), civettone (musc macrocyclique, animal), Iso E Super (boisé-ambré moderne), linalol (floral, mais aussi fixateur léger). Ils agissent en formant un film ou en ayant une pression de vapeur très basse.',
    'Les fixateurs se distinguent des autres matières premières parfumantes par leur volatilité très faible et leur capacité à modifier la courbe d''évaporation du parfum. Ils ne sont pas toujours odorants (ex : certains muscs sont quasi-inodores mais fixent les autres notes).',
    'Faible',
    array['gants','lunettes','masque'],
    'Consulter la fiche spécifique du fixateur choisi. En général, manipulation avec gants et ventilation recommandée.',
    'Consulter la fiche du fixateur spécifique.',
    'Variable.',
    'Stocker dans un endroit frais, sec et à l''abri de la lumière, dans des récipients bien fermés.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Prolongation de la tenue des parfums en composition cosmétique ou alcoolique',
   'Consulter la fiche du fixateur spécifique pour le dosage et la méthode d''incorporation dans le concentré parfumé.',
   'texte_libre', null, null, 'Variable selon le fixateur', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Fructose (Lévulose)
  -- ------------------------------------------------------------
  v_material_id := '26dda453-1ed8-4dd7-9d39-4fe9842ef2ac'::uuid;

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
    'D-fructose (C₆H₁₂O₆)',
    'Fructose, lévulose, sucre de fruit',
    'Alimentaire',
    'Poudre cristalline blanche, très fine, inodore, saveur très sucrée (130-180 % du saccharose, selon la température)',
    'Neutre (6-7)',
    'Extrêmement soluble dans l''eau (375 g/100 mL à 20 °C), peu dans l''alcool',
    1.60, null,
    'Sucre simple le plus sucré. À froid, il est perçu plus sucré que le saccharose. Très hygroscopique, il retient l''humidité et améliore le moelleux des pâtisseries. Pouvoir cryoprotecteur élevé (abaisse le point de congélation). Indice glycémique bas (25), adapté aux régimes diabétiques en quantité modérée.',
    'Par rapport au glucose (dextrose), le fructose est plus sucré et plus hygroscopique. Comparé au saccharose, il ne cristallise pas facilement et donne des textures plus moelleuses.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Récipient étanche, au sec (très hygroscopique). Conserver dans un endroit frais.',
    5, 25, true, false, 36, 'a_valider'
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
  (v_academie_id, 'Agent sucrant et humectant en pâtisserie, glaces, boissons',
   'Remplacer une partie du saccharose (20-30 %) pour augmenter le moelleux et abaisser le point de congélation. Ajuster la cuisson (brunissement plus rapide).',
   'plage', 20, 30, '% du sucre total remplacé', 'Ambiante à 180 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Glucose / Dextrose monohydraté
  -- ------------------------------------------------------------
  v_material_id := '00fcae54-a742-4b3c-bc34-6522ee45101b'::uuid;

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
    'D-glucose monohydraté (C₆H₁₂O₆·H₂O)',
    'Glucose de maïs, sirop de glucose déshydraté, dextrose monohydraté',
    'Alimentaire',
    'Poudre cristalline blanche, inodore, saveur sucrée modérée (70 % du saccharose), légèrement rafraîchissante',
    'Neutre (6-7)',
    'Très soluble dans l''eau (91 g/100 mL à 25 °C)',
    1.54, null,
    'Glucose sous forme monohydratée, contenant une molécule d''eau par molécule de glucose. Utilisé comme source de sucre rapide en alimentation, et comme agent de charge et cryoprotecteur. Le monohydrate est moins hygroscopique que la forme anhydre.',
    'Par rapport au dextrose anhydre, le monohydrate est légèrement moins concentré en glucose (pureté 91 % contre 99,5 %), mais il résiste mieux à l''agglomération lors du stockage.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Récipient étanche, au sec, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Source de sucre pour boissons énergétiques, compléments alimentaires, glaces',
   'Dissoudre dans l''eau. En glace, remplacer 15 à 25 % du sucre par du glucose pour améliorer la texture.',
   'plage', 15, 25, '% du sucre total', 'Ambiante à 80 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Glutamate monosodique MSG (E621)
  -- ------------------------------------------------------------
  v_material_id := '6fbf8e22-fbcf-4ab2-9d78-d8c426c9a968'::uuid;

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
    'L-glutamate de sodium monohydraté (C₅H₈NNaO₄·H₂O)',
    'MSG, E621, glutamate de sodium, exhausteur de goût umami',
    'Alimentaire',
    'Poudre cristalline blanche, inodore, saveur umami caractéristique, légèrement salée',
    'Neutre (7 en solution)',
    'Très soluble dans l''eau (74 g/100 mL à 20 °C), insoluble dans l''alcool',
    null, null,
    'Sel de sodium de l''acide glutamique, un acide aminé naturellement présent dans de nombreux aliments (tomates, fromages, algues). Il renforce le goût umami et la sapidité générale. Utilisé mondialement dans la cuisine asiatique, les snacks, les soupes. Sans danger aux doses usuelles (DJA : 30 mg/kg/j).',
    'Par rapport à l''extrait de levure, le MSG est un additif pur au goût plus direct et moins complexe. Contrairement à l''inosinate/guanylate, il a une saveur propre et n''est pas un simple exhausteur synergique.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts.',
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
  (v_academie_id, 'Exhausteur de goût pour plats salés, snacks, soupes, sauces',
   'Ajouter 0,1 à 0,5 % du produit fini, seul ou en combinaison avec des nucléotides (E627/E631) pour une synergie. Dissoudre dans la phase aqueuse.',
   'plage', 0.1, 0.5, '% du produit fini', 'Ambiante à 100 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Houblon — pellets T90 et extrait CO₂
  -- ------------------------------------------------------------
  v_material_id := '5fcf6642-f2e0-4a42-aadb-6d476b25a6fe'::uuid;

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
    'Pellets : cônes de houblon broyés compressés. Extrait CO₂ : résine riche en acides alpha (humulone) et huiles essentielles.',
    'Houblon, pellets T90, extrait CO₂ de houblon, amérisant bière',
    'Alimentaire (brasserie)',
    'Pellets : granulés vert-brun, odeur intense de houblon. Extrait CO₂ : liquide visqueux vert foncé à brun, odeur très puissante.',
    'Non applicable',
    'Les acides amers sont solubles dans l''eau bouillante (isomérisation) ; les huiles essentielles sont volatiles et liposolubles.',
    null, null,
    'Le houblon (Humulus lupulus) apporte l''amertume, l''arôme et les propriétés antimicrobiennes à la bière. Les pellets T90 (90 % de la matière première d''origine) sont la forme la plus utilisée en brasserie artisanale. L''extrait CO₂ est une résine concentrée utilisée pour ajuster l''amertume sans apport de matière végétale. Les acides alpha doivent être bouillis pour s''isomériser (amertume), tandis que les huiles essentielles sont ajoutées en fin d''ébullition ou à cru (houblonnage à froid) pour l''arôme.',
    'Par rapport aux cônes de houblon entiers, les pellets T90 se conservent mieux et sont plus faciles à doser. L''extrait CO₂ est utilisé pour standardiser l''amertume sans influencer la turbidité ou le volume de la bière.',
    'Faible',
    array['gants','lunettes'],
    'Gants et lunettes pour manipuler l''extrait CO₂ (très concentré, irritant). Les poudres de pellets peuvent être irritantes pour les voies respiratoires.',
    'Yeux : rincer. Peau : laver. Inhalation : air frais.',
    'Oxydants forts. L''oxygène dégrade les acides amers et les huiles essentielles.',
    'Pellets : emballage sous vide, au froid (2-8 °C) ou au congélateur. Extrait CO₂ : récipient étanche, au frais et à l''abri de la lumière.',
    2, 8, true, true, 12, 'a_valider'
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
  (v_academie_id, 'Amérisation et aromatisation de la bière',
   'Pellets : ajouter en début d''ébullition pour l''amertume (60-90 min), en fin d''ébullition (5-15 min) pour l''arôme, ou à cru pour le dry hopping. Extrait CO₂ : ajouter pendant l''ébullition selon le taux d''acides alpha désiré.',
   'plage', 50, 500, 'g de pellets par hectolitre (selon le style)', '100 °C (ébullition) à 4 °C (dry hopping)', 'Pendant l''ébullition ou la fermentation', false, 0);

  -- ------------------------------------------------------------
  -- Huiles essentielles (fiche de synthèse par famille)
  -- ------------------------------------------------------------
  v_material_id := '8a8ee576-5deb-4221-bbf2-8f34a99acd25'::uuid;

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
    'Vue d''ensemble de la famille des huiles essentielles',
    'Essential oils, HE, essences végétales',
    'Cosmétique, Alimentaire (certaines)',
    'Liquides limpides, mobiles, volatils, odeur caractéristique de la plante, couleurs variées',
    'Non applicable',
    'Insolubles dans l''eau, solubles dans l''alcool et les huiles',
    null, null,
    'Substances aromatiques volatiles extraites de plantes par distillation ou expression. Exemples courants : Lavande (linalol, acétate de linalyle) — calmante, allergène ; Tea tree (terpinène-4-ol) — antimicrobien ; Menthe poivrée (menthol) — rafraîchissante ; Citron (limonène) — tonique, photosensibilisante ; Ylang-ylang (linalol, géraniol) — relaxante ; Eucalyptus (1,8-cinéole) — décongestionnante. Précautions générales : ne pas appliquer pures sur la peau, respecter les doses, certaines sont photosensibilisantes (agrumes), d''autres toxiques par ingestion.',
    'Par rapport aux parfums de synthèse, elles sont naturelles mais plus complexes, plus chères et plus sujettes aux variations de composition.',
    'Modéré',
    array['gants','lunettes','masque','ventilation'],
    'Toujours manipuler avec des gants et des lunettes. Porter un masque et ventiler pour les HE puissantes. Consulter la fiche spécifique.',
    'En cas de projection oculaire, rincer abondamment avec une huile végétale puis de l''eau. Peau : laver au savon. Ingestion : ne pas faire vomir, appeler un centre antipoison.',
    'Oxydants forts, chaleur, lumière (oxydation).',
    'Flacons en verre teinté, bien bouchés, à l''abri de la lumière et de la chaleur. Conserver dans un endroit ventilé.',
    5, 20, false, true, 24, 'a_valider'
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
  (v_academie_id, 'Aromathérapie, cosmétique, parfumerie, arômes alimentaires',
   'Consulter la fiche technique de l''huile essentielle spécifique pour le dosage et les précautions particulières (dilution, photosensibilisation, etc.).',
   'texte_libre', null, null, 'Variable selon l''HE et l''usage (gouttes, % dans l''huile support)', 'Ambiante', 'Variable', false, 0);

  -- ------------------------------------------------------------
  -- Inositol / Myo-inositol (Vitamine B8)
  -- ------------------------------------------------------------
  v_material_id := '467b8ced-d83e-400d-8068-c19fabafc8f8'::uuid;

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
    'Myo-inositol (C₆H₁₂O₆), un polyol cyclique',
    'Inositol, vitamine B8, myo-inositol, facteur anti-alopécique',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche, inodore, saveur légèrement sucrée (50 % du saccharose)',
    'Neutre (6-7)',
    'Très soluble dans l''eau (14 g/100 mL à 20 °C), insoluble dans l''alcool',
    1.75, null,
    'Polyol naturel présent dans le corps humain et les plantes. Impliqué dans la signalisation cellulaire et le métabolisme des graisses. Utilisé comme complément alimentaire pour la fertilité (syndrome des ovaires polykystiques), la santé mentale (anxiété) et en cosmétique pour la croissance des cheveux.',
    'Par rapport à la taurine (autre complément populaire), l''inositol est un polyol sans soufre, avec des propriétés différentes sur le système nerveux. Contrairement aux édulcorants polyols, il est utilisé comme nutriment, pas pour sucrer.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Récipient étanche, au sec, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Complément alimentaire (fertilité, humeur) et cosmétique capillaire',
   'Voie orale : 2 à 4 g par jour en poudre dissoute dans l''eau. Cosmétique : incorporer 1-2 % dans des lotions ou sérums capillaires.',
   'valeur_unique', 2, 2, 'g par jour (usage oral)', 'Ambiante', 'Variable', false, 0);

  -- ------------------------------------------------------------
  -- Levure chimique (poudre à lever)
  -- ------------------------------------------------------------
  v_material_id := '7870a15c-7277-42a6-943f-ed028307ef8d'::uuid;

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
    'Mélange de bicarbonate de sodium (E500) ou d''ammonium (E503) et d''un ou plusieurs acides (pyrophosphate E450, glucono-delta-lactone E575, etc.) et d''amidon',
    'Poudre à lever, levure alsacienne, baking powder',
    'Alimentaire',
    'Poudre blanche, fine, inodore',
    'Neutre, mais libère du CO₂ en présence d''eau (effervescence)',
    'Partiellement soluble (les sels réagissent dans l''eau)',
    null, null,
    'Mélange prêt à l''emploi produisant du dioxyde de carbone à l''humidité et à la chaleur, faisant lever les pâtes. Contient un agent acide (pyrophosphate de sodium, acide citrique, etc.) qui réagit avec le bicarbonate. La présence d''amidon (souvent maïs) absorbe l''humidité et stabilise le mélange.',
    'Par rapport au bicarbonate de sodium seul, elle ne nécessite pas d''ajouter un acide (yaourt, citron) à la pâte. Contrairement à la levure de boulanger (biologique), elle produit du gaz immédiatement sans fermentation.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Acides forts supplémentaires, humidité (activation prématurée).',
    'Récipient étanche, au sec, à l''abri de l''humidité.',
    5, 30, true, false, 18, 'a_valider'
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
  (v_academie_id, 'Agent levant en pâtisserie, biscuits, cakes',
   'Incorporer 2 à 3 % du poids de farine, tamiser avec la farine. Ne pas laisser reposer la pâte trop longtemps avant cuisson.',
   'valeur_unique', 2.5, 2.5, '% du poids de farine', 'Cuisson au four (180-220 °C)', 'Pendant la cuisson', false, 0);

  -- ------------------------------------------------------------
  -- Maltodextrine
  -- ------------------------------------------------------------
  v_material_id := '9c950547-a6ee-4d31-8fee-bb796b4134f1'::uuid;

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
    'Polymère de glucose (mélange de saccharides de DP 3-19) obtenu par hydrolyse partielle de l''amidon',
    'Maltodextrin, dextrine de malt, liant glucidique',
    'Alimentaire, Cosmétique',
    'Poudre blanche à crème, fine, hygroscopique, saveur légèrement sucrée (DE < 20)',
    'Neutre (6-7 en solution)',
    'Très soluble dans l''eau',
    0.50, null,
    'Glucide complexe très peu sucré (DE 3-20). Utilisé comme agent de charge, support pour arômes déshydratés, texturant, et source d''énergie à libération prolongée (boissons pour sportifs). En cosmétique, il est utilisé comme liant pour les poudres compactes.',
    'Par rapport au dextrose, la maltodextrine a un pouvoir sucrant très faible et un indice glycémique variable. Comparée aux sirops de glucose, elle se présente sous forme de poudre sèche, facile à manipuler.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière (poudre très volatile).',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Oxydants forts, humidité (agglomération).',
    'Récipient étanche, au sec, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Agent de charge et support d''arômes, boissons sportives, poudres instantanées',
   'Dissoudre dans l''eau avant ajout. Pour les arômes, mélanger l''arôme liquide avec la maltodextrine jusqu''à absorption complète, puis sécher.',
   'texte_libre', null, null, 'Variable selon l''application (5-50 % du produit fini)', 'Ambiante à 80 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Parfums de synthese (fiche de synthèse par famille)
  -- ------------------------------------------------------------
  v_material_id := 'fd120f46-5ab0-42ff-8cf8-590e106cf249'::uuid;

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
    'Vue d''ensemble de la famille des parfums de synthèse',
    'Fragrances, compositions parfumées synthétiques, perfume oils',
    'Cosmétique, Technique',
    'Liquides limpides, incolores à jaune pâle, odeurs variées selon la composition',
    'Non applicable',
    'Variables, généralement solubles dans l''alcool et les huiles, insolubles dans l''eau',
    null, null,
    'Famille de compositions parfumées obtenues par mélange de molécules de synthèse et/ou d''isolats naturels. Grandes familles olfactives : hespéridée (agrumes : limonène, citral), florale (jasmin, rose : linalol, géraniol), boisée (cèdre, santal : Iso E Super, cédrol), orientale (vanille, ambre : vanilline, coumarine), chyprée (bergamote, mousse de chêne), aromatique (lavande, herbes). Ces concentrés sont destinés à être dilués dans une base (alcool, huile, crème).',
    'Par rapport aux huiles essentielles, les parfums de synthèse sont moins coûteux, plus stables et permettent une créativité illimitée. Ils ne possèdent pas les propriétés thérapeutiques des HE.',
    'Faible',
    array['gants','lunettes','masque'],
    'Toujours manipuler les concentrés avec des gants, lunettes et ventilation. Éviter le contact avec la peau et les yeux.',
    'Yeux : rincer abondamment. Peau : laver au savon. Ingestion : ne pas faire vomir, contacter un médecin.',
    'Oxydants forts, chaleur, lumière.',
    'Flacons hermétiques, dans un endroit frais et ventilé, à l''abri de la lumière et des sources d''inflammation.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Parfumerie alcoolique, cosmétique, savonnerie, bougies',
   'Diluer le concentré dans la base appropriée (alcool pour parfum, phase grasse pour crème). Le dosage varie généralement entre 0,5 % (produits sans rinçage) et 5 % (parfums).',
   'plage', 0.5, 5.0, '% du produit fini', 'Ambiante à 40 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Saccharine sodique (E954)
  -- ------------------------------------------------------------
  v_material_id := 'c0319d34-fe3c-44f6-a0d2-39eb65bb1e2a'::uuid;

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
    'Sel de sodium de la saccharine (C₇H₄NNaO₃S·2H₂O)',
    'Saccharine, E954, édulcorant artificiel',
    'Alimentaire',
    'Poudre cristalline blanche, inodore, saveur sucrée intense (300-500x le saccharose), avec un arrière-goût amer à haute concentration',
    'Neutre (6-7)',
    'Très soluble dans l''eau (100 g/100 mL à 20 °C), peu dans l''alcool',
    null, null,
    'Le plus ancien édulcorant de synthèse (découvert en 1879). Non calorique, stable à la chaleur et en milieu acide. Souvent utilisé en combinaison avec d''autres édulcorants pour masquer son amertume. DJA : 5 mg/kg de poids corporel.',
    'Par rapport à l''aspartame, la saccharine résiste à la cuisson mais laisse un arrière-goût métallique. Contrairement au sucralose, elle est moins chère mais moins appréciée gustativement.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Récipient étanche, au sec, à température ambiante.',
    5, 35, true, false, 48, 'a_valider'
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
  (v_academie_id, 'Édulcorant de table et en formulation (boissons light, confiseries, produits de régime)',
   'Utiliser à très faible dose (0,01-0,05 %). Dissoudre dans l''eau. Combiner avec d''autres édulcorants pour améliorer le goût.',
   'plage', 0.01, 0.05, '% du produit fini', 'Ambiante à 100 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Saccharose (Sucre blanc raffiné / Sucre SP)
  -- ------------------------------------------------------------
  v_material_id := '1c982e1d-fe6c-45e4-9868-361e6f533b1d'::uuid;

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
    'α-D-glucopyranosyl-(1→2)-β-D-fructofuranoside (C₁₂H₂₂O₁₁)',
    'Sucre de table, sucre cristallisé, sucrose, sucre semoule',
    'Alimentaire',
    'Cristaux blancs, inodore, saveur sucrée de référence (pouvoir sucrant = 1)',
    'Neutre (7)',
    'Très soluble dans l''eau (200 g/100 mL à 20 °C), insoluble dans l''alcool',
    1.59, null,
    'Disaccharide extrait de la betterave ou de la canne à sucre. C''est l''étalon de la saveur sucrée. Utilisé comme édulcorant, conservateur (confitures à haute teneur en sucre), et agent de texture en pâtisserie (caramélisation, croustillant). Le sucre SP (sans poussière) est un sucre cristallisé tamisé pour éviter les fines particules.',
    'Par rapport au sirop de glucose, le saccharose cristallise facilement, ce qui donne des textures cassantes (bonbons durs). Comparé au fructose, il est moins sucré et moins hygroscopique.',
    'Faible',
    array[]::text[],
    'Aucun. Risque de glissade en cas de déversement.',
    'Yeux : rincer. Peau : laver.',
    'Acides forts (hydrolyse en sucre inverti), bases fortes.',
    'Sacs étanches, dans un endroit sec et à l''abri de l''humidité.',
    5, 30, true, false, 120, 'a_valider'
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
  (v_academie_id, 'Édulcorant et texturant universel en pâtisserie, confiserie, boissons',
   'Utiliser tel quel ou en solution. Pour les sirops, dissoudre à chaud (1 kg de sucre pour 500-600 g d''eau).',
   'texte_libre', null, null, 'Selon la recette', 'Ambiante à 180 °C (caramélisation)', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Saccharose inverti (Trimoline)
  -- ------------------------------------------------------------
  v_material_id := '320a9f7b-1291-4574-99dd-c01f8afc4923'::uuid;

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
    'Mélange équimolaire de glucose et de fructose obtenu par hydrolyse du saccharose',
    'Sucre inverti, Trimoline, sirop de sucre inverti',
    'Alimentaire',
    'Sirop visqueux incolore à jaune pâle, odeur neutre, saveur très sucrée (plus sucré que le saccharose)',
    'Légèrement acide (4-5)',
    'Miscible à l''eau en toutes proportions',
    1.43, null,
    'Sirop produit par hydrolyse acide ou enzymatique du saccharose. Il contient 50 % de glucose, 50 % de fructose. Propriétés anti-cristallisation, hygroscopique. Abaisse le point de congélation. Améliore la texture moelleuse des pâtisseries et prolonge leur conservation. Incontournable en glacerie et confiserie.',
    'Par rapport au saccharose solide, le sirop inverti ne cristallise pas et apporte du moelleux. Comparé au sirop de glucose, il est plus sucré et plus hygroscopique.',
    'Faible',
    array[]::text[],
    'Aucun. Surface collante.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Bidon hermétique, à température ambiante. Protéger du gel et de la chaleur excessive.',
    10, 25, true, false, 18, 'a_valider'
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
  (v_academie_id, 'Anti-cristallisant et humectant en glaces, pâtisseries, confiseries',
   'Remplacer une partie du saccharose (20-40 %) par du sirop inverti. Incorporer directement dans la préparation liquide ou à chaud.',
   'plage', 20, 40, '% du poids total de sucre', 'Ambiante à 100 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Sirop de glucose (DE 38–42)
  -- ------------------------------------------------------------
  v_material_id := '535f9efa-a9e2-4bda-864d-59c577401c4e'::uuid;

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
    'Mélange de glucose, maltose et dextrines obtenu par hydrolyse partielle de l''amidon',
    'Glucose syrup, sirop de maïs, sirop de blé',
    'Alimentaire',
    'Liquide visqueux incolore à jaune pâle, inodore, saveur sucrée modérée',
    'Neutre à légèrement acide (5-6)',
    'Miscible à l''eau',
    1.38, null,
    'Sirop caractérisé par son équivalent dextrose (DE), ici 38-42. Il apporte du corps, de la viscosité et un pouvoir anti-cristallisant sans excès de sucrosité. Utilisé en confiserie, pâtisserie, glaces. Le DE indique la teneur en sucres réducteurs ; un DE 40 donne un bon compromis entre pouvoir liant et sucré.',
    'Par rapport au sirop de glucose-fructose (HFCS), ce sirop de glucose standard est moins sucré et a un indice glycémique plus bas. Comparé au sirop inverti, il cristallise moins facilement.',
    'Faible',
    array[]::text[],
    'Aucun. Surface collante.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Bidons hermétiques, à température ambiante. Protéger des températures extrêmes.',
    15, 35, false, false, 18, 'a_valider'
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
  (v_academie_id, 'Texturant et agent de corps en confiserie, sauces, glaces',
   'Ajouter 10 à 30 % du poids de sucre. Chauffer doucement pour fluidifier et faciliter l''incorporation.',
   'plage', 10, 30, '% du poids de sucre', 'Ambiante à 100 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Sirop de glucose-fructose (HFCS)
  -- ------------------------------------------------------------
  v_material_id := 'd71b3f30-090d-4282-be61-6dda642f6e54'::uuid;

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
    'Mélange de glucose et de fructose obtenu par isomérisation partielle du glucose',
    'HFCS, sirop de maïs haute teneur en fructose, isoglucose',
    'Alimentaire',
    'Liquide visqueux incolore à jaune pâle, inodore, très sucré',
    'Neutre à légèrement acide (5-6)',
    'Miscible à l''eau',
    1.38, null,
    'Sirop de glucose ayant subi une isomérisation pour convertir une partie du glucose en fructose. Teneur en fructose de 42 % à 55 % selon le grade. Très sucré, il retarde la cristallisation et améliore le moelleux. Utilisé dans les boissons gazeuses, confiseries, pâtisseries industrielles.',
    'Par rapport au sirop de glucose standard, il est plus sucré et plus hygroscopique. Comparé au sucre inverti, il a un ratio glucose/fructose similaire mais un coût plus bas.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Bidons hermétiques, à température ambiante. Protéger des températures extrêmes.',
    15, 35, false, false, 18, 'a_valider'
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
  (v_academie_id, 'Agent sucrant et texturant en boissons, pâtisseries, confitures industrielles',
   'Remplacer partiellement le saccharose (30-60 %). Ajouter directement dans la formulation.',
   'plage', 30, 60, '% du sucre total remplacé', 'Ambiante à 80 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Sorbitol (E420)
  -- ------------------------------------------------------------
  v_material_id := '3e5236fe-a0bd-4538-a102-0679a51b7b17'::uuid;

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
    'D-glucitol (C₆H₁₄O₆)',
    'Sorbitol, E420, polyol naturel, sirop de sorbitol',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche ou sirop visqueux incolore, inodore, saveur sucrée (60 % du saccharose), sensation rafraîchissante',
    'Neutre (5-7)',
    'Très soluble dans l''eau (235 g/100 mL à 20 °C), insoluble dans l''alcool',
    1.49, null,
    'Polyol le plus courant, présent dans de nombreux fruits. Excellente humectant et texturant. Utilisé en confiserie, dentifrice, cosmétique. Non cariogène, index glycémique bas (5). Peut provoquer un effet laxatif à des doses supérieures à 50 g/jour.',
    'Par rapport au xylitol, le sorbitol est moins sucré et a un effet rafraîchissant moins prononcé. Comparé au maltitol, il est plus hygroscopique et mieux adapté aux dentifrices.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Récipient étanche, au sec pour la poudre. Bidon hermétique pour le sirop.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Édulcorant de charge et humectant en confiserie, dentifrice, cosmétique',
   'Utiliser le sirop ou la poudre selon la texture désirée. Remplacer le sucre en ajustant le pouvoir sucrant avec des édulcorants intenses.',
   'texte_libre', null, null, 'Selon la recette (jusqu''à 100 % du sucre remplacé pour le volume)', 'Jusqu''à 160 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Stévia (Glycosides de stéviol E960)
  -- ------------------------------------------------------------
  v_material_id := '0da770af-3294-4d3b-b315-4b710e3a3821'::uuid;

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
    'Mélange de glycosides de stéviol (stévioside, rébaudioside A, etc.)',
    'Stevia, E960, édulcorant naturel, rébaudioside A',
    'Alimentaire, Cosmétique',
    'Poudre blanche à crème, odeur réglissée légère, saveur sucrée intense (200-300x le saccharose) avec un arrière-goût amer à haute dose',
    'Neutre (6-7 en solution)',
    'Soluble dans l''eau et les solutions hydroalcooliques',
    null, null,
    'Édulcorant naturel extrait des feuilles de Stevia rebaudiana. Stable à la chaleur et en milieu acide. Non calorigène, index glycémique nul. Le rébaudioside A est la forme la plus pure gustativement. DJA : 4 mg/kg de poids corporel (exprimé en équivalents stéviol).',
    'Par rapport aux édulcorants de synthèse, la stévia est naturelle mais peut avoir un arrière-goût de réglisse. Contrairement au sucralose, elle n''est pas un dérivé chloré et bénéficie d''une image plus saine auprès des consommateurs.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Récipient étanche, au sec, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Édulcorant naturel pour boissons, desserts, confiseries',
   'Dissoudre la quantité requise (quelques ppm) dans la phase aqueuse. Combiner avec des polyols pour apporter du volume.',
   'texte_libre', null, null, 'Selon le goût sucré désiré (0,01-0,05 % du produit fini)', 'Ambiante à 100 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Sucralose (E955)
  -- ------------------------------------------------------------
  v_material_id := '524e6fef-5725-434e-89ff-5997a79155bd'::uuid;

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
    '1,6-dichloro-1,6-didésoxy-β-D-fructofuranosyl-4-chloro-4-désoxy-α-D-galactopyranoside (C₁₂H₁₉Cl₃O₈)',
    'Sucralose, E955, édulcorant intense chloré',
    'Alimentaire',
    'Poudre cristalline blanche, inodore, saveur sucrée très intense (600x le saccharose), propre, sans amertume',
    'Neutre (6-7 en solution)',
    'Très soluble dans l''eau (28 g/100 mL à 20 °C), peu dans l''alcool',
    null, null,
    'Édulcorant dérivé du saccharose par chloration sélective. Très stable à la chaleur et en milieu acide. Excellente qualité gustative, sans arrière-goût. Non calorigène. DJA : 15 mg/kg de poids corporel.',
    'Par rapport à l''aspartame, le sucralose est stable à la cuisson et ne contient pas de phénylalanine. Comparé à la stévia, il n''a pas d''arrière-goût de réglisse et son pouvoir sucrant est bien supérieur.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts, chaleur excessive prolongée (> 120 °C en milieu alcalin).',
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
  (v_academie_id, 'Édulcorant de table et en formulation (boissons, produits laitiers, confitures)',
   'Utiliser à très faible dose (0,005-0,02 %). Dissoudre dans l''eau. Stable à la cuisson et à la congélation.',
   'plage', 0.005, 0.02, '% du produit fini', 'Ambiante à 120 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Taurine
  -- ------------------------------------------------------------
  v_material_id := '74dd2fc2-6814-4637-9233-496f85b713d4'::uuid;

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
    'Acide 2-aminoéthanesulfonique (C₂H₇NO₃S)',
    'Taurine, acide aminoéthylsulfonique, complément énergétique',
    'Alimentaire, Pharmaceutique',
    'Poudre cristalline blanche, inodore, saveur légèrement amère',
    'Neutre à légèrement acide (5-6)',
    'Très soluble dans l''eau (8 g/100 mL à 20 °C), insoluble dans l''alcool',
    1.73, null,
    'Acide aminé soufré, le plus abondant dans l''organisme. Impliqué dans la régulation osmotique, la contraction musculaire, et la détoxification. Populaire dans les boissons énergisantes (effet anti-oxydant et stabilisateur de membrane). Sans danger aux doses usuelles (DJA non fixée, jusqu''à 3 g/j considéré comme sûr).',
    'Par rapport à la caféine, la taurine n''est pas un stimulant mais un protecteur cellulaire. Souvent combinée dans les boissons énergisantes pour contrer les effets négatifs de la caféine.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver.',
    'Oxydants forts.',
    'Récipient étanche, au sec, à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Boissons énergisantes, compléments alimentaires',
   'Dissoudre 1000-4000 mg par litre de boisson énergisante. Ajouter dans la phase aqueuse.',
   'valeur_unique', 2000, 2000, 'mg par canette (250 mL)', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Tylose CMC (Pâtisserie décorative)
  -- ------------------------------------------------------------
  v_material_id := '31b53444-06ff-48a7-8232-6785aaabdaed'::uuid;

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
    'Carboxyméthylcellulose de sodium (E466), grade spécial pâtisserie',
    'CMC pâtissière, Tylose, gomme cellulosique, colle alimentaire',
    'Alimentaire',
    'Poudre blanche très fine, inodore, gonfle au contact de l''eau',
    '6-7,5 (solution à 1 %)',
    'Soluble dans l''eau froide, forme un gel visqueux et collant',
    0.75, null,
    'Gomme cellulosique spécifiquement formulée pour les usages de décoration en pâtisserie (pâte à sucre, fleurs en sucre, modelage). Elle apporte de la plasticité, de la résistance et accélère le séchage des pièces en pâte à sucre. Sans danger, utilisée à très faible dose (quelques grammes par kilo).',
    'Par rapport à la CMC standard (utilisée comme épaississant), la Tylose est un grade ultra-pur à haut pouvoir collant et filmogène, spécialement conçu pour le cake design.',
    'Faible',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger.',
    'Humidité (prise en masse), oxydants forts.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Colle alimentaire, durcisseur pour pâte à sucre, fleurs en sucre',
   'Diluer une petite quantité (1-2 g) dans un peu d''eau tiède pour obtenir une colle. Pour durcir la pâte à sucre, ajouter 1-2 g par kilo de pâte.',
   'valeur_unique', 2, 2, 'g par kg de pâte à sucre', 'Ambiante', 'Prise en 30 min, séchage complet 24 h', false, 0);

  -- ------------------------------------------------------------
  -- Vanilline de synthèse (éthylvanilline)
  -- ------------------------------------------------------------
  v_material_id := '93253128-5fd9-4289-b167-873a0914d238'::uuid;

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
    '3-éthoxy-4-hydroxybenzaldéhyde (C₉H₁₀O₃)',
    'Ethylvanillin, éthylvanilline, arôme vanille de synthèse',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche à jaune très pâle, odeur intense de vanille, beaucoup plus puissante que la vanilline (3-5x)',
    'Faiblement acide en solution',
    'Peu soluble dans l''eau (0,3 g/100 mL), très soluble dans l''alcool et les glycols',
    1.10, 145.0,
    'Dérivé de synthèse de la vanilline, possédant un groupe éthoxy au lieu de méthoxy. Arôme vanillé très puissant et stable à la chaleur. Utilisé en remplacement ou en complément de la vanilline pour renforcer la note vanillée. Largement employé dans la chocolaterie, la biscuiterie et les glaces.',
    'Par rapport à la vanilline (nature-identique), l''éthylvanilline est 3 à 5 fois plus puissante et a une note légèrement plus douce et crémeuse. Elle n''existe pas à l''état naturel.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Oxydants forts.',
    'Récipient étanche, au sec, à l''abri de la lumière et de la chaleur.',
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
  (v_academie_id, 'Arôme vanille pour pâtisserie, biscuiterie, chocolaterie, glaces',
   'Diluer dans un peu d''alcool ou de propylène glycol avant incorporation. Ajouter 10-50 ppm dans le produit fini. Résiste bien à la cuisson.',
   'plage', 10, 50, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 100 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Vitamines B3, B6, B12 (niacine, pyridoxine, cobalamine)
  -- ------------------------------------------------------------
  v_material_id := 'db83d59e-e31b-441f-ad89-1147ea237dac'::uuid;

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
    'B3 : nicotinamide (C₆H₆N₂O) ; B6 : chlorhydrate de pyridoxine (C₈H₁₁NO₃·HCl) ; B12 : cyanocobalamine (C₆₃H₈₈CoN₁₄O₁₄P)',
    'Vitamine B3, B6, B12 ; nicotinamide ; pyridoxine ; cobalamine',
    'Alimentaire, Cosmétique',
    'Poudres cristallines blanches à rouge foncé (B12), inodores',
    'Neutre (B3, B6) à neutre (B12)',
    'Très solubles dans l''eau (B3 > 100 g/100 mL ; B6 22 g/100 mL ; B12 1,25 g/100 mL)',
    null, null,
    'Ce combo regroupe trois vitamines du groupe B hydrosolubles : B3 (niacine) : essentielle au métabolisme énergétique et à la santé de la peau ; B6 (pyridoxine) : impliquée dans la synthèse des neurotransmetteurs et des globules rouges ; B12 (cobalamine) : indispensable à la formation des globules rouges et au fonctionnement du système nerveux. Utilisées en enrichissement nutritionnel (farines, céréales, boissons) et en cosmétique (soins capillaires, anti-âge). La B12 est sensible à la lumière.',
    'Par rapport aux autres vitamines B (B1, B2), elles agissent en synergie dans le métabolisme cellulaire. La B12 est la plus complexe et la seule à contenir un atome de cobalt.',
    'Faible',
    array['gants','masque'],
    'Gants et masque recommandés pour la manipulation des poudres pures, surtout la B12 qui peut colorer et est très active.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger aux doses nutritionnelles.',
    'Oxydants forts, bases fortes.',
    'Récipients étanches, au sec, à l''abri de la lumière (surtout B12). Conserver à température ambiante.',
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Enrichissement nutritionnel de farines, céréales, boissons, compléments alimentaires, cosmétiques',
   'Prémélanger les poudres de vitamines avec une partie de l''excipient (maltodextrine) pour faciliter la dispersion. Ajouter en phase aqueuse selon les doses nutritionnelles recommandées.',
   'texte_libre', null, null, 'Selon les apports journaliers recommandés (AJR) : B3 16 mg, B6 1,4 mg, B12 2,5 µg', 'Ambiante à 60 °C', 'Immédiat', false, 0);
end $$;
