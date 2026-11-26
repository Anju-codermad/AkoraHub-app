-- ============================================================
-- AkoraHub - Patch Phase 313 : place de marché (Espace Producteurs,
-- Espace Acheteurs, Investisseurs) inspirée d'EspaceAgro
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- (APRÈS les patchs Espace Producteurs : producer_categories,
-- producer_proposals, producer_proposal_products, et buyer_requests)
--
-- Demande du 26/11 : publier sur le site des offres de producteurs, des
-- demandes d'achat, un annuaire de producteurs et des projets à financer,
-- tout en gardant Akora comme intermédiaire (« il faut toujours que je
-- puisse gagner une commission ») :
--   * AUCUNE coordonnée n'est publiée. Les tables sont privées (équipe
--     Akora) ; le site lit uniquement des VUES publiques qui ne
--     contiennent ni nom réel, ni téléphone, ni e-mail.
--   * Un visiteur intéressé remplit « Je suis intéressé » : la demande
--     arrive dans market_leads (mises en relation), avec suivi du montant
--     de l'affaire et de la commission d'Akora.
--
-- Contenu :
--   1. market_producers   : annuaire (nom public choisi par Akora)
--   2. market_offers      : offres de vente publiées
--   3. buyer_requests     : + publication anonyme des demandes d'achat
--   4. investment_projects: projets à financer (page Investisseurs)
--   5. market_leads       : mises en relation + commissions
--   6. Vues publiques     : *_public + market_stats_public
--   7. RPC submit_market_lead (anti-abus)
--
-- Idempotent : peut être relancé sans risque.
-- ============================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.current_user_is_market_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('admin', 'commercial', 'production', 'comptable')
  );
$$;
grant execute on function public.current_user_is_market_staff() to anon, authenticated;

create sequence if not exists public.market_ref_seq;

-- Référence lisible : OFF-2611-0007, DEM-…, PRJ-…, MER-…
create or replace function public.market_next_ref(p_prefix text)
returns text
language sql
volatile
security definer
set search_path = public
as $$
  select p_prefix || '-' || to_char(now(), 'YYMM') || '-' || lpad(nextval('public.market_ref_seq')::text, 4, '0');
$$;

-- ------------------------------------------------------------
-- 1) Annuaire des producteurs
-- ------------------------------------------------------------
create table if not exists public.market_producers (
  id uuid primary key default gen_random_uuid(),
  public_name text not null,
  producer_type text not null default 'producteur'
    check (producer_type in ('producteur', 'cooperative', 'entreprise', 'association', 'transformateur', 'artisan')),
  region text,
  description text,
  category_ids uuid[] not null default '{}',
  photo_url text,
  verified boolean not null default true,
  member_since date not null default current_date,
  status text not null default 'brouillon'
    check (status in ('brouillon', 'publie', 'archive')),
  -- Lien privé vers la proposition d'origine (jamais publié).
  source_proposal_id uuid references public.producer_proposals(id) on delete set null,
  private_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists market_producers_updated_at on public.market_producers;
create trigger market_producers_updated_at
  before update on public.market_producers
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- 2) Offres de vente
-- ------------------------------------------------------------
create table if not exists public.market_offers (
  id uuid primary key default gen_random_uuid(),
  reference text unique,
  title text not null,
  category_id uuid references public.producer_categories(id) on delete set null,
  description text,
  photo_urls text[] not null default '{}',
  quantity_available text,
  unit text,
  min_order text,
  indicative_price numeric(14, 2),
  price_unit text,
  region text,
  certifications text[] not null default '{}',
  availability text,
  packaging text,
  featured boolean not null default false,
  producer_id uuid references public.market_producers(id) on delete set null,
  status text not null default 'brouillon'
    check (status in ('brouillon', 'publiee', 'archivee')),
  published_at timestamptz,
  -- Lien privé vers le produit proposé d'origine (jamais publié).
  source_proposal_product_id uuid references public.producer_proposal_products(id) on delete set null,
  private_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.market_offers_before_write()
returns trigger
language plpgsql
as $$
begin
  if new.reference is null then new.reference := public.market_next_ref('OFF'); end if;
  if new.status = 'publiee' and new.published_at is null then new.published_at := now(); end if;
  return new;
end;
$$;

drop trigger if exists market_offers_before_write on public.market_offers;
create trigger market_offers_before_write
  before insert or update on public.market_offers
  for each row execute function public.market_offers_before_write();

drop trigger if exists market_offers_updated_at on public.market_offers;
create trigger market_offers_updated_at
  before update on public.market_offers
  for each row execute function public.set_updated_at();

create index if not exists market_offers_status_idx on public.market_offers (status, published_at desc);

-- ------------------------------------------------------------
-- 3) Demandes d'achat : publication anonyme
-- ------------------------------------------------------------
alter table public.buyer_requests
  add column if not exists allow_publication boolean not null default false,
  add column if not exists is_public boolean not null default false,
  add column if not exists public_title text,
  add column if not exists public_summary text,
  add column if not exists public_region text,
  add column if not exists public_status text not null default 'ouverte',
  add column if not exists published_at timestamptz,
  add column if not exists reference text;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'buyer_requests_public_status_check') then
    alter table public.buyer_requests add constraint buyer_requests_public_status_check
      check (public_status in ('ouverte', 'pourvue', 'fermee'));
  end if;
