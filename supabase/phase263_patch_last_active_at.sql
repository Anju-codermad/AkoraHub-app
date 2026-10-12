-- ============================================================
-- AkoraHub - Patch Phase 263 : colonne `profiles.last_active_at` pour
-- mesurer les utilisateurs actifs directement dans l'app (demande
-- explicite de la propriétaire, 12/10) — alternative gratuite à
-- Firebase Analytics (dont les statistiques ne sont lisibles que
-- depuis la Firebase Console ou une API payante, pas depuis l'app).
--
-- Distincte de `profiles.last_seen_at` (phase250) : `last_seen_at` ne
-- sert qu'au statut "En ligne"/"Vu(e) à..." de la messagerie, mis à
-- jour seulement pendant qu'un écran de chat est ouvert.
-- `last_active_at` est mise à jour à CHAQUE ouverture de l'app (tous
-- écrans confondus), donc reflète l'usage réel de l'app, pas juste la
-- messagerie — voir lib/core/analytics/activity_tracker.dart.
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Idempotent (`add column if not exists`).
-- ============================================================

alter table public.profiles
  add column if not exists last_active_at timestamptz;

-- Vérification :
-- select
--   count(*) filter (where last_active_at > now() - interval '1 day') as actifs_24h,
--   count(*) filter (where last_active_at > now() - interval '7 days') as actifs_7j,
--   count(*) filter (where last_active_at > now() - interval '28 days') as actifs_28j,
--   count(*) as total_comptes
-- from public.profiles;
