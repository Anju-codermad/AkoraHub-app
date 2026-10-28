-- ============================================================
-- AkoraHub - Patch Phase 278 : vérification d'identité par selfie
-- avant le premier visionnage d'une formation achetée
--
-- Demande explicite (28/10) : confirmer que c'est bien l'acheteur qui
-- consulte le contenu payant. Vérification PONCTUELLE par selfie (pas
-- de caméra en continu, pas de scan des tiers — voir discussion du
-- même jour sur les limites légales/techniques d'une surveillance
-- continue). Une fois vérifié, couvre TOUTES les formations du client
-- (au niveau du profil, pas par cours) — voir
-- course_content_screen.dart, nouvel écran de vérification avant
-- l'accès aux modules.
--
-- Bucket privé (comme `payment-proofs`, phase29) : seul le client
-- propriétaire et le staff peuvent lire ces selfies — jamais publics.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

alter table public.profiles
  add column if not exists selfie_verified_at timestamptz,
  add column if not exists selfie_url text;

insert into storage.buckets (id, name, public)
values ('identity-verification', 'identity-verification', false)
on conflict (id) do nothing;

drop policy if exists "identity_verification_owner_upload" on storage.objects;
create policy "identity_verification_owner_upload" on storage.objects
  for insert with check (
    bucket_id = 'identity-verification'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "identity_verification_owner_or_staff_read" on storage.objects;
create policy "identity_verification_owner_or_staff_read" on storage.objects
  for select using (
    bucket_id = 'identity-verification'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.current_role_is_staff()
    )
  );
