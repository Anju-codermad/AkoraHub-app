-- ============================================================
-- AkoraHub - Patch Phase 196 : bascule vers le pilier Akor'Eau les
-- produits restés sous Akora Pro après la Phase 190.
--
-- La Phase 190 a été écrite avant que Akor'Eau devienne un pilier à
-- part entière (Phase 191) : elle crée les 6 nouveaux produits avec
-- business_unit_id = Akora Pro (celui de leur fiche raw_materials),
-- category = 'Akor''Eau' en texte seulement. La Phase 191, qui a fait
-- ce basculement en bloc, avait déjà été exécutée AVANT que la Phase
-- 190 ne le soit enfin (04/09/2026) — ces 6 produits n'ont donc jamais
-- été basculés.
--
-- Reprend exactement la même logique que l'étape 2 de la Phase 191,
-- de façon générique (n'importe quel produit encore sous Akora Pro
-- avec category = 'Akor''Eau', pas seulement les 6 de la phase 190) —
-- pour être sûr de ne rien laisser passer si ce cas se reproduit.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (sans effet si déjà appliqué).
-- ============================================================

do $$
declare
  v_akora_pro_id uuid;
  v_akoreau_id uuid;
  v_moved_count int;
begin
  select id into v_akora_pro_id from public.business_units where slug = 'matieres-premieres';
  select id into v_akoreau_id from public.business_units where slug = 'akor-eau';

  if v_akora_pro_id is null then
    raise notice 'Pilier Akora Pro (slug matieres-premieres) introuvable — rien fait.';
    return;
  end if;
  if v_akoreau_id is null then
    raise notice 'Pilier Akor''Eau (slug akor-eau) introuvable — exécuter d''abord la phase 191.';
    return;
  end if;

  update public.products
  set business_unit_id = v_akoreau_id
  where business_unit_id = v_akora_pro_id
    and category = 'Akor''Eau';
  get diagnostics v_moved_count = row_count;
  raise notice '% produit(s) basculé(s) vers le pilier Akor''Eau.', v_moved_count;
end $$;

-- Vérification : tous les produits "Akor'Eau" doivent maintenant être
-- sous le pilier Akor'Eau (13 attendus : 9 historiques + Chaux eteinte
-- + 3 de la phase 195, en comptant les 6 de la phase 190)
-- select bu.name as pilier, p.category, p.name, p.visibility
-- from public.products p
-- join public.business_units bu on bu.id = p.business_unit_id
-- where bu.slug = 'akor-eau'
-- order by p.name;
