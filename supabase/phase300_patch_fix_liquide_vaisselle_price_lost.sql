-- ============================================================
-- AkoraHub - Patch Phase 300 : correction du prix perdu de la
-- formation "Liquide Vaisselle"
--
-- Diagnostic (29/10) : la cliente a confirmé via une capture CSV que
-- price = null pour "Liquide Vaisselle" malgré l'exécution de
-- phase282 (qui devait le fixer à 650 000 Ar). Cause probable : le
-- `where category = '...' and title = '...'` de phase282 a dû
-- correspondre à 0 ligne (ex. un caractère accentué encodé
-- différemment entre le script et la ligne existante) — un simple
-- `update` affiche "Success" même s'il ne modifie aucune ligne, donc
-- ça n'a pas pu être détecté à l'exécution.
--
-- Ce correctif ne filtre plus que sur le titre (avec `ilike`, moins
-- sensible aux différences d'encodage), sans dépendre de la
-- catégorie — sûr maintenant qu'il n'existe plus qu'une seule
-- formation "Liquide Vaisselle" dans le catalogue (le doublon a été
-- supprimé en phase282).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

update public.formation_courses
set price = 650000,
    status = 'deja_developpee'
where title ilike '%liquide vaisselle%';

-- Vérification : doit renvoyer exactement 1 ligne, avec price = 650000
-- et status = deja_developpee.
select id, category, title, price, status, module_count
from public.formation_courses
where title ilike '%liquide vaisselle%';
