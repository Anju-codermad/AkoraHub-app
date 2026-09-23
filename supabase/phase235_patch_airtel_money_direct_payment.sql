-- ============================================================
-- AkoraHub - Patch Phase 235 : Paiement Airtel Money direct (push USSD)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Ajoute le paiement Airtel Money en ligne (Collection API, push USSD)
-- comme alternative au paiement manuel (référence + preuve) déjà en place
-- pour Mvola/Orange Money/Airtel Money — au moment de payer une commande
-- réglée par Airtel Money, le client choisit entre payer directement en
-- ligne (ce patch) ou rester sur le flux manuel existant.
--
-- Limité aux commandes produits (`orders`) pour l'instant — l'acompte
-- diagnostic-eau (`website_service_requests`) pourra être ajouté plus
-- tard avec le même principe si besoin (voir create-service-request-
-- payment-link pour le pattern à suivre).
--
-- Voir supabase/functions/create-airtel-payment-request (initie le
-- paiement) et supabase/functions/airtel-payment-notification (callback
-- de confirmation envoyé par Airtel).
-- ============================================================

alter table public.orders
  add column if not exists airtel_transaction_id text,
  add column if not exists airtel_money_transaction_ref text;

-- Une transaction Airtel initiée ne doit correspondre qu'à une seule
-- commande — évite qu'un id généré en double (bug ou rejeu) ne fasse
-- confirmer la mauvaise commande à la réception du callback.
create unique index if not exists orders_airtel_transaction_id_key
  on public.orders (airtel_transaction_id)
  where airtel_transaction_id is not null;
