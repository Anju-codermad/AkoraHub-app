-- ============================================================
-- AkoraHub - Patch Phase 309 : wallet marchand Airtel Money (paiement
-- automatique) + paiement manuel activable par moyen de paiement
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (23/11) : Airtel a approuvé l'application en production
-- (wallet marchand communiqué par Airtel). Demandes explicites :
--   1. Le paiement manuel (envoi sur un numéro + preuve) reste une
--      option, activable/désactivable PAR MOYEN de paiement depuis
--      l'administration, avec les coordonnées affichées modifiables.
--   2. Le paiement Airtel Money en ligne (push USSD, argent versé
--      directement sur le wallet marchand) s'active depuis
--      l'administration.
--   3. Une page « Payer Akora Fanadiovana » à partager (WhatsApp,
--      Facebook, devis) : le client saisit le montant et la référence de
--      son devis/facture et paie par Airtel Money -> table direct_payments.
--
-- Idempotent : peut être relancé sans risque. Aucune donnée existante
-- modifiée (les nouvelles colonnes gardent le comportement actuel par
-- défaut : manuel activé, paiement en ligne désactivé).
-- ============================================================

-- ------------------------------------------------------------
-- 1) Réglages par moyen de paiement (table de la phase 28)
-- ------------------------------------------------------------
alter table public.payment_method_settings
  add column if not exists manual_enabled boolean not null default true,
  add column if not exists manual_instructions text,
  add column if not exists online_enabled boolean not null default false;

comment on column public.payment_method_settings.manual_enabled is
  'Paiement manuel (envoi sur le numéro/compte affiché + preuve) proposé au client. Sans objet pour paiement_livraison.';
comment on column public.payment_method_settings.manual_instructions is
  'Coordonnées affichées pour le paiement manuel (numéro, titulaire, IBAN...). Null = texte par défaut du site/de l''App.';
comment on column public.payment_method_settings.online_enabled is
  'Paiement en ligne automatique proposé au client (actuellement : airtel_money, push USSD vers le wallet marchand).';

-- ------------------------------------------------------------
-- 2) Paiements directs (page « Payer Akora Fanadiovana »)
-- Écrits uniquement par l'Edge Function create-airtel-direct-payment
-- (service role) et par le callback airtel-payment-notification ; lus
-- et annotés par le staff depuis l'administration.
-- ------------------------------------------------------------
create table if not exists public.direct_payments (
  id uuid primary key default gen_random_uuid(),
  payer_name text not null,
  reference text,
  amount numeric not null check (amount >= 100),
  msisdn text not null,
  method text not null default 'airtel_money',
  status text not null default 'en_attente'
    check (status in ('en_attente', 'paye', 'echoue')),
  airtel_transaction_id text,
  airtel_money_transaction_ref text,
  error_message text,
  staff_note text,
  created_at timestamptz not null default now(),
  paid_at timestamptz,
  updated_at timestamptz not null default now()
);

create unique index if not exists direct_payments_airtel_tx_idx
  on public.direct_payments (airtel_transaction_id)
  where airtel_transaction_id is not null;
create index if not exists direct_payments_created_at_idx
  on public.direct_payments (created_at desc);
create index if not exists direct_payments_msisdn_created_idx
  on public.direct_payments (msisdn, created_at desc);

create or replace function public.direct_payments_touch()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  if new.status = 'paye' and new.paid_at is null then
    new.paid_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists direct_payments_touch on public.direct_payments;
create trigger direct_payments_touch
  before insert or update on public.direct_payments
  for each row execute function public.direct_payments_touch();

alter table public.direct_payments enable row level security;

-- Aucune policy pour les visiteurs : ils ne voient jamais la table (ni les
-- numéros des autres payeurs). Le suivi de leur propre paiement passe par
-- la fonction get_direct_payment_status ci-dessous.
drop policy if exists "direct_payments_staff_select" on public.direct_payments;
create policy "direct_payments_staff_select" on public.direct_payments
  for select using (public.current_role_is_staff());

-- Le staff peut seulement annoter (staff_note) ou corriger un statut à la
-- main ; la création passe toujours par l'Edge Function.
drop policy if exists "direct_payments_staff_update" on public.direct_payments;
create policy "direct_payments_staff_update" on public.direct_payments
  for update using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- ------------------------------------------------------------
-- 3) Suivi par le payeur (page d'attente) : statut seulement, à partir de
-- l'identifiant (UUID impossible à deviner) renvoyé à SON navigateur.
-- ------------------------------------------------------------
create or replace function public.get_direct_payment_status(p_id uuid)
returns table (status text, amount numeric, reference text, paid_at timestamptz)
language sql
security definer
set search_path = public
stable
as $$
  select d.status, d.amount, d.reference, d.paid_at
  from public.direct_payments d
  where d.id = p_id;
$$;

grant execute on function public.get_direct_payment_status(uuid) to anon, authenticated;
