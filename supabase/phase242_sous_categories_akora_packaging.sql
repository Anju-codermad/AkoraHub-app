-- ============================================================
-- AkoraHub - Patch Phase 242 : 6 catégories supplémentaires pour le
-- pilier Akora Packaging — demande explicite de la propriétaire le
-- 19/09/2026 ("sous-catégories... pour bien organisé"), confirmée sur
-- une capture du catalogue site montrant les 9 catégories existantes
-- (phase233) toutes vides.
--
-- Ne remplace ni ne renomme aucune catégorie existante — s'ajoute aux
-- 9 déjà en place. "Accessoires d'emballage" (où est actuellement
-- rangé "Bouchon push-pull", phase241) reste : ces 6 nouvelles
-- catégories permettent de répartir plus finement les prochains
-- produits plutôt que de tout entasser dedans.
--
-- Site et app lisent les catégories en direct depuis cette table —
-- aucun changement de code nécessaire de part et d'autre pour qu'elles
-- apparaissent.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do nothing, contrainte unique
-- (business_unit_id, name) déjà en place depuis phase6).
-- ============================================================

insert into public.categories (business_unit_id, name, active)
select bu.id, c.name, true
from public.business_units bu
cross join (values
  ('Bouchons & fermetures'),
  ('Pompes & vaporisateurs'),
  ('Flacons & bouteilles'),
  ('Pots & bocaux'),
  ('Sacs & sachets'),
  ('Rubans & adhésifs')
) as c(name)
where bu.slug = 'akora-packaging'
on conflict (business_unit_id, name) do nothing;

-- Garde-fou : prévenir si le pilier Akora Packaging n'a pas été trouvé.
do $$
begin
  if not exists (
    select 1 from public.business_units where slug = 'akora-packaging'
  ) then
    raise notice 'Aucun pilier avec le slug ''akora-packaging'' trouvé — rien inséré.';
  end if;
end $$;

-- Vérification
select bu.name as pilier, cat.name as categorie, cat.active
from public.categories cat
join public.business_units bu on bu.id = cat.business_unit_id
where bu.slug = 'akora-packaging'
order by cat.name;
