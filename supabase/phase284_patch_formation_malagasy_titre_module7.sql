-- ============================================================
-- AkoraHub - Patch Phase 284 : correction du titre du module 7
-- (version malgache de la formation Liquide vaisselle)
--
-- Correction demandée par la propriétaire (locutrice native) le 28/10 :
-- "Aiza no mividianana ny akora" -> "Aiza no hividianana ireo akora"
-- (grammaire malgache correcte).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

update public.formation_course_modules
set title = 'Aiza no hividianana ireo akora'
where title = 'Aiza no mividianana ny akora'
  and course_id = (
    select id from public.formation_courses
    where title = 'Savony fanasan-dovia (Malagasy)'
  );
