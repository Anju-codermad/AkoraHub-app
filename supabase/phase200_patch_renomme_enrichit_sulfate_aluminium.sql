-- ============================================================
-- AkoraHub - Patch Phase 200 : renomme "Sulfate d'aluminium (Alun)" en
-- "Sulfate d'aluminium (Sulfate d'alumine)" — demande explicite de la
-- propriétaire le 04/09/2026, pour que les clients cherchant l'un ou
-- l'autre terme ("sulfate d'alumine" est le nom courant en français
-- industriel, "sulfate d'aluminium" le nom chimique) retrouvent le
-- même produit. Le synonyme "sulfate d'alumine" était déjà présent
-- dans la fiche Académie (champ synonymes), mais pas dans le NOM du
-- produit lui-même, ce qui le rendait invisible à une recherche texte
-- sur "alumine".
--
-- Enrichit aussi la fiche Académie avec les infos fournies :
--   - N° CAS 10043-01-3 (absent jusqu'ici du champ nom_chimique)
--   - Nom anglais "Aluminium sulfate" ajouté aux synonymes
--   - Forme commerciale "granulés" ajoutée à la description des formes
--     disponibles (poudre/cristaux, granulés, liquide, alimentaire)
--
-- Renomme raw_materials.name ET products.name (le lien entre les deux
-- se fait par raw_material_id, pas par nom — le renommage ne casse
-- aucune référence). "Alun" reste dans les synonymes, donc toujours
-- trouvable pour qui cherche ce terme.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (les UPDATE sont sans effet si déjà appliqués).
-- ============================================================

do $$
declare
  v_akora_pro_id uuid;
  v_material_id uuid;
  v_ancien_nom text := 'Sulfate d''aluminium (Alun)';
  v_nouveau_nom text := 'Sulfate d''aluminium (Sulfate d''alumine)';
begin
  select id into v_akora_pro_id from public.business_units where slug = 'matieres-premieres';
  if v_akora_pro_id is null then
    raise exception 'Aucun pilier avec le slug "matieres-premieres" trouvé — arrêt.';
  end if;

  select id into v_material_id from public.raw_materials
    where business_unit_id = v_akora_pro_id and name = v_ancien_nom;

  if v_material_id is null then
    -- Déjà renommé (script relancé après un premier passage réussi) ?
    select id into v_material_id from public.raw_materials
      where business_unit_id = v_akora_pro_id and name = v_nouveau_nom;
    if v_material_id is null then
      raise exception 'Produit "%" introuvable (ni sous l''ancien ni le nouveau nom) — arrêt.', v_ancien_nom;
    end if;
  end if;

  update public.raw_materials
    set name = v_nouveau_nom
    where id = v_material_id and name = v_ancien_nom;

  update public.products
    set name = v_nouveau_nom
    where raw_material_id = v_material_id and name = v_ancien_nom;

  update public.matieres_premieres_academie
  set nom_chimique = 'Sulfate d''aluminium (Al₂(SO₄)₃), CAS 10043-01-3',
      synonymes = 'Alun, alun de potassium (si KAl(SO₄)₂), sulfate d''alumine, Aluminium sulfate (anglais)',
      particularite = 'Densité donnée pour le sulfate d''aluminium hydraté. Agent floculant et coagulant, acidifie légèrement l''eau par hydrolyse. Coagulant polyvalent utilisé dans de nombreux secteurs au-delà du traitement de l''eau : industrie du papier (agent de collage), textile (fixation de colorants), fabrication de pigments/peintures, agriculture (correction de sols alcalins) et bâtiment (traitements de surface spécifiques). Disponible commercialement sous plusieurs formes : poudre (blanche à légèrement jaunâtre), granulés/cristaux (souvent plus faciles à doser dans certaines installations de traitement d''eau), solution liquide prête à doser (stations de traitement d''eau), et grade alimentaire (plus contrôlé, pour les applications où un contact alimentaire est autorisé selon la réglementation en vigueur).',
      updated_at = now()
  where matiere_premiere_id = v_material_id;
end $$;

-- Vérification :
-- select name from public.raw_materials where id = (
--   select matiere_premiere_id from public.matieres_premieres_academie a
--   join public.raw_materials rm on rm.id = a.matiere_premiere_id
--   where rm.name ilike '%sulfate d''alumin%'
-- );
-- select name from public.products where name ilike '%sulfate d''alumin%';
-- select nom_chimique, synonymes from public.matieres_premieres_academie a
-- join public.raw_materials rm on rm.id = a.matiere_premiere_id
-- where rm.name ilike '%sulfate d''alumin%';
