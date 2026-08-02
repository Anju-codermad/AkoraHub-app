-- ============================================================
-- AkoraHub - Patch Phase 51 : Communauté — bloquer un client, masquer
-- une publication, enregistrer une publication, indicateur "Modifié"
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (02/08) : Lot 1 d'une liste de fonctionnalités demandée pour
-- rapprocher la Communauté d'un vrai réseau social (voir
-- PROJECT_CONTEXT.md) — priorité donnée à la confiance/sécurité, la
-- partie la plus en retard par rapport à Facebook.
--
-- ⚠️ Script idempotent (create table if not exists, drop policy if
-- exists) : relancer en entier depuis le début est sans risque.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Blocage — un client bloque un autre client, à sens unique. Créée
-- en premier avec sa fonction `is_blocked` : les policies posts/amis
-- ci-dessous en dépendent (une expression de policy est résolue à la
-- création, voir le correctif Phase 40).
--
-- Lecture volontairement limitée à SES PROPRES blocages (qui J'AI
-- bloqué) — jamais qui M'A bloqué, même principe que post_reports
-- (Phase 47) : évite qu'un blocage devienne un motif de confrontation.
-- ------------------------------------------------------------
create table if not exists public.user_blocks (
  id uuid primary key default gen_random_uuid(),
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  check (blocker_id <> blocked_id),
  unique (blocker_id, blocked_id)
);

alter table public.user_blocks enable row level security;

drop policy if exists "user_blocks_select_own" on public.user_blocks;
create policy "user_blocks_select_own" on public.user_blocks
  for select using (blocker_id = auth.uid());

drop policy if exists "user_blocks_insert_own" on public.user_blocks;
create policy "user_blocks_insert_own" on public.user_blocks
  for insert with check (blocker_id = auth.uid());

drop policy if exists "user_blocks_delete_own" on public.user_blocks;
create policy "user_blocks_delete_own" on public.user_blocks
  for delete using (blocker_id = auth.uid());

create or replace function public.is_blocked(a uuid, b uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.user_blocks
    where (blocker_id = a and blocked_id = b)
       or (blocker_id = b and blocked_id = a)
  );
$$;

-- ------------------------------------------------------------
-- 2) Masquer une publication (pour soi seulement, sans la signaler —
-- distinct de post_reports qui, lui, alerte le staff).
-- ------------------------------------------------------------
create table if not exists public.hidden_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  post_id uuid not null references public.posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, post_id)
);

alter table public.hidden_posts enable row level security;

drop policy if exists "hidden_posts_select_own" on public.hidden_posts;
create policy "hidden_posts_select_own" on public.hidden_posts
  for select using (user_id = auth.uid());

drop policy if exists "hidden_posts_insert_own" on public.hidden_posts;
create policy "hidden_posts_insert_own" on public.hidden_posts
  for insert with check (user_id = auth.uid());

drop policy if exists "hidden_posts_delete_own" on public.hidden_posts;
create policy "hidden_posts_delete_own" on public.hidden_posts
  for delete using (user_id = auth.uid());

-- ------------------------------------------------------------
-- 3) Enregistrer une publication ("Sauvegardés").
-- ------------------------------------------------------------
create table if not exists public.saved_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  post_id uuid not null references public.posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, post_id)
);

alter table public.saved_posts enable row level security;

drop policy if exists "saved_posts_select_own" on public.saved_posts;
create policy "saved_posts_select_own" on public.saved_posts
  for select using (user_id = auth.uid());

drop policy if exists "saved_posts_insert_own" on public.saved_posts;
create policy "saved_posts_insert_own" on public.saved_posts
  for insert with check (user_id = auth.uid());

drop policy if exists "saved_posts_delete_own" on public.saved_posts;
create policy "saved_posts_delete_own" on public.saved_posts
  for delete using (user_id = auth.uid());

-- ------------------------------------------------------------
-- 4) Indicateur "Modifié" — colonne déjà implicitement attendue par
-- wall_tab.dart::_editPost, qui va désormais la renseigner.
-- ------------------------------------------------------------
alter table public.posts
  add column if not exists updated_at timestamptz;

-- ------------------------------------------------------------
-- 5) Le fil ne montre plus les publications d'un compte bloqué (dans
-- les deux sens) ni celles que le client a masquées lui-même. La
-- protection est ici, dans la RLS — pas seulement un filtre côté app.
-- ------------------------------------------------------------
drop policy if exists "posts_select" on public.posts;
create policy "posts_select" on public.posts
  for select using (
    (visibility = 'public' or author_id = auth.uid() or public.current_role_is_staff())
    and not public.is_blocked(auth.uid(), author_id)
    and not exists (
      select 1 from public.hidden_posts hp
      where hp.user_id = auth.uid() and hp.post_id = posts.id
    )
  );

-- ------------------------------------------------------------
-- 6) Un blocage coupe aussi les nouvelles demandes d'ami et, via
-- `are_friends` (déjà utilisée par la policy d'insertion des messages
-- privés, Phase 48 — inutile de la modifier ici), les messages privés
-- entre deux comptes qui se bloquent, même s'ils étaient déjà amis.
-- ------------------------------------------------------------
create or replace function public.are_friends(a uuid, b uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.friendships
    where status = 'acceptee'
      and ((requester_id = a and addressee_id = b)
        or (requester_id = b and addressee_id = a))
  ) and not public.is_blocked(a, b);
$$;

drop policy if exists "friendships_insert_own_if_purchased" on public.friendships;
create policy "friendships_insert_own_if_purchased" on public.friendships
  for insert
  with check (
    auth.uid() = requester_id
    and status = 'en_attente'
    and public.has_made_purchase(auth.uid())
    and not public.is_blocked(auth.uid(), addressee_id)
  );
