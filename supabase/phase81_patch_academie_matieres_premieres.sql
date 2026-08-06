-- ============================================================
-- AkoraHub - Patch Phase 81 : Académie Matières Premières (fiche technique)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (06/08) : sur la fiche d'une matière première déjà achetée
-- (voir phase45_patch_formation_per_product_pricing.sql), un DEUXIÈME
-- onglet "Académie" propose une fiche technique complète (nom chimique,
-- grade, pH, EPI, premiers secours, incompatibilités, dosages précis
-- par domaine d'application...). C'est un accès payant DISTINCT de
-- l'achat de la fiche produit — une nouvelle source de revenus propre à
-- l'utilisatrice : avoir acheté la fiche produit ne donne PAS accès à
-- l'Académie, il faut un achat séparé, produit par produit, avec ses
-- propres paliers dégressifs (même principe que phase45, table à part).
--
-- Tout reste verrouillé sans l'achat correspondant (pas de "teaser"
-- gratuit) — décision explicite de l'utilisatrice.
-- ============================================================

-- ------------------------------------------------------------
-- 0) Achats Académie (paiement manuel référence + preuve, validé par le
-- staff — même flux que formation_purchases). Une ligne par matière
-- première, regroupées par batch_id pour valider plusieurs d'un coup.
-- ------------------------------------------------------------
create table if not exists public.academie_purchases (
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
  unique (customer_id, raw_material_id)
);

create index if not exists academie_purchases_customer_idx
  on public.academie_purchases (customer_id, status);
create index if not exists academie_purchases_batch_idx
  on public.academie_purchases (batch_id);

alter table public.academie_purchases enable row level security;

drop policy if exists "academie_purchases_select_own_or_staff" on public.academie_purchases;
create policy "academie_purchases_select_own_or_staff" on public.academie_purchases
  for select using (auth.uid() = customer_id or public.current_role_is_staff());

drop policy if exists "academie_purchases_insert_own" on public.academie_purchases;
create policy "academie_purchases_insert_own" on public.academie_purchases
  for insert
  with check (auth.uid() = customer_id and status = 'en_attente');

drop policy if exists "academie_purchases_resubmit_own_refused" on public.academie_purchases;
create policy "academie_purchases_resubmit_own_refused" on public.academie_purchases
  for update
  using (auth.uid() = customer_id and status = 'refusee')
  with check (auth.uid() = customer_id and status = 'en_attente');

drop policy if exists "academie_purchases_staff_review" on public.academie_purchases;
create policy "academie_purchases_staff_review" on public.academie_purchases
  for update
  using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

create or replace function public.has_purchased_academie_access(uid uuid, material_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.academie_purchases
    where customer_id = uid
      and raw_material_id = material_id
      and status = 'validee'
  );
$$;

-- ------------------------------------------------------------
-- 1) Paliers de prix Académie — indépendants des paliers Formation
-- (formation_pricing_tiers), modifiables par l'Admin.
-- ------------------------------------------------------------
create table if not exists public.academie_pricing_tiers (
  min_quantity integer primary key check (min_quantity > 0),
  price numeric not null check (price >= 0),
  updated_at timestamptz not null default now()
);

alter table public.academie_pricing_tiers enable row level security;

drop policy if exists "academie_pricing_tiers_select_all" on public.academie_pricing_tiers;
create policy "academie_pricing_tiers_select_all" on public.academie_pricing_tiers
  for select using (true);

drop policy if exists "academie_pricing_tiers_write_admin_only" on public.academie_pricing_tiers;
create policy "academie_pricing_tiers_write_admin_only" on public.academie_pricing_tiers
  for all using (public.current_role_is_admin())
  with check (public.current_role_is_admin());

insert into public.academie_pricing_tiers (min_quantity, price) values
  (1, 15000),
  (5, 12000),
  (10, 8000)
on conflict (min_quantity) do nothing;

-- ------------------------------------------------------------
-- 2) Contenu de la fiche technique Académie — un modèle générique,
-- applicable à toute matière première quelle que soit sa catégorie
-- chimique (acides & bases, tensioactifs, agents de charge, épaississants,
-- conservateurs, chélatants, huiles, solvants, humectants, oxydants,
-- liants, pigments, parfums/colorants).
-- ------------------------------------------------------------
create table if not exists public.matieres_premieres_academie (
  id uuid primary key default gen_random_uuid(),
  matiere_premiere_id uuid not null unique
    references public.raw_materials(id) on delete cascade,
  nom_chimique text,
  synonymes text,
  grade text, -- Standard / Alimentaire / Cosmétique / Technique
  aspect text,
  ph_solution text,
  solubilite text,
  particularite text, -- ex: hygroscopique, exothermique
  difference_produit_similaire text,
  niveau_danger text, -- Aucun / Modéré / Élevé / Corrosif
  epi_requis text[] not null default '{}', -- ex: ["gants","lunettes","masque","ventilation"]
  premiers_secours text,
  incompatibilites text,
  stockage text,
  statut_verification text not null default 'a_valider'
    check (statut_verification in ('verifie','a_valider')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.matieres_premieres_academie enable row level security;

drop policy if exists "matieres_premieres_academie_select_staff_or_purchaser" on public.matieres_premieres_academie;
create policy "matieres_premieres_academie_select_staff_or_purchaser" on public.matieres_premieres_academie
  for select using (
    public.current_role_is_staff()
    or public.has_purchased_academie_access(auth.uid(), matiere_premiere_id)
  );

drop policy if exists "matieres_premieres_academie_write_staff_only" on public.matieres_premieres_academie;
create policy "matieres_premieres_academie_write_staff_only" on public.matieres_premieres_academie
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- ------------------------------------------------------------
-- 3) Usages détaillés (répétable, sans limite de blocs) — dosage/technique
-- précis par domaine d'application, distinct de raw_material_usages
-- (qui reste sur la fiche produit "gratuite").
-- ------------------------------------------------------------
create table if not exists public.matieres_premieres_usages (
  id uuid primary key default gen_random_uuid(),
  academie_id uuid not null
    references public.matieres_premieres_academie(id) on delete cascade,
  domaine_application text not null, -- ex: Savonnerie, Nettoyage industriel
  technique_methode text,
  dosage_concentration text, -- ex: "1-5%", "N1V1=N2V2"
  a_verifier_labo boolean not null default false,
  ordre int not null default 0
);

create index if not exists matieres_premieres_usages_academie_idx
  on public.matieres_premieres_usages (academie_id, ordre);

alter table public.matieres_premieres_usages enable row level security;

drop policy if exists "matieres_premieres_usages_select_staff_or_purchaser" on public.matieres_premieres_usages;
create policy "matieres_premieres_usages_select_staff_or_purchaser" on public.matieres_premieres_usages
  for select using (
    public.current_role_is_staff()
    or exists (
      select 1 from public.matieres_premieres_academie a
      where a.id = academie_id
        and public.has_purchased_academie_access(auth.uid(), a.matiere_premiere_id)
    )
  );

drop policy if exists "matieres_premieres_usages_write_staff_only" on public.matieres_premieres_usages;
create policy "matieres_premieres_usages_write_staff_only" on public.matieres_premieres_usages
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());
