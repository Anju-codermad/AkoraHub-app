-- ============================================================
-- AkoraHub - Patch Phase 203 : nouveau pilier "Akora NutriLab" —
-- décision explicite de la propriétaire le 04/09/2026.
--
-- Contexte : Akora NutriLab regroupe les matières premières
-- (produits chimiques / ingrédients alimentaires) destinées aux
-- professionnels de l'agroalimentaire — un pilier technique/B2B,
-- distinct d'Akora Pro (matières premières généralistes) et d'un
-- futur pilier "Akora Food" prévu pour le produit fini agroalimentaire
-- grand public (même logique que Akora Paints/Akora Coatings :
-- un nom technique pour l'amont, un nom grand public pour l'aval —
-- le pilier "Akora Food" sera créé séparément le moment venu).
--
-- Effet : crée le pilier (business_units), actif. Pas de catégories
-- ni de produits pour l'instant — la propriétaire les ajoutera via
-- l'Admin ou une phase ultérieure une fois le premier catalogue prêt.
--
-- Le site web (groupe-akora-site) et l'app lisent toutes deux les
-- piliers en direct depuis cette table — aucun changement de code
-- nécessaire de part et d'autre, le nouveau pilier apparaîtra
-- automatiquement (mais restera vide/"Bientôt disponible" tant
-- qu'aucune catégorie/produit n'y est rattaché).
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (on conflict do nothing).
-- ============================================================

insert into public.business_units (name, slug, active)
values ('Akora NutriLab', 'akora-nutrilab', true)
on conflict (slug) do nothing;

-- Vérification
select id, name, slug, active
from public.business_units
where slug = 'akora-nutrilab';
