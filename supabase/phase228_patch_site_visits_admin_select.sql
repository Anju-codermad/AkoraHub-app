-- ============================================================
-- AkoraHub - Patch Phase 228 : lecture de site_visits réservée à l'admin
--
-- Contexte (08/09) : site_visits (phase226) n'avait aucune policy SELECT
-- (lecture prévue uniquement depuis le SQL Editor du dashboard, qui
-- contourne RLS). Demande explicite : afficher ce rapport directement
-- dans une page admin du site (site/admin-visites.html) — cette page se
-- connecte via le même compte Supabase Auth que le reste du site
-- (assets/auth.js), donc il faut une vraie policy SELECT plutôt que de
-- continuer à dépendre du dashboard.
--
-- Reprend la fonction current_role_is_admin() déjà utilisée ailleurs
-- (phase1_schema.sql) — un compte avec profiles.role = 'admin' (celui de
-- la gérante/du gérant, déjà utilisé pour l'app Flutter) peut se
-- connecter sur cette même page. Aucun autre rôle (commercial,
-- production, comptable, client) n'y a accès.
--
-- À exécuter une seule fois, APRÈS la phase226 : Supabase Dashboard ->
-- SQL Editor -> New query.
-- ============================================================

drop policy if exists "site_visits_select_admin" on public.site_visits;
create policy "site_visits_select_admin" on public.site_visits
  for select
  to authenticated
  using (public.current_role_is_admin());

-- Vérification : la policy existe bien.
select policyname, cmd, roles from pg_policies where tablename = 'site_visits';
