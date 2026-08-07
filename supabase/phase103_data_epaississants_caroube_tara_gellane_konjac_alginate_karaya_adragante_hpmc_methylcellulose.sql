-- ============================================================
-- AkoraHub - Patch Phase 103 : fiches Académie pour 9 des 10 nouveaux
-- épaississants — contenu DeepSeek, vérifié par l'utilisatrice.
-- Manque encore : Éthylcellulose (E462) — DeepSeek n'a pas fourni de
-- contenu pour ce produit dans ce lot, à redemander séparément.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Gomme de caroube (LBG, E410)
  -- ------------------------------------------------------------
  v_material_id := '68492b2e-5a60-4303-9ea3-fb94047f9f35'::uuid;

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
    'Galactomannane de caroube ((C₆H₁₀O₅)n)',
    'Gomme de caroube, LBG, farine de graines de caroube, E410',
    'Alimentaire',
    'Poudre blanche à crème, fine, inodore',
    '5,5-6,5 (dispersion à 1 %)',
    'Soluble dans l''eau chaude (80-90 °C) ; gonfle en dessous, forme un gel après chauffage et refroidissement, surtout en synergie avec la xanthane ou la carraghénane',
    0.80, null,
    'Densité apparente de la poudre. Seule, elle donne une solution visqueuse mais gélifie uniquement en présence d''autres gommes (xanthane, carraghénane). Synergie très marquée avec la gomme xanthane (gel élastique).',
    'Contrairement à la gomme guar, la LBG nécessite une cuisson pour s''hydrater complètement et donne des gels plus fermes en combinaison avec la xanthane. Moins soluble à froid que le guar, mais plus stable aux cycles gel-dégel.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Masque anti-poussière recommandé pour les manipulations de grandes quantités.',
    'Yeux : rincer à l''eau. Peau : laver. Ingestion sans danger.',
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Glaces et crèmes glacées (anti-cristallisation)',
   'Mélanger à sec avec le sucre avant de disperser dans le lait chaud (80-85 °C), pasteuriser, refroidir et turbiner.',
   'valeur_unique', 0.2, 0.5, '% du poids total', '80-85 °C (hydratation)', '10-15 min de chauffage', false, 0),
  (v_academie_id, 'Stabilisant de crèmes dessert et sauces (synergie avec xanthane)',
   'Disperser le mélange LBG/xanthane (ratio 1:1 à 4:1) dans la phase aqueuse chaude, agiter jusqu''à épaississement.',
   'plage', 0.1, 0.5, '% du produit fini', '80-90 °C', '10 min', false, 1);

  -- ------------------------------------------------------------
  -- Gomme Tara (E417)
  -- ------------------------------------------------------------
  v_material_id := '950ab370-b643-480e-9c96-3d48e3b161fa'::uuid;

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
    'Galactomannane de tara',
    'Gomme Tara, E417, Caesalpinia spinosa gum',
    'Alimentaire',
    'Poudre blanche à beige, fine',
    '5-7 (dispersion à 1 %)',
    'Soluble dans l''eau chaude, partiellement soluble à froid. Synergie avec la gomme xanthane et la carraghénane.',
    0.80, null,
    'Galactomannane proche de la gomme de caroube, mais avec un ratio mannose/galactose différent, ce qui lui confère une meilleure solubilité à froid et une synergie encore plus forte avec la xanthane.',
    'Par rapport à la gomme de caroube (LBG), la gomme tara s''hydrate mieux à froid et donne des gels plus élastiques avec la xanthane. Remplace souvent la LBG dans les glaces pour un coût inférieur.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire.',
    'Yeux : rincer à l''eau.',
    'Aucune notable.',
    'Récipient étanche, au sec.',
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
  (v_academie_id, 'Stabilisant de glaces et sorbets',
   'Mélanger à sec avec le sucre, disperser dans le lait ou l''eau à 80 °C, refroidir et turbiner.',
   'valeur_unique', 0.2, 0.4, '% du poids total', '80 °C', '10 min', false, 0);

  -- ------------------------------------------------------------
  -- Gomme gellane (E418)
  -- ------------------------------------------------------------
  v_material_id := 'e0833564-5db7-424e-a135-8ae79b7ce6db'::uuid;

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
    'Gomme gellane ((C₁₂H₁₈O₁₁)n)',
    'Gellan gum, E418, gellane',
    'Alimentaire',
    'Poudre blanche à crème, fine',
    '5-6 (dispersion à 1 %)',
    'Soluble dans l''eau chaude (85-90 °C). Forme un gel transparent et ferme en refroidissant, renforcé par les cations (calcium, magnésium).',
    0.80, null,
    'Produit des gels très transparents et thermoréversibles (type low acyl). Existe en version high acyl (gels mous et élastiques) et low acyl (gels fermes et cassants).',
    'Comparé à l''agar-agar, le gel de gellane est plus transparent et moins sensible à la synérèse. Par rapport à la gélatine, il gélifie à plus basse concentration et supporte des températures plus élevées sans fondre.',
    'Aucun',
    array[]::text[],
    'Aucun obligatoire.',
    'Yeux : rincer. Peau : laver.',
    'Aucune notable.',
    'Récipient étanche, au sec.',
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
  (v_academie_id, 'Gels transparents pour desserts végétaux ou boissons',
   'Disperser 0,3-0,5 % de gellane dans l''eau froide, chauffer à 85-90 °C, ajouter 0,05-0,1 % de chlorure de calcium, refroidir pour gélifier.',
   'valeur_unique', 0.4, 0.5, '% du liquide', '85-90 °C (dissolution)', 'Refroidissement pour gel', false, 0);

  -- ------------------------------------------------------------
  -- Gomme de konjac (E425)
  -- ------------------------------------------------------------
  v_material_id := '59585dbd-b264-4c16-b6e8-cf9b2fc36592'::uuid;

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
    'Glucomannane ((C₆H₁₀O₅)n)',
    'Gomme de konjac, E425, farine de konjac',
    'Alimentaire',
    'Poudre blanche à crème, fine',
    '5-7 (dispersion à 1 %)',
    'Gonfle dans l''eau froide, nécessite chauffage (85 °C) pour une hydratation complète et une viscosité maximale. Forme un gel thermostable, surtout en milieu alcalin.',
    0.85, null,
    'Capacité d''absorption d''eau exceptionnelle (jusqu''à 200 fois son poids). Forme des gels fermes et élastiques, utilisés pour les nouilles shirataki ou les perles de konjac.',
    'Comparé à la gomme de caroube, le konjac gonfle beaucoup plus et donne des gels plus fermes sans synergie. Souvent utilisé avec de l''eau de chaux (hydroxyde de calcium) pour former des gels irréversibles.',
    'Aucun',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer.',
    'Acides forts.',
    'Récipient étanche, au sec.',
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
  (v_academie_id, 'Gels vegan et nouilles shirataki',
   'Disperser 3-5 % de konjac dans l''eau, ajouter une solution alcaline (hydroxyde de calcium), chauffer pour former un gel. Façonner les nouilles puis rincer.',
   'valeur_unique', 4, null, '% dans l''eau', '85-90 °C', '20-30 min', false, 0),
  (v_academie_id, 'Épaississant pour masques cosmétiques peel-off',
   'Mélanger 1-2 % de konjac avec des agents filmogènes (PVA) pour obtenir une texture gélifiée applicable en couche.',
   'valeur_unique', 1.5, null, '% du masque', 'Ambiante', 'Hydratation 30 min', false, 1);

  -- ------------------------------------------------------------
  -- Alginate de sodium (E401)
  -- ------------------------------------------------------------
  v_material_id := '587a388f-dc9b-4c35-94c0-d88846ea35b5'::uuid;

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
    'Alginate de sodium ((C₆H₇NaO₆)n)',
    'E401, alginate, sel de sodium de l''acide alginique',
    'Alimentaire',
    'Poudre fibreuse ou granulée, blanche à jaune pâle, inodore',
    '6-8 (solution à 1 %)',
    'Soluble dans l''eau froide ou chaude, forme un gel irréversible en présence de cations calcium (Ca²⁺)',
    0.80, null,
    'Gélifiant à froid en présence de calcium, ne nécessite pas de chauffage. Forme des gels thermostables (ne fondent pas à la chaleur).',
    'Contrairement à la gélatine, il gélifie à froid et le gel est thermoirréversible. Par rapport à la pectine, il est moins sensible au pH et ne nécessite pas de sucre pour gélifier.',
    'Aucun',
    array[]::text[],
    'Masque anti-poussière pour les manipulations de poudre en grande quantité.',
    'Yeux : rincer. Peau : laver.',
    'Cations calcium (gélification instantanée), acides forts.',
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
  (v_academie_id, 'Sphérification directe (perles aromatiques)',
   'Préparer un bain de chlorure de calcium (0,5-1 %). Dissoudre l''alginate dans le liquide à sphérifier (0,5-1 %). Verser goutte à goutte dans le bain calcique.',
   'valeur_unique', 0.5, 1, '% du liquide à sphérifier', 'Ambiante', 'Quelques secondes (bain calcique)', false, 0),
  (v_academie_id, 'Épaississant pour impression textile (technique)',
   'Dissoudre 2-4 % d''alginate dans l''eau, mélanger avec les pigments pour obtenir une pâte d''impression.',
   'plage', 2, 4, '% de la pâte d''impression', 'Ambiante', 'Hydratation 1-2 h', false, 1);

  -- ------------------------------------------------------------
  -- Gomme karaya (E416)
  -- ------------------------------------------------------------
  v_material_id := '9d804f59-ed14-42b3-9831-2fa09bff5173'::uuid;

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
    'Gomme karaya (mélange de polysaccharides)',
    'Gomme de Sterculia, E416',
    'Alimentaire',
    'Poudre beige à brun clair',
    '5-6 (dispersion)',
    'Gonfle dans l''eau froide pour former un gel visqueux, ne se dissout pas complètement.',
    0.85, null,
    'Exsudat végétal à fort pouvoir adhésif et épaississant, très économique. Utilisée dans les pâtes à prothèses dentaires et les sauces.',
    'Comparée à la gomme adragante, la gomme karaya est moins chère et a un pouvoir adhésif plus important, mais sa viscosité est moins stable en milieu acide.',
    'Aucun',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer.',
    'Aucune notable.',
    'Récipient étanche, au sec.',
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
    dosage_texte, temperature_utilisation, temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Adhésif pour prothèses dentaires',
   'Mélanger la gomme karaya avec de l''eau pour former une pâte adhésive appliquée sur la prothèse.',
   'texte_libre', 'Quantité suffisante pour une pâte', 'Ambiante', 'Application', false, 0);

  -- ------------------------------------------------------------
  -- Gomme adragante (E413)
  -- ------------------------------------------------------------
  v_material_id := 'd5dd4f07-95aa-48d8-bf33-9d74c3e00ecb'::uuid;

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
    'Gomme adragante (mélange complexe de polysaccharides)',
    'Gomme tragacanthe, E413, gomme de dragon',
    'Alimentaire',
    'Poudre blanche à crème, ou rubans',
    '5-6 (dispersion à 1 %)',
    'Gonfle dans l''eau froide pour former un gel visqueux. Partiellement soluble. Résistante aux acides.',
    0.80, null,
    'Exsudat végétal très ancien, excellente stabilité en milieu acide et sur une large plage de température. Utilisée en confiserie et pour les décors en sucre.',
    'Comparée à la gomme arabique, la gomme adragante est plus épaississante et moins soluble. Irremplaçable en pâtisserie fine (pâte à sucre, fleurs en sucre).',
    'Aucun',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer.',
    'Aucune.',
    'Récipient étanche, au sec.',
    5, 30, true, false, 60, 'a_valider'
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
    dosage_min, unite_dosage, temperature_utilisation, temps_action,
    a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Pâte à sucre et fleurs en sucre (cake design)',
   'Mélanger la gomme adragante en poudre (1-5 %) avec du sucre glace et un peu d''eau pour former une pâte modelable et résistante.',
   'valeur_unique', 3, '% du poids du sucre', 'Ambiante', 'Pétrissage', false, 0);

  -- ------------------------------------------------------------
  -- HPMC (hydroxypropylméthylcellulose, E464)
  -- ------------------------------------------------------------
  v_material_id := 'b12aa2d8-452c-4f95-b23f-b36c3d11f797'::uuid;

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
    'Hydroxypropylméthylcellulose ((C₁₀H₁₈O₆)n)',
    'HPMC, E464, hypromellose',
    'Alimentaire',
    'Poudre blanche à blanc cassé, granuleuse',
    '5-8 (solution à 1 %)',
    'Dispersible dans l''eau froide, soluble à chaud (gel thermique réversible : gélifie à chaud, redevient liquide en refroidissant)',
    0.50, null,
    'Densité apparente. Seul éther de cellulose qui gélifie à chaud (60-90 °C) et redevient fluide en refroidissant. Idéal pour des applications de cuisson vegan (substitut d''œuf).',
    'Contrairement à la méthylcellulose (MC), l''HPMC a une température de gélification plus basse. Apporte une texture unique de "gel à chaud" utilisée dans les préparations culinaires vegan.',
    'Aucun',
    array[]::text[],
    'Masque anti-poussière recommandé.',
    'Yeux : rincer. Inhalation : air frais.',
    'Oxydants forts.',
    'Récipient étanche, au sec.',
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
  (v_academie_id, 'Substitut d''œuf vegan (pâtisserie)',
   'Disperser 2 % d''HPMC dans l''eau froide, chauffer : le gel formé apporte de la texture. Utilisé dans les muffins, cakes.',
   'valeur_unique', 2, null, '% du poids du liquide', '60-80 °C (gélification)', 'Quelques minutes', false, 0),
  (v_academie_id, 'Colle à papier peint (technique)',
   'Dissoudre 2-3 % d''HPMC dans l''eau froide, laisser gonfler, appliquer.',
   'valeur_unique', 2.5, null, '% de l''eau', 'Ambiante', '30 min de gonflement', false, 1);

  -- ------------------------------------------------------------
  -- Méthylcellulose (E461)
  -- ------------------------------------------------------------
  v_material_id := '68b06038-b02f-4f63-bdbc-ec28465d0521'::uuid;

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
    'Méthylcellulose ((C₇H₁₂O₅)n)',
    'MC, E461, méthylcellulose',
    'Alimentaire',
    'Poudre blanche à crème',
    '5-7 (solution à 1 %)',
    'Dispersible dans l''eau froide, se dissout en refroidissant. Gélifie à chaud (50-70 °C) et redevient liquide en refroidissant.',
    0.55, null,
    'Comportement thermogélifiant inverse : gélifie à chaud. Utilisé pour les préparations devant tenir à la cuisson.',
    'Comparé à l''HPMC, la MC a une température de gélification plus basse (50-70 °C) et est moins chère. Choix classique pour les gels chauds en cuisine moléculaire.',
    'Aucun',
    array[]::text[],
    'Aucun.',
    'Yeux : rincer.',
    'Aucune.',
    'Récipient étanche, au sec.',
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
  (v_academie_id, 'Cuisine moléculaire (gel chaud)',
   'Disperser 2 % de MC dans l''eau froide, laisser hydrater, puis chauffer pour gélifier. Utilisé pour des "spaghettis" chauds ou des mousses chaudes.',
   'valeur_unique', 2, null, '% du liquide', '50-70 °C (gélification)', 'Quelques minutes', false, 0);
end $$;
