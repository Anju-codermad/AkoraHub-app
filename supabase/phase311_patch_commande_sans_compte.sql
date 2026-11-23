-- ============================================================
-- AkoraHub - Patch Phase 311 : commande sans compte sur le site
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- (APRÈS phase310_patch_paiements_unifies.sql)
--
-- Demande du 23/11 : un client doit pouvoir commander sur
-- groupe-akora.com sans créer de compte (nom, téléphone, adresse), puis
-- payer sur la page de paiement unique et recevoir son reçu. Le compte
-- reste possible et proposé après la commande.
--
--   orders.guest_name / guest_phone : coordonnées de l'acheteur sans
--   compte (customer_id reste vide).
--   create_guest_order(...) : seule façon de créer une telle commande.
--   Les prix NE viennent PAS du navigateur : seuls les produits et les
--   quantités sont transmis, le prix de chaque ligne est imposé par le
--   trigger enforce_order_item_price (phase154/273) et le total par
--   recompute_order_total. Anti-abus : champ piège, 3 commandes par
--   numéro et par heure, 30 commandes sans compte par heure au total.
--   get_payment_target / submit_manual_payment (phase310) : une commande
--   sans compte est accessible par son identifiant, comme un acompte.
--
-- Idempotent : peut être relancé sans risque.
-- ============================================================

alter table public.orders
  add column if not exists guest_name text,
  add column if not exists guest_phone text;

comment on column public.orders.guest_name is
  'Commande passée sans compte sur le site (phase311) : nom indiqué par l''acheteur. customer_id est alors vide.';
comment on column public.orders.guest_phone is
  'Commande passée sans compte sur le site (phase311) : téléphone indiqué par l''acheteur.';

create index if not exists orders_guest_phone_created_idx
  on public.orders (guest_phone, created_at desc) where guest_phone is not null;

