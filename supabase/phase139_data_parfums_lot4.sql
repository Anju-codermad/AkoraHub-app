-- ============================================================
-- AkoraHub - Patch Phase 139 : fiches Académie pour le lot 4 (8
-- produits) des nouveaux produits "Parfums & Additifs" — contenu
-- DeepSeek, vérifié par l'utilisatrice.
-- L-cystéine documentée avec précision sur la variabilité d'origine
-- (synthétique, végétale par fermentation, ou historiquement issue
-- d'hydrolyse de kératine animale) à vérifier auprès du fournisseur.
-- Limonène D documenté avec avertissement sur l'oxydation à l'air
-- (formation d'allergènes de contact plus puissants).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Guanylate disodique (E627) / Acide guanylique (E626)
  -- ------------------------------------------------------------
  v_material_id := 'ba6337b6-9e94-4e6b-a42b-cca873fcbeb0'::uuid;

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
    '5''-guanylate de sodium (E627, C₁₀H₁₂N₅Na₂O₈P) et acide guanylique (E626, C₁₀H₁₄N₅O₈P)',
    'Disodium Guanylate, GMP, acide guanylique, exhausteur umami',
    'Alimentaire',
    'Poudre cristalline blanche, inodore, saveur umami intense, légèrement salée',
    '7-8 (solution à 1 %)',
    'Très soluble dans l''eau, peu soluble dans l''alcool, insoluble dans les huiles',
    null, null,
    'Sel de sodium du nucléotide guanosine monophosphate. Exhausteur de goût puissant, il renforce le goût umami et la saveur salée. Effet synergique très marqué avec le glutamate monosodique (E621) et l''inosinate (E631) : le mélange GMP/MSG potentialise jusqu''à 10 fois la perception du glutamate. Utilisé dans les snacks, soupes, bouillons, sauces.',
    'Par rapport à l''inosinate (E631), il est plus efficace sur la perception umami et est souvent utilisé en combinaison (mélange 50/50). Contrairement au glutamate, il n''est pas un acide aminé mais un nucléotide. Il est plus coûteux que le MSG mais s''utilise à plus faible dose.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter l''inhalation de poussières.',
    'Yeux : rincer à l''eau. Peau : laver. Ingestion sans danger.',
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
  (v_academie_id, 'Exhausteur de goût umami pour bouillons, snacks, sauces, soupes',
   'Ajouter 0,05-0,1 % en combinaison avec du MSG (ratio 1:10 à 1:20). Dissoudre dans la phase aqueuse. Stable à la cuisson.',
   'plage', 0.05, 0.1, '% du produit fini', 'Ambiante à 100 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Inosinate disodique (E631) / Acide inosinique (E630)
  -- ------------------------------------------------------------
  v_material_id := '6b5a74d5-e735-4de2-8021-9dccde02a8fd'::uuid;

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
    '5''-inosinate de sodium (E631, C₁₀H₁₁N₄Na₂O₈P) et acide inosinique (E630, C₁₀H₁₃N₄O₈P)',
    'Disodium Inosinate, IMP, acide inosinique, exhausteur umami',
    'Alimentaire',
    'Poudre cristalline blanche, inodore, saveur umami douce, légèrement salée',
    '7-8 (solution à 1 %)',
    'Très soluble dans l''eau, peu soluble dans l''alcool',
    null, null,
    'Sel de sodium du nucléotide inosine monophosphate. Exhausteur de goût umami, il renforce l''effet du glutamate monosodique (E621) de manière synergique. Souvent associé au guanylate (E627) dans un rapport 1:1. Utilisé dans les snacks, soupes, sauces, charcuteries.',
    'Par rapport au guanylate (E627), il est légèrement moins puissant seul, mais la combinaison des deux offre le meilleur rapport coût/efficacité. Contrairement au MSG, il n''apporte pas de saveur propre mais amplifie l''existant. Il est le nucléotide le plus utilisé.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter l''inhalation de poussières.',
    'Yeux : rincer à l''eau. Peau : laver. Ingestion sans danger.',
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
  (v_academie_id, 'Exhausteur de goût umami pour snacks, soupes, sauces, charcuteries',
   'Ajouter 0,05-0,1 % en combinaison avec du MSG (ratio 1:10 à 1:20) et éventuellement du guanylate. Dissoudre dans l''eau.',
   'plage', 0.05, 0.1, '% du produit fini', 'Ambiante à 100 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Iso E Super (tétraméthyl-acétyl-octahydronaphtalènes)
  -- ------------------------------------------------------------
  v_material_id := 'f17c4fe2-eaf1-4148-8002-7e7143998406'::uuid;

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
    '1-(2,3,8,8-tétraméthyl-1,2,3,4,5,6,7,8-octahydronaphtalén-1-yl)éthanone (mélange d''isomères)',
    'Iso E Super, OTNE, note boisée ambrée, fixateur synthétique',
    'Cosmétique (parfumerie), Technique',
    'Liquide incolore à jaune très pâle, odeur boisée, ambrée, veloutée, avec des nuances de cèdre et de musc',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau, miscible à l''alcool, aux huiles et aux solvants organiques',
    0.96, 110.0,
    'Matière première de parfumerie synthétique très répandue. Odeur boisée-amandée, très diffusible et rémanente. Utilisée comme fond boisé ou comme exhausteur de notes florales et ambrées. Faible coût, excellente stabilité. Suspectée d''être un sensibilisant cutané à très haute concentration, mais considérée comme sûre aux doses d''usage.',
    'Par rapport à l''ambroxide (ambre), l''Iso E Super est plus boisé et moins marin. Contrairement aux muscs, il a un caractère boisé-cèdre et non animal. C''est le pilier des compositions modernes minimalistes.',
    'Faible',
    array['gants','lunettes'],
    'Gants en nitrile, lunettes de sécurité. Éviter l''inhalation prolongée de vapeurs à chaud. Peut être irritant à l''état pur.',
    'Yeux : rincer 15 min. Peau : laver au savon. Ingestion : rincer la bouche, boire de l''eau.',
    'Oxydants forts.',
    'Bidon en métal ou verre, bien fermé, au frais, à l''abri de la lumière.',
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
  (v_academie_id, 'Note de fond boisée en parfumerie fine, cosmétique, savons',
   'Utiliser pur ou en solution dans la composition parfumée à 1-20 %. Excellent fixateur, s''accorde avec presque toutes les notes.',
   'plage', 1, 20, '% du concentré parfumé', 'Ambiante', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Isobutyrate d'éthyle (arôme fruits rouges)
  -- ------------------------------------------------------------
  v_material_id := '1ba117e0-3683-4d72-a3bb-5f78721d4004'::uuid;

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
    '2-méthylpropanoate d''éthyle (C₆H₁₂O₂)',
    'Ethyl isobutyrate, arôme fruits rouges, arôme fraise/framboise',
    'Alimentaire, Cosmétique',
    'Liquide incolore, très volatil, odeur fruitée intense de fraise des bois, framboise, bonbon anglais',
    'Neutre (très peu soluble dans l''eau)',
    'Très peu soluble dans l''eau, miscible à l''alcool et aux huiles',
    0.87, 7.0,
    'Ester de faible poids moléculaire, très volatil et très inflammable. Arôme fruité puissant, utilisé en combinaison avec d''autres esters pour créer des profils de fruits rouges (fraise, framboise, cerise). Apporte une note de tête fraîche et joyeuse.',
    'Par rapport à l''aldéhyde C16 (fraise, époxyde), il est plus naturel, plus volatil et moins sucré. Comparé à l''acétate d''éthyle (poire/banane), il a un profil spécifiquement fraise/framboise.',
    'Élevé',
    array['gants','lunettes','ventilation'],
    'Gants en nitrile, lunettes de sécurité. Très inflammable (point éclair < 10 °C) : manipuler loin des flammes et sources de chaleur. Travailler dans un espace bien ventilé.',
    'Inhalation : air frais. Peau : laver à l''eau. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas faire vomir, appeler un médecin.',
    'Oxydants forts, bases fortes (hydrolyse de l''ester).',
    'Bidon en métal ou verre, bien fermé, dans un local frais et ventilé, à l''écart des sources d''inflammation.',
    5, 25, false, false, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H225', 'H315', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P233', 'P261', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Arôme fruits rouges pour confiseries, glaces, sirops, boissons',
   'Diluer à 1-10 % dans de l''alcool ou du propylène glycol. Ajouter 5-50 ppm dans le produit fini. Incorporer en fin de cuisson si possible.',
   'plage', 5, 50, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 50 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Isomalt (E953)
  -- ------------------------------------------------------------
  v_material_id := 'ab787380-1a33-4eff-beda-b278a971167c'::uuid;

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
    'Mélange de 1-O-α-D-glucopyranosyl-D-mannitol dihydraté et de 6-O-α-D-glucopyranosyl-D-sorbitol dihydraté',
    'E953, Isomalt, édulcorant de charge, polyol',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche ou granulés, inodore, saveur sucrée pure (45-65 % du pouvoir sucrant du saccharose), sans arrière-goût',
    'Neutre (5-7 en solution aqueuse)',
    'Soluble dans l''eau (25 g/100 mL à 20 °C), insoluble dans l''alcool',
    1.45, null,
    'Polyol obtenu à partir du saccharose. Non cariogène, faible indice glycémique (2), bien toléré sur le plan digestif. Très résistant à la chaleur (jusqu''à 200 °C) et ne brunit pas. Utilisé en confiserie, pâtisserie, et comme agent de charge pour les comprimés.',
    'Par rapport au maltitol (E965), il est moins hygroscopique et plus résistant à la chaleur, ce qui le rend idéal pour les bonbons cuits. Contrairement à l''érythritol (E968), il a un pouvoir sucrant plus proche du sucre et ne provoque pas d''effet rafraîchissant intense.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter l''inhalation de poussières.',
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
  (v_academie_id, 'Édulcorant de charge pour confiserie, pâtisserie, bonbons sans sucre',
   'Utiliser en remplacement du sucre (ajuster le pouvoir sucrant avec des édulcorants intenses). Résiste à la cuisson jusqu''à 200 °C. Idéal pour les bonbons durs, les pastilles, les décors.',
   'texte_libre', null, null, 'Selon la recette (jusqu''à 100 % du sucre remplacé)', 'Jusqu''à 200 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- L-cystéine (E920)
  -- ------------------------------------------------------------
  v_material_id := 'fafb21f0-fcf7-40d7-b1e2-a7a41783b89d'::uuid;

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
    'Acide L-2-amino-3-mercaptopropionique (C₃H₇NO₂S)',
    'E920, L-cysteine, agent de traitement de la farine',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche, odeur caractéristique légèrement soufrée',
    '5-6 (solution aqueuse)',
    'Soluble dans l''eau (28 g/100 mL à 20 °C), insoluble dans les solvants organiques',
    1.30, null,
    'Acide aminé soufré utilisé comme agent de traitement de la farine (E920) pour améliorer l''extensibilité du gluten et réduire le temps de pétrissage. Également utilisé en cosmétique pour des soins capillaires (lissage brésilien) ou des crèmes antioxydantes. Origine : la L-cystéine de grade alimentaire peut être d''origine synthétique, végétale par fermentation, ou historiquement issue de l''hydrolyse de kératine animale (plumes de canard, poils de porc, cheveux). Les fournisseurs actuels privilégient largement les sources synthétiques ou végétales pour répondre aux exigences réglementaires et à la demande du marché (végan, casher, halal), mais l''origine doit être systématiquement vérifiée auprès du fournisseur avant achat.',
    'Contrairement au bisulfite de sodium (autre agent de panification), elle n''a pas d''action oxydante ou réductrice forte, elle rompt simplement les ponts disulfures. Par rapport à la méthionine (autre acide aminé soufré), elle n''est pas un donneur de méthyle mais un agent réducteur.',
    'Faible',
    array['masque'],
    'Porter un masque anti-poussière pour éviter l''inhalation de poudre soufrée. Éviter le contact avec les yeux.',
    'Yeux : rincer 15 min. Peau : laver. Ingestion : rincer la bouche, boire de l''eau.',
    'Oxydants forts, métaux lourds (chélation).',
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
  (v_academie_id, 'Agent de traitement de la farine en boulangerie industrielle',
   'Ajouter 1-3 g pour 100 kg de farine lors du pétrissage. Améliore la machinabilité et réduit le temps de pétrissage. Ne pas dépasser la dose autorisée.',
   'valeur_unique', 2, 2, 'g pour 100 kg de farine', 'Ambiante', 'Pendant le pétrissage', false, 0);

  -- ------------------------------------------------------------
  -- Lactitol (E966)
  -- ------------------------------------------------------------
  v_material_id := '5287d01f-4af9-4be7-8d54-25ea927f469a'::uuid;

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
    '4-O-β-D-galactopyranosyl-D-glucitol (C₁₂H₂₄O₁₁)',
    'E966, Lactitol, édulcorant polyol, sucre de lait hydrogéné',
    'Alimentaire, Cosmétique',
    'Poudre cristalline blanche, inodore, saveur sucrée propre (30-40 % du pouvoir sucrant du saccharose), légère sensation de fraîcheur',
    'Neutre (5-7 en solution aqueuse)',
    'Très soluble dans l''eau (55 g/100 mL à 20 °C), insoluble dans l''alcool',
    1.45, null,
    'Polyol obtenu par hydrogénation du lactose. Non cariogène, faible indice glycémique (< 5). Il a également des propriétés prébiotiques (favorise la croissance des bifidobactéries). Utilisé comme édulcorant de charge dans les produits sans sucre, les confiseries, les glaces et les pâtisseries. Peut provoquer un effet laxatif à des doses supérieures à 30 g/jour.',
    'Par rapport à l''isomalt (E953), il est plus soluble dans l''eau mais moins résistant à la chaleur. Contrairement au maltitol (E965), il a un pouvoir sucrant plus faible et des propriétés prébiotiques marquées.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter l''inhalation de poussières.',
    'Yeux : rincer. Peau : laver. Ingestion sans danger (effet laxatif à haute dose).',
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
  (v_academie_id, 'Édulcorant de charge et prébiotique en confiserie, glaces, pâtisserie',
   'Utiliser en remplacement du sucre (ajuster le pouvoir sucrant). Résiste à la cuisson jusqu''à 160 °C. Peut être combiné avec des édulcorants intenses.',
   'texte_libre', null, null, 'Selon la recette', 'Jusqu''à 160 °C', 'Immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Limonène D (d-limonène, arôme agrume)
  -- ------------------------------------------------------------
  v_material_id := '2a240b22-3abf-4828-815e-6e9c502c62f6'::uuid;

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
    '(R)-p-mentha-1,8-diène (C₁₀H₁₆)',
    'D-Limonene, Citrus Terpenes, arôme orange, essence d''orange',
    'Alimentaire, Cosmétique',
    'Liquide incolore à jaune très pâle, odeur intense et fraîche d''orange (zeste), légèrement boisée',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau, miscible à l''alcool, aux huiles et aux solvants organiques',
    0.84, 48.0,
    'Principal composant de l''huile essentielle d''orange (jusqu''à 95 %). Arôme agrume de référence, utilisé dans les boissons, confiseries, parfums et produits de nettoyage. Il s''oxyde lentement à l''air en formant des dérivés (limonène oxyde, carvone, etc.) qui sont des allergènes de contact plus puissants que le limonène frais. Pour limiter cette oxydation, il doit être stocké sous atmosphère inerte, à l''abri de l''air et de la lumière, et utilisé rapidement après ouverture.',
    'Par rapport au citral (arôme citron), le limonène D a une odeur d''orange plus douce et moins agressive. Contrairement à d''autres terpènes, il est très abondant dans les écorces d''agrumes. C''est également un excellent solvant dégraissant d''origine naturelle.',
    'Modéré',
    array['gants','lunettes','ventilation'],
    'Gants en nitrile, lunettes de sécurité. Travailler dans un endroit ventilé. Le produit oxydé est sensibilisant : vérifier la qualité avant usage et ne pas utiliser un produit qui a été exposé à l''air pendant une longue période.',
    'Inhalation : air frais. Peau : laver au savon. Yeux : rincer 15 min. Ingestion : ne pas faire vomir (risque de pneumonie d''inhalation), appeler immédiatement un médecin.',
    'Oxydants forts, acides forts. Attaque certains plastiques (polystyrène, caoutchouc).',
    'Bidon en acier inoxydable ou verre ambré, rempli à ras bord et fermé hermétiquement, à l''abri de l''air, de la lumière et de la chaleur. Idéalement sous atmosphère inerte (azote). Utiliser rapidement après ouverture.',
    5, 25, false, true, 12, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H226', 'H304', 'H315', 'H317', 'H319', 'H411')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P261', 'P264', 'P273', 'P280', 'P301+P310', 'P302+P352', 'P305+P351+P338', 'P331', 'P333+P313')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Arôme orange pour boissons gazeuses, confiseries, pâtisseries, glaces',
   'Diluer à 1-10 % dans de l''alcool ou un glycol. Ajouter 10-100 ppm dans le produit fini. Incorporer en fin de cuisson si possible.',
   'plage', 10, 100, 'ppm (mg/kg) dans le produit fini', 'Ambiante à 60 °C', 'Immédiat', false, 0),
  (v_academie_id, 'Parfumerie, cosmétique (notes hespéridées) et dégraissant écologique',
   'Utiliser pur ou en solution dans la composition parfumée à 0,5-5 %. Comme dégraissant, appliquer pur sur la surface, rincer.',
   'texte_libre', null, null, '0,5-5 % en parfumerie, ou pur en dégraissant', 'Ambiante', 'Immédiat', false, 1);
end $$;
