-- ============================================================
-- Akora Fanadiovana / AkoraHub - Schéma Phase 17
-- Déclenchement réel des notifications push : à chaque nouveau message
-- (messagerie ou négociation de devis), appelle automatiquement l'Edge
-- Function `send-push-notification` (voir
-- supabase/functions/send-push-notification/index.ts) qui envoie la
-- vraie notification via Firebase.
--
-- ⚠️ IMPORTANT avant d'exécuter ce script :
-- 1. L'Edge Function `send-push-notification` doit déjà être déployée
--    (Supabase Dashboard -> Edge Functions).
-- 2. Remplacer <WEBHOOK_SECRET> ci-dessous par la même valeur que celle
--    définie dans les secrets de l'Edge Function (WEBHOOK_SECRET).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

create extension if not exists pg_net with schema extensions;

create or replace function public.notify_push_on_new_message()
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

drop trigger if exists on_new_message_push on public.messages;
create trigger on_new_message_push
  after insert on public.messages
  for each row execute procedure public.notify_push_on_new_message();

drop trigger if exists on_new_quote_message_push on public.quote_messages;
create trigger on_new_quote_message_push
  after insert on public.quote_messages
  for each row execute procedure public.notify_push_on_new_message();
