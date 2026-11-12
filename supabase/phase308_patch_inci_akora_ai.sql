-- ============================================================
-- AkoraHub - Patch Phase 308 : nom INCI des produits, proposé par
-- Akora AI et validé par le staff
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Demande explicite (12/11) : afficher la référence INCI des produits qui
-- en ont une (site + App), en laissant Akora AI faire la proposition.
--
--   inci            : nom INCI VALIDÉ par le staff — le seul affiché aux
--                     clients (site + App). Null = rien d'affiché.
--   inci_suggestion : proposition d'Akora AI (Edge Function akora-ai-inci),
--                     jamais affichée aux clients. Chaîne vide = Akora AI
--                     a jugé que le produit n'a pas de nom INCI simple
--                     (produit fini, mélange, produit non cosmétique...).
--   inci_note       : explication courte d'Akora AI (niveau de confiance,
--                     points à vérifier sur la fiche fournisseur).
--
-- Idempotent : peut être relancé sans risque.
-- ============================================================

alter table public.products
  add column if not exists inci text,
  add column if not exists inci_suggestion text,
  add column if not exists inci_note text;

comment on column public.products.inci is
  'Nom INCI validé par le staff, affiché aux clients (site + App). Null = non affiché.';
comment on column public.products.inci_suggestion is
  'Proposition Akora AI (non affichée aux clients). Chaîne vide = pas de nom INCI applicable selon l''IA.';
comment on column public.products.inci_note is
  'Note d''Akora AI accompagnant la proposition INCI (confiance, points à vérifier).';
