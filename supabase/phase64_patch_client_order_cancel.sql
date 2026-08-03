-- ============================================================
-- AkoraHub - Patch Phase 64 : Commandes client Lot 3/5 — annulation
-- d'une commande encore "reçue" par le client lui-même.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Jusqu'ici, la seule policy UPDATE sur `orders` était
-- `orders_update_staff` (staff uniquement) — un client ne pouvait donc
-- jamais annuler sa propre commande sans passer par le support. Cette
-- policy est étroite à dessein : uniquement tant que le statut est
-- encore "recue" (pas encore en préparation), et seulement pour la
-- faire passer à "annulee" — impossible pour le client de se donner
-- un autre statut (livree, etc.) via cette policy.
-- ============================================================

drop policy if exists "orders_update_own_cancel_if_recue" on public.orders;
create policy "orders_update_own_cancel_if_recue" on public.orders
  for update
  using (auth.uid() = customer_id and status = 'recue')
  with check (auth.uid() = customer_id and status = 'annulee');