end $$;

create unique index if not exists buyer_requests_reference_idx
  on public.buyer_requests (reference) where reference is not null;

-- Un visiteur ne peut jamais publier lui-même sa demande : seule l'équipe
-- Akora la publie (après relecture du titre et du résumé anonymes).
create or replace function public.buyer_requests_before_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.reference is null then new.reference := public.market_next_ref('DEM'); end if;
  if not public.current_user_is_market_staff() then
    if tg_op = 'INSERT' then
      new.is_public := false;
      new.published_at := null;
      new.public_title := null;
      new.public_summary := null;
      new.public_region := null;
      new.public_status := 'ouverte';
    end if;
  elsif new.is_public and new.published_at is null then
    new.published_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists buyer_requests_before_write on public.buyer_requests;
create trigger buyer_requests_before_write
  before insert or update on public.buyer_requests
  for each row execute function public.buyer_requests_before_write();

update public.buyer_requests set reference = public.market_next_ref('DEM') where reference is null;

-- ------------------------------------------------------------
-- 4) Projets à financer
-- ------------------------------------------------------------
create table if not exists public.investment_projects (
  id uuid primary key default gen_random_uuid(),
  reference text unique,
  title text not null,
  sector text,
  summary text,
  description text,
  amount_needed numeric(16, 2),
  min_ticket numeric(16, 2),
  raised_amount numeric(16, 2) not null default 0,
  investment_type text not null default 'partenariat'
    check (investment_type in ('pret', 'participation', 'partenariat', 'precommande', 'autre')),
  expected_return text,
  duration text,
  location text,
  image_url text,
  status text not null default 'brouillon'
    check (status in ('brouillon', 'publie', 'finance', 'archive')),
  sort_order integer not null default 0,
  published_at timestamptz,
  private_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.investment_projects_before_write()
returns trigger
language plpgsql
as $$
begin
  if new.reference is null then new.reference := public.market_next_ref('PRJ'); end if;
  if new.status in ('publie', 'finance') and new.published_at is null then new.published_at := now(); end if;
  return new;
end;
$$;

drop trigger if exists investment_projects_before_write on public.investment_projects;
create trigger investment_projects_before_write
  before insert or update on public.investment_projects
  for each row execute function public.investment_projects_before_write();

drop trigger if exists investment_projects_updated_at on public.investment_projects;
create trigger investment_projects_updated_at
  before update on public.investment_projects
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- 5) Mises en relation (leads) et commissions
-- ------------------------------------------------------------
create table if not exists public.market_leads (
  id uuid primary key default gen_random_uuid(),
  reference text unique,
  target_type text not null check (target_type in ('offre', 'demande', 'producteur', 'projet', 'general')),
  target_id uuid,
  target_label text,
  lead_role text not null default 'acheteur'
    check (lead_role in ('acheteur', 'producteur', 'investisseur', 'autre')),
  full_name text not null,
  company text,
  phone text,
  email text,
  quantity text,
  message text,
  status text not null default 'nouveau'
    check (status in ('nouveau', 'en_contact', 'negociation', 'conclu', 'perdu')),
  deal_amount numeric(16, 2),
  commission_rate numeric(5, 2),
  commission_amount numeric(16, 2),
  commission_status text not null default 'non_due'
    check (commission_status in ('non_due', 'a_facturer', 'facturee', 'payee')),
  staff_note text,
  handled_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.market_leads_before_write()
returns trigger
language plpgsql
as $$
begin
  if new.reference is null then new.reference := public.market_next_ref('MER'); end if;
  -- Commission calculée automatiquement (modifiable à la main).
  if new.deal_amount is not null and new.commission_rate is not null
     and (new.commission_amount is null
          or (tg_op = 'UPDATE' and (new.deal_amount is distinct from old.deal_amount
                                    or new.commission_rate is distinct from old.commission_rate)
              and new.commission_amount is not distinct from old.commission_amount)) then
    new.commission_amount := round(new.deal_amount * new.commission_rate / 100);
  end if;
  if new.status = 'conclu' and new.commission_status = 'non_due' and coalesce(new.commission_amount, 0) > 0 then
    new.commission_status := 'a_facturer';
  end if;
  return new;
end;
$$;

drop trigger if exists market_leads_before_write on public.market_leads;
create trigger market_leads_before_write
  before insert or update on public.market_leads
  for each row execute function public.market_leads_before_write();

drop trigger if exists market_leads_updated_at on public.market_leads;
create trigger market_leads_updated_at
  before update on public.market_leads
  for each row execute function public.set_updated_at();

create index if not exists market_leads_created_idx on public.market_leads (created_at desc);
create index if not exists market_leads_contact_idx on public.market_leads (phone, created_at desc);

-- ------------------------------------------------------------
-- RLS : tout est réservé à l'équipe Akora. Le public passe par les vues
-- (sans coordonnées) et par la fonction submit_market_lead.
-- ------------------------------------------------------------
alter table public.market_producers enable row level security;
alter table public.market_offers enable row level security;
alter table public.investment_projects enable row level security;
alter table public.market_leads enable row level security;

drop policy if exists "market_producers_staff_all" on public.market_producers;
create policy "market_producers_staff_all" on public.market_producers
  for all using (public.current_user_is_market_staff()) with check (public.current_user_is_market_staff());

drop policy if exists "market_offers_staff_all" on public.market_offers;
create policy "market_offers_staff_all" on public.market_offers
  for all using (public.current_user_is_market_staff()) with check (public.current_user_is_market_staff());

drop policy if exists "investment_projects_staff_all" on public.investment_projects;
create policy "investment_projects_staff_all" on public.investment_projects
  for all using (public.current_user_is_market_staff()) with check (public.current_user_is_market_staff());

drop policy if exists "market_leads_staff_all" on public.market_leads;
create policy "market_leads_staff_all" on public.market_leads
  for all using (public.current_user_is_market_staff()) with check (public.current_user_is_market_staff());

-- ------------------------------------------------------------
-- 6) Vues publiques : uniquement des informations non sensibles.
-- (Vues exécutées avec les droits du propriétaire : elles ne lisent que
-- les lignes publiées et les colonnes listées ici.)
-- ------------------------------------------------------------
drop view if exists public.market_producers_public;
create view public.market_producers_public as
  select p.id, p.public_name, p.producer_type, p.region, p.description, p.photo_url,
         p.verified, p.member_since,
         coalesce((select array_agg(c.label order by c.sort_order)
                   from public.producer_categories c where c.id = any(p.category_ids)), '{}') as categories,
         (select count(*) from public.market_offers o
           where o.producer_id = p.id and o.status = 'publiee')::int as offers_count
  from public.market_producers p
  where p.status = 'publie';

