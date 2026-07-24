-- ============================================================
-- Akora Fanadiovana - Patch Phase 6 : sous-catégories produit (categories)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : jusqu'ici `products.category` était un champ texte libre
-- (risque de faute de frappe créant une catégorie fantôme, puisque le
-- filtre client compare le texte exactement). On applique le même schéma
-- que pour formats/parfums (phase4_schema.sql) : une table de référence
-- PRÉ-REMPLIE, choisie via un menu déroulant côté Admin au lieu d'être
-- retapée à la main. Contrairement à formats/parfums qui sont partagés
-- entre tous les produits, les catégories sont scopées par pilier
-- (business_unit_id) car "Carrelage & Sols" n'a de sens que pour
-- Akora Fanadiovana, pas pour un pilier Formation par exemple.
-- ============================================================

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  business_unit_id uuid not null references public.business_units(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  unique (business_unit_id, name)
);

alter table public.categories enable row level security;

drop policy if exists "categories_select_all" on public.categories;
create policy "categories_select_all" on public.categories
  for select using (true);

drop policy if exists "categories_write_staff" on public.categories;
create policy "categories_write_staff" on public.categories
  for all using (public.current_role_is_staff())
  with check (public.current_role_is_staff());

-- ------------------------------------------------------------
-- Pré-remplissage des 8 catégories pour le pilier Akora Fanadiovana
-- ------------------------------------------------------------
insert into public.categories (business_unit_id, name)
select bu.id, c.name
from public.business_units bu
cross join (values
  ('Carrelage & Sols'),
  ('Cuisine & Vaisselle'),
  ('Désinfectants & Hygiène'),
  ('Entretien Véhicules'),
  ('Lessive & Textile'),
  ('Sanitaire & Salle de Bain'),
  ('Soins du Corps & Cosmétiques'),
  ('Vitres & Surfaces')
) as c(name)
where bu.name ilike 'Akora Fanadiovana'
on conflict (business_unit_id, name) do nothing;

-- Garde-fou : prévenir si aucun pilier "Akora Fanadiovana" n'a été trouvé
-- (le nom exact du pilier créé dans l'app diffère peut-être).
do $$
begin
  if not exists (
    select 1 from public.business_units where name ilike 'Akora Fanadiovana'
  ) then
    raise notice 'Aucun pilier nommé "Akora Fanadiovana" trouvé — les 8 catégories n''ont pas été insérées. Vérifie le nom exact du pilier dans la table business_units et adapte le WHERE ci-dessus.';
  end if;
end $$;

-- Vérification : voir les catégories insérées
select bu.name as pilier, cat.name as categorie
from public.categories cat
join public.business_units bu on bu.id = cat.business_unit_id
order by bu.name, cat.name;
