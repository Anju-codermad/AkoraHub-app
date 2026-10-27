-- ============================================================
-- AkoraHub - Patch Phase 268 : garde products.price_detail/price_gros
-- synchronisés avec la variante la moins chère, à chaque ajout/
-- modification/suppression de variante
--
-- Demande explicite (27/10, suite du correctif d'affichage prix/unité) :
-- l'utilisatrice a demandé de vérifier si l'ajout de produit/variante
-- avait un bug dans le catalogue. Trouvé en lisant product_variants_
-- screen.dart : ajouter ou modifier une variante n'écrit QUE dans
-- product_variants — products.price_detail/price_gros/gros_threshold_qty
-- (mis à jour une seule fois par le backfill phase185) ne sont jamais
-- recalculés ensuite. Au-delà de l'affichage (déjà corrigé côté app,
-- voir cheapestVariantPriceAndUnit), ça a un vrai impact financier :
-- - "Ajout rapide" (quick-add, catalog_tab.dart/product_detail_client.dart
--   "Vous pourriez aussi aimer") utilise products.price_detail/price_gros
--   DIRECTEMENT, sans passer par les variantes.
-- - Le trigger anti-falsification de prix (phase154,
--   enforce_order_item_price) lit LUI AUSSI products.price_detail/
--   price_gros pour imposer le prix final d'une commande — toujours à
--   partir du produit, jamais de la variante, même quand un variant_id
--   est renseigné.
-- Un produit avec une variante moins chère ajoutée après le backfill
-- pouvait donc facturer un prix périmé à un vrai client via l'ajout
-- rapide, sans qu'aucun mécanisme ne corrige ça automatiquement.
--
-- Correctif : un trigger sur product_variants (même principe que
-- recompute_order_total, phase154) recalcule products.price_detail/
-- price_gros/gros_threshold_qty depuis la variante la moins chère à
-- chaque insert/update/delete — reste donc toujours à jour, quelle que
-- soit l'interface utilisée pour gérer les variantes.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

create or replace function public.sync_product_base_price()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_product_id uuid;
  v_cheapest record;
begin
  v_product_id := coalesce(new.product_id, old.product_id);
  if v_product_id is null then
    return null;
  end if;

  select price_detail, price_gros, gros_threshold_qty
    into v_cheapest
    from public.product_variants
    where product_id = v_product_id
    order by price_detail asc
    limit 1;

  -- Si la dernière variante vient d'être supprimée, on garde le dernier
  -- prix connu sur le produit plutôt que de le remettre à zéro.
  if found then
    update public.products
      set price_detail = v_cheapest.price_detail,
          price_gros = v_cheapest.price_gros,
          gros_threshold_qty = v_cheapest.gros_threshold_qty
      where id = v_product_id;
  end if;

  return null;
end;
$$;

drop trigger if exists sync_product_base_price_trigger on public.product_variants;
create trigger sync_product_base_price_trigger
  after insert or update or delete on public.product_variants
  for each row execute function public.sync_product_base_price();

-- Rattrapage immédiat (27/10) : resynchronise tous les produits ayant
-- déjà des variantes, pour corriger tout de suite les écarts existants
-- (pas seulement les futurs changements) — même logique que le trigger
-- ci-dessus, appliquée une fois à l'ensemble du catalogue.
update public.products p
set price_detail = v.price_detail,
    price_gros = v.price_gros,
    gros_threshold_qty = v.gros_threshold_qty
from (
  select distinct on (product_id)
    product_id, price_detail, price_gros, gros_threshold_qty
  from public.product_variants
  order by product_id, price_detail asc
) v
where v.product_id = p.id;
