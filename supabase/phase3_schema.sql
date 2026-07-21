-- ============================================================
-- Akora Fanadiovana - Schéma Phase 3 (Social)
-- Mur personnel, likes, commentaires, avis produits.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

-- ------------------------------------------------------------
-- 1. STOCKAGE : bucket pour les photos du mur
-- ------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('wall-photos', 'wall-photos', true)
on conflict (id) do nothing;

-- Un utilisateur connecté peut uploader dans son propre dossier
-- (nommé avec son propre user id), tout le monde peut lire (bucket public).
create policy "wall_photos_public_read" on storage.objects
  for select using (bucket_id = 'wall-photos');
create policy "wall_photos_owner_upload" on storage.objects
  for insert with check (
    bucket_id = 'wall-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "wall_photos_owner_delete" on storage.objects
  for delete using (
    bucket_id = 'wall-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ------------------------------------------------------------
-- 2. MUR — Publications (texte + photo optionnelle)
-- ------------------------------------------------------------
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  content text not null default '',
  image_url text,
  visibility text not null default 'public' check (visibility in ('public','private')),
  mentioned_user_id uuid references public.profiles(id),
  mentioned_product_id uuid references public.products(id),
  created_at timestamptz not null default now()
);

create table if not exists public.post_likes (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (post_id, user_id)
);

create table if not exists public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 3. AVIS PRODUITS (séparés du mur, rattachés à la fiche produit)
-- ------------------------------------------------------------
create table if not exists public.product_reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  unique (product_id, author_id)
);

-- ============================================================
-- SÉCURITÉ
-- ============================================================
alter table public.posts enable row level security;
alter table public.post_likes enable row level security;
alter table public.post_comments enable row level security;
alter table public.product_reviews enable row level security;

-- Mur visible si public, ou si c'est le sien, ou si on est staff.
create policy "posts_select" on public.posts
  for select using (
    visibility = 'public' or author_id = auth.uid() or public.current_role_is_staff()
  );
create policy "posts_insert_own" on public.posts
  for insert with check (author_id = auth.uid());
create policy "posts_update_own" on public.posts
  for update using (author_id = auth.uid() or public.current_role_is_staff());
create policy "posts_delete_own" on public.posts
  for delete using (author_id = auth.uid() or public.current_role_is_staff());

-- Likes : lecture publique, chacun gère ses propres likes.
create policy "post_likes_select_all" on public.post_likes
  for select using (true);
create policy "post_likes_insert_own" on public.post_likes
  for insert with check (user_id = auth.uid());
create policy "post_likes_delete_own" on public.post_likes
  for delete using (user_id = auth.uid());

-- Commentaires : lecture publique, chacun écrit les siens.
create policy "post_comments_select_all" on public.post_comments
  for select using (true);
create policy "post_comments_insert_own" on public.post_comments
  for insert with check (author_id = auth.uid());
create policy "post_comments_delete_own" on public.post_comments
  for delete using (author_id = auth.uid() or public.current_role_is_staff());

-- Avis produits : lecture publique, un avis par client et par produit.
create policy "product_reviews_select_all" on public.product_reviews
  for select using (true);
create policy "product_reviews_insert_own" on public.product_reviews
  for insert with check (author_id = auth.uid());
create policy "product_reviews_update_own" on public.product_reviews
  for update using (author_id = auth.uid());
create policy "product_reviews_delete_own" on public.product_reviews
  for delete using (author_id = auth.uid() or public.current_role_is_staff());
