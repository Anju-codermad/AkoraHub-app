-- ============================================================
-- AkoraHub - Patch Phase 171 : pondération par secteur pour "Découvrez
-- aussi" (accueil client)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (13/08, demande explicite) : random_published_products
-- (phase170) tirait un pur aléatoire, sans tenir compte du secteur
-- d'activité du client. Ce script ajoute un paramètre optionnel
-- `preferred_categories` — les produits de ces catégories passent en
-- premier (toujours en ordre aléatoire ENTRE EUX, donc pas figé), le
-- reste du catalogue complète ensuite si besoin d'atteindre limit_count.
-- Une PRIORITÉ, pas un FILTRE strict : un client dont le secteur n'a que
-- peu de produits dédiés voit quand même une sélection complète, avec le
-- reste du catalogue en découverte.
--
-- La correspondance secteur -> catégories (kSectorPreferredCategories)
-- vit côté app plutôt qu'en base, pour rester à côté de
-- kClientTypeOptions (lib/core/constants/client_types.dart) — même
-- source, pas de table de référence supplémentaire à maintenir en double.
-- ============================================================

drop function if exists public.random_published_products(int);

create or replace function public.random_published_products(
  limit_count int default 10,
  preferred_categories text[] default null
)
returns setof public.products as $$
  select * from public.products
  where visibility = true
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

grant execute on function public.random_published_products(int, text[]) to authenticated, anon;
