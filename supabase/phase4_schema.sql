-- ============================================================
-- Akora Fanadiovana / AkoraHub - Schéma Phase 4
-- Variantes produit (Format x Parfum), chacune avec son propre prix.
-- Formats et parfums sont des listes de référence PRÉ-REMPLIES
-- (contrairement aux piliers, que l'Admin crée lui-même).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

-- ------------------------------------------------------------
-- 1. FORMATS (liste de référence, réutilisable pour tous les produits)
-- ------------------------------------------------------------
create table if not exists public.formats (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

insert into public.formats (name) values
  ('100 ml'), ('250 ml'), ('500 ml'), ('1 L'), ('2 L'), ('5 L'),
  ('10 L'), ('Bidon 20 L'), ('Fût 200 L'),
  ('Sachet 1 kg'), ('Sachet 5 kg'), ('Carton'), ('Format échantillon')
on conflict (name) do nothing;

-- ------------------------------------------------------------
-- 2. PARFUMS (liste de référence, réutilisable pour tous les produits)
-- ------------------------------------------------------------
create table if not exists public.parfums (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

insert into public.parfums (name) values
  ('Sans parfum'), ('Lavande'), ('Citron'), ('Pin'), ('Fleurs'),
  ('Marin'), ('Rose'), ('Eucalyptus'), ('Menthe fraîche'),
  ('Vanille'), ('Amande')
on conflict (name) do nothing;

-- ------------------------------------------------------------
-- 3. VARIANTES PRODUIT (Format x Parfum, chacune avec son propre prix)
-- ------------------------------------------------------------
create table if not exists public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  format_id uuid references public.formats(id),
  parfum_id uuid references public.parfums(id),
  price_detail numeric not null default 0,
  price_gros numeric not null default 0,
  gros_threshold_qty integer not null default 10,
  stock_quantity numeric not null default 0,
  low_stock_threshold numeric not null default 5,
  created_at timestamptz not null default now(),
  unique (product_id, format_id, parfum_id)
);

-- Traçabilité : on garde une référence à la variante choisie sur les
-- commandes et devis (en plus du texte déjà enregistré pour l'historique).
alter table public.order_items
  add column if not exists variant_id uuid references public.product_variants(id);
alter table public.quote_items
  add column if not exists variant_id uuid references public.product_variants(id);

-- ============================================================
-- SÉCURITÉ
-- ============================================================
alter table public.formats enable row level security;
alter table public.parfums enable row level security;
alter table public.product_variants enable row level security;

create policy "formats_select_all" on public.formats
  for select using (true);
create policy "formats_write_staff" on public.formats
  for all using (public.current_role_is_staff()) with check (public.current_role_is_staff());

create policy "parfums_select_all" on public.parfums
  for select using (true);
create policy "parfums_write_staff" on public.parfums
  for all using (public.current_role_is_staff()) with check (public.current_role_is_staff());

create policy "product_variants_select_all" on public.product_variants
  for select using (true);
create policy "product_variants_write_staff" on public.product_variants
  for all using (public.current_role_is_staff()) with check (public.current_role_is_staff());
