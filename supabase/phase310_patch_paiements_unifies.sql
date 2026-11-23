-- ============================================================
-- AkoraHub - Patch Phase 310 : table unique des paiements + page de
-- paiement indépendante (site groupe-akora.com/paiement)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Demande explicite (23/11) : « une meilleure table et une page de
-- paiement bien indépendante des autres pages », pour tout ce qui se
-- paie (commandes, acomptes du diagnostic eau, liens « Payer »), avec un
-- reçu téléchargeable.
--
-- public.payments = UNE ligne par tentative de paiement, quelle que soit
-- son origine (source) et sa façon de payer (mode) :
--   source : 'commande' (orders) | 'acompte' (website_service_requests)
--            | 'lien' (paiement libre : devis, facture WhatsApp...)
--   mode   : 'en_ligne' (Airtel Money, push USSD vers le wallet
--            marchand, confirmé automatiquement) | 'manuel' (référence /
--            preuve envoyée par le client, validée par le staff)
--
-- Les colonnes de paiement des commandes et des acomptes
-- (orders.payment_status, etc.) restent la référence pour l'App et les
-- écrans existants : un trigger les met à jour automatiquement quand un
-- paiement change d'état. Dans l'autre sens, une commande marquée
-- « payée » à la main par le staff (App) est aussi inscrite dans payments.
--
-- Idempotent : peut être relancé sans risque. Les paiements Airtel déjà
-- reçus (page « Payer », commandes, acomptes) sont repris dans la table.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Table
-- ------------------------------------------------------------
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  source text not null check (source in ('commande', 'acompte', 'lien')),
  order_id uuid references public.orders(id) on delete set null,
  service_request_id uuid references public.website_service_requests(id) on delete set null,
  legacy_direct_payment_id uuid unique,
  reference text,
  payer_name text,
  payer_phone text,
  customer_id uuid references public.profiles(id) on delete set null,
  method text not null check (method in
    ('airtel_money', 'mvola', 'orange_money', 'virement_bancaire', 'paiement_livraison')),
  mode text not null check (mode in ('en_ligne', 'manuel')),
  amount numeric not null check (amount > 0),
  fee numeric,
  status text not null default 'en_attente'
    check (status in ('en_attente', 'paye', 'echoue', 'annule')),
  airtel_transaction_id text,
  airtel_money_transaction_ref text,
  manual_reference text,
  proof_path text,
  error_message text,
  staff_note text,
  validated_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  paid_at timestamptz,
  updated_at timestamptz not null default now()
);

create unique index if not exists payments_airtel_tx_idx
  on public.payments (airtel_transaction_id) where airtel_transaction_id is not null;
create index if not exists payments_created_at_idx on public.payments (created_at desc);
create index if not exists payments_order_idx on public.payments (order_id);
create index if not exists payments_service_request_idx on public.payments (service_request_id);
create index if not exists payments_phone_created_idx on public.payments (payer_phone, created_at desc);

comment on table public.payments is
  'Tous les paiements (commandes, acomptes, liens Payer ; en ligne Airtel ou manuels). Voir phase310.';

-- ------------------------------------------------------------
-- 2) Horodatage
-- ------------------------------------------------------------
create or replace function public.payments_touch()
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

drop trigger if exists payments_touch on public.payments;
create trigger payments_touch
  before insert or update on public.payments
  for each row execute function public.payments_touch();

-- ------------------------------------------------------------
-- 3) Paiement -> commande / acompte (colonnes lues par l'App)
-- ------------------------------------------------------------
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
             payment_reference = coalesce(new.manual_reference, payment_reference),
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

drop trigger if exists payments_sync_target on public.payments;
create trigger payments_sync_target
  after insert or update on public.payments
  for each row execute function public.payments_sync_target();

-- ------------------------------------------------------------
-- 4) Commande / acompte marqué « payé » à la main par le staff (App,
-- administration) -> inscrit dans payments. Ignoré quand la mise à jour
-- vient elle-même du trigger ci-dessus (pg_trigger_depth() > 1).
-- ------------------------------------------------------------
create or replace function public.orders_sync_payments()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if pg_trigger_depth() > 1 then return new; end if;
  if new.payment_status = 'paye' and old.payment_status is distinct from 'paye' then
    -- Un paiement manuel en attente de vérification est validé.
    update public.payments
       set status = 'paye', validated_by = coalesce(validated_by, auth.uid())
     where order_id = new.id and status = 'en_attente' and mode = 'manuel';
    -- Aucun paiement enregistré (ex. espèces à la livraison) : on l'inscrit.
    if not exists (select 1 from public.payments where order_id = new.id and status = 'paye')
       and coalesce(new.total_amount, 0) > 0 then
      -- Paiement Airtel en ligne lancé par l'App (create-airtel-payment-
      -- request) et confirmé par le callback : inscrit comme « en ligne ».
      insert into public.payments (source, order_id, reference, customer_id, method, mode,
                                   amount, status, manual_reference, proof_path, validated_by, staff_note,
                                   payer_name, payer_phone, airtel_money_transaction_ref)
      select 'commande', new.id, new.order_number, new.customer_id,
             coalesce(new.payment_method, 'paiement_livraison'),
             case when new.airtel_transaction_id is not null and new.payment_method = 'airtel_money'
                  then 'en_ligne' else 'manuel' end,
             new.total_amount, 'paye', new.payment_reference, new.payment_proof_path, auth.uid(),
             case when new.airtel_transaction_id is not null and new.payment_method = 'airtel_money'
                  then 'Airtel Money (application)' else 'Marquée payée depuis la gestion des commandes' end,
             p.full_name, p.phone, new.airtel_money_transaction_ref
        from (select 1) x
        left join public.profiles p on p.id = new.customer_id;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists orders_sync_payments on public.orders;
