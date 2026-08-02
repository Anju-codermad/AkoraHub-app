-- ============================================================
-- AkoraHub - Patch Phase 54 : Communauté — fil "Tendances" (Lot 4).
-- Le filtre par pilier (business_units) réutilise products/business_units
-- déjà en place, aucun changement de schéma nécessaire pour ça.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- ⚠️ Script idempotent : relancer en entier depuis le début est sans
-- risque.
-- ============================================================

-- ------------------------------------------------------------
-- Score d'engagement par publication (réactions + commentaires). Sert
-- UNIQUEMENT à classer les publications les plus actives — le contenu
-- réel des publications repasse toujours par `posts` (RLS complète,
-- Phase 3/51 : visibilité, blocages, masquage) côté app avant affichage,
-- cette vue n'expose donc aucune fuite de contenu, juste un id + un
-- score pour ordonner.
-- ------------------------------------------------------------
create or replace view public.post_engagement_scores as
select
  p.id as post_id,
  p.created_at,
  coalesce(l.like_count, 0) + coalesce(c.comment_count, 0) as score
from public.posts p
left join (
  select post_id, count(*) as like_count
  from public.post_likes
  group by post_id
) l on l.post_id = p.id
left join (
  select post_id, count(*) as comment_count
  from public.post_comments
  group by post_id
) c on c.post_id = p.id;

grant select on public.post_engagement_scores to authenticated;
