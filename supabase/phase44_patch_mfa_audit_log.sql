-- ============================================================
-- AkoraHub - Patch Phase 44 : journal de sécurité pour la double
-- authentification (TOTP)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (01/08) : ajout de la double authentification côté app
-- (`two_factor_setup_screen.dart`, `mfa_challenge_screen.dart`), qui
-- s'appuie sur l'API MFA native de Supabase Auth (`auth.mfa`) — aucune
-- table supplémentaire n'est nécessaire pour stocker les facteurs
-- eux-mêmes (Supabase les gère déjà dans son propre schéma `auth`).
--
-- Ce patch ajoute seulement les deux nouveaux types d'événement
-- ('mfa_enabled', 'mfa_disabled') à la liste blanche déjà en place
-- depuis la Phase 34 (`security_audit_log.event_type` +
-- `log_security_event()`) — sans lui, les appels
-- `log_security_event('mfa_enabled'/'mfa_disabled')` échouent
-- silencieusement (best-effort côté app) et l'activation/désactivation de
-- la 2FA n'apparaît jamais dans le journal de sécurité consulté par
-- l'Admin.
-- ============================================================

alter table public.security_audit_log drop constraint if exists security_audit_log_event_type_check;
alter table public.security_audit_log add constraint security_audit_log_event_type_check
  check (event_type in (
    'login_failed', 'login_success', 'password_reset_requested',
    'password_changed', 'role_changed', 'mfa_enabled', 'mfa_disabled'
  ));

create or replace function public.log_security_event(p_event_type text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_event_type not in (
    'password_reset_requested', 'password_changed',
    'mfa_enabled', 'mfa_disabled'
  ) then
    raise exception 'event_type non autorisé pour cette fonction';
  end if;
  insert into public.security_audit_log (event_type, user_id)
  values (p_event_type, auth.uid());
end;
$$;
