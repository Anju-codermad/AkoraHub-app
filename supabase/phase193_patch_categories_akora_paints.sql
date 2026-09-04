-- ============================================================
-- AkoraHub - Patch Phase 193 : 7 catégories pour le pilier "Akora
-- Paints" (slug arca-paints), qui n'en avait aucune depuis son
-- lancement — demande explicite de la propriétaire le 04/09/2026.
--
-- 5 catégories demandées (avec leur code produit interne, gardé en
-- commentaire ici mais pas stocké : la table `categories` n'a qu'un
-- champ `name`, utilisé comme libellé affiché client — cohérent avec
-- le reste du catalogue, qui n'affiche que des noms descriptifs, pas
-- de codes) :
--   MURO  -> Peinture Mur Intérieur Acrylique Mate
--   FAÇAD -> Façade Extérieure
--   FERRO -> Antirouille Alkyde
--   LUSSO -> Glycéro Brillant Bois & Fer
--   PRIMO -> Sous-Couche Universelle
-- + 2 catégories suggérées et validées par la propriétaire, pertinentes
-- pour le marché malgache :
--   TOITU -> Peinture Toiture (Tôles & Bacs Acier)
--   LASUR -> Lasure & Vernis Bois
--
-- Le site web et l'app AkoraHub lisent toutes deux les catégories en
-- direct depuis cette table (actives uniquement) — aucun changement de
-- code nécessaire de part et d'autre, ces 7 catégories apparaîtront
-- automatiquement sous "Akora Paints" une fois ce script exécuté.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do nothing).
-- ============================================================

insert into public.categories (business_unit_id, name)
select bu.id, c.name
from public.business_units bu
cross join (values
  ('Peinture Mur Intérieur Acrylique Mate'),
  ('Façade Extérieure'),
  ('Antirouille Alkyde'),
  ('Glycéro Brillant Bois & Fer'),
  ('Sous-Couche Universelle'),
  ('Peinture Toiture (Tôles & Bacs Acier)'),
  ('Lasure & Vernis Bois')
) as c(name)
where bu.slug = 'arca-paints'
on conflict (business_unit_id, name) do nothing;

-- Garde-fou : prévenir si le pilier Akora Paints (slug arca-paints)
-- n'a pas été trouvé.
do $$
begin
  if not exists (
    select 1 from public.business_units where slug = 'arca-paints'
  ) then
    raise notice 'Aucun pilier avec le slug ''arca-paints'' trouvé — les 7 catégories n''ont pas été insérées. Vérifier le slug exact du pilier Akora Paints.';
  end if;
end $$;

-- Vérification : catégories insérées
select bu.name as pilier, cat.name as categorie
from public.categories cat
join public.business_units bu on bu.id = cat.business_unit_id
where bu.slug = 'arca-paints'
order by cat.name;
