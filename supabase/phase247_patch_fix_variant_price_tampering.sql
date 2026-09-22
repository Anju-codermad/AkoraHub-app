-- ============================================================
-- AkoraHub - Patch Phase 247 : le anti-fraude prix ignorait les
-- variantes
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (22/09/2026) : découvert en vérifiant le pipeline de
-- synchronisation stock ComptivA. Le trigger anti-tampering des prix
-- (`enforce_order_item_price`, phase154) recalcule TOUJOURS le prix
-- server-side à partir de `products.price_detail`/`price_gros`, même
-- quand `order_items.variant_id` est renseigné (phase4) — le prix
-- propre à la variante choisie (`product_variants.price_detail`/
-- `price_gros`, qui peut être différent, ex. "Sac 25 kg" vendu plus
-- cher que l'unité de base) était donc systématiquement écrasé par le
-- prix du produit de base pour tout client (le staff garde la main,
-- comme avant). Perte de revenu potentielle, pas juste un problème de
-- cohérence de stock.
--
-- Correctif : si `variant_id` est renseigné, recalcule à partir du
-- prix de LA VARIANTE (avec repli sur le prix du produit parent si la
-- variante a un champ à 0/non défini — même logique de repli que
-- l'affichage client, product_detail_client.dart). Sinon, comportement
-- inchangé (recalcul à partir du produit, comme avant ce patch).
-- ============================================================

create or replace function public.enforce_order_item_price()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_detail numeric;
  v_gros numeric;
  v_threshold integer;
begin
  if public.current_role_is_staff() then
    return new;
  end if;

  if new.variant_id is not null then
    select coalesce(nullif(pv.price_detail, 0), p.price_detail),
           coalesce(nullif(pv.price_gros, 0), p.price_gros),
           coalesce(pv.gros_threshold_qty, p.gros_threshold_qty)
      into v_detail, v_gros, v_threshold
      from public.product_variants pv
      join public.products p on p.id = pv.product_id
      where pv.id = new.variant_id;
    if found then
      new.is_gros_price := new.quantity >= coalesce(v_threshold, 10);
      new.unit_price := case
        when new.is_gros_price then coalesce(v_gros, v_detail)
        else coalesce(v_detail, 0)
      end;
      return new;
    end if;
  end if;

  if new.product_id is not null then
    select price_detail, price_gros, gros_threshold_qty
      into v_detail, v_gros, v_threshold
      from public.products where id = new.product_id;
    if found then
      new.is_gros_price := new.quantity >= v_threshold;
      new.unit_price := case
        when new.is_gros_price then coalesce(v_gros, v_detail)
        else coalesce(v_detail, 0)
      end;
    end if;
  end if;
  return new;
end;
$$;
