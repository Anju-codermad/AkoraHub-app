-- ============================================================
-- AkoraHub - Patch Phase 134 : fiche Académie pour le produit déjà
-- présent dans le catalogue "Polymères & Résines" avant la
-- campagne — contenu DeepSeek, vérifié par l'utilisatrice.
--
-- Termine la catégorie "Polymères & Résines" (21/21 : 20 nouveaux en
-- phases 131-133 + ce produit déjà existant).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_material_id uuid;
  v_academie_id uuid;
begin
  -- ------------------------------------------------------------
  -- Polymères floculants (traitement de l'eau)
  -- ------------------------------------------------------------
  v_material_id := 'beedbd5b-d49b-4a57-8f1e-2cfe59003eb2'::uuid;

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
    'Polyacrylamides de haut poids moléculaire, éventuellement modifiés : polyacrylamide anionique (PAM), cationique (PAM-C) ou non ionique',
    'Floculants polymères, polyacrylamide, PAM, polyélectrolytes, agents de coagulation/floculation',
    'Technique',
    'Poudre granulaire blanche ou légèrement jaunâtre, ou émulsion liquide laiteuse, inodore ou très faible odeur d''ammoniac pour les grades cationiques',
    'Neutre (6-8) en solution aqueuse',
    'Soluble dans l''eau (nécessite une dispersion lente et une agitation pour éviter les grumeaux). Insoluble dans les solvants organiques.',
    0.75, null,
    'Polymères hydrosolubles de très haut poids moléculaire (plusieurs millions de daltons) utilisés pour agglomérer les particules en suspension dans l''eau. Les types anioniques (chargés négativement) sont les plus courants pour le traitement des eaux chargées en matières minérales (argiles). Les types cationiques (chargés positivement) sont efficaces pour les boues organiques (stations d''épuration). Les types non ioniques sont utilisés dans des conditions extrêmes de pH ou de salinité. Le monomère résiduel d''acrylamide est un composé neurotoxique et cancérogène (CIRC groupe 2A). Dans les polymères de qualité commerciale, la teneur en acrylamide libre est strictement contrôlée (< 0,1 % pour les usages eau potable) et ne présente pas de risque aux doses d''emploi.',
    'Contrairement aux autres polymères du catalogue (épaississants cosmétiques, résines), les polymères floculants sont spécifiquement conçus pour le traitement de l''eau, avec des poids moléculaires extrêmement élevés et des charges ioniques permettant la formation de flocs. Ils ne sont pas destinés à un usage cosmétique ou alimentaire direct.',
    'Faible',
    array['gants','lunettes','masque'],
    'Porter des gants en nitrile, des lunettes de sécurité et un masque anti-poussière pour éviter l''inhalation de poudre. Le produit sec est glissant lorsqu''il est mouillé. Éviter de respirer les poussières.',
    'Inhalation : air frais. Peau : laver à l''eau et au savon. Yeux : rincer 15 min. Ingestion : rincer la bouche, boire de l''eau, consulter un médecin si symptômes.',
    'Oxydants forts, agents mouillants anioniques (inversion de charge pour les cationiques), pH extrêmes (hydrolyse).',
    'Récipient étanche, au sec, à l''abri de l''humidité (la poudre absorbe l''eau et devient collante). Éviter les températures supérieures à 40°C qui peuvent dégrader le polymère.',
    5, 35, true, false, 24, 'a_valider'
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
  (v_academie_id, 'Clarification des eaux de surface et traitement des eaux usées',
   'Préparer une solution mère à 0,1-0,5 % en dispersant lentement la poudre dans l''eau sous agitation. Laisser mûrir 30-60 min. Injecter la solution dans le flux d''eau à traiter à une dose typique de 0,1-5 mg/L (ppm). La formation des flocs est immédiate ; leur séparation se fait par décantation ou flottation.',
   'plage', 0.1, 5.0, 'mg/L (ppm) de produit actif', '5-40°C', 'Formation des flocs en quelques secondes, décantation en 30-60 min', false, 0);
end $$;
