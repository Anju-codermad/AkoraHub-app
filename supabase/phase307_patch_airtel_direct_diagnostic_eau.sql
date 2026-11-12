-- ============================================================
-- AkoraHub - Patch Phase 307 : Paiement Airtel Money direct pour
-- l'acompte diagnostic-eau (website_service_requests)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Suite du phase235 (paiement Airtel Money direct, limité à `orders`
-- à l'époque — voir son commentaire "pourra être ajouté plus tard avec
-- le même principe si besoin"). Papi.mg et FiveOne Pay sont retirés du
-- flux Airtel Money (remplacés par l'API Collection Airtel directe,
-- comme pour les commandes produits) ; ce patch donne à
-- `website_service_requests` les mêmes colonnes que `orders` pour que
-- create-service-request-payment-link et airtel-payment-notification
-- puissent faire la même chose sur cette table.
--
-- Mvola et Orange Money restent inchangés sur ce flux (toujours via
-- Papi/FiveOne Pay, aucune intégration directe pour ces deux opérateurs
-- à ce jour).
-- ============================================================

alter table public.website_service_requests
  add column if not exists airtel_transaction_id text,
  add column if not exists airtel_money_transaction_ref text;

-- Même garde qu'orders_airtel_transaction_id_key (phase235) : une
-- transaction Airtel initiée ne doit correspondre qu'à une seule demande.
create unique index if not exists website_service_requests_airtel_transaction_id_key
  on public.website_service_requests (airtel_transaction_id)
  where airtel_transaction_id is not null;
