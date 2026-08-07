-- ============================================================
-- AkoraHub - Patch Phase 104 : ajout au catalogue + fiche Académie
-- complète pour "Alginate de propylène glycol (PGA, E405)" — contenu
-- DeepSeek du lot précédent, vérifié par l'utilisatrice.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

do $$
declare
  v_business_unit_id uuid;
  v_material_id uuid;
  v_academie_id uuid;
begin
  select business_unit_id into v_business_unit_id
  from public.raw_materials
  where category_name = 'Épaississants'
  limit 1;

  if v_business_unit_id is null then
    raise exception 'Aucun business_unit_id trouvé pour la catégorie "Épaississants".';
  end if;

  insert into public.raw_materials (business_unit_id, category_name, name, stock_status, current_price)
  values (v_business_unit_id, 'Épaississants', 'Alginate de propylène glycol (PGA, E405)', 'rupture', null)
  on conflict (business_unit_id, category_name, name) do update set updated_at = now()
  returning id into v_material_id;

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
    'Alginate de propylène glycol ((C₉H₁₄O₇)n)',
    'PGA, E405, alginate de propane-1,2-diol',
    'Alimentaire',
    'Poudre fibreuse blanche à crème',
    '4-5 (dispersion à 1 %)',
    'Soluble dans l''eau froide, donne des solutions visqueuses, moins sensible aux cations que l''alginate de sodium. Résistant aux acides.',
    0.80, null,
    'Dérivé d''alginate résistant aux milieux acides (pH < 4). Utilisé pour stabiliser les mousses et les boissons acides (bière, jus de fruits).',
    'Par rapport à l''alginate de sodium (E401), le PGA est stable en milieu acide et ne gélifie pas avec le calcium. Idéal pour les boissons lactées fermentées et la bière.',
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
    dosage_min, unite_dosage, temperature_utilisation, temps_action,
    a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Stabilisant de mousse de bière',
   'Ajouter 20-50 ppm (mg/L) dans la bière avant la carbonatation pour améliorer la tenue de la mousse.',
   'valeur_unique', 30, 'ppm (mg/L)', 'Froide', 'Incorporation', false, 0);
end $$;
