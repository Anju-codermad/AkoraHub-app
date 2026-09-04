-- ============================================================
-- AkoraHub - Patch Phase 192 : déplace la catégorie "Traitement de
-- l'eau & Piscine" du pilier Akora Protect vers le pilier Akor'Eau —
-- décision explicite de la propriétaire le 04/09/2026, suite à la
-- phase 191 (Akor'Eau devenu pilier à part entière).
--
-- Effet :
--   1. Bascule vers Akor'Eau tous les produits actuellement classés
--      dans la catégorie "Traitement de l'eau & Piscine" du pilier
--      Akora Protect (products.business_unit_id), sans toucher à leur
--      `category` texte ("Traitement de l'eau & Piscine" reste le nom
--      de la catégorie, maintenant sous Akor'Eau plutôt qu'Akora
--      Protect).
--   2. Recrée la catégorie "Traitement de l'eau & Piscine" sous le
--      pilier Akor'Eau (categories) — première catégorie de ce pilier,
--      qui n'en avait aucune depuis la phase 191.
--   3. Retire la catégorie du pilier Akora Protect (elle n'y a plus
--      lieu d'être).
--
-- Aucun changement requis côté site web (lecture en direct).
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent.
-- ============================================================

do $$
declare
  v_protect_id uuid;
  v_akoreau_id uuid;
  v_moved_count int;
begin
  select id into v_protect_id from public.business_units where slug = 'anti-nuisibles';
  select id into v_akoreau_id from public.business_units where slug = 'akor-eau';

  if v_protect_id is null then
    raise notice 'Pilier Akora Protect (slug anti-nuisibles) introuvable — rien fait.';
    return;
  end if;
  if v_akoreau_id is null then
    raise notice 'Pilier Akor''Eau (slug akor-eau) introuvable — exécuter d''abord la phase 191.';
    return;
  end if;

  -- 1) Bascule les produits
  update public.products
  set business_unit_id = v_akoreau_id
  where business_unit_id = v_protect_id
    and category = 'Traitement de l''eau & Piscine';
  get diagnostics v_moved_count = row_count;
  raise notice '% produit(s) basculé(s) vers Akor''Eau.', v_moved_count;

  -- 2) Recrée la catégorie sous Akor'Eau
  insert into public.categories (business_unit_id, name)
  values (v_akoreau_id, 'Traitement de l''eau & Piscine')
  on conflict (business_unit_id, name) do nothing;

  -- 3) Retire la catégorie du pilier Akora Protect
  delete from public.categories
  where business_unit_id = v_protect_id
    and name = 'Traitement de l''eau & Piscine';
end $$;

-- Vérification : produits maintenant rattachés à Akor'Eau, par catégorie
select bu.name as pilier, p.category, p.name as produit
from public.products p
join public.business_units bu on bu.id = p.business_unit_id
where bu.slug = 'akor-eau'
order by p.category, p.name;
