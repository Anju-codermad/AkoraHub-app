-- ============================================================
-- AkoraHub - Patch Phase 266 : photo optionnelle sur les Flash infos
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Demande explicite (27/10) : pouvoir joindre une photo à un flash info,
-- en plus du texte (jusqu'ici texte seul par design, voir phase26 — "pas
-- d'upload d'image" pour rester rapide à publier, mais la demande montre
-- que c'est parfois utile). Simple colonne optionnelle : aucune policy à
-- changer, celles de phase26 couvrent déjà toutes les colonnes de la
-- table (select public si active, write réservée à l'Admin).
--
-- Le rendu des liens cliquables dans le texte du message est géré
-- uniquement côté app (voir lib/core/utils/linkify_text.dart) : pas
-- besoin de colonne supplémentaire pour ça.
-- ============================================================

alter table public.flash_infos
  add column if not exists image_url text;
