-- ============================================================
-- AkoraHub - Patch Phase 279 : un seul appareil actif à la fois pour
-- consulter les formations achetées
--
-- Demande explicite (28/10) : dissuader le partage de compte — si un
-- client ouvre ses formations sur un nouvel appareil, l'ancien est
-- automatiquement "éjecté" (le champ est écrasé). Pas une session
-- globale pour toute l'app, seulement pour l'accès aux formations
-- (voir course_content_screen.dart).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

alter table public.profiles
  add column if not exists formation_device_id text;
