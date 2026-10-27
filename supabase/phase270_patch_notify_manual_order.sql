-- ============================================================
-- AkoraHub - Patch Phase 270 : notifie le client quand le staff
-- enregistre une commande WhatsApp/directe en son nom
--
-- Demande explicite (27/10) : le client concerné par une commande
-- ajoutée manuellement (voir create_manual_order_screen.dart,
-- phase267) doit recevoir une notification à ce sujet — jusqu'ici il
-- ne le découvrait qu'en ouvrant l'app par hasard.
--
-- ⚠️ Avant d'exécuter ce script :
-- 1. Redéployer l'Edge Function `send-push-notification` avec le code
--    à jour du dépôt (supabase/functions/send-push-notification/index.ts,
--    nouveau cas "orders_manual_created") — Supabase Dashboard ->
--    Edge Functions -> send-push-notification -> coller le nouveau
--    code -> Deploy. Sans ce redéploiement, le trigger ci-dessous
--    appellera la fonction mais elle ne saura pas encore quoi faire de
--    ce nouveau cas.
-- 2. Remplacer <WEBHOOK_SECRET> ci-dessous par la même valeur que dans
--    les secrets de l'Edge Function (déjà utilisée en Phase 17/18).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

create or replace function public.notify_push_on_manual_order_created()
returns trigger as $$
begin
  perform net.http_post(
    url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', '<WEBHOOK_SECRET>'
    ),
    body := jsonb_build_object(
      'table', 'orders_manual_created',
      'record', to_jsonb(NEW)
    )
  );
  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists on_manual_order_created_push on public.orders;
create trigger on_manual_order_created_push
  after insert on public.orders
  for each row
  when (NEW.created_by_staff is not null)
  execute procedure public.notify_push_on_manual_order_created();
