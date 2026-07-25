-- ============================================================
-- Akora Fanadiovana / AkoraHub - Schéma Phase 13
-- Traçabilité QR code : un client doit pouvoir lire les infos d'un lot
-- (date de fabrication, DLC) en scannant le QR code, alors que jusqu'ici
-- la table production_batches était réservée strictement au staff.
-- On ouvre la LECTURE seule à tout utilisateur connecté ; la modification
-- reste réservée au staff.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

drop policy if exists "batches_staff_only" on public.production_batches;

create policy "batches_select_all" on public.production_batches
  for select using (true);

create policy "batches_write_staff" on public.production_batches
  for insert with check (public.current_role_is_staff());
create policy "batches_update_staff" on public.production_batches
  for update using (public.current_role_is_staff())
  with check (public.current_role_is_staff());
create policy "batches_delete_staff" on public.production_batches
  for delete using (public.current_role_is_staff());
