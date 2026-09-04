-- ============================================================
-- AkoraHub - Patch Phase 194 : retire "arca" du slug du pilier
-- "Akora Paints" — demande explicite de la propriétaire le 04/09/2026
-- ("Nous devons n'utilise pas le nom de marque Arca dans cette Akora
-- Paints. Effacer tout le nom Arca paints dans ce projet").
--
-- Le nom affiché du pilier est déjà "Akora Paints" (renommé le
-- 04/09/2026 depuis "Peinture"), mais son slug technique était resté
-- "arca-paints" — hérité du tout premier nom de ce pilier ("ARCA
-- PAINTS"), jamais mis à jour car un slug ne s'affiche nulle part à
-- l'écran. Ce script le fait disparaître aussi de la base.
--
-- Recherche par bu.name (stable en ce moment, déjà vérifié) plutôt que
-- par l'ancien slug, pour ne dépendre d'aucun ordre d'exécution avec
-- la Phase 193 (qui a été corrigée pour ne plus dépendre du slug non
-- plus — les deux scripts peuvent donc s'exécuter dans n'importe quel
-- ordre l'un par rapport à l'autre).
--
-- Aucun code Flutter/site ne fait de comparaison exacte sur ce slug
-- (`product_catalog_tab.dart` teste seulement `slug.contains('paint')`,
-- qui reste vrai avec le nouveau slug) — aucun changement de code
-- nécessaire après ce script.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (sans effet si déjà appliqué).
-- ============================================================

update public.business_units
set slug = 'akora-paints'
where name = 'Akora Paints'
  and slug = 'arca-paints';

-- Garde-fou : prévenir si le pilier n'a pas été trouvé (déjà renommé,
-- ou nom différent de "Akora Paints").
do $$
begin
  if not exists (
    select 1 from public.business_units where slug = 'akora-paints'
  ) then
    raise notice 'Le pilier "Akora Paints" avec le slug "akora-paints" est introuvable après exécution — vérifier le nom exact du pilier dans business_units.';
  end if;
end $$;

-- Vérification :
-- select name, slug from public.business_units where name = 'Akora Paints';
