-- ============================================================
-- AkoraHub - Patch Phase 173 : conditionnement manquant (Fût 45 kg)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (14/08) : oublié dans la liste initiale (Phase 172).
-- ============================================================

insert into public.formats (name, base_unit_quantity) values
  ('Fût 45 kg', 45)
on conflict (name) do update set base_unit_quantity = excluded.base_unit_quantity;
