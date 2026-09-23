-- ============================================================
-- AkoraHub - Patch Phase 248 : la suppression de compte échouait pour
-- tout client ayant déjà passé une commande
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (23/09/2026) : découvert en vérifiant le formulaire "Sécurité
-- des données" de Google Play (URL de suppression de compte). La
-- fonction `delete-account` (phase30/07) supprime `profiles`, ce qui est
-- censé tout nettoyer via les `on delete cascade` des tables liées
-- (orders, quotes, favorites, conversations, wall posts...). Sauf que
-- `public.orders.customer_id` référence `profiles(id)` SANS clause
-- `on delete`, donc en `no action` par défaut : toute suppression de
-- profil ayant au moins une commande liée échouait avec une violation de
-- contrainte de clé étrangère, au lieu de réussir.
--
-- Correctif : `on delete set null` (pas cascade) sur `orders.customer_id`
-- — la commande elle-même est conservée (nécessaire pour l'historique de
-- facturation/comptable, comme l'indique déjà notre politique de
-- confidentialité), seul le lien vers le compte supprimé est retiré.
-- ============================================================

alter table public.orders
  drop constraint if exists orders_customer_id_fkey;

alter table public.orders
  add constraint orders_customer_id_fkey
    foreign key (customer_id) references public.profiles(id) on delete set null;
