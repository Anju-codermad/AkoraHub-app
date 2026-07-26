-- ============================================================
-- AkoraHub - Patch Phase 20 : bio + photo de couverture du profil client
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : redesign de l'écran Profil client (style centré façon
-- Facebook mobile). Deux nouveaux champs texte simples, pas de nouvelle
-- table. La photo de couverture réutilise le bucket Storage `avatars`
-- déjà existant (même dossier par utilisateur, juste un nom de fichier
-- différent : `${userId}/cover_*.jpg` au lieu de `${userId}/*.jpg`) —
-- la policy actuelle (dossier = auth.uid()) couvre déjà ce cas, aucun
-- changement de policy Storage nécessaire.
-- ============================================================

alter table public.profiles
  add column if not exists bio text,
  add column if not exists cover_url text;
