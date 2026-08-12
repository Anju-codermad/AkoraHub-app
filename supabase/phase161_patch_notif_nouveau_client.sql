-- ============================================================
-- AkoraHub - Patch Phase 161 : notifier le staff dès qu'un nouveau
-- client s'inscrit sur l'apk
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (12/08, testé en conditions réelles par l'Admin avec un
-- nouveau compte de test) : la liste "Activité récente" du tableau de
-- bord affiche déjà les nouvelles inscriptions, mais seulement quand on
-- ouvre/rafraîchit l'écran — rien ne prévenait l'Admin en temps réel
-- (notification push) qu'un nouvel utilisateur venait de rejoindre
-- l'apk, contrairement aux commandes, devis, demandes de service, etc.
-- Réutilise le mécanisme générique déjà en place (Phase 17) : le
-- trigger appelle la même Edge Function send-push-notification, à
-- laquelle un nouveau cas "profiles" est ajouté pour notifier
-- Admin/Commercial.
-- ============================================================

drop trigger if exists on_new_client_signup_push on public.profiles;
create trigger on_new_client_signup_push
  after insert on public.profiles
  for each row
  when (new.role = 'client')
  execute procedure public.notify_push_on_new_message();
