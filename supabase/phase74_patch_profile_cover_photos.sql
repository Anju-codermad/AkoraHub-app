-- ============================================================
-- AkoraHub - Patch Phase 74 : plusieurs photos de couverture (profil client)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : la photo de couverture du profil client (`cover_url`,
-- singulier) était unique. Sur demande, jusqu'à 5 photos (optionnel),
-- affichées en fondu automatique côté app toutes les 5 secondes (même
-- esprit que la bannière promo de l'accueil, phase du 05/08). Ajout
-- réservé côté app aux clients ayant déjà passé au moins une commande
-- (vérifié via `orders.customer_id`, pas besoin de colonne dédiée ici).
--
-- `cover_url` n'est lu par aucun autre écran de l'app (vérifié) : la
-- colonne reste en base pour ne rien casser, mais n'est plus écrite —
-- reprise ci-dessous comme première (et seule) photo de `cover_urls`
-- pour les profils qui avaient déjà une couverture.
-- ============================================================

alter table public.profiles
  add column if not exists cover_urls text[] not null default '{}';

update public.profiles
set cover_urls = array[cover_url]
where cover_url is not null
  and cover_url <> ''
  and cover_urls = '{}';
