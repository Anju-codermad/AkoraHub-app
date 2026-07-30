-- ============================================================
-- AkoraHub - Patch Phase 24 : préférence de son de notification par catégorie
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Chaque utilisateur (client ou staff) peut choisir un son différent
-- pour chacune des 3 catégories de notification distinguées par
-- l'Edge Function send-push-notification : messagerie, devis, commandes.
-- Valeurs par défaut = les sons "classiques" déjà utilisés jusqu'ici.
-- ============================================================

alter table public.profiles
  add column if not exists notification_sound_message text
    not null default 'notif_message_classique',
  add column if not exists notification_sound_devis text
    not null default 'notif_devis_classique',
  add column if not exists notification_sound_commande text
    not null default 'notif_commande_classique';