create trigger orders_sync_payments
  after update of payment_status on public.orders
  for each row execute function public.orders_sync_payments();

create or replace function public.service_requests_sync_payments()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if pg_trigger_depth() > 1 then return new; end if;
  if new.payment_status = 'paye' and old.payment_status is distinct from 'paye' then
    update public.payments
       set status = 'paye', validated_by = coalesce(validated_by, auth.uid())
     where service_request_id = new.id and status = 'en_attente' and mode = 'manuel';
    if not exists (select 1 from public.payments where service_request_id = new.id and status = 'paye')
       and coalesce(new.deposit_amount, 0) > 0 then
      insert into public.payments (source, service_request_id, reference, method, mode, amount,
                                   status, validated_by, staff_note, payer_name, payer_phone)
      values ('acompte', new.id, coalesce(new.proforma_number, 'Acompte diagnostic eau'),
              coalesce(new.payment_method, 'mvola'), 'manuel', new.deposit_amount, 'paye', auth.uid(),
              'Marqué payé depuis les demandes de service', new.name, new.phone);
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists service_requests_sync_payments on public.website_service_requests;
create trigger service_requests_sync_payments
  after update of payment_status on public.website_service_requests
  for each row execute function public.service_requests_sync_payments();

-- ------------------------------------------------------------
-- 5) Droits : le staff voit et valide tout ; un client voit ses propres
-- paiements. Aucune écriture directe pour les clients : création par la
-- fonction submit_manual_payment ci-dessous ou par l'Edge Function
-- payment-airtel (service role).
-- ------------------------------------------------------------
alter table public.payments enable row level security;

drop policy if exists "payments_select_staff_or_own" on public.payments;
create policy "payments_select_staff_or_own" on public.payments
  for select using (public.current_role_is_staff() or customer_id = auth.uid());

drop policy if exists "payments_update_staff" on public.payments;
create policy "payments_update_staff" on public.payments
  for update using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

drop policy if exists "payments_delete_admin" on public.payments;
create policy "payments_delete_admin" on public.payments
  for delete using (public.current_role_is_admin());

