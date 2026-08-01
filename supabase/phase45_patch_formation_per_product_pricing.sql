-- ============================================================
-- AkoraHub - Patch Phase 45 : Formation — achat par produit (paliers dégressifs)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (01/08) : remplace le modèle d'abonnement Formation
-- (mensuel/annuel, accès global à tout le catalogue — Phase 40) par un
-- achat PERMANENT, PRODUIT PAR PRODUIT, avec un tarif dégressif selon le
-- nombre total de produits déjà achetés (validés) par le client
-- (cumulatif, tous achats confondus dans le temps) :
--   1 produit   : 10 000 Ar / produit
--   5 produits  :  8 000 Ar / produit
--   10 produits :  5 000 Ar / produit
-- Le palier atteint (une fois les produits déjà possédés + ceux de
-- l'achat en cours comptés) s'applique à TOUS les produits de l'achat en
-- cours — jamais de recalcul rétroactif sur ce qui a déjà été payé
-- auparavant. Confirmé : aucun client n'a encore payé d'abonnement à ce
-- jour, donc aucune migration de données existantes n'est nécessaire.
--
-- Ces trois montants sont modifiables par l'Admin (table
-- formation_pricing_tiers ci-dessous, même principe que
-- formation_plan_pricing qu'elle remplace — celle-ci n'est pas
-- supprimée, elle reste juste inutilisée).
--
-- La table formation_subscriptions (Phase 40) n'est pas supprimée non
-- plus (par prudence, pas de perte de données), mais n'est plus utilisée
-- pour l'accès : `has_active_formation_subscription` n'est appelée par
-- aucune policy après ce script.
-- ============================================================

-- ------------------------------------------------------------
-- 0) Achats individuels + fonction de vérification d'accès — créées
-- avant tout le reste (voir le correctif Phase 40 : l'expression d'un
-- CREATE POLICY est résolue à la création, la fonction référencée doit
-- donc déjà exister).
--
-- Flux de validation, même principe que les anciennes demandes
-- d'abonnement (référence + preuve, validées par le staff) : une ligne
-- par produit acheté, regroupées par `batch_id` (un même achat peut
-- porter sur plusieurs produits à la fois) pour que l'Admin les
-- valide/refuse ensemble en un clic plutôt que produit par produit.
-- ------------------------------------------------------------
create table if not exists public.formation_purchases (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  raw_material_id uuid not null references public.raw_materials(id) on delete cascade,
  batch_id text not null,
  amount numeric not null,
  status text not null default 'en_attente'
    check (status in ('en_attente','validee','refusee')),
  payment_method text,
  payment_reference text,
  payment_proof_path text,
  requested_at timestamptz not null default now(),
  validated_at timestamptz,
  -- Un produit ne peut être acheté qu'une seule fois par client (accès
  -- permanent) — un achat refusé peut être re-soumis (voir policy de
  -- mise à jour ci-dessous) plutôt que de créer une nouvelle ligne.
  unique (customer_id, raw_material_id)
);

create index if not exists formation_purchases_customer_idx
  on public.formation_purchases (customer_id, status);
create index if not exists formation_purchases_batch_idx
  on public.formation_purchases (batch_id);

alter table public.formation_purchases enable row level security;

drop policy if exists "formation_purchases_select_own_or_staff" on public.formation_purchases;
create policy "formation_purchases_select_own_or_staff" on public.formation_purchases
  for select using (auth.uid() = customer_id or public.current_role_is_staff());

drop policy if exists "formation_purchases_insert_own" on public.formation_purchases;
create policy "formation_purchases_insert_own" on public.formation_purchases
  for insert
  with check (auth.uid() = customer_id and status = 'en_attente');

-- Un client ne peut modifier que SA propre ligne, et seulement pour la
-- re-soumettre après un refus (refusee -> en_attente) — il ne peut
-- jamais se donner l'accès lui-même en passant status à 'validee'.
drop policy if exists "formation_purchases_resubmit_own_refused" on public.formation_purchases;
create policy "formation_purchases_resubmit_own_refused" on public.formation_purchases
  for update
  using (auth.uid() = customer_id and status = 'refusee')
  with check (auth.uid() = customer_id and status = 'en_attente');

drop policy if exists "formation_purchases_staff_review" on public.formation_purchases;
create policy "formation_purchases_staff_review" on public.formation_purchases
  for update
  using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

create or replace function public.has_purchased_raw_material(uid uuid, material_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.formation_purchases
    where customer_id = uid
      and raw_material_id = material_id
      and status = 'validee'
  );
$$;

-- ------------------------------------------------------------
-- 1) Paliers de prix (modifiables par l'Admin — écran "Achats Formation").
-- ------------------------------------------------------------
create table if not exists public.formation_pricing_tiers (
  min_quantity integer primary key check (min_quantity > 0),
  price numeric not null check (price >= 0),
  updated_at timestamptz not null default now()
);

alter table public.formation_pricing_tiers enable row level security;

drop policy if exists "formation_pricing_tiers_select_all" on public.formation_pricing_tiers;
create policy "formation_pricing_tiers_select_all" on public.formation_pricing_tiers
  for select using (true);

drop policy if exists "formation_pricing_tiers_write_admin_only" on public.formation_pricing_tiers;
create policy "formation_pricing_tiers_write_admin_only" on public.formation_pricing_tiers
  for all using (public.current_role_is_admin())
  with check (public.current_role_is_admin());

insert into public.formation_pricing_tiers (min_quantity, price) values
  (1, 10000),
  (5, 8000),
  (10, 5000)
on conflict (min_quantity) do nothing;

-- ------------------------------------------------------------
-- 2) Remplacement des 5 policies qui utilisaient l'ancien booléen global
-- `has_active_formation_subscription` par une vérification PAR PRODUIT.
-- ------------------------------------------------------------
drop policy if exists "raw_materials_select_staff_or_subscriber" on public.raw_materials;
create policy "raw_materials_select_staff_or_purchaser" on public.raw_materials
  for select using (
    public.current_role_is_staff()
    or public.has_purchased_raw_material(auth.uid(), id)
  );

drop policy if exists "raw_material_images_select_staff_or_subscriber" on public.raw_material_images;
create policy "raw_material_images_select_staff_or_purchaser" on public.raw_material_images
  for select using (
    public.current_role_is_staff()
    or public.has_purchased_raw_material(auth.uid(), raw_material_id)
  );

drop policy if exists "raw_material_usages_select_staff_or_subscriber" on public.raw_material_usages;
create policy "raw_material_usages_select_staff_or_purchaser" on public.raw_material_usages
  for select using (
    public.current_role_is_staff()
    or public.has_purchased_raw_material(auth.uid(), raw_material_id)
  );

drop policy if exists "raw_material_packaging_select_staff_or_subscriber" on public.raw_material_packaging;
create policy "raw_material_packaging_select_staff_or_purchaser" on public.raw_material_packaging
  for select using (
    public.current_role_is_staff()
    or public.has_purchased_raw_material(auth.uid(), raw_material_id)
  );

drop policy if exists "raw_material_price_history_select_staff_or_subscriber" on public.raw_material_price_history;
create policy "raw_material_price_history_select_staff_or_purchaser" on public.raw_material_price_history
  for select using (
    public.current_role_is_staff()
    or public.has_purchased_raw_material(auth.uid(), raw_material_id)
  );
