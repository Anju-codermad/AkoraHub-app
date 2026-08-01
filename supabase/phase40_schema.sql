-- ============================================================
-- AkoraHub - Phase 40 : Matières premières (Formation) + abonnement payant
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (01/08) : le pilier "Formation" devient une vraie base de
-- référence des matières premières/ingrédients utilisés en fabrication
-- (chimiques, cosmétiques, agroalimentaires...) — distincte du catalogue
-- de vente (`products`). Chaque fiche est rédigée par l'Admin (recherche
-- approfondie), avec dosage d'usage par domaine, conditionnements et
-- historique de prix. La LISTE (nom/catégorie/stock/photo) reste visible
-- par tout client connecté ; le DÉTAIL complet (description, dosages,
-- conditionnement, historique prix) est réservé au staff + aux clients
-- avec un abonnement Formation actif.
--
-- Suite du travail commencé en phase33 (suggestions de noms) : cette
-- phase crée les vraies fiches, pas juste des suggestions de saisie.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Fiche matière première (données complètes, accès restreint).
-- ------------------------------------------------------------
create table if not exists public.raw_materials (
  id uuid primary key default gen_random_uuid(),
  business_unit_id uuid not null references public.business_units(id) on delete cascade,
  category_name text not null,
  name text not null,
  description text,
  safety_note text,
  stock_status text not null default 'en_stock'
    check (stock_status in ('en_stock','stock_faible','rupture')),
  current_price numeric,
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Permet un re-seed idempotent (voir phase41) : un même nom ne se
  -- duplique pas s'il appartient déjà au même pilier/catégorie.
  unique (business_unit_id, category_name, name)
);

create index if not exists raw_materials_unit_category_idx
  on public.raw_materials (business_unit_id, category_name);

alter table public.raw_materials enable row level security;

drop policy if exists "raw_materials_select_staff_or_subscriber" on public.raw_materials;
create policy "raw_materials_select_staff_or_subscriber" on public.raw_materials
  for select using (
    public.current_role_is_staff()
    or public.has_active_formation_subscription(auth.uid())
  );

drop policy if exists "raw_materials_write_staff" on public.raw_materials;
create policy "raw_materials_write_staff" on public.raw_materials
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- ------------------------------------------------------------
-- 2) Vue "teaser" — nom/catégorie/stock/photo uniquement, lisible par
-- tout utilisateur connecté (même principe que public_profiles,
-- phase9_patch_public_profiles.sql) : la vue s'exécute avec les droits de
-- son propriétaire, donc elle reste lisible même si la RLS de la table
-- source ci-dessus est restrictive. Sert à afficher le catalogue Formation
-- en entier (même non abonné), sans exposer description/dosages/prix.
-- ------------------------------------------------------------
create or replace view public.raw_materials_preview as
select
  id,
  business_unit_id,
  category_name,
  name,
  stock_status,
  image_url
from public.raw_materials;

grant select on public.raw_materials_preview to authenticated;

