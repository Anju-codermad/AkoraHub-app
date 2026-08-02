-- ============================================================
-- AkoraHub - Patch Phase 53 : Communauté — carrousel multi-images
-- (Lot 3). Les mentions @ réutilisent `posts.mentioned_user_id`
-- (présente depuis la Phase 3, jamais reliée à une interface jusqu'ici)
-- et les hashtags sont analysés côté app depuis `content` — aucun
-- changement de schéma nécessaire pour ces deux-là, voir wall_tab.dart.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- ⚠️ Script idempotent : relancer en entier depuis le début est sans
-- risque.
-- ============================================================

-- ------------------------------------------------------------
-- Une publication peut désormais avoir plusieurs photos (même principe
-- que product_images/raw_material_images, Phase 8/40). `posts.image_url`
-- reste renseignée (1ère photo) pour compatibilité avec l'affichage
-- existant qui ne connaît pas encore cette table (aperçu du profil
-- public, wall_tab.dart::_sharePost).
-- ------------------------------------------------------------
create table if not exists public.post_images (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  image_url text not null,
  position integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists post_images_post_idx
  on public.post_images (post_id, position);

alter table public.post_images enable row level security;

-- Visible exactement dans les mêmes conditions que la publication
-- elle-même (public/privée, bloqué, masqué...) : la sous-requête sur
-- `posts` est elle-même filtrée par la RLS de `posts` (Phase 3/51), pas
-- besoin de dupliquer cette logique ici.
drop policy if exists "post_images_select" on public.post_images;
create policy "post_images_select" on public.post_images
  for select using (
    exists (select 1 from public.posts where posts.id = post_images.post_id)
  );

drop policy if exists "post_images_insert_own" on public.post_images;
create policy "post_images_insert_own" on public.post_images
  for insert with check (
    exists (
      select 1 from public.posts
      where posts.id = post_images.post_id
        and (posts.author_id = auth.uid() or public.current_role_is_staff())
    )
  );

drop policy if exists "post_images_delete_own" on public.post_images;
create policy "post_images_delete_own" on public.post_images
  for delete using (
    exists (
      select 1 from public.posts
      where posts.id = post_images.post_id
        and (posts.author_id = auth.uid() or public.current_role_is_staff())
    )
  );