drop view if exists public.market_offers_public;
create view public.market_offers_public as
  select o.id, o.reference, o.title, o.category_id, c.label as category_label, o.description,
         o.photo_urls, o.quantity_available, o.unit, o.min_order, o.indicative_price, o.price_unit,
         o.region, o.certifications, o.availability, o.packaging, o.featured, o.published_at,
         p.id as producer_id, p.public_name as producer_name, p.producer_type, p.verified as producer_verified,
         p.member_since as producer_member_since
  from public.market_offers o
  left join public.producer_categories c on c.id = o.category_id
  left join public.market_producers p on p.id = o.producer_id and p.status = 'publie'
  where o.status = 'publiee';

drop view if exists public.market_requests_public;
create view public.market_requests_public as
  select r.id, r.reference,
         coalesce(nullif(r.public_title, ''), r.product_name) as title,
         r.public_summary as summary,
         r.product_category as category,
         r.quantity_wanted, r.frequency, r.desired_deadline,
         coalesce(nullif(r.public_region, ''), 'Madagascar') as region,
         r.buyer_type, r.public_status, r.published_at
  from public.buyer_requests r
  where r.is_public;

drop view if exists public.investment_projects_public;
create view public.investment_projects_public as
  select id, reference, title, sector, summary, description, amount_needed, min_ticket, raised_amount,
         investment_type, expected_return, duration, location, image_url, status, sort_order, published_at
  from public.investment_projects
  where status in ('publie', 'finance');

