-- ============================================================
-- AkoraHub - Patch Phase 255 : notification push au staff à CHAQUE
-- nouvelle commande — demande explicite de la propriétaire (05/10) :
-- "Des clients font de commande ... la notification n'a pas encore
-- fonctionné".
--
-- Constat : il n'existait jusqu'ici AUCUNE notification au staff à la
-- simple création d'une commande. Le seul trigger existant sur
-- `orders` (phase39, `on_order_manual_payment_submitted_push`) ne se
-- déclenche QUE pour les paiements manuels (virement/Mvola/Orange/
-- Airtel en mode manuel) à vérifier — les commandes en paiement à la
-- livraison ou payées automatiquement en ligne ne notifiaient jamais
-- personne.
--
-- Ce trigger-ci se déclenche sur TOUTE nouvelle commande SAUF celles
-- qui ont déjà un paiement manuel à vérifier (`payment_reference`/
-- `payment_proof_path` renseignés) — celles-là gardent leur
-- notification dédiée et plus actionnable ("Paiement à vérifier",
-- phase39) ; ensemble, les deux triggers couvrent TOUTE nouvelle
-- commande avec exactement une notification chacune, sans doublon.
--
-- ⚠️ Avant d'exécuter ce script : remplace `<WEBHOOK_SECRET>` ci-dessous
-- par la même valeur secrète que les autres triggers (Edge Functions ->
-- send-push-notification -> Manage secrets -> WEBHOOK_SECRET).
--
-- ⚠️ Si les notifications ne fonctionnent toujours pas après ce script :
-- le code d'envoi (trigger + Edge Function) a l'air correct, donc la
-- cause la plus probable est une clé secrète désynchronisée (ce
-- WEBHOOK_SECRET ne correspond plus à celui de l'Edge Function, après
-- une rotation — voir phase220 — qui aurait oublié de mettre à jour
-- CE trigger-ci en même temps), ou un token FCM jamais enregistré pour
-- les comptes Admin/Commercial (profiles.fcm_token). Vérifier les deux
-- côté Dashboard Supabase.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

create or replace function public.notify_push_on_order_placed()
returns trigger as $$
begin
  perform net.http_post(
    url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', '<WEBHOOK_SECRET>'
    ),
    body := jsonb_build_object(
      'table', 'orders_new',
      'record', to_jsonb(NEW)
    )
  );
  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists on_order_placed_push on public.orders;
create trigger on_order_placed_push
  after insert on public.orders
  for each row
  when (NEW.payment_reference is null and NEW.payment_proof_path is null)
  execute procedure public.notify_push_on_order_placed();
