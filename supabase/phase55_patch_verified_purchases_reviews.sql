-- ============================================================
-- AkoraHub - Patch Phase 55 : Communauté — avis vérifiés (achat réel),
-- galerie "Réalisations clients" (Lot 5).
--
-- Aucune nouvelle table : la galerie réutilise `posts`/`post_images`
-- déjà en place (publication avec image + produit taggé), les avis
-- vérifiés réutilisent `product_reviews`/`orders`/`order_items` déjà en
-- place. Uniquement 3 fonctions SECURITY DEFINER (même principe que
-- `has_purchased_raw_material`, Phase 45 : ne révèlent qu'un booléen ou
-- un id, jamais le détail d'une commande).
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- ⚠️ Script idempotent : relancer en entier depuis le début est sans
-- risque.
-- ============================================================

-- Un client a-t-il réellement commandé (commande non annulée) un
-- produit donné.
create or replace function public.has_ordered_product(uid uuid, pid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.order_items oi
    join public.orders o on o.id = oi.order_id
    where o.customer_id = uid
      and oi.product_id = pid
      and o.status <> 'annulee'
  );
$$;

-- Parmi les auteurs d'avis (product_reviews) sur un produit donné, ceux
-- qui l'ont réellement commandé — un appel par page produit plutôt qu'un
-- appel par avis.
create or replace function public.verified_reviewers(pid uuid)
returns table(author_id uuid)
language sql
stable
security definer
set search_path = public
as $$
  select distinct pr.author_id
  from public.product_reviews pr
  where pr.product_id = pid
    and public.has_ordered_product(pr.author_id, pid);
$$;

-- Parmi une liste de publications, celles dont l'auteur a réellement
-- commandé le produit taggé — un appel par page du fil plutôt qu'un
-- appel par publication.
create or replace function public.verified_purchase_post_ids(post_ids uuid[])
returns table(post_id uuid)
language sql
stable
security definer
set search_path = public
as $$
  select p.id
  from public.posts p
  where p.id = any(post_ids)
    and p.mentioned_product_id is not null
    and public.has_ordered_product(p.author_id, p.mentioned_product_id);
$$;
