-- ============================================================
-- AkoraHub - Patch Phase 170 : sélection aléatoire de produits pour
-- l'accueil client ("Découvrez aussi")
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (13/08, demande explicite) : une fonction plutôt qu'une
-- requête `order by random()` directe depuis l'app — PostgREST n'accepte
-- pas d'expression arbitraire dans `.order()`, seulement des noms de
-- colonnes. `security invoker` (par défaut) : respecte les policies RLS
-- de l'appelant, donc ne renvoie que des produits déjà publics
-- (`products_select_all` : visibility = true), rien de plus que ce que le
-- catalogue affiche déjà.
-- ============================================================

create or replace function public.random_published_products(limit_count int default 10)
returns setof public.products as $$
  select * from public.products
  where visibility = true
  order by random()
  limit limit_count;
$$ language sql stable;

grant execute on function public.random_published_products(int) to authenticated, anon;
