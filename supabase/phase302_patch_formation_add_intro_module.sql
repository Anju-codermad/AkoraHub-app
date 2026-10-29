-- ============================================================
-- AkoraHub - Patch Phase 302 : transformer le module en double en
-- un vrai module d'introduction — formation Liquide Vaisselle
--
-- Demande explicite (29/10) : garder 9 modules au lieu de 8 — le
-- premier résume ce que les participants vont apprendre dans les 8
-- modules suivants. Remplace phase301 (ne pas exécuter les deux) :
-- au lieu de supprimer le doublon "Matières premières & Sourcing"
-- (sort_order = 1 en double), on le réutilise comme nouveau module 1
-- "Ce que vous allez apprendre", et tous les autres modules décalent
-- d'un cran (0→1, 1→2, ..., 7→8).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

-- 1) Transformer UNE des deux lignes dupliquées en module d'intro,
--    avec un sort_order temporaire hors plage pour ne pas entrer en
--    conflit pendant le décalage ci-dessous.
with course as (
  select id from public.formation_courses where title ilike '%liquide vaisselle%'
),
dup as (
  select ctid from public.formation_course_modules
  where course_id = (select id from course) and sort_order = 1
  order by ctid desc
  limit 1
)
update public.formation_course_modules
set sort_order = 100,
    title = 'Ce que vous allez apprendre',
    title_mg = null,
    duree_minutes = 10,
    content_delta = null,
    content_text_mg = null,
    content_text = $$Cette formation vous guide pas à pas dans la fabrication professionnelle de liquide vaisselle, de la chimie de base jusqu'à la vente :

1. Chimie des tensioactifs — comprendre les ingrédients actifs (SLES, LABSA, CAPB) et calculer leur dosage
2. Matières premières & Sourcing — choisir et acheter vos ingrédients au meilleur prix
3. Formulation par gamme — fabriquer plusieurs qualités de produit (économique, standard, premium)
4. Processus de fabrication — organiser votre atelier et produire de façon fiable, lot après lot
5. Contrôle qualité ISO — vérifier que chaque lot respecte les normes
6. Norme Malagasy & BNM — respecter la réglementation officielle à Madagascar
7. Sécurité, FDS & Réglementation — manipuler vos matières premières en toute sécurité
8. Commercialisation & Business — calculer vos prix et vendre avec une vraie marge

À la fin de cette formation, vous saurez fabriquer, contrôler et vendre votre propre liquide vaisselle, du début à la fin.$$
where ctid = (select ctid from dup);

-- 2) Décaler tous les autres modules d'un cran (0→1, 1→2, ..., 7→8)
update public.formation_course_modules
set sort_order = sort_order + 1
where course_id = (
    select id from public.formation_courses
    where title ilike '%liquide vaisselle%'
  )
  and sort_order <> 100;

-- 3) Remettre le module d'intro en première position
update public.formation_course_modules
set sort_order = 0
where course_id = (
    select id from public.formation_courses
    where title ilike '%liquide vaisselle%'
  )
  and sort_order = 100;

-- 4) Mettre à jour le nombre de modules (9 au lieu de 8)
update public.formation_courses
set module_count = 9
where title ilike '%liquide vaisselle%';

-- Vérification : doit renvoyer 9 lignes, sort_order 0 à 8, "Ce que
-- vous allez apprendre" en premier.
select sort_order, title
from public.formation_course_modules
where course_id = (
  select id from public.formation_courses
  where title ilike '%liquide vaisselle%'
)
order by sort_order;
