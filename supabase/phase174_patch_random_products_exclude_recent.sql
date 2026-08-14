-- ============================================================
-- AkoraHub - Patch Phase 174 : éviter les doublons entre "Pour vous"
-- (produits récents) et "Découvrez aussi" (aléatoire) sur l'accueil
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (14/08, constaté en conditions réelles) : avec un catalogue
-- encore restreint, un produit tout juste publié apparaît à la fois dans
-- "Pour vous" (les plus récents) ET dans "Découvrez aussi" (tirage
-- aléatoire) — le même produit visible deux fois sur l'accueil. Ajout
-- d'un paramètre optionnel exclude_ids pour retirer explicitement les
-- produits déjà montrés dans "Pour vous" du tirage aléatoire.
-- ============================================================

drop function if exists public.random_published_products(int, text[]);

create or replace function public.random_published_products(
  limit_count int default 10,
  preferred_categories text[] default null,
  exclude_ids uuid[] default null
)
returns setof public.products as $$
  select * from public.products
  where visibility = true
    and (exclude_ids is null or id != all(exclude_ids))
  order by
    case
      when preferred_categories is not null
        and category = any(preferred_categories)
      then 0
      else 1
    end,
    random()
  limit limit_count;
$$ language sql stable;

grant execute on function public.random_published_products(int, text[], uuid[]) to authenticated, anon;
