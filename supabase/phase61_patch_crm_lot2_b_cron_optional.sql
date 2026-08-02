-- ============================================================
-- AkoraHub - Patch Phase 61, Partie B (OPTIONNELLE) : planifie
-- l'exécution quotidienne de process_stale_quote_reminders() via
-- pg_cron. À exécuter APRÈS phase61_patch_crm_lot2_a.sql.
--
-- ⚠️ Cette partie peut échouer selon le plan Supabase (pg_cron pas
-- toujours disponible sur le plan gratuit — même avertissement que
-- Phase 13 pour les commandes récurrentes). Si le "Run" affiche une
-- erreur du type "extension pg_cron is not available" ou "permission
-- denied" : ce n'est pas grave, ignore cette partie pour l'instant —
-- il faudra alors relancer manuellement de temps en temps
-- `select process_stale_quote_reminders();` depuis le SQL Editor.
-- ============================================================

create extension if not exists pg_cron;

select cron.schedule(
  'process-stale-quote-reminders-daily',
  '0 6 * * *',  -- tous les jours à 06h00 UTC (≈ 09h00 à Madagascar)
  $$select public.process_stale_quote_reminders();$$
);
