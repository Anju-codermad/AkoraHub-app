-- ============================================================
-- AkoraHub - Patch Phase 39 : notification push immédiate au staff
-- quand un client soumet un paiement manuel (référence et/ou photo) à
-- vérifier — pour réduire le délai de confirmation humaine (jusque-là,
-- rien ne signalait au staff qu'une commande attendait une vérification,
-- il fallait consulter la liste manuellement).
--
-- Ne concerne que virement bancaire et Mvola/Orange/Airtel en mode
-- manuel (secours) : ce sont les seuls cas où `payment_reference` ou
-- `payment_proof_path` sont renseignés à la création (voir
-- `_showManualPaymentFields` dans cart_tab.dart). Paiement à la
-- livraison et paiement automatique via Papi ne déclenchent jamais ce
-- trigger.
--
-- ⚠️ Avant d'exécuter ce script : remplace `<WEBHOOK_SECRET>` ci-dessous
-- par la même valeur secrète que les autres triggers (Edge Functions ->
-- send-push-notification -> Manage secrets -> WEBHOOK_SECRET).
-- ============================================================

create or replace function public.notify_push_on_manual_payment_submitted()
returns trigger as $$
begin
  perform net.http_post(
    url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', '<WEBHOOK_SECRET>'
    ),
    body := jsonb_build_object(
      'table', 'orders_manual_payment_submitted',
      'record', to_jsonb(NEW)
    )
  );
  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists on_order_manual_payment_submitted_push on public.orders;
create trigger on_order_manual_payment_submitted_push
  after insert on public.orders
  for each row
  when (NEW.payment_reference is not null or NEW.payment_proof_path is not null)
  execute procedure public.notify_push_on_manual_payment_submitted();
