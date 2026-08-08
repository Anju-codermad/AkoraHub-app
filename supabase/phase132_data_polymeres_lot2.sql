-- ============================================================
-- AkoraHub - Patch Phase 132 : fiches Académie pour le lot 2 (7
-- silicones, résines filmogènes et résines de casting) des nouveaux
-- produits "Polymères & Résines" — contenu DeepSeek, vérifié par
-- l'utilisatrice.
--
-- Lot 2/3 : Diméthicone, Cyclopentasiloxane/Cyclométhicone,
-- Polyquaternium, Résine acrylique filmogène, Polyuréthane
-- filmogène, Résine époxy, Résine polyester.
--
-- Résine époxy et Résine polyester documentées avec niveau_danger
-- 'Élevé' et avertissements renforcés (sensibilisation cutanée
-- documentée du durcisseur amine pour l'époxy ; styrène et
-- catalyseur MEKP oxydant/corrosif pour le polyester).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Diméthicone
  -- ------------------------------------------------------------
  v_material_id := '1b149866-bea8-4e0f-b8bd-5dddfc91c70d'::uuid;

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
    'Polydiméthylsiloxane (PDMS)',
    'Dimethicone, Polydimethylsiloxane, huile de silicone, silicone linéaire',
    'Cosmétique, Technique',
    'Liquide incolore, limpide, plus ou moins visqueux (de très fluide à pâteux), inodore, toucher soyeux et glissant',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau et l''alcool, miscible avec les huiles minérales, les esters et de nombreux solvants organiques',
    0.97, 315.0,
    'Silicone non réactive, chimiquement inerte, stérilisable. Excellentes propriétés d''étalement, de glissance et de protection cutanée. Forme un film occlusif respirant, non comédogène. Disponible en différentes viscosités (de 0,65 cSt à plusieurs millions de cSt).',
    'Par rapport au cyclopentasiloxane, elle ne s''évapore pas et laisse un film durable. Contrairement aux huiles végétales, elle ne rancit pas et donne un toucher sec non gras. Elle est le silicone de référence pour les sérums, les après-shampoings et les lubrifiants intimes.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter le contact prolongé avec les yeux.',
    'Yeux : rincer à l''eau. Peau : laver au savon. Ingestion sans danger.',
    'Oxydants puissants.',
    'Récipient hermétique, à température ambiante, à l''abri de l''humidité. Éviter le gel.',
    5, 35, false, false, 36, 'a_valider'
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
  (v_academie_id, 'Agent de glisse et protecteur en cosmétique (crèmes, sérums, après-shampoings)',
   'Incorporer 1 à 10 % dans la phase grasse ou en fin de formulation. Apporte un toucher soyeux, démêle les cheveux et forme un film protecteur non gras.',
   'plage', 1.0, 10.0, '% du produit fini', 'Ambiante à 80°C', 'Immédiat', false, 0),
  (v_academie_id, 'Lubrifiant et anti-mousse en milieu technique',
   'Appliquer une fine couche sur les surfaces métalliques ou plastiques pour lubrifier, protéger de la corrosion ou réduire la mousse.',
   'texte_libre', null, null, 'Quantité suffisante pour recouvrir la surface', 'Ambiante à 200°C', 'Immédiat', false, 1);

  -- ------------------------------------------------------------
  -- Cyclopentasiloxane / Cyclométhicone
  -- ------------------------------------------------------------
  v_material_id := '2ddebd2b-1b9f-4fee-a48d-e99274014037'::uuid;

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
    'Décaméthylcyclopentasiloxane (D5) et autres cyclométhicones (D4, D5, D6)',
    'Cyclomethicone, Cyclopentasiloxane, D5, silicone volatil',
    'Cosmétique, Technique',
    'Liquide incolore, très fluide, volatil, inodore',
    'Non applicable (insoluble dans l''eau)',
    'Insoluble dans l''eau, miscible avec la plupart des solvants organiques et des silicones',
    0.95, 77.0,
    'Silicone cyclique volatile qui s''évapore complètement après application, ne laissant aucun résidu gras. Excellente alternative aux solvants organiques légers. Facilite l''étalement des crèmes et donne un toucher sec soyeux. Le D5 est le plus courant ; le D4 est soumis à restriction (REACH) pour toxicité environnementale.',
    'Contrairement à la diméthicone (non volatile), il ne laisse pas de film persistant. Par rapport à l''isododécane (solvant volatil), il est plus doux et a un toucher plus soyeux. Il est le silicone de choix pour les sérums légers et les démaquillants biphasiques.',
    'Faible',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter l''inhalation prolongée de vapeurs en milieu confiné. Le D4 est suspecté reprotoxique, privilégier le D5.',
    'Inhalation : air frais. Peau : laver. Yeux : rincer 15 min. Ingestion : boire de l''eau, ne pas faire vomir.',
    'Oxydants forts, bases fortes.',
    'Bidon hermétique, à température ambiante, à l''écart des sources d''inflammation (point éclair 77°C).',
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
  select v_academie_id, id from public.phrases_h where code in ('H226', 'H315', 'H319', 'H335')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P261', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Base volatile pour sérums, huiles sèches, démaquillants biphasiques',
   'Incorporer 5 à 30 % dans la phase huileuse ou en mélange avec d''autres huiles. S''évapore en quelques secondes, laissant un toucher sec.',
   'plage', 5.0, 30.0, '% du produit fini', 'Ambiante', 'Évaporation en quelques secondes', false, 0);

  -- ------------------------------------------------------------
  -- Polyquaternium (conditionneur capillaire)
  -- ------------------------------------------------------------
  v_material_id := 'bb4d5abb-3033-45d8-9a27-95b34c844d39'::uuid;

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
    'Polymère d''ammonium quaternaire (ex: Polyquaternium-7, PQ-10, PQ-22, PQ-37, etc.)',
    'Polyquat, Polyquaternium, conditionneur cationique',
    'Cosmétique',
    'Liquide visqueux translucide à légèrement trouble, ou poudre blanche selon le grade, odeur neutre',
    '5-7 (solution à 1 %)',
    'Très soluble dans l''eau. Insoluble dans les huiles.',
    1.05, null,
    'Polymère cationique qui se dépose sur la fibre capillaire chargée négativement (cheveux mouillés) pour former un film conditionneur, anti-statique et démêlant. Excellente compatibilité avec les tensioactifs anioniques (shampoings 2 en 1). Améliore le peignage, la brillance et la douceur.',
    'Par rapport à la diméthicone (silicone), il est hydrosoluble et ne crée pas d''accumulation (build-up). Contrairement au PVP, il est spécifiquement conçu pour le soin capillaire et apporte une charge positive pour neutraliser l''électricité statique.',
    'Aucun',
    array[]::text[],
    'Aucun EPI obligatoire. Éviter le contact avec les yeux.',
    'Yeux : rincer. Peau : laver. Ingestion : boire de l''eau.',
    'Tensioactifs cationiques à forte dose, oxydants forts.',
    'Récipient hermétique, à température ambiante. Protéger du gel.',
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
  -- Pas de phrases H/P : produit non classé dangereux.

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Agent conditionneur pour shampoings et après-shampoings',
   'Ajouter 0,5-2 % dans la phase aqueuse ou en dilution avec le tensioactif. Se dépose sur les cheveux lors du rinçage.',
   'plage', 0.5, 2.0, '% du produit fini', 'Ambiante', 'Effet démêlant immédiat', false, 0);

  -- ------------------------------------------------------------
  -- Résine acrylique filmogène (vernis à ongles, mascara)
  -- ------------------------------------------------------------
  v_material_id := 'cc198729-b24d-4bb3-9fff-ee82cd1412cc'::uuid;

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
    'Copolymère d''acrylates en dispersion aqueuse ou en solution solvantée',
    'Acrylic Resin, polymère acrylique pour vernis, vernis acrylique, latex acrylique',
    'Cosmétique, Technique',
    'Liquide laiteux (dispersion aqueuse) ou liquide clair visqueux (solvanté), odeur douce à piquante selon les solvants',
    '6-8 (dispersion aqueuse)',
    'La dispersion aqueuse est miscible à l''eau ; le film sec est insoluble dans l''eau. La forme solvantée est soluble dans les solvants organiques.',
    1.05, 40.0,
    'Polymère filmogène transparent et brillant, utilisé comme base de vernis à ongles, mascara waterproof, ou liant pour fards. La forme aqueuse (latex) est sans solvant, la forme solvantée contient de l''acétate d''éthyle ou de l''alcool. Excellente adhérence, flexibilité et résistance à l''eau.',
    'Par rapport au polyuréthane filmogène, la résine acrylique est plus brillante, plus dure, mais moins souple. Contrairement au nitrocellulose (vernis à ongles classique), elle est moins cassante et plus résistante à l''eau.',
    'Modéré',
    array['gants','lunettes','ventilation'],
    'Gants en nitrile, lunettes de sécurité. Travailler dans un endroit ventilé (la forme solvantée dégage des vapeurs inflammables). La dispersion aqueuse est moins dangereuse.',
    'Inhalation : air frais. Peau : laver au savon. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas faire vomir, appeler un médecin.',
    'Oxydants forts, bases fortes. La forme solvantée est incompatible avec l''eau (précipitation).',
    'Bidon hermétique, à température ambiante, à l''écart des flammes et des sources de chaleur (pour la forme solvantée).',
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
  select v_academie_id, id from public.phrases_h where code in ('H226', 'H315', 'H319', 'H335', 'H336')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P261', 'P280', 'P305+P351+P338')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Base filmogène pour vernis à ongles, mascaras waterproof, eye-liners',
   'Appliquer au pinceau directement ou en mélange avec des pigments. Pour la forme aqueuse, séchage à l''air (2-5 min). Pour la forme solvantée, séchage rapide (< 1 min).',
   'texte_libre', null, null, 'Quantité suffisante pour former un film', 'Ambiante', 'Séchage 1-5 min', false, 0);

  -- ------------------------------------------------------------
  -- Polyuréthane filmogène (vernis)
  -- ------------------------------------------------------------
  v_material_id := '4490b227-b143-4006-8b77-fd7f0a052ac0'::uuid;

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
    'Polyuréthane en dispersion aqueuse (PUD) ou en solution solvantée',
    'Polyurethane, PUD, vernis polyuréthane, vernis PU',
    'Technique, Cosmétique (grade spécifique)',
    'Liquide laiteux (dispersion aqueuse) ou liquide clair visqueux (solvanté), odeur neutre à piquante',
    '7-9 (dispersion aqueuse)',
    'La dispersion est miscible à l''eau ; le film sec est insoluble dans l''eau et résistant aux solvants',
    1.05, 45.0,
    'Polymère filmogène très résistant à l''abrasion, aux solvants et à l''eau. Les dispersions aqueuses (PUD) sont sans COV et durcissent par évaporation de l''eau. Utilisé pour les vernis de sol, les revêtements industriels, et en cosmétique pour les mascaras longue tenue et les vernis à ongles "gel effect".',
    'Par rapport à la résine acrylique, le polyuréthane est plus souple, plus résistant aux chocs, mais moins brillant. Il est souvent le choix pour les revêtements de haute performance.',
    'Modéré',
    array['gants','lunettes','ventilation'],
    'Gants en nitrile, lunettes. La forme solvantée contient des isocyanates résiduels (sensibilisants respiratoires) : utiliser une ventilation efficace.',
    'Inhalation : air frais, consulter si gêne respiratoire. Peau : laver. Yeux : rincer 15 min. Ingestion : rincer la bouche, ne pas faire vomir.',
    'Eau (pour la forme solvantée), oxydants forts, bases fortes.',
    'Bidon hermétique, au frais, à l''écart des sources d''inflammation. La dispersion aqueuse craint le gel.',
    5, 30, false, false, 12, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H226', 'H315', 'H319', 'H335', 'H334')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P261', 'P280', 'P304+P340', 'P305+P351+P338', 'P342+P311')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Vernis de finition pour meubles, sols, et revêtements industriels',
   'Appliquer au pinceau, rouleau ou pistolet. La dispersion aqueuse sèche en 30-60 min ; la forme solvantée en 15-30 min.',
   'texte_libre', null, null, 'Application en couche fine', 'Ambiante à 30°C', 'Séchage 15-60 min', false, 0);

  -- ------------------------------------------------------------
  -- Résine époxy
  -- ------------------------------------------------------------
  v_material_id := 'eb171f23-3a7a-467a-a52a-35844ab45143'::uuid;

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
    'Mélange de pré-polymère époxy (diglycidyl éther de bisphénol A, DGEBA) et d''un durcisseur amine',
    'Epoxy, résine époxy, colle époxy, résine de stratification',
    'Technique, Artistique',
    'Liquide visqueux, incolore à jaune pâle (partie A). Le durcisseur (partie B) est un liquide ambré à odeur aminée. Le mélange dégage une chaleur modérée.',
    'Non applicable (réactif)',
    'Non polymérisée : soluble dans les cétones, esters, hydrocarbures aromatiques. Polymérisée : insoluble et résistante à la plupart des solvants.',
    1.15, 150.0,
    'Résine thermodurcissable à deux composants. La réaction de polymérisation avec le durcisseur amine est exothermique. Le mélange non polymérisé est un sensibilisant cutané puissant (dermatite de contact allergique). Les amines du durcisseur sont corrosives et irritantes pour la peau et les voies respiratoires. Ne jamais utiliser de gants en latex ou vinyle (perméables), seulement des gants en nitrile épais ou en caoutchouc butyle.',
    'Par rapport à la résine polyester, elle adhère sur une plus grande variété de supports, est plus résistante mécaniquement et chimiquement, et ne contient pas de styrène. Elle est plus chère mais plus performante.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Porter impérativement des gants en nitrile épais ou caoutchouc butyle (pas de latex/vinyle, perméables aux composants). Lunettes de sécurité ou écran facial. Masque à cartouche pour vapeurs organiques. Manipuler sous hotte ou en local très ventilé. Éviter tout contact cutané avec la résine non polymérisée et le durcisseur.',
    'Peau : enlever les vêtements contaminés, rincer immédiatement et abondamment à l''eau pendant 15 min. Ne pas utiliser de solvant pour nettoyer la peau. Yeux : rincer 15 min, consulter un ophtalmologue en urgence. Ingestion : rincer la bouche, ne pas faire vomir, appeler un centre antipoison. Inhalation : air frais, consulter.',
    'Acides forts, bases fortes, amines tertiaires (accélèrent la réaction de manière incontrôlable), oxydants.',
    'Récipients d''origine bien fermés, dans un local frais, sec et ventilé. Tenir hors de portée des enfants. Le durcisseur doit être protégé de l''humidité et du CO₂ de l''air (carbonatation).',
    10, 30, true, false, 12, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H314', 'H315', 'H317', 'H319', 'H334', 'H335', 'H350', 'H411')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P201', 'P260', 'P264', 'P272', 'P280', 'P284', 'P301+P330+P331', 'P303+P361+P353', 'P304+P340', 'P305+P351+P338', 'P310', 'P333+P313', 'P403+P233')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Stratification, collage, moulage et revêtement de sol (art, bijouterie, réparation)',
   'Mélanger intimement la résine et le durcisseur dans les proportions exactes indiquées par le fabricant (généralement 2:1 ou 100:50 en poids). Appliquer dans le temps d''utilisation (pot life). La polymérisation complète prend 24-72 h à température ambiante.',
   'texte_libre', null, null, 'Selon le ratio du fabricant', 'Ambiante (18-25°C idéal)', 'Pot life de 30-60 min, durcissement complet en 24-72 h', false, 0);

  -- ------------------------------------------------------------
  -- Résine polyester
  -- ------------------------------------------------------------
  v_material_id := 'b8f4aa4a-de2f-4d44-b13b-7422e3651c41'::uuid;

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
    'Résine de polyester insaturé en solution de styrène (C₆H₅CH=CH₂)',
    'Polyester resin, résine stratifiée, résine fibre de verre, résine de moulage',
    'Technique, Artistique',
    'Liquide visqueux, translucide à rose/violet, odeur très forte de styrène. Le catalyseur (peroxyde de MEK, MEKP) est un liquide incolore, oxydant puissant.',
    'Non applicable (réactif)',
    'Non polymérisée : soluble dans le styrène et les cétones. Polymérisée : insoluble, résistante à l''eau et à de nombreux produits chimiques.',
    1.12, 33.0,
    'Résine thermodurcissable contenant du styrène (monomère volatil inflammable, irritant). Le durcissement est initié par un catalyseur oxydant (peroxyde de MEK, MEKP) qui est corrosif, irritant pour les yeux et la peau. Le mélange dégage de la chaleur. La résine polymérisée est rigide, transparente, mais moins résistante que l''époxy.',
    'Par rapport à la résine époxy, la résine polyester est moins chère, a une odeur beaucoup plus forte (styrène), est moins résistante et moins adhérente, mais prend plus rapidement. Le catalyseur MEKP est plus dangereux à manipuler que les durcisseurs amines.',
    'Élevé',
    array['gants','lunettes','masque','ventilation'],
    'Porter impérativement des gants en nitrile résistants aux solvants, des lunettes de sécurité étanches, un masque à cartouche pour vapeurs organiques (A2). Travailler sous hotte ou en local très ventilé. Le catalyseur MEKP ne doit jamais être mélangé avec du cobalt ou des amines seuls (risque d''explosion).',
    'Inhalation : air frais, consulter si gêne. Peau : laver immédiatement au savon et à l''eau, retirer les vêtements contaminés. Yeux : rincer 15 min, consulter un ophtalmologue. Ingestion : rincer la bouche, ne pas faire vomir, appeler un centre antipoison. En cas de projection de catalyseur dans les yeux, rincer immédiatement et abondamment, consulter en urgence.',
    'Le catalyseur (peroxyde) est un oxydant puissant : éviter le contact avec les métaux, les amines, les accélérateurs au cobalt (risque d''incendie ou d''explosion). Ne jamais mélanger le catalyseur directement avec un accélérateur.',
    'Récipient d''origine, dans un local frais, sec et ventilé, à l''écart des sources de chaleur, des flammes et des oxydants. Le catalyseur doit être stocké séparément, au frais, à l''abri de la lumière et des matières combustibles.',
    5, 25, true, true, 6, 'a_valider'
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
  select v_academie_id, id from public.phrases_h where code in ('H226', 'H315', 'H318', 'H335', 'H361d', 'H373')
  on conflict (academie_id, phrase_h_id) do nothing;

  insert into public.academie_phrases_p (academie_id, phrase_p_id)
  select v_academie_id, id from public.phrases_p
  where code in ('P210', 'P260', 'P264', 'P280', 'P301+P330+P331', 'P303+P361+P353', 'P305+P351+P338', 'P310', 'P403+P233')
  on conflict (academie_id, phrase_p_id) do nothing;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Stratification fibre de verre, moulage, réparation de carrosserie',
   'Ajouter le catalyseur (généralement 1 à 3 %) à la résine, bien mélanger. Imprégner le renfort (fibre de verre). La résine gélifie en 10-30 min et durcit complètement en 24 h.',
   'valeur_unique', 2.0, null, '% de catalyseur MEKP par rapport à la résine', '15-25°C', 'Gélification 10-30 min, durcissement 24 h', false, 0);
end $$;
