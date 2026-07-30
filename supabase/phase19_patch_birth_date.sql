-- ============================================================
-- AkoraHub - Patch : date de naissance sur le profil client
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

alter table public.profiles
  add column if not exists birth_date date;
