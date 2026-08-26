-- ============================================================
-- AkoraHub - Patch Phase 184 : formats manquants (vrac liquide, 5 kg)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (25/08) : pour ajouter "Juo Liquide Vaisselle" (vendu en
-- vrac jusqu'à 170L, voir affiche), il manquait un format pour le
-- grand contenant liquide (au-delà de "Fût 200 L" existant, le
-- fournisseur utilise des fûts de 170 L) et un format "5 kg" simple
-- (distinct de "Sachet 5 kg" — phase4 — pour un produit vendu en vrac
-- sans sachet, ex. bidon/seau).
-- ============================================================

insert into public.formats (name, base_unit_quantity) values
  ('Fût 170 L', null),
  ('5 kg', 5)
on conflict (name) do update set base_unit_quantity = excluded.base_unit_quantity;
