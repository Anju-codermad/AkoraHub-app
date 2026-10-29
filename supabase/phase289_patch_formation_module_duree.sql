-- ============================================================
-- AkoraHub - Patch Phase 289 : durée affichée par module de formation
--
-- Demande explicite (29/10) : afficher une durée estimée par module
-- (comme sur la maquette : "2h00", "3h00"...) — nouveau champ
-- `duree_minutes` (entier, en minutes, pour rester facilement
-- modifiable/triable) sur formation_course_modules.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

alter table public.formation_course_modules
  add column if not exists duree_minutes integer;

-- Durées reprises de la maquette fournie, pour les 8 modules de
-- "Liquide Vaisselle" (Entretien & Hygiène).
update public.formation_course_modules m
set duree_minutes = new_durees.minutes
from (values
  (0, 120),  -- Chimie des tensioactifs — 2h00
  (1, 120),  -- Matières premières & Sourcing — 2h00
  (2, 180),  -- Formulation par gamme — 3h00
  (3, 150),  -- Processus de fabrication — 2h30
  (4, 120),  -- Contrôle qualité ISO — 2h00
  (5, 120),  -- Norme Malagasy & BNM — 2h00
  (6, 120),  -- Sécurité, FDS & Réglementation — 2h00
  (7, 150)   -- Commercialisation & Business — 2h30
) as new_durees(sort_order, minutes)
where m.course_id = (
    select id from public.formation_courses
    where category = 'Entretien & Hygiène' and title = 'Liquide Vaisselle'
  )
  and m.sort_order = new_durees.sort_order;
