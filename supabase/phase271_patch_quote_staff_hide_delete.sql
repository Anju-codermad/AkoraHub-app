-- ============================================================
-- AkoraHub - Patch Phase 271 : masquage (tout le staff) + suppression
-- définitive (Admin uniquement) des devis, côté gestion staff
--
-- Demande explicite (27/10) : même besoin que pour les commandes
-- (phase265) mais pour l'écran Devis (quotes_management.dart) — aucun
-- moyen de retirer un devis de la liste de gestion.
--
-- Même principe que phase265 : masquage réversible pour tout le staff
-- (indépendant du masquage côté client, hidden_by_customer, phase264)
-- + suppression définitive réservée à l'Admin.
--
-- Pas de nouvelle fonction security definer pour le masquage : la
-- policy `quotes_update_staff` (phase1) autorise déjà tout le staff à
-- modifier n'importe quelle colonne d'un devis, donc `hidden_by_staff`
-- est déjà librement modifiable par un simple .update() depuis l'app.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

alter table public.quotes
  add column if not exists hidden_by_staff boolean not null default false;

-- Suppression définitive : aucune policy DELETE n'existait jusqu'ici sur
-- `quotes` (RLS refuse par défaut) — réservée au rôle Admin. quote_items
-- a déjà "on delete cascade" (phase1), donc les lignes du devis sont
-- effacées automatiquement avec lui.
drop policy if exists "quotes_delete_admin" on public.quotes;
create policy "quotes_delete_admin" on public.quotes
  for delete using (public.current_role_is_admin());
