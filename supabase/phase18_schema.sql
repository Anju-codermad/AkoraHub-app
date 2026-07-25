-- ============================================================
-- Akora Fanadiovana / AkoraHub - Schéma Phase 18
-- Étend les notifications push (Phase 17) à deux nouveaux cas :
-- - Commande passée à "expediee" ou "livree" -> notifie le client
-- - Devis passé à "accepte" ou "refuse" -> notifie l'équipe (staff)
--
-- Les triggers utilisent une clause WHEN pour ne se déclencher QUE sur un
-- vrai changement vers l'un de ces statuts précis (pas à chaque UPDATE,
-- ex: modification du montant d'un devis ne déclenche rien ici).
--
-- ⚠️ Remplacer <WEBHOOK_SECRET> par la même valeur que dans les secrets
-- de l'Edge Function (déjà fait en Phase 17, valeur identique).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

create or replace function public.notify_push_on_status_change()
returns trigger as $$
begin
  perform net.http_post(
    url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', '<WEBHOOK_SECRET>'
    ),
    body := jsonb_build_object(
      'table', TG_TABLE_NAME,
      'record', to_jsonb(NEW)
    )
  );
  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists on_order_shipped_push on public.orders;
create trigger on_order_shipped_push
  after update on public.orders
  for each row
  when (OLD.status is distinct from NEW.status and NEW.status in ('expediee', 'livree'))
  execute procedure public.notify_push_on_status_change();

drop trigger if exists on_quote_response_push on public.quotes;
create trigger on_quote_response_push
  after update on public.quotes
  for each row
  when (OLD.status is distinct from NEW.status and NEW.status in ('accepte', 'refuse'))
  execute procedure public.notify_push_on_status_change();
