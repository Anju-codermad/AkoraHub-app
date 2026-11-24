-- ============================================================
-- AkoraHub - Patch Phase 312 : paiement MVola en ligne (API Merchant Pay)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- (APRÈS phase310 et phase311)
--
-- Préparé le 24/11 en attendant les identifiants API MVola (compte
-- Entreprise activé le 24/11). Le client paie sur la page de paiement
-- unique : demande de paiement envoyée sur son téléphone MVola, validation
-- par son code secret, confirmation automatique (callback MVola + statut
-- redemandé à MVola). Edge Functions : payment-mvola et
-- mvola-payment-notification.
--
--   payments.provider_correlation_id : identifiant de suivi renvoyé par
--     MVola (serverCorrelationId), pour retrouver le paiement.
--   payments.provider_transaction_ref : référence de la transaction MVola
--     (affichée sur le reçu et reportée sur la commande).
--
-- Idempotent : peut être relancé sans risque. Le paiement en ligne MVola
-- reste désactivé tant qu'il n'est pas coché dans Admin -> Paiements.
-- ============================================================

alter table public.payments
  add column if not exists provider_correlation_id text,
  add column if not exists provider_transaction_ref text;

create unique index if not exists payments_provider_correlation_idx
  on public.payments (provider_correlation_id) where provider_correlation_id is not null;

comment on column public.payments.provider_correlation_id is
  'Identifiant de suivi de l''opérateur (MVola : serverCorrelationId), phase312.';
comment on column public.payments.provider_transaction_ref is
  'Référence de transaction de l''opérateur (MVola), affichée sur le reçu, phase312.';

-- Réglage du paiement en ligne MVola (désactivé par défaut).
insert into public.payment_method_settings (method_id, enabled)
values ('mvola', true)
on conflict (method_id) do nothing;

create or replace function public.payments_sync_target()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' and old.status is not distinct from new.status then
    return new;
  end if;

  if new.order_id is not null then
    if new.status = 'paye' then
      update public.orders
         set payment_status = 'paye',
             payment_method = new.method,
             airtel_money_transaction_ref = coalesce(new.airtel_money_transaction_ref, airtel_money_transaction_ref),
             payment_reference = coalesce(new.manual_reference, new.provider_transaction_ref, payment_reference),
             payment_proof_path = coalesce(new.proof_path, payment_proof_path)
       where id = new.order_id and payment_status is distinct from 'paye';
    elsif new.status = 'echoue' and new.mode = 'en_ligne' then
      update public.orders set payment_status = 'echoue'
       where id = new.order_id and payment_status = 'en_attente';
    elsif tg_op = 'INSERT' and new.status = 'en_attente' then
      -- Nouvelle tentative : la commande affiche le moyen choisi (et, pour
      -- un paiement manuel, la référence / preuve à vérifier par le staff).
      update public.orders
         set payment_method = new.method,
             payment_status = case when payment_status = 'echoue' then 'en_attente' else payment_status end,
             payment_reference = case when new.mode = 'manuel' then new.manual_reference else payment_reference end,
             payment_proof_path = case when new.mode = 'manuel' then coalesce(new.proof_path, payment_proof_path) else payment_proof_path end
       where id = new.order_id and payment_status is distinct from 'paye';
    end if;
  end if;

  if new.service_request_id is not null then
    if new.status = 'paye' then
      update public.website_service_requests
         set payment_status = 'paye',
             payment_method = case when new.method in ('mvola', 'orange_money', 'airtel_money')
                                   then new.method else payment_method end,
             airtel_money_transaction_ref = coalesce(new.airtel_money_transaction_ref, airtel_money_transaction_ref)
       where id = new.service_request_id and payment_status is distinct from 'paye';
    elsif new.status = 'echoue' and new.mode = 'en_ligne' then
      update public.website_service_requests set payment_status = 'echoue'
       where id = new.service_request_id and payment_status = 'en_attente';
    elsif tg_op = 'INSERT' and new.status = 'en_attente' then
      update public.website_service_requests
         set payment_status = case when payment_status = 'echoue' then 'en_attente' else payment_status end,
             payment_method = case when new.method in ('mvola', 'orange_money', 'airtel_money')
                                   then new.method else payment_method end
       where id = new.service_request_id and payment_status is distinct from 'paye';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.get_payment_receipt(p_id uuid)
returns jsonb
language sql
security definer
set search_path = public
stable
as $$
  select jsonb_build_object(
    'id', p.id,
    'source', p.source,
    'reference', p.reference,
    'amount', p.amount,
    'fee', p.fee,
    'status', p.status,
    'method', p.method,
    'mode', p.mode,
    'payer_name', p.payer_name,
    'payer_phone', case
      when length(regexp_replace(coalesce(p.payer_phone, ''), '\D', '', 'g')) >= 9 then
        left(lpad(right(regexp_replace(p.payer_phone, '\D', '', 'g'), 9), 10, '0'), 3)
        || ' •• ••• ' || right(regexp_replace(p.payer_phone, '\D', '', 'g'), 2)
      else null end,
    -- Référence de l'opérateur : Airtel (airtel_money_id) ou MVola (référence de transaction).
    'airtel_money_transaction_ref', coalesce(p.airtel_money_transaction_ref, p.provider_transaction_ref),
    'manual_reference', p.manual_reference,
    'error_message', case when p.status = 'echoue' then left(p.error_message, 200) end,
    'created_at', p.created_at,
    'paid_at', p.paid_at,
    -- Lignes de la commande (reçu PDF détaillé, comme une facture).
    'items', case when p.order_id is not null then
      coalesce((select jsonb_agg(jsonb_build_object(
                  'name', i.product_name, 'quantity', i.quantity, 'unit_price', i.unit_price))
                from public.order_items i where i.order_id = p.order_id), '[]'::jsonb)
      end
  )
  from public.payments p
  where p.id = p_id;
$$;

grant execute on function public.get_payment_receipt(uuid) to anon, authenticated;