-- ------------------------------------------------------------
-- 6) Ce qu'il y a à payer (page de paiement). Commande : réservée à son
-- client (ou au staff). Acompte : l'identifiant de la demande (UUID
-- impossible à deviner) suffit, comme le lien envoyé au client.
-- ------------------------------------------------------------
create or replace function public.get_payment_target(p_source text, p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
stable
as $$
declare
  v_order public.orders%rowtype;
  v_req public.website_service_requests%rowtype;
begin
  if p_source = 'commande' then
    select * into v_order from public.orders where id = p_id;
    if not found then return null; end if;
    if auth.uid() is null
       or (v_order.customer_id is distinct from auth.uid() and not public.current_role_is_staff()) then
      return jsonb_build_object('error', 'forbidden');
    end if;
    return jsonb_build_object(
      'source', 'commande',
      'id', v_order.id,
      'reference', v_order.order_number,
      'amount', v_order.total_amount,
      'delivery_fee', v_order.delivery_fee,
      'payment_status', v_order.payment_status,
      'payment_method', v_order.payment_method,
      'order_status', v_order.status,
      'created_at', v_order.created_at,
      'payer_name', (select full_name from public.profiles where id = v_order.customer_id),
      'payer_phone', (select phone from public.profiles where id = v_order.customer_id),
      'items', coalesce((select jsonb_agg(jsonb_build_object(
                  'name', i.product_name, 'quantity', i.quantity, 'unit_price', i.unit_price))
                from public.order_items i where i.order_id = v_order.id), '[]'::jsonb),
      'paid_payment_id', (select p.id from public.payments p
                           where p.order_id = v_order.id and p.status = 'paye'
                           order by p.paid_at desc nulls last limit 1)
    );
  elsif p_source = 'acompte' then
    select * into v_req from public.website_service_requests where id = p_id;
    if not found then return null; end if;
    return jsonb_build_object(
      'source', 'acompte',
      'id', v_req.id,
      'reference', coalesce(v_req.proforma_number, 'Diagnostic eau'),
      'amount', v_req.deposit_amount,
      'estimated_total', v_req.estimated_total,
      'payment_status', v_req.payment_status,
      'created_at', v_req.created_at,
      'payer_name', v_req.name,
      'payer_phone', v_req.phone,
      'paid_payment_id', (select p.id from public.payments p
                           where p.service_request_id = v_req.id and p.status = 'paye'
                           order by p.paid_at desc nulls last limit 1)
    );
  end if;
  return null;
end;
$$;

grant execute on function public.get_payment_target(text, uuid) to anon, authenticated;

-- ------------------------------------------------------------
-- 7) Suivi + reçu d'un paiement (page d'attente, reçu téléchargeable).
-- L'identifiant du paiement (UUID) n'est connu que du payeur ; le numéro
-- de téléphone est tout de même masqué (le reçu peut être partagé).
-- ------------------------------------------------------------
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
    'airtel_money_transaction_ref', p.airtel_money_transaction_ref,
    'manual_reference', p.manual_reference,
    'error_message', case when p.status = 'echoue' then left(p.error_message, 200) end,
    'created_at', p.created_at,
    'paid_at', p.paid_at
  )
  from public.payments p
  where p.id = p_id;
$$;

grant execute on function public.get_payment_receipt(uuid) to anon, authenticated;

