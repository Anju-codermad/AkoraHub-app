-- ============================================================
-- Akora Fanadiovana - Schéma Phase 1 (Espace Admin + fondations client)
-- À exécuter une seule fois dans Supabase : Dashboard -> SQL Editor -> New query
-- ============================================================

-- Extension nécessaire pour générer des UUID
create extension if not exists "pgcrypto";

-- ------------------------------------------------------------
-- 1. PILIERS D'ENTREPRISE (business_units)
-- ------------------------------------------------------------
create table if not exists public.business_units (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

insert into public.business_units (name, slug)
values
  ('Akora Fanadiovana', 'akora-fanadiovana'),
  ('ARCA PAINTS', 'arca-paints'),
  ('AkoraFormation', 'akoraformation')
on conflict (slug) do nothing;

-- ------------------------------------------------------------
-- 2. PROFILS (étend auth.users : admin, équipe, clients)
-- ------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'client'
    check (role in ('admin','commercial','production','comptable','client')),
  client_type text
    check (client_type in ('hotel','hopital','entreprise','particulier') or client_type is null),
  full_name text,
  company_name text,
  phone text,
  location text,
  avatar_url text,
  business_unit_ids uuid[] not null default '{}', -- piliers assignés (staff)
  created_at timestamptz not null default now()
);

-- Crée automatiquement un profil "client" à chaque inscription
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, role, full_name)
  values (new.id, 'client', new.raw_user_meta_data->>'full_name');
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Fonction utilitaire : le rôle de l'utilisateur connecté (pour les policies RLS)
create or replace function public.current_role_is_staff()
returns boolean as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('admin','commercial','production','comptable')
  );
$$ language sql security definer stable;

create or replace function public.current_role_is_admin()
returns boolean as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  );
$$ language sql security definer stable;

