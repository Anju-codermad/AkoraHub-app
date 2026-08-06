-- ============================================================
-- AkoraHub - Patch Phase 75 : algorithmes de personnalisation
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : sur demande explicite ("appliquez les algorithmes
-- correspondants", 06/08, suite à une question sur l'algorithme
-- Facebook), 3 fonctions dans le même esprit que post_engagement_scores
-- (phase54) — classer par un score plutôt que par un seul critère brut.
--
-- 1. personalized_feed_post_ids : fil "Pour toi" de la Communauté.
--    Combine engagement (réactions + commentaires) + affinité (le client
--    a-t-il déjà commandé dans le pilier du produit taggé par le post ?)
--    + décroissance par ancienneté (formule inspirée du classement
--    Hacker News/Reddit : score / (1 + âge_en_jours)^1.2, pour que les
--    posts récents restent visibles même sans encore beaucoup
--    d'engagement, plutôt qu'un pur tri par engagement total qui
--    favoriserait toujours les plus anciens).
-- 2. products_bought_together : "Vous pourriez aussi aimer" sur la fiche
--    produit — produits achetés dans la même commande que celui-ci,
--    par n'importe quel client (panier-jumelage classique du e-commerce).
-- 3. client_top_categories : catégories que CE client achète le plus
--    souvent, pour réordonner les puces de catégorie du Catalogue (celles
--    qu'il utilise vraiment en premier, au lieu de l'ordre alphabétique).
-- ============================================================

create or replace function public.personalized_feed_post_ids(
  uid uuid,
  days_back int default 30,
  max_results int default 30
)
returns table(post_id uuid)
language sql
stable
security definer
set search_path = public
as $$
  with my_units as (
    select p.business_unit_id
    from public.orders o
    join public.order_items oi on oi.order_id = o.id
    join public.products p on p.id = oi.product_id
    where o.customer_id = uid
      and o.status <> 'annulee'
    group by p.business_unit_id
  ),
  scored as (
    select
      po.id as post_id,
      coalesce(pes.score, 0) as engagement_score,
      case
        when prod.business_unit_id is not null
             and exists (
               select 1 from my_units mu
               where mu.business_unit_id = prod.business_unit_id
             )
        then 5
        else 0
      end as affinity_bonus,
      extract(epoch from (now() - po.created_at)) / 86400.0 as days_old
    from public.posts po
    left join public.post_engagement_scores pes on pes.post_id = po.id
    left join public.products prod on prod.id = po.mentioned_product_id
    where po.created_at >= now() - (days_back || ' days')::interval
  )
  select post_id
  from scored
  order by
    (engagement_score + affinity_bonus) / power(1 + days_old, 1.2) desc,
    days_old asc
  limit max_results;
$$;

grant execute on function public.personalized_feed_post_ids(uuid, int, int)
  to authenticated;

create or replace function public.products_bought_together(
  pid uuid,
  max_results int default 6
)
returns table(product_id uuid, times_bought_together bigint)
language sql
stable
security definer
set search_path = public
as $$
  select oi2.product_id, count(distinct oi1.order_id) as times_bought_together
  from public.order_items oi1
  join public.order_items oi2
    on oi2.order_id = oi1.order_id
   and oi2.product_id <> oi1.product_id
  where oi1.product_id = pid
  group by oi2.product_id
  order by times_bought_together desc
  limit max_results;
$$;

grant execute on function public.products_bought_together(uuid, int)
  to authenticated;

create or replace function public.client_top_categories(uid uuid)
returns table(category text, times_ordered bigint)
language sql
stable
security definer
set search_path = public
as $$
  select p.category, count(*) as times_ordered
  from public.orders o
  join public.order_items oi on oi.order_id = o.id
  join public.products p on p.id = oi.product_id
  where o.customer_id = uid
    and o.status <> 'annulee'
    and p.category is not null
    and p.category <> ''
  group by p.category
  order by times_ordered desc;
$$;

grant execute on function public.client_top_categories(uuid) to authenticated;
