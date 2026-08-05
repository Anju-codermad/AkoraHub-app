-- ============================================================
-- AkoraHub - Patch Phase 73 : usages produit (Savonnerie, Industriel...)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (05/08) : les visuels marketing (ex. "Soude Caustique")
-- listent toujours les usages possibles du produit (Savonnerie,
-- Industriel, Nettoyage...) en badges. Reproduit dans l'app : une liste
-- de tags choisis par l'admin à la publication du produit, affichés en
-- badges sur la fiche produit côté client.
-- ============================================================

alter table public.products
  add column if not exists use_cases text[] not null default '{}';
