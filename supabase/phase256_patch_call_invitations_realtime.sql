-- ============================================================
-- AkoraHub - Patch Phase 256 : active Realtime sur `call_invitations`
-- — demande explicite de la propriétaire (05/10) : "les appels audio,
-- vidéo... ça ne marche pas" (bloqué sur "Appel en cours..." sans fin).
--
-- Bug trouvé (indépendant des notifications push, voir phase255) :
-- quand la personne appelée refuse l'appel (`IncomingCallScreen._decline`,
-- `CallRepo.updateStatus(..., 'declined')`), elle ne rejoint JAMAIS le
-- canal Agora — donc côté appelant, aucun événement Agora ne se
-- déclenche (`onUserOffline` ne peut pas se déclencher : personne n'a
-- jamais rejoint pour en partir). Résultat : l'appelant reste bloqué
-- sur "Appel en cours..." indéfiniment, même quand tout le reste
-- fonctionne parfaitement.
--
-- phase37 avait explicitement choisi de ne PAS activer Realtime sur
-- cette table ("la notification push suffit à détecter un appel
-- entrant") — exact pour détecter l'appel, mais insuffisant pour que
-- l'APPELANT détecte un refus. Ce script corrige ce choix initial.
--
-- Voir aussi `lib/presentation/calls/call_screen.dart` (écoute
-- désormais `call_invitations.status` en direct + timeout de secours
-- de 45s si personne ne répond du tout).
--
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- Script idempotent (vérifie avant d'ajouter à la publication).
-- ============================================================

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'call_invitations'
  ) then
    alter publication supabase_realtime add table public.call_invitations;
  end if;
end $$;
