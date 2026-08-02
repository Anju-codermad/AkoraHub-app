-- ============================================================
-- AkoraHub - Patch Phase 58 : notification push immédiate au staff
-- quand un client soumet une demande d'achat Formation (matière première
-- ou cours AkoraFormation) — même lacune que celle corrigée en Phase 39
-- pour les paiements manuels de commande : jusqu'ici rien ne signalait au
-- staff qu'une demande attendait vérification, il fallait consulter
-- "Achats Formation" manuellement (voir aussi la fusion des deux écrans
-- de validation en un seul avec onglets, formation_purchases_hub.dart).
--
-- ⚠️ Avant d'exécuter ce script : remplace `<WEBHOOK_SECRET>` aux DEUX
-- endroits ci-dessous par la même valeur secrète que les autres triggers
-- (Edge Functions -> send-push-notification -> Manage secrets ->
-- WEBHOOK_SECRET).
-- ============================================================

create or replace function public.notify_push_on_formation_purchase_submitted()
returns trigger as $$
begin
  perform net.http_post(
    url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', '<WEBHOOK_SECRET>'
    ),
    body := jsonb_build_object(
      'table', 'formation_purchases',
      'record', to_jsonb(NEW)
    )
  );
  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists on_formation_purchase_submitted_push on public.formation_purchases;
create trigger on_formation_purchase_submitted_push
  after insert on public.formation_purchases
  for each row
  when (NEW.status = 'en_attente')
  execute procedure public.notify_push_on_formation_purchase_submitted();

create or replace function public.notify_push_on_course_purchase_submitted()
returns trigger as $$
begin
  perform net.http_post(
    url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', '<WEBHOOK_SECRET>'
    ),
    body := jsonb_build_object(
      'table', 'course_purchases',
      'record', to_jsonb(NEW)
    )
  );
  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists on_course_purchase_submitted_push on public.course_purchases;
create trigger on_course_purchase_submitted_push
  after insert on public.course_purchases
  for each row
  when (NEW.status = 'en_attente')
  execute procedure public.notify_push_on_course_purchase_submitted();
