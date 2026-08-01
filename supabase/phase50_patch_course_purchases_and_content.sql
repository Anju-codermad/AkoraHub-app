-- ============================================================
-- AkoraHub - Patch Phase 50 : achat des cours AkoraFormation +
-- contenu protégé (vidéos/documents par module)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (01-02/08) : les groupes communautaires par catégorie de
-- Formation (demande de l'utilisatrice) doivent être réservés aux
-- clients ayant réellement accès à cette formation. Pour "Matières
-- premières", cet accès existe déjà (formation_purchases, phase45).
-- Pour les 8 catégories de cours AkoraFormation (formation_courses,
-- phase43), il n'existait jusqu'ici aucune notion d'achat ni de
-- contenu réel — juste une liste/vitrine ("Déjà développée" ne
-- voulait dire que la formation existe, pas qu'elle est consultable).
-- Ce script ajoute les deux : achat par cours, et modules avec
-- vidéo/document réels.
--
-- ⚠️ Paiement manuel (référence + preuve), même principe que les
-- commandes et Matières premières — voir web/formation-access (page
-- externe, conformité Google Play, Phase 49).
--
-- ⚠️ Script idempotent (create table if not exists, drop policy if
-- exists) : si une première exécution s'est arrêtée en erreur, relancer
-- ce script en entier depuis le début est sans risque.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Prix par cours (nul = pas encore en vente, le staff le définit
-- quand le cours est prêt).
-- ------------------------------------------------------------
alter table public.formation_courses
  add column if not exists price numeric;

-- ------------------------------------------------------------
-- 2) Achats de cours — même principe que formation_purchases
-- (matières premières) : paiement manuel, validation staff, une seule
-- ligne par (client, cours), re-soumission possible après refus.
-- Créée AVANT formation_course_modules ci-dessous : sa policy de
-- lecture référence cette table, qui doit donc déjà exister (une
-- expression de policy est résolue à la création, voir Phase 40).
-- ------------------------------------------------------------
create table if not exists public.course_purchases (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  course_id uuid not null references public.formation_courses(id) on delete cascade,
  batch_id text,
  amount numeric not null default 0,
  status text not null default 'en_attente'
    check (status in ('en_attente','validee','refusee')),
  payment_method text,
  payment_reference text,
  payment_proof_path text,
  created_at timestamptz not null default now(),
  validated_at timestamptz,
  unique (customer_id, course_id)
);

create index if not exists course_purchases_customer_idx
  on public.course_purchases (customer_id, status);

alter table public.course_purchases enable row level security;

drop policy if exists "course_purchases_select_own_or_staff" on public.course_purchases;
create policy "course_purchases_select_own_or_staff" on public.course_purchases
  for select using (customer_id = auth.uid() or public.current_role_is_staff());

drop policy if exists "course_purchases_insert_own" on public.course_purchases;
create policy "course_purchases_insert_own" on public.course_purchases
  for insert with check (customer_id = auth.uid() and status = 'en_attente');

-- Le client peut re-soumettre après un refus (upsert), mais ne peut
-- jamais lui-même passer une ligne à 'validee'.
drop policy if exists "course_purchases_resubmit_own_refused" on public.course_purchases;
create policy "course_purchases_resubmit_own_refused" on public.course_purchases
  for update using (customer_id = auth.uid() and status = 'refusee')
  with check (customer_id = auth.uid() and status = 'en_attente');

drop policy if exists "course_purchases_update_staff" on public.course_purchases;
create policy "course_purchases_update_staff" on public.course_purchases
  for update using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- Pas de notification push automatique ici, cohérent avec
-- formation_purchases (Matières premières, phase45) : le staff vérifie
-- les demandes en attente manuellement depuis l'admin.

-- ------------------------------------------------------------
-- 3) Modules réels par cours (remplace le simple compteur
-- `module_count` par du contenu effectif : vidéo, document, texte).
-- Lecture réservée au staff et aux clients ayant validé leur achat de
-- CE cours précis — c'est la vraie protection (la RLS, pas
-- l'interface) : un client qui n'a pas payé ne peut tout simplement
-- pas récupérer video_url/document_url depuis l'API.
-- ------------------------------------------------------------
create table if not exists public.formation_course_modules (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.formation_courses(id) on delete cascade,
  title text not null,
  sort_order integer not null default 0,
  video_url text,
  document_url text,
  content_text text,
  created_at timestamptz not null default now()
);

create index if not exists formation_course_modules_course_idx
  on public.formation_course_modules (course_id, sort_order);

alter table public.formation_course_modules enable row level security;

drop policy if exists "course_modules_select_staff_or_owner" on public.formation_course_modules;
create policy "course_modules_select_staff_or_owner" on public.formation_course_modules
  for select using (
    public.current_role_is_staff()
    or exists (
      select 1 from public.course_purchases cp
      where cp.course_id = formation_course_modules.course_id
        and cp.customer_id = auth.uid()
        and cp.status = 'validee'
    )
  );

drop policy if exists "course_modules_write_staff" on public.formation_course_modules;
create policy "course_modules_write_staff" on public.formation_course_modules
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());
