-- ============================================================
-- Akora Fanadiovana - Patch Phase 6 : bannière hero de l'accueil client
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

-- ------------------------------------------------------------
-- 1. TABLE home_banners
-- ------------------------------------------------------------
-- Remplace le carrousel de promos codé en dur dans l'app client par
-- des slides gérables depuis l'espace Admin (titre, sous-titre, photo).
create table if not exists public.home_banners (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text,
  image_url text,
  sort_order int not null default 0,
  active boolean not null default true,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.home_banners enable row level security;

-- Lecture publique des bannières actives (tout le monde, y compris les
-- clients non connectés le cas échéant) ; l'Admin voit aussi les inactives
-- pour pouvoir les prévisualiser/réactiver.
drop policy if exists "home_banners_select_active_or_admin" on public.home_banners;
create policy "home_banners_select_active_or_admin" on public.home_banners
  for select using (active = true or public.current_role_is_admin());

-- Écriture réservée strictement à l'Admin (pas le reste du staff), comme
-- demandé : seul l'Admin peut ajouter/modifier/supprimer une bannière et
-- changer sa photo.
drop policy if exists "home_banners_write_admin_only" on public.home_banners;
create policy "home_banners_write_admin_only" on public.home_banners
  for all using (public.current_role_is_admin())
  with check (public.current_role_is_admin());

-- ------------------------------------------------------------
-- 2. BUCKET STORAGE pour les photos de bannière
-- ------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('home-banners', 'home-banners', true)
on conflict (id) do nothing;

-- Lecture publique (bucket public, nécessaire pour l'affichage côté client).
drop policy if exists "home_banners_images_public_read" on storage.objects;
create policy "home_banners_images_public_read" on storage.objects
  for select using (bucket_id = 'home-banners');

-- Upload/mise à jour/suppression réservés à l'Admin uniquement.
drop policy if exists "home_banners_images_admin_upload" on storage.objects;
create policy "home_banners_images_admin_upload" on storage.objects
  for insert with check (
    bucket_id = 'home-banners' and public.current_role_is_admin()
  );

drop policy if exists "home_banners_images_admin_update" on storage.objects;
create policy "home_banners_images_admin_update" on storage.objects
  for update using (
    bucket_id = 'home-banners' and public.current_role_is_admin()
  );

drop policy if exists "home_banners_images_admin_delete" on storage.objects;
create policy "home_banners_images_admin_delete" on storage.objects
  for delete using (
    bucket_id = 'home-banners' and public.current_role_is_admin()
  );
