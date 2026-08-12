-- ============================================================
-- AkoraHub - Patch Phase 166 : nouveaux rôles Services et Livraison
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (12/08, suite à "Akora_Operational_Architecture.pdf") :
-- l'organigramme réel d'Akora a 2 fonctions non couvertes par les 4
-- rôles existants (Admin/Commercial/Production/Comptable) — le
-- Superviseur des Services (Pilier 2 : nettoyage, blanchisserie,
-- désinsectisation) et le Chauffeur-Livreur (Pilier 5, Chaîne
-- Logistique). Étape 1/2 du chantier : permettre d'assigner ces rôles
-- dès maintenant. Note importante : `current_role_is_staff()` (voir
-- plus bas) ne les inclut PAS encore — une personne promue "Services"
-- ou "Livraison" ne verra donc encore RIEN côté staff tant que l'Étape
-- 2 (écrans dédiés + policies RLS ciblées) n'est pas faite. C'est
-- volontaire : mieux vaut un accès nul par défaut qu'un accès trop
-- large par erreur.
-- ============================================================

alter table public.profiles
  drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_check
    check (role in (
      'admin', 'commercial', 'production', 'comptable',
      'services', 'livraison', 'client'
    ));
