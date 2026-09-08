-- ============================================================
-- AkoraHub - Patch Phase 223 : nouveau pilier "Akora Foods" —
-- demande explicite de la propriétaire (branche "Akora Agro" du site,
-- volet produits finis grand public — pendant d'"Akora NutriSource",
-- l'ingrédient B2B, cf. phase 222). Déjà anticipé dans le commentaire
-- de la phase 203 ("un futur pilier 'Akora Food' ... sera créé
-- séparément le moment venu").
--
-- Contexte : Akora Foods regroupe les produits alimentaires finis
-- (boissons, sirops, confitures, sauces, snacks...) destinés au grand
-- public — pilier B2C, distinct d'Akora NutriSource (matières
-- premières/ingrédients B2B).
--
-- Effet : crée le pilier (business_units) et ses 11 catégories,
-- toutes vides pour l'instant — la propriétaire ajoutera les produits
-- via l'Admin une fois le premier catalogue prêt (même principe que
-- la phase 203 pour Akora NutriLab).
--
-- Le site web (groupe-akora-site) et l'app lisent toutes deux les
-- piliers/catégories en direct depuis ces tables — aucun changement de
-- code nécessaire de part et d'autre.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do nothing).
-- ============================================================

insert into public.business_units (name, slug, active)
values ('Akora Foods', 'akora-foods', true)
on conflict (slug) do nothing;

insert into public.categories (business_unit_id, name)
select bu.id, c.name
from public.business_units bu
cross join (values
  ('Boissons & jus'),
  ('Sirops'),
  ('Confitures & produits fruités'),
  ('Sauces & condiments'),
  ('Épices conditionnées'),
  ('Biscuits & produits de pâtisserie'),
  ('Produits céréaliers'),
  ('Snacks'),
  ('Produits transformés agricoles'),
  ('Produits nutritionnels'),
  ('Produits naturels et artisanaux')
) as c(name)
where bu.slug = 'akora-foods'
on conflict (business_unit_id, name) do nothing;

-- Garde-fou : prévenir si le pilier Akora Foods n'a pas été trouvé.
do $$
begin
  if not exists (
    select 1 from public.business_units where slug = 'akora-foods'
  ) then
    raise notice 'Aucun pilier avec le slug ''akora-foods'' trouvé — les 11 catégories n''ont pas été insérées.';
  end if;
end $$;

-- Vérification
select bu.name as pilier, cat.name as categorie
from public.categories cat
join public.business_units bu on bu.id = cat.business_unit_id
where bu.slug = 'akora-foods'
order by cat.name;
