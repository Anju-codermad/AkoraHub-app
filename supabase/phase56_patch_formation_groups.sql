-- ============================================================
-- AkoraHub - Patch Phase 56 : Groupes communautaires AkoraFormation, par
-- catégorie, réservés aux participants ayant réellement acheté un cours
-- de cette catégorie.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (01-02/08) : demande explicite de l'utilisatrice — "Le
-- groupe sont spécialement pour tout le participant des nôtres
-- formation. Seulement pour les participants." Choix retenu (via
-- AskUserQuestion) : un fil filtré par catégorie plutôt qu'un vrai
-- système de groupes avec membres/invitations, et d'abord construire
-- l'achat de cours (Phase 50, fait) avant ces groupes — c'est ce socle
-- qui permet de définir "participant" sans rien inventer.
--
-- Version volontairement simple (choisie explicitement) : publications
-- texte/photo par catégorie, PAS de commentaires ni réactions pour
-- cette première version (extensible plus tard si demandé) — juste un
-- fil, modifiable/supprimable par son auteur ou le staff.
--
-- ⚠️ Script idempotent : relancer en entier depuis le début est sans
-- risque.
-- ============================================================

-- ------------------------------------------------------------
-- 0) Un client est-il "participant" d'une catégorie de formation — au
-- moins un achat de cours VALIDÉ (course_purchases, Phase 50) dans
-- cette catégorie. Créée avant la table qui l'utilise : une expression
-- de policy est résolue à la création (voir le correctif Phase 40).
-- ------------------------------------------------------------
create or replace function public.is_formation_group_participant(uid uuid, cat text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.course_purchases cp
    join public.formation_courses fc on fc.id = cp.course_id
    where cp.customer_id = uid
      and cp.status = 'validee'
      and fc.category = cat
  );
$$;

-- ------------------------------------------------------------
-- 1) Publications du groupe — un fil par catégorie (`category` reprend
-- exactement `formation_courses.category`). Réutilise le bucket
-- `wall-photos` (public, Phase 3) pour les photos, aucun nouveau bucket
-- nécessaire.
-- ------------------------------------------------------------
create table if not exists public.formation_group_posts (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  author_id uuid not null references public.profiles(id) on delete cascade,
  content text not null default '',
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz
);

create index if not exists formation_group_posts_category_idx
  on public.formation_group_posts (category, created_at desc);

alter table public.formation_group_posts enable row level security;

-- Lecture et écriture réservées au staff et aux participants VALIDÉS de
-- cette catégorie précise — c'est ici, dans la RLS, la vraie protection
-- ("seulement pour les participants"), pas juste un filtre côté app.
drop policy if exists "formation_group_posts_select" on public.formation_group_posts;
create policy "formation_group_posts_select" on public.formation_group_posts
  for select using (
    public.current_role_is_staff()
    or public.is_formation_group_participant(auth.uid(), category)
  );

drop policy if exists "formation_group_posts_insert" on public.formation_group_posts;
create policy "formation_group_posts_insert" on public.formation_group_posts
  for insert with check (
    author_id = auth.uid()
    and (
      public.current_role_is_staff()
      or public.is_formation_group_participant(auth.uid(), category)
    )
  );

drop policy if exists "formation_group_posts_update_own" on public.formation_group_posts;
create policy "formation_group_posts_update_own" on public.formation_group_posts
  for update using (author_id = auth.uid() or public.current_role_is_staff());

drop policy if exists "formation_group_posts_delete_own" on public.formation_group_posts;
create policy "formation_group_posts_delete_own" on public.formation_group_posts
  for delete using (author_id = auth.uid() or public.current_role_is_staff());
