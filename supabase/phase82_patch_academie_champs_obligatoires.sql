-- ============================================================
-- AkoraHub - Patch Phase 82 : Académie — champs obligatoires
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (06/08) : sur demande explicite, chaque fiche technique
-- Académie DOIT avoir un nom chimique, un nom commun (colonne
-- `synonymes`), un aspect, un pH en solution et une solubilité — déjà
-- imposé côté formulaire admin (academie_editor_screen.dart), renforcé
-- ici au niveau de la base pour empêcher toute fiche incomplète même en
-- cas d'insertion directe (hors app).
--
-- Si cette commande échoue avec une erreur "contains null values", c'est
-- qu'une fiche Académie existante a déjà un de ces champs vide —
-- complète-la d'abord depuis l'app puis relance ce script.
-- ============================================================

alter table public.matieres_premieres_academie
  alter column nom_chimique set not null,
  alter column synonymes set not null,
  alter column aspect set not null,
  alter column ph_solution set not null,
  alter column solubilite set not null;
