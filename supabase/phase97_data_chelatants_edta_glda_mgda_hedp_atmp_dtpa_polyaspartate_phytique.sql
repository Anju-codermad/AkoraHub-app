-- ============================================================
-- AkoraHub - Patch Phase 97 : fiches Académie pour 9 des 12
-- chélatants du catalogue — contenu DeepSeek, vérifié par
-- l'utilisatrice. Manquent encore : Gluconate de sodium (E576),
-- DTPMPA (lot suivant).
--
-- "EDTA disodique" appliqué à 2 variantes catalogue : "EDTA /
-- Sequestrant" (nom générique) et "EDTA disodique (E385)" — DeepSeek
-- n'a fourni qu'une fiche disodique + une tétrasodique, le nom
-- générique est donc rattaché à la forme la plus courante (disodique).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  r record;
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- EDTA disodique — 2 variantes catalogue ("EDTA / Sequestrant" +
  -- "EDTA disodique (E385)")
  -- ------------------------------------------------------------
  for r in
    select * from (values
      ('45f87cb1-a4b7-4da8-90c5-e1d37835b120'::uuid), -- EDTA / Sequestrant
      ('3f15d768-ce4c-4e94-9dfe-d00613ed9468'::uuid)  -- EDTA disodique (E385)
    ) as t(material_id)
  loop
    insert into public.matieres_premieres_academie (
      matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
      ph_solution, solubilite, densite, point_eclair, particularite,
      difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
      premiers_secours, incompatibilites, consignes_stockage,
      temperature_stockage_min, temperature_stockage_max,
      sensible_humidite, sensible_lumiere, duree_conservation_mois,
      statut_verification
    ) values (
      r.material_id,
      'Éthylènediaminetétraacétate de sodium, sel disodique (C₁₀H₁₄N₂Na₂O₈·2H₂O)',
      'EDTA disodique, EDTA Na₂, complexon III, Titriplex III',
      'Technique',
      'Poudre cristalline blanche, inodore',
      '4-5 (solution à 1 %)',
      'Très soluble dans l''eau (10 g/100 mL à 20 °C)',
      1.01, null,
      'Densité de la solution commerciale à 40 %. Le sel disodique est la forme la plus courante pour les usages domestiques et artisanaux, bien plus soluble que l''acide libre.',
      'Contrairement à l''EDTA tétrasodique (pH 10-11), le sel disodique a un pH acide et sert plutôt à stabiliser des formules acides ou neutres.',
      'Modéré',
      array['gants','lunettes'],
      'Gants en nitrile, éviter l''inhalation de poussières.',
      'Yeux : rincer 15 min. Peau : laver à l''eau. Ingestion : rincer la bouche, boire de l''eau. Inhalation : air frais.',
      'Acides forts (dégagement de vapeurs nitreuses), métaux lourds (complexation).',
      'Récipient étanche, au sec, à température ambiante.',
      5, 30, false, false, 36, 'a_valider'
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
    select v_academie_id, id from public.phrases_h where code in ('H319', 'H332')
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
    (v_academie_id, 'Cosmétique (stabilisant, booster de conservation)',
     'Incorporer dans la phase aqueuse à 0,1-0,5 % pour chélater les ions métalliques et renforcer l''efficacité des conservateurs.',
     'plage', 0.1, 0.5, '% du produit fini', 'Ambiante', 'Dissolution immédiate', false, 0),
    (v_academie_id, 'Nettoyant anticalcaire (salle de bain, WC)',
     'Ajouter 1-2 % dans une formulation acide ou neutre pour dissoudre les dépôts de savon calcique et le tartre léger.',
     'valeur_unique', 1.5, null, '% du produit', '20-40 °C', '10-15 min', false, 1);
  end loop;

  -- ------------------------------------------------------------
  -- EDTA tétrasodique (Na₄EDTA)
  -- ------------------------------------------------------------
  v_material_id := 'd9fcaecd-35a1-48ee-8398-e8920889b1a7'::uuid;

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
    'Éthylènediaminetétraacétate de sodium, sel tétrasodique (C₁₀H₁₂N₂Na₄O₈)',
    'EDTA tétrasodique, EDTA Na₄, complexon IV',
    'Technique',
    'Poudre blanche à légèrement jaunâtre, hygroscopique',
    '10-11 (solution à 1 %)',
    'Très soluble (60 g/100 mL à 20 °C)',
    0.80, null,
    'Densité apparente de la poudre. Forme la plus alcaline de l''EDTA, idéale pour les formulations à pH élevé.',
    'Contrairement au sel disodique, il est utilisé dans les détergents alcalins et les savons liquides pour piéger le calcium sans baisser le pH.',
    'Modéré',
    array['gants','lunettes','masque'],
    'Gants nitrile, éviter les poussières, ventiler.',
    'Yeux : rincer 15 min. Peau : laver à l''eau. Ingestion : boire de l''eau, ne pas faire vomir. Inhalation : air frais.',
    'Acides forts, sels métalliques acides.',
    'Récipient hermétique, au sec, à température ambiante.',
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
  select v_academie_id, id from public.phrases_h where code in ('H319', 'H315', 'H335')
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
  (v_academie_id, 'Savonnerie (adoucissement de l''eau de process)',
   'Ajouter 0,2-0,5 % dans la solution de soude avant mélange pour éviter les précipités de savon calcique dans les savons liquides.',
   'valeur_unique', 0.3, null, '% du poids de la solution de soude', '40-50 °C', 'Incorporation immédiate', false, 0),
  (v_academie_id, 'Détergent lessive liquide',
   'Incorporer 1-3 % dans la formulation pour séquestrer les ions calcium et magnésium de l''eau de lavage.',
   'plage', 1, 3, '% du produit fini', 'Ambiante', 'Agitation jusqu''à dissolution', false, 1);

  -- ------------------------------------------------------------
  -- GLDA
  -- ------------------------------------------------------------
  v_material_id := '44a21438-f847-4d5d-b386-2a3a06dd3055'::uuid;

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
    'Acide glutamique diacétique, sel tétrasodique (C₉H₁₃NO₈Na₄)',
    'GLDA, Dissolvine GL, chélatant vert',
    'Cosmétique',
    'Liquide clair jaune pâle (solution à 38-40 %)',
    '11-12 (solution commerciale)',
    'Totalement miscible à l''eau',
    1.30, null,
    'Densité de la solution commerciale à 40 %. Chélatant biodégradable issu de matières premières végétales, certifié Ecocert/COSMOS.',
    'Alternative "verte" à l''EDTA, biodégradable à plus de 80 % en 28 jours, aussi efficace à pH neutre et alcalin.',
    'Modéré',
    array['gants','lunettes'],
    'Gants en caoutchouc, lunettes de sécurité, éviter le contact prolongé.',
    'Yeux : rincer 15 min. Peau : laver à l''eau. Ingestion : rincer la bouche, boire de l''eau.',
    'Acides forts, agents oxydants.',
    'Bidon en PEHD bien fermé, à l''abri du gel.',
    5, 35, false, false, 12, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Cosmétique naturelle (shampoing, gel douche)',
   'Ajouter en phase aqueuse à 0,1-0,5 % pour améliorer la mousse et la conservation en piégeant le calcium.',
   'valeur_unique', 0.3, null, '% du produit fini', 'Ambiante', 'Incorporation immédiate', false, 0),
  (v_academie_id, 'Détergent écologique (liquide vaisselle, nettoyant multi-usage)',
   'Incorporer 1-2 % dans la formulation, compatible avec les tensioactifs anioniques et non ioniques.',
   'plage', 1, 2, '% du produit', 'Ambiante', 'Agitation jusqu''à homogénéité', false, 1);

  -- ------------------------------------------------------------
  -- MGDA
  -- ------------------------------------------------------------
  v_material_id := 'b53e9d13-4155-4ef3-8e9d-d3474008e2f4'::uuid;

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
    'Acide méthylglycinediacétique, sel trisodique (C₅H₈NNa₃O₆)',
    'MGDA, Trilon M, Dissolvine M',
    'Cosmétique',
    'Liquide clair incolore à jaune pâle (solution à 40 %) ou granulés blancs',
    '11-12 (solution commerciale)',
    'Totalement miscible à l''eau',
    1.31, null,
    'Densité de la solution commerciale à 40 %. Excellent chélatant biodégradable, stable en milieu fortement alcalin et oxydant (chlore, eau oxygénée).',
    'Plus performant que le GLDA en milieu très alcalin et en présence d''eau de Javel ; idéal pour les détergents lave-vaisselle et lessives.',
    'Modéré',
    array['gants','lunettes'],
    'Gants nitrile, lunettes de sécurité.',
    'Yeux : rincer 15 min. Peau : laver. Ingestion : boire de l''eau.',
    'Acides forts.',
    'Bidon en PEHD fermé, température ambiante, éviter le gel.',
    5, 35, false, false, 12, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Détergent lave-vaisselle automatique (poudre ou liquide)',
   'Incorporer 10-20 % dans la formulation pour séquestrer le calcium et empêcher les dépôts sur la vaisselle.',
   'plage', 10, 20, '% du produit', 'Ambiante', 'Mélange à sec ou en solution', true, 0),
  (v_academie_id, 'Lessive écologique liquide',
   'Ajouter 1-3 % dans la lessive pour améliorer le lavage en eau dure et réduire la dose de tensioactifs.',
   'plage', 1, 3, '% du produit fini', 'Ambiante', 'Agitation jusqu''à dissolution', false, 1);

  -- ------------------------------------------------------------
  -- HEDP (acide étidronique)
  -- ------------------------------------------------------------
  v_material_id := '36e52f0f-809a-497c-bb0b-a241b3646957'::uuid;

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
    'Acide 1-hydroxyéthylidène-1,1-diphosphonique (C₂H₈O₇P₂)',
    'HEDP, étidronate, acide étidronique',
    'Technique',
    'Liquide clair incolore à jaune pâle (solution aqueuse à 60 %)',
    '<2 (solution concentrée)',
    'Totalement miscible à l''eau',
    1.45, null,
    'Densité de la solution commerciale à 60 %. Phosphonate stable au chlore, très utilisé pour le traitement de l''eau et les formulations détergentes.',
    'Contrairement à l''ATMP, il présente une meilleure stabilité hydrolytique et est plus efficace pour inhiber la corrosion dans les circuits de refroidissement.',
    'Corrosif',
    array['gants','lunettes','ventilation','tablier'],
    'Gants en caoutchouc butyle, écran facial, travailler sous hotte.',
    'Peau : rincer 15 min, retirer vêtements. Yeux : rincer 15 min. Ingestion : rincer bouche, ne pas vomir, appeler médecin.',
    'Bases fortes, agents oxydants, hypochlorite de sodium (eau de Javel) à haute concentration.',
    'Bidon en PEHD ou acier inoxydable, local ventilé, à l''écart des bases.',
    5, 35, false, false, 24, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H314')
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
  (v_academie_id, 'Traitement antitartre pour tours de refroidissement',
   'Diluer dans l''eau d''appoint à raison de 5-15 ppm (g/m³) pour inhiber la formation de tartre et la corrosion.',
   'plage', 5, 15, 'g/m³ d''eau', 'Ambiante à 80 °C', 'Action continue', true, 0),
  (v_academie_id, 'Produit de rinçage lave-vaisselle professionnel',
   'Formuler 10-30 % de HEDP avec des tensioactifs non ioniques pour un rinçage sans traces.',
   'plage', 10, 30, '% de la solution de rinçage', '60-85 °C', 'Quelques secondes', false, 1);

  -- ------------------------------------------------------------
  -- ATMP
  -- ------------------------------------------------------------
  v_material_id := 'fad24020-48ff-4524-b6cf-f09dc1027128'::uuid;

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
    'Acide aminotriméthylènephosphonique (C₃H₁₂NO₉P₃)',
    'ATMP, acide nitrilotriméthylènephosphonique',
    'Technique',
    'Liquide clair incolore à jaune pâle (solution à 50 %)',
    '<2 (solution concentrée)',
    'Totalement miscible à l''eau',
    1.33, null,
    'Densité de la solution commerciale à 50 %. Phosphonate économique, très efficace pour inhiber le tartre carbonaté et sulfaté.',
    'Moins cher que l''HEDP mais moins stable à haute température et en présence d''oxydants forts ; souvent utilisé dans les formulations antitartre basiques.',
    'Corrosif',
    array['gants','lunettes','tablier'],
    'Gants en caoutchouc, écran facial, éviter les projections.',
    'Peau : rincer 15 min. Yeux : rincer 15 min. Ingestion : rincer bouche, ne pas vomir.',
    'Agents oxydants forts, bases fortes.',
    'Bidon en plastique, local ventilé, à l''écart des alcalis.',
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
  select v_academie_id, id from public.phrases_h where code in ('H314')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P280', 'P301+P330+P331', 'P305+P351+P338', 'P310')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Antitartre pour circuit d''eau industrielle',
   'Doser en continu à 2-10 ppm dans l''eau d''appoint pour prévenir les dépôts de carbonate de calcium.',
   'plage', 2, 10, 'g/m³', '20-60 °C', 'Action préventive permanente', true, 0);

  -- ------------------------------------------------------------
  -- Polyaspartate de sodium
  -- ------------------------------------------------------------
  v_material_id := 'a2a0c84f-287b-4dc0-b60d-dc1747ce4ace'::uuid;

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
    'Polyaspartate de sodium ((C₄H₅NO₃Na)n)',
    'PASP, polyaspartate',
    'Technique',
    'Liquide visqueux ambré (solution à 30-40 %)',
    '9-10 (solution commerciale)',
    'Totalement miscible à l''eau',
    1.20, null,
    'Densité de la solution commerciale à 35 %. Polymère biodégradable d''acide aspartique, utilisé comme dispersant et anticalcaire vert.',
    'Alternative biodégradable aux polyacrylates ; chélate modérément mais disperse très bien les particules minérales.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire, mais éviter le contact prolongé.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Acides forts, oxydants.',
    'Bidon en plastique, à l''abri du gel.',
    5, 35, false, false, 12, 'a_valider'
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
  (v_academie_id, 'Détergent écologique (anticalcaire, dispersant)',
   'Ajouter 1-5 % dans la formule pour éviter la reprécipitation du tartre et améliorer le rinçage.',
   'plage', 1, 5, '% du produit', 'Ambiante', 'Incorporation directe', false, 0);

  -- ------------------------------------------------------------
  -- Acide phytique (E391)
  -- ------------------------------------------------------------
  v_material_id := '500e1489-8453-4660-80d7-e536468c40e3'::uuid;

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
    'Acide phytique (C₆H₁₈O₂₄P₆)',
    'Phytate, acide inositol hexaphosphorique, E391',
    'Cosmétique',
    'Liquide sirupeux jaune pâle à brun clair (solution aqueuse à 50 %)',
    '<2 (solution concentrée)',
    'Totalement miscible à l''eau',
    1.30, null,
    'Densité de la solution commerciale à 50 %. Chélatant naturel extrait du son de riz, antioxydant et exfoliant doux.',
    '100 % naturel, contrairement aux aminopolycarboxylates de synthèse ; très efficace pour chélater le fer et le cuivre, mais moins pour le calcium.',
    'Modéré',
    array['gants','lunettes'],
    'Gants nitrile, éviter le contact avec les yeux (acide).',
    'Yeux : rincer 15 min. Peau : laver. Ingestion : boire de l''eau.',
    'Bases fortes, métaux alcalins.',
    'Flacon en verre ou PEHD, à l''abri de la lumière, au frais.',
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Cosmétique naturel (peeling, antioxydant)',
   'Ajouter 0,5-2 % dans la phase aqueuse d''un sérum ou d''une lotion, ajuster le pH final à 4-5.',
   'plage', 0.5, 2, '% du produit', 'Ambiante', 'Incorporation à froid', true, 0);

  -- ------------------------------------------------------------
  -- DTPA
  -- ------------------------------------------------------------
  v_material_id := '80323c27-545c-445f-ae3a-ee52e0811716'::uuid;

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
    'Acide diéthylènetriaminepentaacétique, sel pentasodique (C₁₄H₁₈N₃Na₅O₁₀)',
    'DTPA, DTPA pentasodique',
    'Technique',
    'Liquide clair jaune pâle (solution à 40 %)',
    '11-12 (solution commerciale)',
    'Totalement miscible à l''eau',
    1.30, null,
    'Densité de la solution à 40 %. Très fort chélatant pour métaux lourds, spécialisé dans le blanchiment de pâte et le traitement d''eaux très dures.',
    'Plus puissant que l''EDTA pour le fer et le manganèse, mais plus cher et moins biodégradable.',
    'Modéré',
    array['gants','lunettes'],
    'Gants nitrile, lunettes de sécurité.',
    'Yeux : rincer 15 min. Peau : laver. Ingestion : boire de l''eau.',
    'Acides forts, oxydants puissants.',
    'Bidon en PEHD, température ambiante, éviter le gel.',
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
  select v_academie_id, id from public.phrases_h where code in ('H315', 'H319')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p where code in ('P264', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Blanchiment du bois / pâte à papier (artisanat)',
   'Ajouter 0,2-0,5 % dans le bain de blanchiment (peroxyde d''hydrogène) pour stabiliser et éviter la décomposition par les métaux.',
   'valeur_unique', 0.3, null, '% du bain', '50-70 °C', '30-60 min', true, 0);
end $$;
