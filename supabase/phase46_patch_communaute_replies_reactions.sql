-- ============================================================
-- AkoraHub - Patch Phase 46 : réponses aux commentaires, réactions emoji
-- et notifications push pour la Communauté (ex-Mur)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (01/08) : trois demandes de l'utilisatrice —
-- 1. Répondre à un commentaire (fils de discussion) :
--    `post_comments.parent_comment_id`.
-- 2. Notifications push quand quelqu'un commente/réagit à une
--    publication (réutilise l'infrastructure FCM déjà en place —
--    Phase 17/24 — jusqu'ici jamais branchée sur la Communauté).
-- 3. Réactions emoji variées (👍 ❤️ 😂 😮 😢 😡, comme Facebook) au lieu
--    d'un simple cœur — sur les publications uniquement pour l'instant
--    (pas encore sur les commentaires ni la messagerie privée —
--    périmètre délibérément limité pour cette première version, voir
--    PROJECT_CONTEXT.md).
--
-- ⚠️ Nécessite que l'Edge Function `send-push-notification` soit
-- redéployée avec la gestion des tables `post_comments`/`post_likes`
-- (voir supabase/functions/send-push-notification/index.ts) — sans ça,
-- les triggers ci-dessous appellent la fonction mais elle ignorera ces
-- deux tables silencieusement (aucune erreur, juste aucune notification
-- envoyée).
-- ============================================================

-- ------------------------------------------------------------
-- 1) Fils de discussion sur les commentaires.
-- ------------------------------------------------------------
alter table public.post_comments
  add column if not exists parent_comment_id uuid
    references public.post_comments(id) on delete cascade;

create index if not exists post_comments_parent_idx
  on public.post_comments (parent_comment_id);

-- ------------------------------------------------------------
-- 2) Réactions emoji sur les publications (remplace le simple like) —
-- changer de réaction se fait par suppression + réinsertion côté
-- application (voir wall_tab.dart), les policies insert/delete
-- existantes (Phase 3) suffisent donc telles quelles, aucune nouvelle
-- policy nécessaire.
-- ------------------------------------------------------------
alter table public.post_likes
  add column if not exists reaction_type text not null default 'like'
    check (reaction_type in ('like','love','haha','wow','sad','angry'));

-- ------------------------------------------------------------
-- 3) Notifications push : nouveau commentaire (+ réponse) et nouvelle
-- réaction sur une publication — réutilise la fonction générique déjà
-- en place (Phase 17 : `notify_push_on_new_message`, déjà réutilisée
-- pour les commandes/devis/produits/appels malgré son nom), aucune
-- nouvelle fonction de trigger nécessaire.
-- ------------------------------------------------------------
drop trigger if exists on_new_post_comment_push on public.post_comments;
create trigger on_new_post_comment_push
  after insert on public.post_comments
  for each row execute procedure public.notify_push_on_new_message();

drop trigger if exists on_new_post_reaction_push on public.post_likes;
create trigger on_new_post_reaction_push
  after insert on public.post_likes
  for each row execute procedure public.notify_push_on_new_message();