drop view if exists public.market_stats_public;
create view public.market_stats_public as
  select
    (select count(*) from public.market_offers where status = 'publiee')::int as offers,
    (select count(*) from public.buyer_requests where is_public and public_status = 'ouverte')::int as requests,
    (select count(*) from public.market_producers where status = 'publie')::int as producers,
    (select count(*) from public.investment_projects where status = 'publie')::int as projects,
    (select count(*) from public.market_leads)::int as connections;

grant select on public.market_producers_public, public.market_offers_public, public.market_requests_public,
  public.investment_projects_public, public.market_stats_public to anon, authenticated;

-- ------------------------------------------------------------
-- 7) « Je suis intéressé » : enregistre une mise en relation.
-- ------------------------------------------------------------
create or replace function public.submit_market_lead(
  p_target_type text,
  p_target_id uuid,
  p_full_name text,
  p_phone text,
  p_email text default null,
  p_company text default null,
  p_quantity text default null,
  p_message text default null,
  p_website text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_label text;
  v_role text;
  v_phone text := nullif(regexp_replace(coalesce(p_phone, ''), '[^0-9+]', '', 'g'), '');
  v_email text := nullif(lower(trim(coalesce(p_email, ''))), '');
  v_ref text;
begin
  -- Robot (champ piège rempli) : réponse neutre, rien n'est enregistré.
  if coalesce(trim(p_website), '') <> '' then
    return jsonb_build_object('reference', public.market_next_ref('MER'));
  end if;
  if coalesce(trim(p_full_name), '') = '' then
    raise exception 'Indiquez votre nom.';
  end if;
  if v_phone is null and v_email is null then
    raise exception 'Indiquez un téléphone ou un e-mail.';
  end if;
  if v_phone is not null and length(regexp_replace(v_phone, '\D', '', 'g')) < 8 then
    raise exception 'Numéro de téléphone invalide.';
  end if;
  if v_email is not null and v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'E-mail invalide.';
  end if;

  if p_target_type = 'offre' then
    select title, 'acheteur' into v_label, v_role from public.market_offers
     where id = p_target_id and status = 'publiee';
  elsif p_target_type = 'producteur' then
    select public_name, 'acheteur' into v_label, v_role from public.market_producers
     where id = p_target_id and status = 'publie';
  elsif p_target_type = 'demande' then
    select coalesce(nullif(public_title, ''), product_name), 'producteur' into v_label, v_role
      from public.buyer_requests
     where id = p_target_id and is_public and public_status = 'ouverte';
  elsif p_target_type = 'projet' then
    select title, 'investisseur' into v_label, v_role from public.investment_projects
     where id = p_target_id and status = 'publie';
  elsif p_target_type = 'general' then
    v_label := 'Demande générale'; v_role := 'autre';
  else
    raise exception 'Type de demande invalide.';
  end if;
  if v_label is null then
    raise exception 'Cette annonce n''est plus disponible.';
  end if;

  -- Anti-abus : 5 demandes par contact et par heure, 200 au total.
  if (select count(*) from public.market_leads
       where created_at > now() - interval '1 hour'
         and ((v_phone is not null and phone = v_phone) or (v_email is not null and email = v_email))) >= 5 then
    raise exception 'Trop de demandes envoyées. Réessayez plus tard.';
  end if;
  if (select count(*) from public.market_leads where created_at > now() - interval '1 hour') >= 200 then
    raise exception 'Service très sollicité. Réessayez plus tard.';
  end if;

  insert into public.market_leads (target_type, target_id, target_label, lead_role, full_name, company,
                                   phone, email, quantity, message)
  values (p_target_type, case when p_target_type = 'general' then null else p_target_id end,
          left(v_label, 200), v_role, left(trim(p_full_name), 120), left(nullif(trim(p_company), ''), 160),
          v_phone, v_email, left(nullif(trim(p_quantity), ''), 120), left(nullif(trim(p_message), ''), 2000))
  returning reference into v_ref;

  return jsonb_build_object('reference', v_ref);
end;
$$;

revoke all on function public.submit_market_lead(text, uuid, text, text, text, text, text, text, text) from public;
grant execute on function public.submit_market_lead(text, uuid, text, text, text, text, text, text, text) to anon, authenticated;
