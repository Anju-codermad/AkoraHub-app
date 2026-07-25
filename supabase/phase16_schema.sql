-- ============================================================
-- Akora Fanadiovana / AkoraHub - Schéma Phase 16
-- Notifications push réelles : stocke le token FCM (Firebase Cloud
-- Messaging) de l'appareil de chaque utilisateur, pour pouvoir lui
-- envoyer une notification plus tard (nouveau message, réponse de devis,
-- statut de commande changé...).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

alter table public.profiles
  add column if not exists fcm_token text;

-- Note : la RLS existante sur `profiles` (profiles_select_own_or_staff,
-- Phase 1) couvre déjà la lecture/écriture de cette nouvelle colonne —
-- chaque utilisateur peut mettre à jour son propre token, le staff peut
-- tout lire (nécessaire pour l'envoi côté serveur plus tard).
