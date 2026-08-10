-- ============================================================
-- AkoraHub - Patch Phase 154 : CORRECTIF CRITIQUE — falsification du
-- prix des commandes (order_items.unit_price / orders.total_amount)
--
-- Faille trouvée le 10/08 (revue systématique des policies RLS,
-- suite du fix profiles.role) : `order_items_insert_own` (phase1/2)
-- vérifie seulement que la commande (`order_id`) appartient bien au
-- client, jamais que `unit_price`/`is_gros_price` correspondent au
-- vrai prix du produit. `orders_insert_own` ne vérifie pas non plus
-- `total_amount`. Confirmé dans le code Flutter (payment_screen.dart)
-- : le prix, le drapeau prix Gros et le total sont calculés côté
-- CLIENT et envoyés tels quels — un client pouvait donc passer une
-- vraie commande à n'importe quel prix (0 Ar, négatif...) en appelant
-- l'API directement, sans passer par l'interface de l'app.
--
-- Même faille trouvée sur `recurring_order_items` (commandes
-- récurrentes, phase13_schema_a.sql) : `process_recurring_orders()`
-- utilise le `unit_price` stocké tel quel pour générer de VRAIES
-- commandes automatiquement à intervalle régulier — encore plus
-- risqué car sans repasser par l'app à chaque fois.
--
-- `quote_items` (devis) n'est PAS concerné : un devis reste une
-- simple proposition tant que le staff ne l'a pas traité
-- manuellement (`quotes_update_staff`, aucune policy ne permet à un
-- client de faire passer un devis à "accepté" lui-même) — un prix
-- fantaisiste sur un devis ne débouche sur rien sans validation
-- humaine, contrairement à une commande.
--
-- Correctif : même principe que le trigger `profiles.role` — un
-- trigger BEFORE INSERT/UPDATE recalcule `unit_price` à partir du
-- VRAI prix courant du produit (`products.price_detail`/`price_gros`
-- selon `gros_threshold_qty`) pour toute ligne créée/modifiée par un
-- compte qui n'est pas déjà staff (le staff garde la main pour les
-- ajustements manuels). Un trigger AFTER sur `order_items` recalcule
-- ensuite `orders.total_amount` à partir de la vraie somme des
-- lignes + frais de livraison, pour que la falsification du total au
-- moment de la création de la commande n'ait plus aucun effet.
--
-- Non couvert par ce patch (résiduel, ampleur bien plus limitée) :
-- `orders.delivery_fee` reste calculé côté client sans table de
-- référence des zones/tarifs en base pour le revalider — nécessiterait
-- une vraie table de zones de livraison, à voir séparément si besoin.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

-- ------------------------------------------------------------
-- 1) order_items : impose le vrai prix produit, sauf pour le staff
-- ------------------------------------------------------------
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

drop trigger if exists enforce_order_item_price_trigger on public.order_items;
create trigger enforce_order_item_price_trigger
  before insert or update on public.order_items
  for each row execute function public.enforce_order_item_price();

-- ------------------------------------------------------------
-- 2) orders.total_amount : toujours recalculé depuis la vraie somme
-- des lignes (déjà sécurisées par le trigger ci-dessus) + frais de
-- livraison — annule toute falsification tentée à la création de la
-- commande elle-même.
-- ------------------------------------------------------------
create or replace function public.recompute_order_total()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order_id uuid;
  v_sum numeric;
  v_fee numeric;
begin
  v_order_id := coalesce(new.order_id, old.order_id);
  if v_order_id is null then
    return null;
  end if;
  select coalesce(sum(quantity * unit_price), 0) into v_sum
    from public.order_items where order_id = v_order_id;
  select coalesce(delivery_fee, 0) into v_fee
    from public.orders where id = v_order_id;
  update public.orders set total_amount = v_sum + v_fee where id = v_order_id;
  return null;
end;
$$;

drop trigger if exists recompute_order_total_trigger on public.order_items;
create trigger recompute_order_total_trigger
  after insert or update or delete on public.order_items
  for each row execute function public.recompute_order_total();

-- ------------------------------------------------------------
-- 3) recurring_order_items : même protection, essentielle ici car
-- ces lignes génèrent automatiquement de vraies commandes sans repasser
-- par l'app (voir process_recurring_orders(), phase13_schema_a.sql).
-- Entouré d'un test d'existence (10/08) : la table peut ne pas exister
-- sur toutes les bases si phase13_schema_a.sql n'a jamais été exécuté
-- (fonctionnalité "Commandes récurrentes" présente dans le code Flutter
-- mais migration jamais lancée) — sans ce garde-fou, cette partie fait
-- échouer TOUT le script (y compris les parties 1 et 2, plus critiques)
-- avec "relation does not exist" si la table est absente.
-- ------------------------------------------------------------
do $$
begin
  if to_regclass('public.recurring_order_items') is not null then
    execute $ddl$
      create or replace function public.enforce_recurring_order_item_price()
      returns trigger
      language plpgsql
      security definer
      set search_path = public
      as $func$
      declare
        v_detail numeric;
        v_gros numeric;
        v_threshold integer;
      begin
        if public.current_role_is_staff() then
          return new;
        end if;
        if new.product_id is not null then
          select price_detail, price_gros, gros_threshold_qty
            into v_detail, v_gros, v_threshold
            from public.products where id = new.product_id;
          if found then
            new.unit_price := case
              when new.quantity >= v_threshold then coalesce(v_gros, v_detail)
              else coalesce(v_detail, 0)
            end;
          end if;
        end if;
        return new;
      end;
      $func$;

      drop trigger if exists enforce_recurring_order_item_price_trigger on public.recurring_order_items;
      create trigger enforce_recurring_order_item_price_trigger
        before insert or update on public.recurring_order_items
        for each row execute function public.enforce_recurring_order_item_price();
    $ddl$;
  end if;
end $$;
