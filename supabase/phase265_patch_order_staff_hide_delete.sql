-- ============================================================
-- AkoraHub - Patch Phase 265 : masquage (tout le staff) + suppression
-- définitive (Admin uniquement) des commandes, côté gestion staff
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Demande explicite (26/10) : "Toutes commandes Test" encombraient
-- l'écran Commandes (order_management_real.dart). Choix retenu et
-- confirmé par l'utilisatrice : masquage réversible pour tout le staff
-- (comme pour les commandes/devis côté client, phase69/phase264) ET
-- suppression définitive réservée au rôle Admin, pour les vrais cas de
-- test/doublon.
--
-- Pas de nouvelle fonction security definer pour le masquage : la
-- policy `orders_update_staff` (phase1) autorise déjà tout le staff à
-- modifier n'importe quelle colonne d'une commande (contrairement au
-- cas client, phase69/phase264), donc `hidden_by_staff` est déjà
-- librement modifiable par un simple .update() depuis l'app.
-- ============================================================

alter table public.orders
  add column if not exists hidden_by_staff boolean not null default false;

-- Suppression définitive : aucune policy DELETE n'existait jusqu'ici sur
-- `orders` (RLS refuse par défaut) — réservée au rôle Admin.
drop policy if exists "orders_delete_admin" on public.orders;
create policy "orders_delete_admin" on public.orders
  for delete using (public.current_role_is_admin());
