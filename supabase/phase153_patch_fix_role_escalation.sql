-- ============================================================
-- AkoraHub - Patch Phase 153 : CORRECTIF CRITIQUE — élévation de
-- privilège via profiles.role
--
-- Faille trouvée le 10/08 (suite de l'audit de sécurité) : la policy
-- RLS "profiles_update_own_or_staff" (phase1_schema.sql) autorise
-- chaque utilisateur à modifier sa PROPRE ligne (`auth.uid() = id`)
-- mais n'a AUCUN `with check` empêchant de changer la colonne `role`
-- au passage. N'importe quel client authentifié pouvait donc
-- s'attribuer le rôle 'admin' (ou 'commercial'/'production'/
-- 'comptable') via un simple appel `profiles.update({role: 'admin'})`
-- sur son propre compte — sans avoir besoin d'y être autorisé.
-- `current_role_is_admin()`/`current_role_is_staff()` lisant
-- directement `profiles.role`, ça donnait un accès total et immédiat
-- à TOUT ce qui est protégé par ces fonctions dans toute l'app
-- (produits, matières premières, commandes, factures, écrans admin...).
--
-- Correctif : un trigger BEFORE UPDATE qui annule silencieusement
-- tout changement de `role` tenté par quelqu'un qui n'est pas déjà
-- Admin (`current_role_is_admin()`) — la ligne se met à jour
-- normalement pour tous les autres champs, seul `role` revient à sa
-- valeur d'origine si le changement n'est pas autorisé. Complète (ne
-- remplace pas) le trigger `log_role_change` (phase34) qui, lui, se
-- contente de journaliser les changements réels — désormais
-- uniquement ceux effectués légitimement par un Admin.
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

create or replace function public.guard_profile_role_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role is distinct from old.role and not public.current_role_is_admin() then
    new.role := old.role;
  end if;
  return new;
end;
$$;

drop trigger if exists on_profile_role_change_guard on public.profiles;
create trigger on_profile_role_change_guard
  before update on public.profiles
  for each row
  execute function public.guard_profile_role_change();
