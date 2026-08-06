-- ============================================================
-- AkoraHub - Patch Phase 77 : "M'alerter quand disponible" (rupture de stock)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : sur demande ("M'alerter quand disponible sur un [produit
-- en rupture]", 06/08) — un client s'abonne à un produit en rupture de
-- stock (stock_quantity <= 0) et reçoit une notification push dès qu'un
-- membre du staff repasse le stock au-dessus de 0. Même plomberie que
-- l'abonnement par catégorie (phase36) : une table d'abonnements + un
-- trigger qui appelle l'Edge Function `send-push-notification` déjà en
-- place, qui lit ensuite la table pour savoir qui prévenir.
--
-- ⚠️ Avant d'exécuter : remplace `<WEBHOOK_SECRET>` ci-dessous par la
-- même valeur secrète déjà utilisée pour les autres triggers (phase17/
-- phase18/phase36...) — Edge Functions -> send-push-notification ->
-- Manage secrets -> WEBHOOK_SECRET.
--
-- ⚠️ Nécessite aussi une modification du CODE de l'Edge Function
-- send-push-notification (nouveau cas `payload.table ===
-- "product_back_in_stock"`, livré dans ce même commit) — à redéployer
-- depuis Supabase Dashboard -> Edge Functions après ce script SQL.
-- ============================================================

create table if not exists public.product_stock_alerts (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (customer_id, product_id)
);

create index if not exists product_stock_alerts_product_idx
  on public.product_stock_alerts (product_id);

alter table public.product_stock_alerts enable row level security;

drop policy if exists "product_stock_alerts_own_select" on public.product_stock_alerts;
create policy "product_stock_alerts_own_select" on public.product_stock_alerts
  for select using (auth.uid() = customer_id);

drop policy if exists "product_stock_alerts_own_insert" on public.product_stock_alerts;
create policy "product_stock_alerts_own_insert" on public.product_stock_alerts
  for insert with check (auth.uid() = customer_id);

drop policy if exists "product_stock_alerts_own_delete" on public.product_stock_alerts;
create policy "product_stock_alerts_own_delete" on public.product_stock_alerts
  for delete using (auth.uid() = customer_id);

-- ------------------------------------------------------------
-- Trigger : uniquement quand stock_quantity passe de <= 0 à > 0 (pas à
-- chaque modification du produit). Ne supprime PAS les abonnements ici
-- (fait côté Edge Function, après lecture des destinataires, pour
-- éviter une course : le trigger ne fait que déclencher l'appel HTTP
-- asynchrone, il ne sait pas quand l'Edge Function l'aura traité).
-- ------------------------------------------------------------
create or replace function public.notify_push_on_product_back_in_stock()
returns trigger as $$
begin
  if coalesce(old.stock_quantity, 0) <= 0 and coalesce(new.stock_quantity, 0) > 0 then
    perform net.http_post(
      url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-webhook-secret', '<WEBHOOK_SECRET>'
      ),
      body := jsonb_build_object(
        'table', 'product_back_in_stock',
        'record', to_jsonb(new)
      )
    );
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_product_back_in_stock on public.products;
create trigger on_product_back_in_stock
  after update of stock_quantity on public.products
  for each row
  execute procedure public.notify_push_on_product_back_in_stock();
