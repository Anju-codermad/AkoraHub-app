-- ============================================================
-- AkoraHub - Patch Phase 172 : conditionnements industriels (poids) +
-- calcul automatique du prix depuis le prix de base
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (14/08, demande explicite) : le mécanisme de variantes
-- Format x Parfum (Phase 4) existe déjà et fonctionne côté client (choix
-- du format, prix recalculé, ajout au panier) — pas besoin d'un nouveau
-- système. Ce script ajoute simplement :
-- 1) De nouveaux formats au poids (250 g -> Fût 235 kg), pour les
--    matières vendues en vrac/industriel plutôt qu'en flacon/bidon
--    liquide (déjà couverts par les formats existants).
-- 2) Une colonne `base_unit_quantity` sur `formats` : le multiplicateur
--    à appliquer au prix de base du produit pour calculer automatiquement
--    le prix de CE conditionnement (ex. Sac 25 kg -> 25, si le produit
--    est tarifé au kg). Reste éditable ensuite côté app — un gros
--    conditionnement a souvent un tarif dégressif, pas une simple règle
--    de trois. NULL pour les formats existants (100 ml, Bidon 20 L...) :
--    aucun changement de comportement pour eux, le calcul reste manuel
--    comme aujourd'hui.
-- ============================================================

alter table public.formats
  add column if not exists base_unit_quantity numeric;

insert into public.formats (name, base_unit_quantity) values
  ('250 g', 0.25),
  ('500 g', 0.5),
  ('1 kg', 1),
  ('Sac 25 kg', 25),
  ('Sac 50 kg', 50),
  ('Bidon 25 kg', 25),
  ('Bidon 30 kg', 30),
  ('Bidon 35 kg', 35),
  ('Bidon 50 kg', 50),
  ('Fût 170 kg', 170),
  ('Fût 210 kg', 210),
  ('Fût 215 kg', 215),
  ('Fût 220 kg', 220),
  ('Fût 235 kg', 235)
on conflict (name) do update set base_unit_quantity = excluded.base_unit_quantity;
