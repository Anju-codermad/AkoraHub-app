-- ============================================================
-- AkoraHub - Patch Phase 175 : alertes de stock étendues aux variantes
-- (conditionnements)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (14/08, suggestion validée par l'Admin) : depuis les
-- conditionnements industriels (Phase 172), chaque variante
-- (product_variants) a son propre stock indépendant du produit "parent"
-- — mais ni l'alerte admin "stock bas" (côté app uniquement, pas de
-- changement SQL nécessaire) ni la notification client "M'alerter quand
-- disponible" (phase77) ne surveillaient ce stock par variante. Un
-- conditionnement précis (ex. "Sac 25 kg") pouvait tomber à zéro puis
-- revenir en stock sans que personne ne soit prévenu.
--
-- Réutilise TEL QUEL la table `product_stock_alerts` (abonnement par
-- produit, pas par variante — pas de nouvelle table ni de changement
-- d'UI client nécessaire) et le même code Edge Function déjà en place
-- (payload.table = 'product_back_in_stock') : le trigger ci-dessous
-- reconstruit juste un payload {id, name} à partir du produit parent de
-- la variante, pour que ça matche exactement ce que l'Edge Function
-- attend déjà.
--
-- ⚠️ Avant d'exécuter : remplace `<WEBHOOK_SECRET>` par la même valeur
-- secrète que les autres triggers (Edge Functions -> send-push-notification
-- -> Manage secrets -> WEBHOOK_SECRET). Aucun redéploiement de l'Edge
-- Function nécessaire — le code existant gère déjà ce cas.
-- ============================================================

create or replace function public.notify_push_on_variant_back_in_stock()
returns trigger as $$
declare
  v_product record;
begin
  if coalesce(old.stock_quantity, 0) <= 0 and coalesce(new.stock_quantity, 0) > 0 then
    select id, name into v_product
    from public.products
    where id = new.product_id;

    if v_product.id is not null then
      perform net.http_post(
        url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'x-webhook-secret', '<WEBHOOK_SECRET>'
        ),
        body := jsonb_build_object(
          'table', 'product_back_in_stock',
          'record', jsonb_build_object('id', v_product.id, 'name', v_product.name)
        )
      );
    end if;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_variant_back_in_stock on public.product_variants;
create trigger on_variant_back_in_stock
  after update of stock_quantity on public.product_variants
  for each row
  execute procedure public.notify_push_on_variant_back_in_stock();
