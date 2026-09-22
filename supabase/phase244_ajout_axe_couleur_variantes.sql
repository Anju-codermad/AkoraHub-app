-- ============================================================
-- AkoraHub - Patch Phase 244 : axe "Couleur" pour les variantes produit
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (21/09/2026, demande explicite) : le "Bouchon push-pull"
-- (Akora Packaging) existe en plusieurs couleurs — aucun axe pour gérer
-- ça aujourd'hui (seulement Format/Parfum/Concentration, voir phase183).
-- Même modèle exact que les 3 axes existants : nouvelle table `colors`,
-- colonne `product_variants.color_id` (nullable — un produit sans
-- variante de couleur n'est pas concerné), contrainte d'unicité étendue.
-- ============================================================

create table if not exists public.colors (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

alter table public.colors enable row level security;

drop policy if exists "colors_select_all" on public.colors;
create policy "colors_select_all" on public.colors
  for select using (true);
drop policy if exists "colors_write_staff" on public.colors;
create policy "colors_write_staff" on public.colors
  for all using (public.current_role_is_staff()) with check (public.current_role_is_staff());

alter table public.product_variants
  add column if not exists color_id uuid references public.colors(id);

alter table public.product_variants
  drop constraint if exists product_variants_product_format_parfum_concentration_key;
alter table public.product_variants
  add constraint product_variants_product_format_parfum_concentration_color_key
    unique (product_id, format_id, parfum_id, concentration_id, color_id);