-- ------------------------------------------------------------
-- 3. MATIÈRES PREMIÈRES
-- ------------------------------------------------------------
create table if not exists public.raw_materials (
  id uuid primary key default gen_random_uuid(),
  business_unit_id uuid references public.business_units(id),
  name text not null,
  unit text not null default 'kg',
  stock_quantity numeric not null default 0,
  low_stock_threshold numeric not null default 0,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 4. PRODUITS (avec tarification Gros/Détail)
-- ------------------------------------------------------------
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  business_unit_id uuid references public.business_units(id),
  name text not null,
  description text,
  category text,
  image_url text,
  price_detail numeric not null default 0,
  price_gros numeric not null default 0,
  gros_threshold_qty integer not null default 10, -- seuil qté déclenchant le prix Gros
  stock_quantity numeric not null default 0,
  low_stock_threshold numeric not null default 5,
  visibility boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 5. LOTS DE PRODUCTION (n° lot, fabrication, DLC)
-- ------------------------------------------------------------
create table if not exists public.production_batches (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references public.products(id) on delete cascade,
  batch_number text not null,
  manufacture_date date not null,
  expiry_date date,
  quantity numeric not null default 0,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 6. COMMANDES
-- ------------------------------------------------------------
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  customer_id uuid references public.profiles(id),
  business_unit_id uuid references public.business_units(id),
  status text not null default 'recue'
    check (status in ('recue','en_preparation','expediee','livree','annulee')),
  payment_status text not null default 'en_attente'
    check (payment_status in ('en_attente','acompte_verse','paye','facture_30j')),
  total_amount numeric not null default 0,
  delivery_zone text,
  delivery_fee numeric not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references public.orders(id) on delete cascade,
  product_id uuid references public.products(id),
  product_name text not null,
  quantity numeric not null,
  unit_price numeric not null,
  is_gros_price boolean not null default false
);

-- ------------------------------------------------------------
-- 7. DEVIS (pour gros volumes / clients pro)
-- ------------------------------------------------------------
create table if not exists public.quotes (
  id uuid primary key default gen_random_uuid(),
  quote_number text not null unique,
  customer_id uuid references public.profiles(id),
  business_unit_id uuid references public.business_units(id),
  status text not null default 'en_attente'
    check (status in ('en_attente','envoye','accepte','refuse','expire')),
  total_amount numeric not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.quote_items (
  id uuid primary key default gen_random_uuid(),
  quote_id uuid references public.quotes(id) on delete cascade,
  product_id uuid references public.products(id),
  product_name text not null,
  quantity numeric not null,
  unit_price numeric not null
);

-- ------------------------------------------------------------
-- 8. FACTURES
-- ------------------------------------------------------------
create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  invoice_number text not null unique,
  order_id uuid references public.orders(id),
  customer_id uuid references public.profiles(id),
  total_amount numeric not null default 0,
  pdf_url text,
  created_at timestamptz not null default now()
);

-- Recherche un profil par email (utilisé pour promouvoir un membre d'équipe).
-- security definer : nécessaire pour lire auth.users, mais restreint au staff.
create or replace function public.find_profile_by_email(search_email text)
returns setof public.profiles as $$
  select p.* from public.profiles p
  join auth.users u on u.id = p.id
  where u.email = search_email
    and public.current_role_is_staff();
$$ language sql security definer stable;

-- ============================================================
-- SÉCURITÉ : activation de RLS sur toutes les tables
-- ============================================================
alter table public.business_units enable row level security;
alter table public.profiles enable row level security;
alter table public.raw_materials enable row level security;
alter table public.products enable row level security;
alter table public.production_batches enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.quotes enable row level security;
alter table public.quote_items enable row level security;
alter table public.invoices enable row level security;

-- --- business_units : lecture publique, écriture staff seulement
create policy "business_units_select_all" on public.business_units
  for select using (true);
create policy "business_units_write_staff" on public.business_units
  for all using (public.current_role_is_staff()) with check (public.current_role_is_staff());

-- --- profiles : chacun voit/modifie son propre profil ; le staff voit tout
create policy "profiles_select_own_or_staff" on public.profiles
  for select using (auth.uid() = id or public.current_role_is_staff());
create policy "profiles_update_own_or_staff" on public.profiles
  for update using (auth.uid() = id or public.current_role_is_staff());

-- --- raw_materials, production_batches : réservé au staff (Production/Admin)
create policy "raw_materials_staff_only" on public.raw_materials
  for all using (public.current_role_is_staff()) with check (public.current_role_is_staff());
create policy "batches_staff_only" on public.production_batches
  for all using (public.current_role_is_staff()) with check (public.current_role_is_staff());

-- --- products : lecture publique (catalogue), écriture staff seulement
create policy "products_select_all" on public.products
  for select using (visibility = true or public.current_role_is_staff());
create policy "products_write_staff" on public.products
  for all using (public.current_role_is_staff()) with check (public.current_role_is_staff());

-- --- orders / order_items : client voit ses commandes, staff voit tout
create policy "orders_select_own_or_staff" on public.orders
  for select using (auth.uid() = customer_id or public.current_role_is_staff());
create policy "orders_insert_own" on public.orders
  for insert with check (auth.uid() = customer_id or public.current_role_is_staff());
create policy "orders_update_staff" on public.orders
  for update using (public.current_role_is_staff());

create policy "order_items_select_related" on public.order_items
  for select using (
    exists (select 1 from public.orders o where o.id = order_id
            and (o.customer_id = auth.uid() or public.current_role_is_staff()))
  );
create policy "order_items_write_staff" on public.order_items
  for all using (public.current_role_is_staff()) with check (public.current_role_is_staff());

-- --- quotes / quote_items : même logique que orders
create policy "quotes_select_own_or_staff" on public.quotes
  for select using (auth.uid() = customer_id or public.current_role_is_staff());
create policy "quotes_insert_own" on public.quotes
  for insert with check (auth.uid() = customer_id or public.current_role_is_staff());
create policy "quotes_update_staff" on public.quotes
  for update using (public.current_role_is_staff());
create policy "quote_items_select_related" on public.quote_items
  for select using (
    exists (select 1 from public.quotes q where q.id = quote_id
            and (q.customer_id = auth.uid() or public.current_role_is_staff()))
  );
create policy "quote_items_write_staff" on public.quote_items
  for all using (public.current_role_is_staff()) with check (public.current_role_is_staff());

-- --- invoices : client voit les siennes, staff (Comptable/Admin) gère tout
create policy "invoices_select_own_or_staff" on public.invoices
  for select using (auth.uid() = customer_id or public.current_role_is_staff());
create policy "invoices_write_staff" on public.invoices
  for all using (public.current_role_is_staff()) with check (public.current_role_is_staff());
