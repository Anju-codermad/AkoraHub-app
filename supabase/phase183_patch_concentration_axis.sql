-- ============================================================
-- AkoraHub - Patch Phase 183 : axe "Concentration" séparé du Parfum
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (25/08) : phase179 a ajouté les concentrations/degrés
-- (Eau de Javel, Peroxyde d'hydrogène) comme de simples `formats`,
-- réutilisant l'axe déjà utilisé pour le conditionnement (1L, 5L,
-- Bidon 35kg...). Résultat signalé par l'utilisatrice : le menu
-- déroulant "Format" mélangeait conditionnement ET concentration pour
-- un même produit, avec des prix qui ne correspondaient plus à la
-- bonne combinaison. Et comme elle va bientôt ajouter des produits à
-- vrais parfums (Liquide Vaisselle, Lave-sol...), réutiliser aussi
-- "Parfum" pour la concentration aurait pollué ce menu-là à son tour
-- avec des valeurs "10%"/"9°" mélangées aux vraies senteurs.
--
-- Ce patch crée un 3ème axe dédié, entièrement séparé :
-- 1) Nouvelle table `concentrations` (même modèle que formats/parfums).
-- 2) `product_variants.concentration_id` (nullable, comme format_id et
--    parfum_id — un produit sans concentration n'est pas concerné).
-- 3) Contrainte d'unicité étendue pour inclure ce nouvel axe.
-- 4) Migration des données déjà saisies par erreur : toute variante
--    dont le `format_id` pointe vers une des 8 valeurs de concentration
--    ajoutées par phase179 (3%, 10%, 50%, 9°, 12°, 18°, 36°, 48°) voit
--    cette valeur déplacée vers `concentration_id`, et `format_id`
--    remis à NULL — l'utilisatrice devra ensuite rouvrir chaque
--    variante concernée dans l'écran "Variantes" pour y indiquer le
--    VRAI conditionnement (1L, 5L, Bidon...), que seule elle connaît.
-- 5) Ces 8 valeurs sont retirées de `formats` pour ne plus jamais
--    réapparaître dans le menu Format d'aucun produit.
-- ============================================================

create table if not exists public.concentrations (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

alter table public.concentrations enable row level security;

drop policy if exists "concentrations_select_all" on public.concentrations;
create policy "concentrations_select_all" on public.concentrations
  for select using (true);
drop policy if exists "concentrations_write_staff" on public.concentrations;
create policy "concentrations_write_staff" on public.concentrations
  for all using (public.current_role_is_staff()) with check (public.current_role_is_staff());

alter table public.product_variants
  add column if not exists concentration_id uuid references public.concentrations(id);

alter table public.product_variants
  drop constraint if exists product_variants_product_id_format_id_parfum_id_key;
alter table public.product_variants
  add constraint product_variants_product_format_parfum_concentration_key
    unique (product_id, format_id, parfum_id, concentration_id);

-- Migration des 8 valeurs mal placées (phase179) de `formats` vers le
-- nouvel axe `concentrations`, en reportant les variantes existantes.
do $$
declare
  bad_name text;
  old_format_id uuid;
  new_concentration_id uuid;
begin
  foreach bad_name in array array['3%','10%','50%','9°','12°','18°','36°','48°']
  loop
    select id into old_format_id from public.formats where name = bad_name;
    if old_format_id is null then
      continue;
    end if;

    insert into public.concentrations (name) values (bad_name)
      on conflict (name) do nothing;
    select id into new_concentration_id from public.concentrations where name = bad_name;

    update public.product_variants
      set concentration_id = new_concentration_id, format_id = null
      where format_id = old_format_id;

    delete from public.formats where id = old_format_id;
  end loop;
end $$;
