-- ============================================================
-- Akora Fanadiovana / AkoraHub - Schéma Phase 13, Partie B (OPTIONNELLE)
-- Planifie l'exécution automatique quotidienne de process_recurring_orders()
-- via l'extension pg_cron. À exécuter APRÈS phase13_schema_a.sql.
--
-- ⚠️ Cette partie peut échouer selon le plan Supabase (pg_cron n'est pas
-- toujours disponible sur le plan gratuit). Si le "Run" affiche une erreur
-- du type "extension pg_cron is not available" ou "permission denied" :
-- ce n'est pas grave, ignore simplement cette partie pour l'instant — les
-- commandes récurrentes fonctionneront quand même, mais il faudra alors
-- qu'un Admin déclenche le traitement manuellement de temps en temps
-- (bouton prévu dans l'écran Admin, ou en relançant ce SQL :
-- `select process_recurring_orders();`) plutôt qu'automatiquement chaque
-- jour.
-- ============================================================

create extension if not exists pg_cron;

select cron.schedule(
  'process-recurring-orders-daily',
  '0 6 * * *',  -- tous les jours à 06h00 UTC (≈ 09h00 à Madagascar)
  $$select public.process_recurring_orders();$$
);
