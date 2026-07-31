-- ============================================================
-- AkoraHub - Patch Phase 38 : Paiement en ligne automatique (Papi.mg)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Remplace la vérification manuelle (référence + photo) pour Mvola/Orange
-- Money/Airtel Money par un paiement en ligne réel via Papi.mg
-- (agrégateur Mobile Money malgache) — le client est redirigé vers une
-- page de paiement sécurisée, Papi confirme automatiquement via un
-- webhook plutôt qu'une vérification manuelle par le staff.
--
-- Le virement bancaire et le paiement à la livraison restent manuels
-- (Papi ne les gère pas).
--
-- ⚠️ Un mode "secours manuel" reste disponible (`manuel_fallback` dans
-- `payment_method_settings`, désactivé par défaut) — l'Admin peut
-- l'activer pour revenir temporairement au flux manuel (référence +
-- photo) si Papi est indisponible.
--
-- ⚠️ Avant d'exécuter ce script : remplace `<WEBHOOK_SECRET>` ci-dessous
-- par la même valeur secrète que les autres triggers (Edge Functions ->
-- send-push-notification -> Manage secrets -> WEBHOOK_SECRET).
-- ============================================================

-- ------------------------------------------------------------
-- 1) Colonnes pour suivre le paiement Papi sur une commande.
-- ------------------------------------------------------------
alter table public.orders
  add column if not exists papi_notification_token text,
  add column if not exists papi_payment_link text;

-- "echoue" ajouté : un paiement Papi refusé est un état différent de
-- "en_attente" (jamais tenté) — le client doit savoir qu'il faut
-- réessayer, pas juste attendre.
alter table public.orders
  drop constraint if exists orders_payment_status_check;
alter table public.orders
  add constraint orders_payment_status_check
    check (payment_status in (
      'en_attente','acompte_verse','paye','facture_30j','echoue'
    ));

-- ------------------------------------------------------------
-- 2) Mode secours manuel — un réglage de plus dans la table déjà
-- utilisée pour activer/désactiver chaque mode de paiement (phase28).
-- Un `method_id` qui ne correspond à aucun `PaymentMethod` de l'app :
-- n'apparaît donc jamais comme un choix de paiement pour le client,
-- seulement comme un interrupteur dans l'écran Admin.
-- ------------------------------------------------------------
insert into public.payment_method_settings (method_id, enabled)
values ('manuel_fallback', false)
on conflict (method_id) do nothing;

-- ------------------------------------------------------------
-- 3) Notification push quand Papi confirme (ou rejette) un paiement —
-- même modèle que phase17/18/36/37, réutilise l'Edge Function
-- existante. Table synthétique "orders_payment_status" (pas "orders")
-- pour que l'Edge Function distingue ce cas de la notification
-- existante sur le statut de LIVRAISON (expediee/livree, phase18) —
-- les deux triggers peuvent modifier la même ligne `orders` sans se
-- confondre.
-- ------------------------------------------------------------
create or replace function public.notify_push_on_payment_status_change()
returns trigger as $$
begin
  perform net.http_post(
    url := 'https://lmnprtwelmmoiuygvgmf.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', '<WEBHOOK_SECRET>'
    ),
    body := jsonb_build_object(
      'table', 'orders_payment_status',
      'record', to_jsonb(NEW)
    )
  );
  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists on_order_payment_confirmed_push on public.orders;
create trigger on_order_payment_confirmed_push
  after update on public.orders
  for each row
  when (OLD.payment_status is distinct from NEW.payment_status
        and NEW.payment_status in ('paye', 'echoue'))
  execute procedure public.notify_push_on_payment_status_change();
