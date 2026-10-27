-- ============================================================
-- AkoraHub - Patch Phase 273 : un "Prix Gros" non renseigné (0 Ar)
-- pouvait rendre un produit GRATUIT dès que la quantité commandée
-- atteignait le seuil Gros
--
-- Contexte (27/10/2026) : découvert via une commande manuelle "hors
-- app" — "Tripolyphosphate de sodium STPP (E451)" affichait
-- 10 × 0 Ar (prix Gros) alors que son prix Détail est de 15 800 Ar.
-- Cause racine : quand le champ "Prix Gros" est laissé vide en créant
-- un produit/variante (product_management_real.dart,
-- product_variants_screen.dart), il était enregistré tel quel comme
-- 0 — et PARTOUT dans l'app (panier client, catalogue, commande
-- manuelle), le calcul est `quantité >= seuil ? prixGros : prixDétail`,
-- donc 0 Ar était utilisé dès que la quantité atteignait le seuil
-- (10 par défaut).
--
-- Plus grave qu'un simple bug d'affichage côté staff : le trigger
-- anti-fraude prix `enforce_order_item_price` (phase154, corrigé pour
-- les variantes en phase247) ne traitait ce 0 comme "non défini" que
-- pour une VARIANTE (repli via nullif(pv.price_gros, 0)) — pas pour un
-- produit sans variante, où `coalesce(v_gros, v_detail)` ne se
-- déclenche que si v_gros est NULL, jamais s'il vaut 0. Un vrai
-- client commandant 10+ unités d'un produit dans ce cas aurait donc
-- été facturé 0 Ar pour cette ligne, même en passant par l'app
-- normalement (pas seulement via une commande manuelle saisie par le
-- staff, qui elle échappe déjà au trigger).
--
-- Corrige en deux temps :
-- 1. Données existantes : tout produit/variante avec un prix Gros à
--    0 ou non défini, alors que son prix Détail est positif, reprend
--    ce prix Détail (pas de rabais Gros accidentel, mais surtout plus
--    jamais gratuit).
-- 2. Trigger : le chemin "pas de variante" applique désormais la même
--    règle de repli (nullif(..., 0)) que le chemin "avec variante"
--    depuis la phase247, pour qu'un futur prix Gros à 0 ne puisse
--    plus jamais être facturé tel quel.
--
-- Voir aussi le correctif côté app (même commit) : les formulaires de
-- produit/variante reprennent désormais le prix Détail saisi si le
-- champ "Prix Gros" est laissé vide, au lieu d'enregistrer 0.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

-- 1. Backfill des données existantes.
update public.products
   set price_gros = price_detail
 where price_detail > 0
   and (price_gros is null or price_gros = 0);

update public.product_variants
   set price_gros = price_detail
 where price_detail > 0
   and (price_gros is null or price_gros = 0);

-- 2. Filet de sécurité côté serveur : repli sur le prix Détail même
-- quand `price_gros` vaut 0 (pas seulement NULL), pour le produit
-- comme pour la variante.
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
        when new.is_gros_price then coalesce(nullif(v_gros, 0), v_detail)
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
        when new.is_gros_price then coalesce(nullif(v_gros, 0), v_detail)
        else coalesce(v_detail, 0)
      end;
    end if;
  end if;
  return new;
end;
$$;