create or replace function public.create_guest_order(
  p_name text,
  p_phone text,
  p_address text,
  p_lat double precision,
  p_lng double precision,
  p_payment_method text,
  p_items jsonb,
  p_visit_session_id text default null,
  p_website text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text := left(nullif(trim(coalesce(p_name, '')), ''), 120);
  v_digits text := regexp_replace(coalesce(p_phone, ''), '\D', '', 'g');
  v_phone text;
  v_address text := left(nullif(trim(coalesce(p_address, '')), ''), 500);
  v_setting public.payment_method_settings%rowtype;
  v_item jsonb;
  v_product public.products%rowtype;
  v_qty integer;
  v_order_id uuid;
  v_number text;
  v_total numeric;
  v_try integer := 0;
begin
  -- Champ piège rempli : robot.
  if coalesce(trim(p_website), '') <> '' then
    raise exception 'Requête refusée';
  end if;
  if v_name is null or length(v_name) < 2 then
    raise exception 'Indiquez votre nom';
  end if;
  -- Téléphone Madagascar : 03X XX XXX XX (avec ou sans +261).
  if v_digits like '261%' then v_digits := substr(v_digits, 4); end if;
  if v_digits !~ '^0?3[2-9][0-9]{7}$' then
    raise exception 'Numéro de téléphone invalide (ex. 034 12 345 67)';
  end if;
  v_phone := '0' || right(v_digits, 9);
  if v_address is null then
    raise exception 'Indiquez votre adresse de livraison';
  end if;
  if p_payment_method not in ('paiement_livraison', 'virement_bancaire', 'orange_money', 'mvola', 'airtel_money') then
    raise exception 'Moyen de paiement invalide';
  end if;
  select * into v_setting from public.payment_method_settings where method_id = p_payment_method;
  if found and v_setting.enabled = false then
    raise exception 'Ce moyen de paiement n''est pas disponible';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Votre panier est vide';
  end if;
  if jsonb_array_length(p_items) > 50 then
    raise exception 'Trop d''articles dans le panier';
  end if;

  -- Anti-abus (page publique).
  if (select count(*) from public.orders
       where guest_phone = v_phone and created_at > now() - interval '1 hour') >= 3 then
    raise exception 'Trop de commandes pour ce numéro, réessayez dans une heure ou contactez-nous';
  end if;
  if (select count(*) from public.orders
       where customer_id is null and guest_phone is not null
         and created_at > now() - interval '1 hour') >= 30 then
    raise exception 'Service très sollicité, réessayez un peu plus tard';
  end if;

  -- Numéro de commande (même format que le site : CMD-AAAAMM-XXXXXX).
  loop
    v_try := v_try + 1;
    v_number := 'CMD-' || to_char(now() at time zone 'Indian/Antananarivo', 'YYYYMM') || '-'
                || lpad((floor(random() * 1000000))::int::text, 6, '0');
    exit when not exists (select 1 from public.orders where order_number = v_number) or v_try > 5;
  end loop;

  insert into public.orders (order_number, customer_id, guest_name, guest_phone, total_amount, delivery_fee,
                             latitude, longitude, delivery_address, payment_method, visit_session_id)
  values (v_number, null, v_name, v_phone, 0, 0, p_lat, p_lng, v_address, p_payment_method,
          left(nullif(trim(coalesce(p_visit_session_id, '')), ''), 100))
  returning id into v_order_id;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_qty := case when coalesce(v_item->>'quantity', '') ~ '^[0-9]{1,5}$' then (v_item->>'quantity')::int else 0 end;
    if v_qty < 1 or v_qty > 10000 then
      raise exception 'Quantité invalide';
    end if;
    select * into v_product from public.products
     where id::text = v_item->>'product_id' and visibility = true;
    if not found then
      raise exception 'Un produit du panier n''est plus disponible';
    end if;
    -- unit_price provisoire : remplacé par le vrai prix par le trigger
    -- enforce_order_item_price (le total est recalculé ensuite).
    insert into public.order_items (order_id, product_id, product_name, quantity, unit_price, is_gros_price)
    values (v_order_id, v_product.id, v_product.name, v_qty, v_product.price_detail, false);
  end loop;

  select total_amount into v_total from public.orders where id = v_order_id;
  return jsonb_build_object('id', v_order_id, 'order_number', v_number, 'total_amount', v_total);
end;
$$;

grant execute on function public.create_guest_order(text, text, text, double precision, double precision, text, jsonb, text, text)
  to anon, authenticated;

-- ------------------------------------------------------------
-- Page de paiement : commande sans compte accessible par son identifiant
-- (versions de la phase310 complétées).
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
    -- Commande d'un client connecté : réservée à ce client (ou au staff).
    -- Commande sans compte (customer_id nul) : l'identifiant de la
    -- commande, connu seulement de l'acheteur, suffit (comme un acompte).
    if v_order.customer_id is not null
       and (auth.uid() is null
            or (v_order.customer_id <> auth.uid() and not public.current_role_is_staff())) then
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
      'payer_name', coalesce((select full_name from public.profiles where id = v_order.customer_id), v_order.guest_name),
      'payer_phone', coalesce((select phone from public.profiles where id = v_order.customer_id), v_order.guest_phone),
      'guest', v_order.customer_id is null,
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
    if not found
       or (v_order.customer_id is not null
           and (auth.uid() is null or v_order.customer_id <> auth.uid())) then
      raise exception 'Commande introuvable';
    end if;
    if v_order.payment_status = 'paye' then raise exception 'Cette commande est déjà payée'; end if;
    v_amount := v_order.total_amount;
    v_ref := v_order.order_number;
    v_customer := v_order.customer_id;
    if v_order.customer_id is not null then
      select coalesce(v_name, full_name), coalesce(v_phone, phone) into v_name, v_phone
        from public.profiles where id = v_order.customer_id;
    else
      v_name := coalesce(v_name, v_order.guest_name);
      v_phone := coalesce(v_phone, v_order.guest_phone);
    end if;
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