-- ------------------------------------------------------------
-- 3) Galerie photo (même mécanique que product_images, phase8).
-- ------------------------------------------------------------
create table if not exists public.raw_material_images (
  id uuid primary key default gen_random_uuid(),
  raw_material_id uuid not null references public.raw_materials(id) on delete cascade,
  image_url text not null,
  position integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists raw_material_images_material_id_idx
  on public.raw_material_images (raw_material_id, position);

alter table public.raw_material_images enable row level security;

drop policy if exists "raw_material_images_select_staff_or_subscriber" on public.raw_material_images;
create policy "raw_material_images_select_staff_or_subscriber" on public.raw_material_images
  for select using (
    public.current_role_is_staff()
    or public.has_active_formation_subscription(auth.uid())
  );

drop policy if exists "raw_material_images_write_staff" on public.raw_material_images;
create policy "raw_material_images_write_staff" on public.raw_material_images
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

create or replace function public.enforce_max_raw_material_images()
returns trigger as $$
begin
  if (select count(*) from public.raw_material_images where raw_material_id = new.raw_material_id) >= 10 then
    raise exception 'Une matière première ne peut pas avoir plus de 10 photos.';
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_enforce_max_raw_material_images on public.raw_material_images;
create trigger trg_enforce_max_raw_material_images
  before insert on public.raw_material_images
  for each row execute procedure public.enforce_max_raw_material_images();

-- ------------------------------------------------------------
-- 4) Usages / dosages, groupés par domaine.
-- ------------------------------------------------------------
create table if not exists public.raw_material_usages (
  id uuid primary key default gen_random_uuid(),
  raw_material_id uuid not null references public.raw_materials(id) on delete cascade,
  domain text not null
    check (domain in ('Nettoyage','Cosmétique','Agroalimentaire','Industriel')),
  -- Deux façons de désigner "ce que ça sert à fabriquer" : un vrai produit
  -- du catalogue (`product_id`, préférable — reste à jour si le produit est
  -- renommé) ou un simple texte libre (`usage_label`, pour une formule pas
  -- encore transformée en produit vendable). Au moins l'un des deux doit
  -- être renseigné, contrôlé côté application.
  product_id uuid references public.products(id) on delete set null,
  usage_label text,
  dosage text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists raw_material_usages_material_id_idx
  on public.raw_material_usages (raw_material_id, domain, sort_order);

alter table public.raw_material_usages enable row level security;

drop policy if exists "raw_material_usages_select_staff_or_subscriber" on public.raw_material_usages;
create policy "raw_material_usages_select_staff_or_subscriber" on public.raw_material_usages
  for select using (
    public.current_role_is_staff()
    or public.has_active_formation_subscription(auth.uid())
  );

drop policy if exists "raw_material_usages_write_staff" on public.raw_material_usages;
create policy "raw_material_usages_write_staff" on public.raw_material_usages
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- ------------------------------------------------------------
-- 5) Conditionnement (formats de vente/livraison de la matière première).
-- ------------------------------------------------------------
create table if not exists public.raw_material_packaging (
  id uuid primary key default gen_random_uuid(),
  raw_material_id uuid not null references public.raw_materials(id) on delete cascade,
  label text not null,
  price numeric,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists raw_material_packaging_material_id_idx
  on public.raw_material_packaging (raw_material_id, sort_order);

alter table public.raw_material_packaging enable row level security;

drop policy if exists "raw_material_packaging_select_staff_or_subscriber" on public.raw_material_packaging;
create policy "raw_material_packaging_select_staff_or_subscriber" on public.raw_material_packaging
  for select using (
    public.current_role_is_staff()
    or public.has_active_formation_subscription(auth.uid())
  );

drop policy if exists "raw_material_packaging_write_staff" on public.raw_material_packaging;
create policy "raw_material_packaging_write_staff" on public.raw_material_packaging
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- ------------------------------------------------------------
-- 6) Historique de prix.
-- ------------------------------------------------------------
create table if not exists public.raw_material_price_history (
  id uuid primary key default gen_random_uuid(),
  raw_material_id uuid not null references public.raw_materials(id) on delete cascade,
  price numeric not null,
  recorded_at date not null default current_date,
  note text,
  created_at timestamptz not null default now()
);

create index if not exists raw_material_price_history_material_id_idx
  on public.raw_material_price_history (raw_material_id, recorded_at);

alter table public.raw_material_price_history enable row level security;

drop policy if exists "raw_material_price_history_select_staff_or_subscriber" on public.raw_material_price_history;
create policy "raw_material_price_history_select_staff_or_subscriber" on public.raw_material_price_history
  for select using (
    public.current_role_is_staff()
    or public.has_active_formation_subscription(auth.uid())
  );

