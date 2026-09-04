-- ============================================================
-- AkoraHub - Patch Phase 188 : nouvelle catégorie "Akor'Eau"
-- (produits de traitement de l'eau), demande explicite du 04/09/2026.
--
-- Même principe que Phase 6 (catégories scopées par pilier) : ajoutée
-- au pilier "Akora Fanadiovana" (matières premières), pas un nouveau
-- pilier — juste une catégorie de plus dans le même catalogue.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do nothing).
--
-- CORRECTIF 04/09/2026 : le pilier "Akora Fanadiovana" a été renommé
-- "Akora Pro" (rebranding "Groupe Akora" fait en parallèle côté site
-- web) — le lookup ci-dessous utilise désormais bu.slug =
-- 'matieres-premieres' (identifiant stable) au lieu de bu.name. La
-- première exécution (nom obsolète) a rapporté "Success" mais n'a en
-- réalité inséré aucune ligne — à ré-exécuter avec ce correctif.
-- ============================================================

insert into public.categories (business_unit_id, name)
select bu.id, 'Akor''Eau'
from public.business_units bu
where bu.slug = 'matieres-premieres'
on conflict (business_unit_id, name) do nothing;

-- Garde-fou : prévenir si aucun pilier avec ce slug n'a été trouvé.
do $$
begin
  if not exists (
    select 1 from public.business_units where slug = 'matieres-premieres'
  ) then
    raise notice 'Aucun pilier avec le slug "matieres-premieres" trouvé — la catégorie "Akor''Eau" n''a pas été insérée. Vérifie le slug exact du pilier dans la table business_units.';
  end if;
end $$;

-- Vérification : voir la catégorie insérée
-- select c.name, bu.name as pilier from public.categories c
-- join public.business_units bu on bu.id = c.business_unit_id
-- where c.name = 'Akor''Eau';
