-- ============================================================
-- AkoraHub - Patch Phase 152 : autoriser mfa_enabled/mfa_disabled/
-- sessions_revoked dans le journal de sécurité
--
-- Bug découvert (10/08, audit de sécurité suite au fix "sessions non
-- révoquées après changement de mot de passe") : `two_factor_setup_
-- screen.dart` appelle `log_security_event('mfa_enabled'/'mfa_disabled')`
-- depuis l'origine de cette fonctionnalité, mais `log_security_event`
-- (phase34) n'autorise que 'password_reset_requested'/'password_changed'
-- — chaque appel levait une exception, silencieusement avalée par le
-- try/catch côté Dart. Résultat : AUCUN événement MFA n'a jamais été
-- réellement journalisé. Ce patch élargit la liste autorisée (fonction
-- ET contrainte CHECK de la table) pour inclure ces événements, plus
-- 'sessions_revoked' (nouveau bouton "Déconnecter les autres appareils").
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

alter table public.security_audit_log
  drop constraint if exists security_audit_log_event_type_check;

alter table public.security_audit_log
  add constraint security_audit_log_event_type_check check (event_type in (
    'login_failed', 'login_success', 'password_reset_requested',
    'password_changed', 'role_changed',
    'mfa_enabled', 'mfa_disabled', 'sessions_revoked'
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
    'mfa_enabled', 'mfa_disabled', 'sessions_revoked'
  ) then
    raise exception 'event_type non autorisé pour cette fonction';
  end if;
  insert into public.security_audit_log (event_type, user_id)
  values (p_event_type, auth.uid());
end;
$$;
