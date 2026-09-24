-- ============================================================
-- AkoraHub - Patch Phase 249 : le staff ne pouvait pas démarrer une
-- conversation en premier avec un client
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (24/09/2026) : ajout d'un bouton "Envoyer un message" sur la
-- fiche client 360° (Customer360Screen), pour que le staff puisse
-- écrire à un client qui ne lui a jamais écrit en premier. Bloqué par
-- la policy INSERT d'origine (phase8) sur `conversations`, qui ne
-- permettait qu'au client lui-même de créer SA propre ligne
-- (`auth.uid() = customer_id`) — jamais prévue pour une initiative du
-- staff. Les policies SELECT/UPDATE de la même table autorisaient déjà
-- le staff, seule l'INSERT manquait.
-- ============================================================

drop policy if exists "conversations_insert_own" on public.conversations;
drop policy if exists "conversations_insert_own_or_staff" on public.conversations;
create policy "conversations_insert_own_or_staff" on public.conversations
  for insert with check (auth.uid() = customer_id or public.current_role_is_staff());