-- ------------------------------------------------------------
-- 8) Paiement manuel déclaré par le client (référence de transaction,
-- preuve facultative si connecté) -> en attente de vérification staff.
-- ------------------------------------------------------------
create or replace function public.submit_manual_payment(
  p_source text,
  p_target_id uuid,
  p_method text,
  p_reference text,
  p_proof_path text default null,
  p_payer_name text default null,
  p_payer_phone text default null,
  p_amount numeric default null,
  p_lien_reference text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_amount numeric;
  v_ref text;
  v_name text := left(nullif(trim(coalesce(p_payer_name, '')), ''), 120);
  v_phone text := left(nullif(trim(coalesce(p_payer_phone, '')), ''), 30);
  v_manual_ref text := left(nullif(trim(coalesce(p_reference, '')), ''), 80);
  v_customer uuid := null;
  v_order public.orders%rowtype;
  v_req public.website_service_requests%rowtype;
  v_setting public.payment_method_settings%rowtype;
begin
  if p_method not in ('airtel_money', 'mvola', 'orange_money', 'virement_bancaire') then
    raise exception 'Moyen de paiement invalide';
  end if;
  select * into v_setting from public.payment_method_settings where method_id = p_method;
  if found and (v_setting.enabled = false or v_setting.manual_enabled = false) then
    raise exception 'Ce moyen de paiement n''est pas disponible';
  end if;
  if v_manual_ref is null and p_proof_path is null then
    raise exception 'Indiquez la référence de la transaction';
  end if;
  if p_proof_path is not null
     and (auth.uid() is null or split_part(p_proof_path, '/', 1) <> auth.uid()::text) then
    raise exception 'Preuve de paiement invalide';
  end if;

  if p_source = 'commande' then
    select * into v_order from public.orders where id = p_target_id;
    if not found or auth.uid() is null or v_order.customer_id is distinct from auth.uid() then
      raise exception 'Commande introuvable';
    end if;
    if v_order.payment_status = 'paye' then raise exception 'Cette commande est déjà payée'; end if;
    v_amount := v_order.total_amount;
    v_ref := v_order.order_number;
    v_customer := auth.uid();
    select coalesce(v_name, full_name), coalesce(v_phone, phone) into v_name, v_phone
      from public.profiles where id = auth.uid();
  elsif p_source = 'acompte' then
    select * into v_req from public.website_service_requests where id = p_target_id;
    if not found then raise exception 'Demande introuvable'; end if;
    if v_req.payment_status = 'paye' then raise exception 'Cet acompte est déjà payé'; end if;
    v_amount := v_req.deposit_amount;
    v_ref := coalesce(v_req.proforma_number, 'Acompte diagnostic eau');
    v_name := coalesce(v_name, v_req.name);
    v_phone := coalesce(v_phone, v_req.phone);
  elsif p_source = 'lien' then
    if v_name is null then raise exception 'Indiquez votre nom'; end if;
    if p_amount is null or p_amount < 300 or p_amount > 5000000 then
      raise exception 'Montant invalide (300 à 5 000 000 Ar)';
    end if;
    v_amount := round(p_amount);
    v_ref := left(nullif(trim(coalesce(p_lien_reference, '')), ''), 60);
    v_customer := auth.uid();
  else
    raise exception 'Origine de paiement invalide';
  end if;

  if v_amount is null or v_amount <= 0 then raise exception 'Montant à payer introuvable'; end if;

  -- Anti-abus (page publique) : 5 déclarations par cible / numéro et par
  -- heure, 40 déclarations « lien » par heure au total.
  if (select count(*) from public.payments
       where mode = 'manuel' and created_at > now() - interval '1 hour'
         and ((p_source = 'commande' and order_id = p_target_id)
           or (p_source = 'acompte' and service_request_id = p_target_id)
           or (p_source = 'lien' and source = 'lien' and payer_phone = v_phone))) >= 5
     or (p_source = 'lien' and (select count(*) from public.payments
          where source = 'lien' and mode = 'manuel' and created_at > now() - interval '1 hour') >= 40) then
    raise exception 'Trop de demandes, réessayez dans une heure';
  end if;

  insert into public.payments (source, order_id, service_request_id, reference, payer_name, payer_phone,
                               customer_id, method, mode, amount, status, manual_reference, proof_path)
  values (p_source,
          case when p_source = 'commande' then p_target_id end,
          case when p_source = 'acompte' then p_target_id end,
          v_ref, v_name, v_phone, v_customer, p_method, 'manuel', v_amount, 'en_attente',
          v_manual_ref, p_proof_path)
  returning id into v_id;
  return v_id;
end;
$$;

grant execute on function public.submit_manual_payment(text, uuid, text, text, text, text, text, numeric, text)
  to anon, authenticated;

-- ------------------------------------------------------------
-- 9) Reprise des paiements déjà enregistrés (Airtel en ligne)
-- ------------------------------------------------------------
do $$
begin
  if to_regclass('public.direct_payments') is not null then
    insert into public.payments (source, legacy_direct_payment_id, reference, payer_name, payer_phone, method,
                                 mode, amount, status, airtel_money_transaction_ref, error_message,
                                 staff_note, created_at, paid_at)
    select 'lien', d.id, d.reference, d.payer_name, d.msisdn, 'airtel_money', 'en_ligne', d.amount, d.status,
           d.airtel_money_transaction_ref, d.error_message, d.staff_note, d.created_at, d.paid_at
      from public.direct_payments d
     where not exists (select 1 from public.payments p where p.legacy_direct_payment_id = d.id);
    -- airtel_transaction_id repris séparément (unique) pour ne rien perdre.
    update public.payments p set airtel_transaction_id = d.airtel_transaction_id
      from public.direct_payments d
     where p.legacy_direct_payment_id = d.id and p.airtel_transaction_id is null
       and d.airtel_transaction_id is not null
       and not exists (select 1 from public.payments x where x.airtel_transaction_id = d.airtel_transaction_id);
  end if;
end;
$$;

insert into public.payments (source, order_id, reference, customer_id, payer_name, payer_phone, method, mode,
                             amount, status, airtel_transaction_id, airtel_money_transaction_ref, created_at, paid_at)
select 'commande', o.id, o.order_number, o.customer_id, pr.full_name, pr.phone, 'airtel_money', 'en_ligne',
       o.total_amount,
       case o.payment_status when 'paye' then 'paye' when 'echoue' then 'echoue' else 'en_attente' end,
       o.airtel_transaction_id, o.airtel_money_transaction_ref, o.created_at,
       case when o.payment_status = 'paye' then o.created_at end
  from public.orders o
  left join public.profiles pr on pr.id = o.customer_id
 where o.airtel_transaction_id is not null and coalesce(o.total_amount, 0) > 0
   and not exists (select 1 from public.payments p where p.airtel_transaction_id = o.airtel_transaction_id);

insert into public.payments (source, service_request_id, reference, payer_name, payer_phone, method, mode,
                             amount, status, airtel_transaction_id, airtel_money_transaction_ref, created_at, paid_at)
select 'acompte', w.id, coalesce(w.proforma_number, 'Acompte diagnostic eau'), w.name, w.phone, 'airtel_money',
       'en_ligne', w.deposit_amount, w.payment_status, w.airtel_transaction_id, w.airtel_money_transaction_ref,
       w.created_at, case when w.payment_status = 'paye' then w.created_at end
  from public.website_service_requests w
 where w.airtel_transaction_id is not null and coalesce(w.deposit_amount, 0) > 0
   and not exists (select 1 from public.payments p where p.airtel_transaction_id = w.airtel_transaction_id);
