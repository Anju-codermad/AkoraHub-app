-- ============================================================
-- AkoraHub - Patch Phase 233 : nouveau pilier "Akora Packaging" —
-- demande explicite de la propriétaire, 11e univers du groupe.
--
-- Contexte : branche dédiée aux solutions d'emballage et de
-- conditionnement (flaconnage, emballages alimentaires/cosmétiques/
-- entretien, carton, étiquetage, accessoires, packaging écologique,
-- solutions industrielles) — même logique que les piliers récents
-- (Akora NutriSource/Foods, phases 203/223) : crée le pilier et ses
-- catégories, toutes vides pour l'instant. La propriétaire ajoutera
-- les produits via l'Admin une fois le premier catalogue prêt (liste
-- détaillée d'articles fournie, mais sans prix/fournisseur pour
-- l'instant — rien à inventer côté migration).
--
-- "Packaging écologique" créée mais désactivée (categories.active,
-- phase9) : la propriétaire l'a explicitement qualifiée d'"extension
-- future" — préparée à l'avance, invisible côté client tant qu'elle
-- n'est pas prête à être lancée (même mécanisme que phase9/10).
--
-- Le site web (groupe-akora-site) et l'app lisent toutes deux les
-- piliers/catégories en direct depuis ces tables — aucun changement de
-- code nécessaire de part et d'autre.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do nothing).
-- ============================================================

insert into public.business_units (name, slug, active)
values ('Akora Packaging', 'akora-packaging', true)
on conflict (slug) do nothing;

insert into public.categories (business_unit_id, name, active)
select bu.id, c.name, true
from public.business_units bu
cross join (values
  ('Emballages plastiques rigides'),
  ('Emballages alimentaires'),
  ('Emballages produits d''entretien'),
  ('Emballages cosmétiques'),
  ('Emballages carton & papier'),
  ('Étiquettes & impression packaging'),
  ('Accessoires d''emballage'),
  ('Solutions industrielles')
) as c(name)
where bu.slug = 'akora-packaging'
on conflict (business_unit_id, name) do nothing;

-- "Packaging écologique" : créée à part, désactivée (extension future).
insert into public.categories (business_unit_id, name, active)
select bu.id, 'Packaging écologique', false
from public.business_units bu
where bu.slug = 'akora-packaging'
on conflict (business_unit_id, name) do nothing;

-- Garde-fou : prévenir si le pilier Akora Packaging n'a pas été trouvé.
do $$
begin
  if not exists (
    select 1 from public.business_units where slug = 'akora-packaging'
  ) then
    raise notice 'Aucun pilier avec le slug ''akora-packaging'' trouvé — les catégories n''ont pas été insérées.';
  end if;
end $$;

-- Vérification
select bu.name as pilier, cat.name as categorie, cat.active
from public.categories cat
join public.business_units bu on bu.id = cat.business_unit_id
where bu.slug = 'akora-packaging'
order by cat.name;
