-- ============================================================
-- AkoraHub - Patch Phase 26 : Flash infos (annonces courtes)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Bandeau d'annonces courtes sur l'Accueil client (promo, rupture de
-- stock temporaire, nouveauté...), distinct de la bannière hero (photo +
-- titre/sous-titre, home_banners) : ici du texte seul, pensé pour être
-- publié rapidement sans upload d'image. Même modèle de permissions que
-- home_banners : écriture réservée à l'Admin, lecture publique des
-- annonces actives.
-- ============================================================

create table if not exists public.flash_infos (
  id uuid primary key default gen_random_uuid(),
  message text not null,
  active boolean not null default true,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

alter table public.flash_infos enable row level security;

drop policy if exists "flash_infos_select_active_or_admin" on public.flash_infos;
create policy "flash_infos_select_active_or_admin" on public.flash_infos
  for select using (active = true or public.current_role_is_admin());

drop policy if exists "flash_infos_write_admin_only" on public.flash_infos;
create policy "flash_infos_write_admin_only" on public.flash_infos
  for all using (public.current_role_is_admin())
  with check (public.current_role_is_admin());
