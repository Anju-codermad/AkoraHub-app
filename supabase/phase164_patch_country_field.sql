-- ============================================================
-- AkoraHub - Patch Phase 164 : pays du client (géolocalisation)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (12/08, demande explicite) : "J'ai de clients à Maurice,
-- réunion, comore, Afrique, Europe" — la géolocalisation Niveau 1
-- (profile_tab.dart, `_useCurrentLocation`) ignorait jusqu'ici le pays
-- renvoyé par le reverse-géocodage (`Placemark.country`), ne gardant que
-- ville/région. Ajouté pour permettre un vrai "Principaux pays" dans les
-- données démographiques (customer_management_real.dart), au lieu de
-- supposer à tort que tous les clients sont à Madagascar.
-- ============================================================

alter table public.profiles
  add column if not exists country text;
