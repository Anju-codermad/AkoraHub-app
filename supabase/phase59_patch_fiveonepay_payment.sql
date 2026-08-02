-- ============================================================
-- AkoraHub - Patch Phase 59 : Intégration FiveOne Pay (Lot 1/4 — SQL)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Second fournisseur de paiement en ligne Mobile Money, en plus de Papi
-- (Phase 38) — pas un remplacement. Une seule API FiveOne Pay pour les 3
-- opérateurs (MVola/Orange Money/Airtel Money), contrairement à Papi qui
-- avait besoin d'un `provider` distinct par appel mais restait, lui
-- aussi, un seul agrégateur.
--
-- Modèle retenu (demande explicite : réglages "clairs, séparés par nom
-- de plateforme" côté Admin) : chaque opérateur (mvola/orange_money/
-- airtel_money) garde UNE SEULE ligne dans `payment_method_settings`
-- (Phase 28), avec une nouvelle colonne `provider` ('papi' ou
-- 'fiveonepay') qui dit LEQUEL des deux le traite. Impossible d'avoir
-- les deux en même temps pour le même opérateur (une seule colonne, pas
-- d'ambiguïté sur qui confirme le paiement) — l'écran Admin affichera
-- juste ce même réglage regroupé visuellement par plateforme (Papi.mg /
-- FiveOne Pay / Manuel), voir Lot 4. Le client, lui, continue de voir
-- simplement "MVola / Orange Money / Airtel Money / Manuel" au
-- checkout — inchangé, il n'a pas besoin de savoir qui traite derrière.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Quel fournisseur traite chaque opérateur Mobile Money — nullable
-- pour paiement_livraison/virement_bancaire/manuel_fallback (pas
-- concernés, ce sont des modes toujours manuels). 'papi' par défaut
-- pour rester sur le comportement actuel tant que l'Admin ne bascule
-- rien.
-- ------------------------------------------------------------
alter table public.payment_method_settings
  add column if not exists provider text
    check (provider in ('papi', 'fiveonepay'));

update public.payment_method_settings
set provider = 'papi'
where method_id in ('mvola', 'orange_money', 'airtel_money')
  and provider is null;

-- ------------------------------------------------------------
-- 2) Colonnes de suivi FiveOne Pay sur une commande — même principe que
-- papi_notification_token/papi_payment_link (Phase 38), mais pas besoin
-- d'un token par commande : FiveOne Pay signe TOUT le corps du webhook
-- (HMAC-SHA256, secret whsec_..., voir Lot 3), l'authenticité ne dépend
-- pas d'une valeur stockée par commande.
-- ------------------------------------------------------------
alter table public.orders
  add column if not exists fiveonepay_reference text,
  add column if not exists fiveonepay_payment_url text;

-- ------------------------------------------------------------
-- 3) Déduplication des webhooks FiveOne Pay — la doc garantit un retry
-- avec backoff jusqu'à réception d'un 2xx, et fournit un
-- X-FiveOne-Event-Id pour reconnaître un envoi déjà traité. Une ligne
-- par event_id déjà vu ; l'insertion échoue silencieusement
-- (on conflict do nothing) si l'event a déjà été traité, ce qui sert de
-- verrou (voir Lot 3 : le webhook ignore l'événement si 0 ligne
-- insérée).
-- ------------------------------------------------------------
create table if not exists public.fiveonepay_webhook_events (
  event_id text primary key,
  received_at timestamptz not null default now()
);

alter table public.fiveonepay_webhook_events enable row level security;

-- Aucune policy select/insert/update pour les rôles authentifiés : cette
-- table n'est écrite que par l'Edge Function via la service role key
-- (qui contourne RLS), jamais par l'app cliente ou l'Admin.
