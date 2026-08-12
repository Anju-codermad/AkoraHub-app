-- ============================================================
-- AkoraHub - Patch Phase 168 : élargir les secteurs d'activité client
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (12/08, demande explicite) : "Je suis un(e)..." à l'inscription
-- ne proposait que Particulier/Hôtel/Hôpital/Entreprise — trop restreint
-- pour les vrais clients (restaurants, écoles, pharmacies...). Liste
-- validée par l'Admin, voir lib/core/constants/client_types.dart (source
-- unique côté app).
-- ============================================================

alter table public.profiles
  drop constraint if exists profiles_client_type_check;
alter table public.profiles
  add constraint profiles_client_type_check
    check (client_type is null or client_type in (
      'particulier', 'hotel', 'hopital', 'restaurant', 'ecole',
      'entreprise', 'usine', 'pharmacie', 'salon_beaute', 'commerce',
      'administration', 'ong', 'autre'
    ));
