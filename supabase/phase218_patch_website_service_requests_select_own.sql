-- ============================================================
-- AkoraHub - Patch Phase 218 : un client peut relire SA PROPRE demande
-- de service du site web, une fois qu'il l'a réclamée
--
-- Contexte (05/09) : après phase217 (paiement de l'acompte diagnostic
-- eau), le client réclame sa demande anonyme via
-- claim_water_diagnostic_request() (pose claimed_by = son compte), puis
-- le site essaie de relire estimated_total/deposit_amount/payment_status
-- pour lui proposer le paiement — mais la seule policy SELECT existante
-- sur website_service_requests (phase214) réserve la lecture au staff
-- (website_service_requests_select_staff). Un client, même propriétaire
-- de sa demande réclamée, n'avait donc aucun moyen de la relire :
-- erreur RLS silencieuse côté site ("Impossible de charger le montant
-- de l'acompte").
--
-- Ajoute une policy SELECT supplémentaire (les policies pour une même
-- commande sont combinées en OU) : un utilisateur connecté peut relire
-- une ligne si claimed_by = son propre id. Avant la réclamation
-- (claimed_by encore null), cette policy ne donne accès à rien —
-- cohérent avec le fait que le formulaire reste anonyme jusqu'à ce que
-- claim_water_diagnostic_request() ait été appelée avec succès.
-- ============================================================

drop policy if exists "website_service_requests_select_own_claimed" on public.website_service_requests;
create policy "website_service_requests_select_own_claimed" on public.website_service_requests
  for select using (auth.uid() = claimed_by);
