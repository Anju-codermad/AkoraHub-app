-- ============================================================
-- AkoraHub - Patch Phase 180 : rapprochement automatique des paiements
-- Mobile Money par lecture de SMS
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : les API marchandes officielles (Mvola/Orange/Airtel) sont
-- trop chères pour le volume actuel. Solution retenue : le client paie
-- manuellement par USSD comme aujourd'hui (voir phase27/28/29), mais un
-- téléphone Android dédié (SIM marchande + appli SMS-vers-webhook) relaie
-- chaque SMS de confirmation reçu vers la fonction Edge
-- `mobile-money-sms-webhook`, qui tente de le rapprocher automatiquement
-- d'une commande "en_attente". Si le rapprochement est ambigu (plusieurs
-- commandes au même montant) ou échoue, l'événement reste "unmatched" et
-- attend une validation manuelle côté staff (nouvel écran admin).
--
-- Sécurité : cette table contient des données financières sensibles
-- (numéros, montants) — RLS activé, lecture réservée au staff, aucune
-- écriture cliente directe. La fonction Edge écrit avec la clé service
-- role (contourne RLS), et le rapprochement manuel passe par la fonction
-- security definer ci-dessous plutôt qu'une policy UPDATE large.
-- ============================================================

create table if not exists public.mobile_money_sms_events (
  id uuid primary key default gen_random_uuid(),
  operator text not null check (operator in ('mvola', 'orange_money', 'airtel_money')),
  raw_text text not null,
  parsed_amount numeric,
  parsed_sender_phone text,
  parsed_reference text,
  sms_received_at timestamptz not null default now(),
  matched_order_id uuid references public.orders(id),
  match_status text not null default 'unmatched'
    check (match_status in ('unmatched', 'auto_matched', 'manual_matched', 'ignored')),
  created_at timestamptz not null default now()
);

create index if not exists mobile_money_sms_events_match_status_idx
  on public.mobile_money_sms_events (match_status);

alter table public.mobile_money_sms_events enable row level security;

drop policy if exists "mobile_money_sms_events_select_staff" on public.mobile_money_sms_events;
create policy "mobile_money_sms_events_select_staff" on public.mobile_money_sms_events
  for select using (public.current_role_is_staff());

-- Rapprochement manuel (écran admin) : marque la commande payée ET
-- l'événement SMS comme rapproché, dans la même transaction. Une
-- fonction dédiée plutôt qu'une policy UPDATE : le staff ne doit pouvoir
-- que lier un événement existant à une commande en attente, jamais
-- modifier le montant, le texte brut ou toute autre colonne.
create or replace function public.manually_match_mobile_money_payment(
  p_event_id uuid,
  p_order_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.current_role_is_staff() then
    raise exception 'Réservé au staff.';
  end if;

  update public.mobile_money_sms_events
  set matched_order_id = p_order_id, match_status = 'manual_matched'
  where id = p_event_id and match_status = 'unmatched';

  if not found then
    raise exception 'Événement introuvable ou déjà rapproché.';
  end if;

  update public.orders
  set payment_status = 'paye'
  where id = p_order_id and payment_status = 'en_attente';

  if not found then
    raise exception 'Commande introuvable ou déjà réglée.';
  end if;
end;
$$;

grant execute on function public.manually_match_mobile_money_payment(uuid, uuid) to authenticated;

-- Permet d'ignorer un événement qui ne correspond à aucune commande
-- (mauvais numéro, virement personnel sans rapport, etc.) pour le sortir
-- de la file d'attente de l'écran admin.
create or replace function public.ignore_mobile_money_sms_event(p_event_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.current_role_is_staff() then
    raise exception 'Réservé au staff.';
  end if;

  update public.mobile_money_sms_events
  set match_status = 'ignored'
  where id = p_event_id and match_status = 'unmatched';
end;
$$;

grant execute on function public.ignore_mobile_money_sms_event(uuid) to authenticated;
