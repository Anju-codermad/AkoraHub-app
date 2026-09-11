-- ============================================================
-- AkoraHub - Patch Phase 236 : crée la fiche Académie complète du
-- "Bicarbonate de soude" (grade technique) — demande explicite de la
-- propriétaire le 11/09/2026 (fiche technique détaillée fournie).
--
-- Ce produit (déjà au catalogue depuis la phase41, pilier principal
-- Akora Pro, relié à Akor'Eau en phase235) n'avait jamais eu de fiche
-- Académie dédiée — seule "Bicarbonate de sodium NaHCO₃ (E500ii)"
-- (grade alimentaire, phase91) en avait une.
--
-- Contenu volontairement centré sur les usages du grade TECHNIQUE
-- (entretien/nettoyage sous Akora Pro, traitement de l'eau/piscine
-- sous Akor'Eau, usages industriels généraux) — la partie
-- agroalimentaire (E500(ii)) décrite dans la fiche fournie par la
-- propriétaire concerne le produit alimentaire séparé, déjà relié à
-- Akora NutriLab (phases 205/208), non dupliquée ici.
--
-- Contenu rédigé à partir de connaissances générales de chimie (CAS,
-- propriétés, dangers GHS) et des données fournies par la
-- propriétaire, À VÉRIFIER PAR LA PROPRIÉTAIRE avant diffusion
-- (statut_verification = 'a_valider').
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do update sur l'academie par
-- matiere_premiere_id).
-- ============================================================

do $$
declare
  v_akora_pro_id uuid;
  v_material_id uuid;
  v_academie_id uuid;
begin
  select id into v_akora_pro_id from public.business_units where slug = 'matieres-premieres';
  if v_akora_pro_id is null then
    raise exception 'Aucun pilier avec le slug "matieres-premieres" trouvé — arrêt.';
  end if;

  select id into v_material_id from public.raw_materials
    where business_unit_id = v_akora_pro_id and name = 'Bicarbonate de soude';
  if v_material_id is null then
    raise exception 'Produit "Bicarbonate de soude" introuvable dans raw_materials — arrêt.';
  end if;

  insert into public.matieres_premieres_academie (
    matiere_premiere_id, nom_chimique, synonymes, grade, aspect,
    ph_solution, solubilite, densite, particularite,
    difference_produit_similaire, niveau_danger, epi_requis, notes_epi,
    premiers_secours, incompatibilites, consignes_stockage,
    temperature_stockage_min, temperature_stockage_max,
    sensible_humidite, sensible_lumiere, duree_conservation_mois,
    statut_verification
  ) values (
    v_material_id,
    'Bicarbonate de sodium (NaHCO₃), CAS 144-55-8, EINECS 205-633-8, masse molaire 84,01 g/mol',
    'Bicarbonate de soude, hydrogénocarbonate de sodium, carbonate acide de sodium, baking soda',
    'Technique',
    'Poudre cristalline blanche, inodore, goût légèrement alcalin',
    '8,0-8,6 (solution à 1 %)',
    'Soluble dans l''eau',
    2.2,
    'Poudre alcaline multifonctionnelle. Grade technique utilisé pour l''entretien/nettoyage (abrasif doux, désodorisant, neutralisation des odeurs), le traitement de l''eau et des piscines (correcteur d''alcalinité : augmente le TAC, stabilise le pH, réduit la corrosion, améliore l''efficacité du chlore) et divers usages industriels (neutralisation de solutions acides, textile, tannerie, fabrication chimique, traitement des fumées industrielles).',
    'Même molécule que les grades alimentaires déjà au catalogue ("Bicarbonate de soude alimentaire", "Bicarbonate de sodium NaHCO₃ (E500ii)", tous deux reliés à Akora NutriLab) — différence de pureté et de contrôles (≥ 99 % NaHCO₃, métaux lourds contrôlés, contrôle microbiologique pour l''alimentaire), pas de différence de formule. Le grade technique n''est pas destiné à un usage alimentaire.',
    'Faible',
    array['gants','masque anti-poussière'],
    'Éviter l''inhalation de poussières ; masque anti-poussière recommandé lors d''une manipulation industrielle importante, gants en cas de contact prolongé.',
    'Inhalation de poussière : air frais. Yeux : rincer à l''eau. Peau : laver à l''eau.',
    'Contact direct avec les acides (dégagement de CO₂).',
    'Endroit sec, température ambiante, sac bien fermé, à l''écart de l''humidité et des acides.',
    5, 35, true, false, 36, 'a_valider'
  )
  on conflict (matiere_premiere_id) do update set
    nom_chimique = excluded.nom_chimique, synonymes = excluded.synonymes,
    grade = excluded.grade, aspect = excluded.aspect,
    ph_solution = excluded.ph_solution, solubilite = excluded.solubilite,
    densite = excluded.densite, particularite = excluded.particularite,
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

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Correction d''alcalinité (eau potable, eau de forage)',
   'Dissoudre dans un seau d''eau, ajouter progressivement dans le circuit à traiter, contrôler le pH et l''alcalinité après traitement. Mesurer d''abord pH + TAC + dureté + conductivité avant de doser — le bicarbonate corrige surtout l''alcalinité, pas tous les problèmes d''eau.',
   'plage', 10, 100, 'g/m³ selon le besoin d''ajustement (eau légèrement acide : 10-30 g/m³ ; eau à faible alcalinité : 50-100 g/m³)', true, 0);

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, unite_dosage, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Augmentation du TAC (piscine)',
   'Dissoudre dans un seau d''eau avant de verser dans le bassin, filtration en marche. Équivalences pratiques : 1 m³ -> ≈150 g, 10 m³ -> ≈1,5 kg, 50 m³ -> ≈7,5 kg, 100 m³ -> ≈15 kg pour +10 ppm de TAC. TAC recommandé généralement entre 80 et 120 ppm pour une piscine classique.',
   'valeur_unique', 150, 'g par m³ d''eau (≈ 1,5 kg pour 10 m³) pour augmenter le TAC d''environ 10 ppm', true, 1);

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_texte, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Stabilisation de l''alcalinité (aquaculture, élevage)',
   'Ajout progressif dans le bassin/circuit d''élevage, avec contrôle du pH et de l''alcalinité — pas de dose fixe, à ajuster selon la mesure du TAC.',
   'texte_libre', 'Dosage déterminé au cas par cas selon la mesure du TAC, pas de valeur standard', true, 2);

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_texte, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Neutralisation industrielle (textile, tannerie, fabrication chimique, traitement des fumées)',
   'Doser progressivement dans la solution ou le flux à neutraliser jusqu''au pH cible, en surveillant le dégagement de CO₂. Réaction : NaHCO₃ + H⁺ -> Na⁺ + CO₂ + H₂O — environ 84 g de produit neutralisent 1 mole d''acidité (1 équivalent H⁺), à titre indicatif théorique.',
   'texte_libre', 'Dosage à valider par essai selon l''acide présent, sa concentration et le pH cible', true, 3);

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Nettoyage et désodorisation (entretien ménager/industriel)',
   'En solution pour surfaces/odeurs, ou en poudre directe (saupoudrage puis humidification) pour un nettoyage doux sans préparation de solution.',
   'plage', 20, 100, 'g/L d''eau en solution ; poudre directe possible sans dosage précis', false, 4);
end $$;

-- Vérification :
-- select nom_chimique, particularite from public.matieres_premieres_academie a
-- join public.raw_materials rm on rm.id = a.matiere_premiere_id
-- where rm.name = 'Bicarbonate de soude';
-- select domaine_application, ordre from public.matieres_premieres_usages u
-- join public.matieres_premieres_academie a on a.id = u.academie_id
-- join public.raw_materials rm on rm.id = a.matiere_premiere_id
-- where rm.name = 'Bicarbonate de soude'
-- order by u.ordre;
