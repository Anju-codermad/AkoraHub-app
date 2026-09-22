-- ============================================================
-- AkoraHub - Patch Phase 245 : notifie ComptivA à chaque commande livrée
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (22/09/2026, demande explicite) : ComptivA (logiciel de
-- comptabilité, projet Supabase SÉPARÉ — jxehggyclclssshorphd) doit
-- recevoir automatiquement les ventes d'AkoraHub pour mettre à jour son
-- propre stock. Le lien entre un produit ComptivA et un produit
-- AkoraHub se fait manuellement côté ComptivA (bouton "Lier à un
-- produit AkoraHub" où l'utilisatrice colle le lien copié depuis
-- l'Admin AkoraHub — voir phase245 côté app, bouton "Copier le lien
-- produit" dans product_management_real.dart) : ComptivA stocke l'ID
-- produit AkoraHub extrait de ce lien, AkoraHub n'a donc besoin de rien
-- savoir sur ce qui est lié ou pas — il notifie TOUJOURS, et c'est
-- ComptivA qui décide s'il y a un produit correspondant.
--
-- Déclenché quand une commande passe au statut "livree" (le stock
-- physique quitte réellement l'entrepôt à ce moment-là — pas à la
-- simple création de la commande, qui peut encore être annulée).
-- Regroupe les lignes de la commande par produit (une commande peut
-- avoir plusieurs variantes du même produit) avant l'envoi.
--
-- Même mécanisme que les triggers de notification push existants
-- (voir phase78_patch_rotate_webhook_secret.sql) : `net.http_post`
-- directement depuis un trigger Postgres, fire-and-forget (pg_net) —
-- si l'Edge Function ComptivA n'existe pas encore ou est indisponible,
-- l'appel échoue silencieusement sans rien casser côté AkoraHub.
--
-- ⚠️ AVANT d'exécuter ce script :
-- 1) Remplace `<COMPTIVA_WEBHOOK_SECRET>` ci-dessous par la vraie
--    valeur (donnée séparément, jamais commitée dans ce fichier).
-- 2) Cette même valeur doit être configurée côté ComptivA (Dashboard
--    ComptivA -> Edge Functions -> receive-akorahub-sale -> Manage
--    secrets -> COMPTIVA_WEBHOOK_SECRET) — l'Edge Function elle-même
--    doit encore être créée côté ComptivA (hors périmètre de ce
--    dépôt), voir le message de relais fourni pour cette conversation.
-- ============================================================

create or replace function public.notify_comptiva_on_order_delivered()
returns trigger as $$
declare
  items jsonb;
begin
  select jsonb_agg(jsonb_build_object(
    'akorahub_product_id', grouped.product_id,
    'product_name', grouped.product_name,
    'quantity', grouped.total_qty
  ))
  into items
  from (
    select product_id, min(product_name) as product_name, sum(quantity) as total_qty
    from public.order_items
    where order_id = new.id and product_id is not null
    group by product_id
  ) grouped;

  if items is null then
    return new;
  end if;

  perform net.http_post(
    url := 'https://jxehggyclclssshorphd.supabase.co/functions/v1/receive-akorahub-sale',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-comptiva-webhook-secret', '<COMPTIVA_WEBHOOK_SECRET>'
    ),
    body := jsonb_build_object(
      'order_id', new.id,
      'order_number', new.order_number,
      'delivered_at', now(),
      'items', items
    )
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_notify_comptiva_on_order_delivered on public.orders;
create trigger trg_notify_comptiva_on_order_delivered
  after update on public.orders
  for each row
  when (new.status = 'livree' and old.status is distinct from 'livree')
  execute function public.notify_comptiva_on_order_delivered();
