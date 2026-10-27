-- ============================================================
-- AkoraHub - Patch Phase 267 : commandes WhatsApp/directes saisies
-- manuellement par le staff pour un client qui a déjà un compte
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Demande explicite (27/10) : plusieurs clients commandent par
-- WhatsApp ou directement (pas via l'app) — l'utilisatrice veut
-- pouvoir quand même enregistrer la commande pour que le client,
-- s'il a un compte AkoraHub, puisse la suivre dans l'app comme une
-- commande normale (onglet Commandes, statuts Reçue/En préparation/
-- Expédiée/Livrée).
--
-- Aucune policy RLS à ajouter : `orders_insert_own`/`order_items_
-- insert_own` (phase1) autorisent déjà le staff à créer une commande
-- pour N'IMPORTE QUEL customer_id (pas seulement le sien), et le
-- trigger anti-falsification de prix (phase154) laisse le staff libre
-- de fixer un prix différent (négocié par WhatsApp) sans y toucher.
--
-- Deux colonnes seulement, pour garder une trace de ces commandes :
-- - created_by_staff : qui l'a saisie (traçabilité).
-- - manual_note : note libre côté staff (ex. "Commande WhatsApp du
--   27/10, négocié avec le client"), jamais visible par le client.
-- ============================================================

alter table public.orders
  add column if not exists created_by_staff uuid references public.profiles(id),
  add column if not exists manual_note text;
