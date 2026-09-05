-- ============================================================
-- AkoraHub - Patch Phase 204 : 7 catégories pour le pilier "Akora
-- NutriLab" (créé en phase 203, sans catégories jusqu'ici) — demande
-- explicite de la propriétaire le 04/09/2026.
--
-- Ingrédients alimentaires & solutions nutritionnelles :
--   - Épaississants, gélifiants et stabilisants
--   - Édulcorants
--   - Additifs alimentaires
--   - Colorants alimentaires
--   - Arômes & parfums alimentaires
--   - Émulsifiants
--   - Ingrédients nutritionnels
--
-- Le site web et l'app AkoraHub lisent toutes deux les catégories en
-- direct depuis cette table (actives uniquement) — aucun changement de
-- code nécessaire de part et d'autre, ces 7 catégories apparaîtront
-- automatiquement sous "Akora NutriLab" une fois ce script exécuté.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do nothing).
-- ============================================================

insert into public.categories (business_unit_id, name)
select bu.id, c.name
from public.business_units bu
cross join (values
  ('Épaississants, gélifiants et stabilisants'),
  ('Édulcorants'),
  ('Additifs alimentaires'),
  ('Colorants alimentaires'),
  ('Arômes & parfums alimentaires'),
  ('Émulsifiants'),
  ('Ingrédients nutritionnels')
) as c(name)
where bu.slug = 'akora-nutrilab'
on conflict (business_unit_id, name) do nothing;

-- Garde-fou : prévenir si le pilier Akora NutriLab n'a pas été trouvé.
do $$
begin
  if not exists (
    select 1 from public.business_units where slug = 'akora-nutrilab'
  ) then
    raise notice 'Aucun pilier avec le slug ''akora-nutrilab'' trouvé — les 7 catégories n''ont pas été insérées. Exécuter d''abord la phase 203.';
  end if;
end $$;

-- Vérification : catégories insérées
select bu.name as pilier, cat.name as categorie
from public.categories cat
join public.business_units bu on bu.id = cat.business_unit_id
where bu.slug = 'akora-nutrilab'
order by cat.name;
