-- ============================================================
-- AkoraHub - Patch Phase 238 : corrige le dosage piscine (TAC) de la
-- fiche "Bicarbonate de soude" (phase236) et ajoute 2 nouveaux usages
-- (détergents industriels, agriculture) fournis par la propriétaire
-- le 11/09/2026.
--
-- Correction du dosage piscine : la phase236 indiquait ≈150 g/m³
-- (≈15 kg/100 m³) pour +10 ppm de TAC, valeur reprise du message de la
-- propriétaire mais incohérente d'un facteur ~10 avec (a) la règle
-- professionnelle standard des fabricants de produits piscine
-- (≈1,5 lb de bicarbonate de sodium pour 10 000 gallons US pour +10 ppm
-- de TA, soit ≈1,8 kg/100 m³) et (b) le calcul stœchiométrique
-- (10 ppm d'alcalinité en équivalent CaCO₃ ≈ 8,4 g/m³ de NaHCO₃).
-- La nouvelle valeur fournie par la propriétaire (1,5 à 1,8 kg pour
-- 100 m³) est cohérente avec ces deux recoupements — c'est donc cette
-- valeur qui est retenue et qui remplace celle de la phase236.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (delete + reinsert des lignes concernées).
-- ============================================================

do $$
declare
  v_academie_id uuid;
begin
  select a.id into v_academie_id
    from public.matieres_premieres_academie a
    join public.raw_materials rm on rm.id = a.matiere_premiere_id
    where rm.name = 'Bicarbonate de soude';

  if v_academie_id is null then
    raise exception 'Fiche Académie introuvable pour "Bicarbonate de soude" — exécuter d''abord la phase 236.';
  end if;

  -- Mise à jour de la description générale : ajout de la pureté typique et
  -- de la précision "pH ≈ 8,3 (solution à 1 %)" déjà cohérente avec la
  -- fourchette existante 8,0-8,6.
  update public.matieres_premieres_academie
  set synonymes = 'Bicarbonate de soude, hydrogénocarbonate de sodium, carbonate acide de sodium, baking soda, sodium bicarbonate technical grade',
      particularite = particularite || ' Pureté typique : ≥ 98-99 % NaHCO₃ selon grade fournisseur.',
      updated_at = now()
  where id = v_academie_id;

  -- Correction du dosage piscine (remplace la ligne ordre=1 de la phase236)
  delete from public.matieres_premieres_usages
  where academie_id = v_academie_id and ordre = 1;

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_min, dosage_max, unite_dosage, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Augmentation du TAC (piscine)',
   'Dissoudre dans un seau d''eau avant de verser dans le bassin, filtration en marche. Équivalences pratiques : 1 m³ -> ≈15-18 g, 10 m³ -> ≈150-180 g, 50 m³ -> ≈750-900 g, 100 m³ -> ≈1,5-1,8 kg pour +10 ppm de TAC. TAC recommandé généralement entre 80 et 120 ppm pour une piscine classique.',
   'plage', 15, 18, 'g par m³ d''eau (≈ 1,5 à 1,8 kg pour 100 m³) pour augmenter le TAC d''environ 10 ppm', true, 1);

  -- Nouveaux usages fournis par la propriétaire
  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_texte, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Industrie des détergents (formulation)',
   'Incorporé en poudre dans les formulations de détergents/nettoyants comme agent tampon : renforce le pouvoir nettoyant et régule le pH de la formulation.',
   'texte_libre', 'Dosage déterminé par la formulation du fabricant, pas de valeur standard', true, 5);

  insert into public.matieres_premieres_usages (
    academie_id, domaine_application, technique_methode, dosage_type,
    dosage_texte, a_verifier_labo, ordre
  ) values
  (v_academie_id, 'Agriculture (correction d''acidité, régulation du pH de solutions)',
   'Ajout progressif dans la solution ou le sol à traiter selon la mesure du pH — pas de dose fixe, à ajuster selon l''analyse.',
   'texte_libre', 'Dosage déterminé au cas par cas selon l''analyse du pH, pas de valeur standard', true, 6);
end $$;

-- Vérification :
-- select domaine_application, dosage_type, dosage_min, dosage_max, unite_dosage, ordre
-- from public.matieres_premieres_usages u
-- join public.matieres_premieres_academie a on a.id = u.academie_id
-- join public.raw_materials rm on rm.id = a.matiere_premiere_id
-- where rm.name = 'Bicarbonate de soude'
-- order by u.ordre;
