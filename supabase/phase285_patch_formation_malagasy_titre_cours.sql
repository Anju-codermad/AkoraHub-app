-- ============================================================
-- AkoraHub - Patch Phase 285 : correction du titre de la formation
-- malgache "Liquide vaisselle"
--
-- Correction demandée par la propriétaire (locutrice native) le 28/10 :
-- "Savony fanasan-dovia (Malagasy)" -> "Ranon-tsavony fanasana vilia"
-- (nom malgache correct pour "liquide vaisselle").
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

update public.formation_courses
set title = 'Ranon-tsavony fanasana vilia'
where title = 'Savony fanasan-dovia (Malagasy)';
