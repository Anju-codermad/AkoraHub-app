-- ============================================================
-- AkoraHub - Patch Phase 29 : Référence et preuve de paiement
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Pour les modes de paiement manuels (virement bancaire, Mobile Money —
-- voir phase27), le staff doit aujourd'hui deviner manuellement quelle
-- commande correspond à quel virement/transfert reçu. Ajoute un champ de
-- référence libre (numéro de transaction) et une capture d'écran
-- optionnelle, uploadée par le client lui-même. Bucket privé (contrairement
-- à `avatars`) : ce sont des documents financiers, seuls le client
-- propriétaire et le staff peuvent les lire.
-- ============================================================

alter table public.orders
  add column if not exists payment_reference text,
  add column if not exists payment_proof_path text;

insert into storage.buckets (id, name, public)
values ('payment-proofs', 'payment-proofs', false)
on conflict (id) do nothing;

drop policy if exists "payment_proofs_owner_upload" on storage.objects;
create policy "payment_proofs_owner_upload" on storage.objects
  for insert with check (
    bucket_id = 'payment-proofs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "payment_proofs_owner_or_staff_read" on storage.objects;
create policy "payment_proofs_owner_or_staff_read" on storage.objects
  for select using (
    bucket_id = 'payment-proofs'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.current_role_is_staff()
    )
  );
