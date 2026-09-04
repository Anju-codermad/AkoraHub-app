-- ============================================================
-- AkoraHub - Patch Phase 191 : Akor'Eau devient un pilier à part
-- entière (business_unit), au même rang que Akora Pro/Home/Protect/
-- Soins/Paints/Coatings — décision explicite de la propriétaire le
-- 04/09/2026, suite aux phases 188/189/190 qui l'avaient mise en place
-- comme simple catégorie du pilier "Akora Pro".
--
-- Effet :
--   1. Crée le pilier "Akor'Eau" (slug 'akor-eau', actif).
--   2. Bascule vers ce nouveau pilier tous les produits actuellement
--      classés dans la catégorie "Akor'Eau" du pilier Akora Pro
--      (products.business_unit_id), sans toucher à leur `category`
--      texte ni à leur fiche Académie (raw_materials — axe de
--      classification séparé, non concerné par ce changement de
--      pilier).
--   3. Retire la catégorie "Akor'Eau" du pilier Akora Pro (elle n'y a
--      plus lieu d'être).
--
-- Le site web (groupe-akora-site) lit les piliers/catégories en direct
-- depuis ces deux tables — aucun changement de code nécessaire côté
-- site, le nouveau pilier apparaîtra automatiquement dans "Nos univers"
-- une fois ce script exécuté.
--
-- Pas de sous-catégories créées pour ce nouveau pilier pour l'instant
-- (comme AkoraFormation/Akora Coatings à leur lancement) — les 9
-- produits s'afficheront comme un seul groupe "Akor'Eau" dans le
-- catalogue. La propriétaire pourra les subdiviser plus tard via
-- l'Admin (ex. "Coagulants", "Anti-tartre"...) si besoin.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do nothing / conditions IF).
-- ============================================================

do $$
declare
  v_akora_pro_id uuid;
  v_akoreau_id uuid;
  v_moved_count int;
begin
  select id into v_akora_pro_id from public.business_units where slug = 'matieres-premieres';
  if v_akora_pro_id is null then
    raise notice 'Pilier Akora Pro (slug matieres-premieres) introuvable — rien fait. Vérifier le slug.';
    return;
  end if;

  -- 1) Crée le pilier Akor'Eau s'il n'existe pas déjà
  insert into public.business_units (name, slug, active)
  values ('Akor''Eau', 'akor-eau', true)
  on conflict (slug) do nothing;

  select id into v_akoreau_id from public.business_units where slug = 'akor-eau';

  -- 2) Bascule les produits de la catégorie "Akor'Eau" (pilier Akora
  -- Pro) vers le nouveau pilier
  update public.products
  set business_unit_id = v_akoreau_id
  where business_unit_id = v_akora_pro_id
    and category = 'Akor''Eau';
  get diagnostics v_moved_count = row_count;
  raise notice '% produit(s) basculé(s) vers le pilier Akor''Eau.', v_moved_count;

  -- 3) Retire la catégorie "Akor'Eau" du pilier Akora Pro
  delete from public.categories
  where business_unit_id = v_akora_pro_id
    and name = 'Akor''Eau';
end $$;

-- Vérification : produits maintenant rattachés au pilier Akor'Eau
select bu.name as pilier, bu.slug, p.name as produit, p.category
from public.products p
join public.business_units bu on bu.id = p.business_unit_id
where bu.slug = 'akor-eau'
order by p.name;