drop policy if exists "raw_material_price_history_write_staff" on public.raw_material_price_history;
create policy "raw_material_price_history_write_staff" on public.raw_material_price_history
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- ------------------------------------------------------------
-- 7) Abonnement Formation (accès payant global aux fiches détaillées).
-- ------------------------------------------------------------
create table if not exists public.formation_subscriptions (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  plan text not null check (plan in ('mensuel','annuel')),
  amount numeric not null,
  status text not null default 'en_attente'
    check (status in ('en_attente','actif','refuse','expire')),
  payment_method text,
  payment_reference text,
  payment_proof_path text,
  started_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists formation_subscriptions_customer_idx
  on public.formation_subscriptions (customer_id, status);

alter table public.formation_subscriptions enable row level security;

drop policy if exists "formation_subscriptions_select_own_or_staff" on public.formation_subscriptions;
create policy "formation_subscriptions_select_own_or_staff" on public.formation_subscriptions
  for select using (auth.uid() = customer_id or public.current_role_is_staff());

drop policy if exists "formation_subscriptions_insert_own" on public.formation_subscriptions;
create policy "formation_subscriptions_insert_own" on public.formation_subscriptions
  for insert with check (auth.uid() = customer_id);

drop policy if exists "formation_subscriptions_update_own_or_staff" on public.formation_subscriptions;
create policy "formation_subscriptions_update_own_or_staff" on public.formation_subscriptions
  for update using (auth.uid() = customer_id or public.current_role_is_staff())
  with check (auth.uid() = customer_id or public.current_role_is_staff());

-- Fonction utilisée par toutes les policies ci-dessus : renvoie vrai si
-- l'utilisateur a un abonnement Formation actif et non expiré. Déclarée
-- après la table (elle en dépend), mais référencée plus haut — Postgres
-- résout les policies au moment de leur exécution, pas de leur création,
-- donc l'ordre du fichier n'a pas d'importance ici.
create or replace function public.has_active_formation_subscription(uid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.formation_subscriptions
    where customer_id = uid
      and status = 'actif'
      and (expires_at is null or expires_at > now())
  );
$$;

-- ------------------------------------------------------------
-- 8) Tarifs des plans Formation (modifiables par l'Admin, même modèle que
-- payment_method_settings — phase28).
-- ------------------------------------------------------------
create table if not exists public.formation_plan_pricing (
  plan text primary key check (plan in ('mensuel','annuel')),
  price numeric not null,
  label text not null,
  updated_at timestamptz not null default now()
);

alter table public.formation_plan_pricing enable row level security;

drop policy if exists "formation_plan_pricing_select_all" on public.formation_plan_pricing;
create policy "formation_plan_pricing_select_all" on public.formation_plan_pricing
  for select using (true);

drop policy if exists "formation_plan_pricing_write_admin_only" on public.formation_plan_pricing;
create policy "formation_plan_pricing_write_admin_only" on public.formation_plan_pricing
  for all using (public.current_role_is_admin())
  with check (public.current_role_is_admin());

insert into public.formation_plan_pricing (plan, price, label) values
  ('mensuel', 20000, 'Mensuel'),
  ('annuel', 200000, 'Annuel (2 mois offerts)')
on conflict (plan) do nothing;

-- ------------------------------------------------------------
-- 9) Bucket Storage pour les photos de matières premières (public en
-- lecture — mêmes photos que la liste teaser, écriture réservée au staff).
-- Le justificatif de paiement de l'abonnement réutilise le bucket privé
-- existant `payment-proofs` (phase29), pas besoin d'en créer un autre.
-- ------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('raw-materials', 'raw-materials', true)
on conflict (id) do nothing;

drop policy if exists "raw_materials_bucket_public_read" on storage.objects;
create policy "raw_materials_bucket_public_read" on storage.objects
  for select using (bucket_id = 'raw-materials');

drop policy if exists "raw_materials_bucket_staff_write" on storage.objects;
create policy "raw_materials_bucket_staff_write" on storage.objects
  for insert with check (bucket_id = 'raw-materials' and public.current_role_is_staff());

drop policy if exists "raw_materials_bucket_staff_update" on storage.objects;
create policy "raw_materials_bucket_staff_update" on storage.objects
  for update using (bucket_id = 'raw-materials' and public.current_role_is_staff());

drop policy if exists "raw_materials_bucket_staff_delete" on storage.objects;
create policy "raw_materials_bucket_staff_delete" on storage.objects
  for delete using (bucket_id = 'raw-materials' and public.current_role_is_staff());
