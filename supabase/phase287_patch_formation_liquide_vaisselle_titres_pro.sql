-- ============================================================
-- AkoraHub - Patch Phase 287 : renommage des 8 modules de la
-- formation "Liquide Vaisselle" vers une structure plus professionnelle
--
-- Demande explicite (29/10, capture d'écran d'une maquette) : adopter
-- une structure en 8 modules couvrant la chimie, le sourcing, la
-- formulation, la fabrication, la qualité ISO, les normes malgaches
-- (BNM), la sécurité/réglementation et le business — au lieu des
-- titres simples précédents (Objectif, Matériel, Ingrédients...).
--
-- IMPORTANT : ce patch ne change QUE les titres (FR + MG remis à
-- vide pour les nouveaux titres, à retraduire plus tard). Le texte
-- de chaque module (content_text/content_text_mg) est volontairement
-- CONSERVÉ tel quel pour l'instant — la formation est déjà en vente
-- (status 'deja_developpee', prix 650 000 Ar), donc on ne vide pas le
-- contenu vu par les clients qui l'ont déjà achetée. Le vrai contenu
-- de chaque nouveau module sera écrit un par un dans une prochaine
-- étape (comme on l'a fait pour Liquide vaisselle au départ).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

with course as (
  select id from public.formation_courses
  where category = 'Entretien & Hygiène' and title = 'Liquide Vaisselle'
)
update public.formation_course_modules m
set title = new_titles.title,
    title_mg = null
from (values
  (0, 'Chimie des tensioactifs'),
  (1, 'Matières premières & Sourcing'),
  (2, 'Formulation par gamme'),
  (3, 'Processus de fabrication'),
  (4, 'Contrôle qualité ISO'),
  (5, 'Norme Malagasy & BNM'),
  (6, 'Sécurité, FDS & Réglementation'),
  (7, 'Commercialisation & Business')
) as new_titles(sort_order, title)
where m.course_id = (select id from course)
  and m.sort_order = new_titles.sort_order;
