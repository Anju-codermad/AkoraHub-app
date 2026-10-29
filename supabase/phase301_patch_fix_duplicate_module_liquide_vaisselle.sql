-- ============================================================
-- AkoraHub - Patch Phase 301 : suppression du module en double
-- ("Matières premières & Sourcing", sort_order = 1 en double) —
-- formation Liquide Vaisselle
--
-- Diagnostic (29/10) : la cliente a confirmé via CSV 9 lignes au
-- lieu de 8 pour cette formation, avec deux lignes identiques à
-- sort_order = 1 — cause probable de l'affichage "désorganisé"
-- signalé (Module 1 semblant mal placé).
--
-- Supprime la ligne la plus récente (ctid le plus grand) pour chaque
-- doublon de sort_order, ne garde qu'une seule ligne par position.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

delete from public.formation_course_modules a
using public.formation_course_modules b
where a.course_id = b.course_id
  and a.sort_order = b.sort_order
  and a.ctid > b.ctid
  and a.course_id = (
    select id from public.formation_courses
    where title ilike '%liquide vaisselle%'
  );

-- Vérification : doit renvoyer exactement 8 lignes, sort_order 0 à 7,
-- sans doublon.
select sort_order, title
from public.formation_course_modules
where course_id = (
  select id from public.formation_courses
  where title ilike '%liquide vaisselle%'
)
order by sort_order;
