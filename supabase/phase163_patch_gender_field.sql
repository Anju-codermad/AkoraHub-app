-- ============================================================
-- AkoraHub - Patch Phase 163 : champ sexe (Homme/Femme) sur le profil
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (12/08, demande explicite) : ajout du choix du sexe au
-- formulaire d'inscription (étape 1, à côté de la date de naissance),
-- optionnel comme cette dernière — utile pour les statistiques
-- démographiques (voir customer_management_real.dart, Phase 161).
-- ============================================================

alter table public.profiles
  add column if not exists gender text
    check (gender in ('homme', 'femme') or gender is null);
