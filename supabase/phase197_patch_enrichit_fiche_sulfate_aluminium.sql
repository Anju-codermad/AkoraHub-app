-- ============================================================
-- AkoraHub - Patch Phase 197 : enrichit la fiche Académie du "Sulfate
-- d'aluminium (Alun)" avec tous ses domaines d'application — demande
-- explicite de la propriétaire le 04/09/2026 (fiche détaillée fournie :
-- potabilisation, eaux industrielles, piscine, papier, textile,
-- pigments/peintures, agriculture, bâtiment).
--
-- La fiche existante (phase95) ne couvrait que 2 usages : "Coagulant /
-- floculant (traitement de l'eau, piscine)" (générique) et "Fixateur
-- de colorant (teinture textile artisanale)". Ce script :
--   1) Sépare le générique "traitement de l'eau / piscine" en deux
--      entrées distinctes et plus précises : "Potabilisation de l'eau"
--      (10-150 mg/L selon turbidité, pH optimal 5,5-7,5) et "Piscine
--      (clarifiant)" (5-20 g/m³, inchangé).
--   2) Ajoute 6 nouveaux domaines : eaux industrielles, papier,
--      textile industriel, pigments/peintures, agriculture, bâtiment.
--   3) Garde l'entrée "Fixateur de colorant (teinture textile
--      artisanale)" déjà existante, inchangée.
--   4) Enrichit `particularite` pour mentionner les formes
--      commerciales (poudre/cristaux, solution liquide, grade
--      alimentaire) — la fiche Académie reste unique pour ce produit,
--      pas de nouvelles fiches créées (un seul "Sulfate d'aluminium
--      (Alun)" au catalogue, plusieurs usages listés dessous).
--
-- Contenu technique (aspect, pH, solubilité, densité) déjà présent et
-- cohérent avec la liste fournie — non modifié pour garder les valeurs
-- déjà vérifiées de la fiche existante.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do update / delete+insert usages).
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
    where business_unit_id = v_akora_pro_id and name = 'Sulfate d''aluminium (Alun)';
  if v_material_id is null then
    raise exception 'Produit "Sulfate d''aluminium (Alun)" introuvable — arrêt.';
  end if;

  update public.matieres_premieres_academie
  set particularite = 'Densité donnée pour le sulfate d''aluminium hydraté. Agent floculant et coagulant, acidifie légèrement l''eau par hydrolyse. Coagulant polyvalent utilisé dans de nombreux secteurs au-delà du traitement de l''eau : industrie du papier (agent de collage), textile (fixation de colorants), fabrication de pigments/peintures, agriculture (correction de sols alcalins) et bâtiment (traitements de surface spécifiques). Disponible commercialement sous plusieurs formes : poudre/cristaux (grade technique, usage industriel), solution liquide prête à doser (stations de traitement d''eau), et grade alimentaire (plus contrôlé, pour les applications où un contact alimentaire est autorisé selon la réglementation en vigueur).',
    updated_at = now()
  where matiere_premiere_id = v_material_id
  returning id into v_academie_id;

  if v_academie_id is null then
    raise exception 'Fiche Académie introuvable pour "Sulfate d''aluminium (Alun)" — exécuter d''abord la phase 95.';
  end if;

  delete from public.matieres_premieres_usages where academie_id = v_academie_id;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Potabilisation de l''eau (coagulation, réduction de la turbidité)',
   'Injecter en continu dans l''eau brute avant décantation, sous agitation rapide puis floculation lente ; ajuster le pH de l''eau autour de 5,5 à 7,5 pour une coagulation optimale.',
   'plage', 10, 150, 'mg/L — 10 à 50 mg/L pour une eau légèrement trouble, 50 à 150 mg/L pour une eau très trouble (dépend aussi du pH)', null, null, true, 0),
  (v_academie_id, 'Piscine (clarifiant)',
   'Dissoudre au préalable dans un seau d''eau (solution à 5-10 %), répartir sur la surface du bassin, filtration en marche pour retenir les impuretés décantées.',
   'plage', 5, 20, 'g/m³ d''eau, selon la turbidité', 'Ambiante', '12-24 h de décantation', true, 1);

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_texte, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Traitement des eaux industrielles (agroalimentaire, textile, papeterie, tanneries, stations d''épuration)',
   'Injecter dans le flux d''eaux usées avant décantation pour former des flocs et réduire la charge polluante (matières en suspension, matières organiques).',
   'texte_libre', 'Dosage variable selon la charge polluante et le secteur — à valider par essai de floculation (jar-test) spécifique à l''effluent traité.', true, 2),
  (v_academie_id, 'Industrie du papier (agent de collage)',
   'Ajouté en pâte à papier pour améliorer le collage, la résistance à l''eau du papier et la fixation des pigments/charges minérales.',
   'texte_libre', 'Dosage à définir selon le type de papier et le procédé de collage — application industrielle spécialisée.', true, 3),
  (v_academie_id, 'Industrie textile (fixation de colorants, traitement des fibres) — échelle industrielle',
   'Utilisé comme mordant/fixateur pour améliorer la tenue des couleurs sur les fibres textiles en production industrielle.',
   'texte_libre', 'Dosage variable selon le colorant et la fibre traitée — à valider par essai.', true, 4),
  (v_academie_id, 'Fabrication de pigments et peintures',
   'Utilisé comme agent de précipitation pour la fabrication de pigments à base d''aluminium et le contrôle de certaines réactions chimiques.',
   'texte_libre', 'Application industrielle spécialisée — dosage à définir selon le procédé de fabrication.', true, 5),
  (v_academie_id, 'Agriculture (correction de sols alcalins, horticulture)',
   'Épandage pour acidifier légèrement des sols trop alcalins, ou traitement spécifique en horticulture. Usage limité : un excès d''aluminium peut être toxique pour les plantes — ne pas dépasser les doses recommandées par un agronome.',
   'texte_libre', 'Usage limité et spécifique — dosage à valider avec un agronome selon le sol et la culture visée.', true, 6),
  (v_academie_id, 'Bâtiment (traitements de surface, applications spécifiques avec le ciment)',
   'Utilisé dans certains traitements de surface et applications spécifiques accélérant certaines réactions avec le ciment.',
   'texte_libre', 'Application spécialisée — dosage à définir selon le procédé et les recommandations du fabricant.', true, 7);

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, temperature_utilisation,
    temps_action, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Fixateur de colorant (teinture textile artisanale)',
   'Dissoudre dans l''eau chaude, immerger le tissu préalablement teint, laisser agir puis rincer.',
   'valeur_unique', 10, null, 'g/L d''eau', '50-60 °C', '30-60 min', false, 8);
end $$;

-- Vérification : tous les usages du Sulfate d'aluminium (Alun)
-- select u.domaine_application, u.ordre from public.matieres_premieres_usages u
-- join public.matieres_premieres_academie a on a.id = u.academie_id
-- join public.raw_materials rm on rm.id = a.matiere_premiere_id
-- where rm.name = 'Sulfate d''aluminium (Alun)'
-- order by u.ordre;
