-- ============================================================
-- AkoraHub - Patch Phase 188 : nouvelle catégorie "Akor'Eau"
-- (produits de traitement de l'eau), demande explicite du 04/09/2026.
--
-- Même principe que Phase 6 (catégories scopées par pilier) : ajoutée
-- au pilier "Akora Fanadiovana" (matières premières), pas un nouveau
-- pilier — juste une catégorie de plus dans le même catalogue.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do nothing).
-- ============================================================

insert into public.categories (business_unit_id, name)
select bu.id, 'Akor''Eau'
from public.business_units bu
where bu.name ilike 'Akora Fanadiovana'
on conflict (business_unit_id, name) do nothing;

-- Garde-fou : prévenir si aucun pilier "Akora Fanadiovana" n'a été trouvé.
do $$
begin
  if not exists (
    select 1 from public.business_units where name ilike 'Akora Fanadiovana'
  ) then
    raise notice 'Aucun pilier nommé "Akora Fanadiovana" trouvé — la catégorie "Akor''Eau" n''a pas été insérée. Vérifie le nom exact du pilier dans la table business_units.';
  end if;
end $$;

-- Vérification : voir la catégorie insérée
-- select c.name, bu.name as pilier from public.categories c
-- join public.business_units bu on bu.id = c.business_unit_id
-- where c.name = 'Akor''Eau';
