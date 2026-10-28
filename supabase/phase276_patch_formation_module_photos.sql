-- ============================================================
-- AkoraHub - Patch Phase 276 : plusieurs photos par module de
-- formation Académie
--
-- Demande explicite (28/10) : "Ajoutez aussi des champ pour les
-- photos si je voulais" — en plus de la vidéo et du document, un
-- module peut désormais avoir plusieurs photos (ex. étapes illustrées
-- d'une recette). Réutilise le bucket `formation-videos`
-- (phase275, à exécuter avant celui-ci) — un bucket Storage n'est pas
-- limité à un seul type de fichier.
--
-- `photo_urls` : tableau JSON de liens (ex. ["url1","url2"]), plutôt
-- qu'une colonne par photo — nombre de photos variable par module.
-- À exécuter une seule fois, APRÈS phase275 : Supabase Dashboard ->
-- SQL Editor -> New query
-- ============================================================

alter table public.formation_course_modules
  add column if not exists photo_urls jsonb not null default '[]'::jsonb;
