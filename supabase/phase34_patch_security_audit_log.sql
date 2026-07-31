-- ============================================================
-- AkoraHub - Patch Phase 34 : Journalisation sécurité + rate limiting connexion
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Derniers 2 points de la checklist perf/sécurité (31/07) :
--   4. Rate limiting sur connexion (via le "Password Verification Hook"
--      officiel de Supabase Auth — la seule façon d'agir AVANT que GoTrue
--      n'accepte une tentative, un trigger sur une table ne suffit pas
--      puisque signInWithPassword ne passe par aucune table qu'on contrôle).
--   5. Journalisation des actions sensibles : connexions (échouées ET
--      réussies, via le même hook), changements de rôle (trigger sur
--      profiles.role), changements/réinitialisations de mot de passe
--      (appel explicite depuis l'app après succès).
--
-- ⚠️ ÉTAPE MANUELLE APRÈS CE SCRIPT (obligatoire, ne peut pas être faite en
-- SQL) : Dashboard Supabase -> Authentication -> Hooks -> "Password
-- Verification Attempt" -> Enable -> choisir la fonction
-- public.hook_password_verification_attempt. Sans cette activation, le
-- rate limiting ne fait rien (mais rien ne casse non plus : la fonction
-- reste juste inutilisée). À TESTER après activation : se tromper de mot
-- de passe une fois (doit encore fonctionner), puis se reconnecter avec
-- le bon mot de passe (doit toujours marcher).
-- ============================================================

create table if not exists public.security_audit_log (
  id uuid primary key default gen_random_uuid(),
  event_type text not null check (event_type in (
    'login_failed', 'login_success', 'password_reset_requested',
    'password_changed', 'role_changed'
  )),
  user_id uuid references auth.users(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists security_audit_log_user_id_idx
  on public.security_audit_log (user_id);
create index if not exists security_audit_log_event_created_idx
  on public.security_audit_log (event_type, created_at);

alter table public.security_audit_log enable row level security;

-- Lecture réservée à l'Admin (revue de sécurité) — aucune policy insert :
-- seules les fonctions SECURITY DEFINER ci-dessous peuvent écrire, jamais
-- un insert direct depuis le client.
drop policy if exists "security_audit_log_select_admin_only" on public.security_audit_log;
create policy "security_audit_log_select_admin_only" on public.security_audit_log
  for select using (public.current_role_is_admin());

-- ------------------------------------------------------------
-- Fonction appelée par l'app pour journaliser un événement précis
-- (changement de mot de passe réussi, réinitialisation demandée) —
-- l'utilisateur ne peut journaliser que pour lui-même (auth.uid()).
-- ------------------------------------------------------------
create or replace function public.log_security_event(p_event_type text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_event_type not in ('password_reset_requested', 'password_changed') then
    raise exception 'event_type non autorisé pour cette fonction';
  end if;
  insert into public.security_audit_log (event_type, user_id)
  values (p_event_type, auth.uid());
end;
$$;

-- `anon` inclus car "réinitialisation demandée" se produit avant
-- connexion (auth.uid() sera alors null dans la ligne journalisée, ce qui
-- est normal et attendu).
grant execute on function public.log_security_event(text) to authenticated, anon;

-- ------------------------------------------------------------
-- Trigger : journalise tout changement de rôle sur profiles, quelle que
-- soit l'origine (écran Admin, SQL Editor...) — plus robuste qu'un appel
-- explicite depuis un seul écran client.
-- ------------------------------------------------------------
create or replace function public.log_role_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role is distinct from old.role then
    insert into public.security_audit_log (event_type, user_id, metadata)
    values (
      'role_changed',
      new.id,
      jsonb_build_object(
        'old_role', old.role,
        'new_role', new.role,
        'changed_by', auth.uid()
      )
    );
  end if;
  return new;
end;
$$;

drop trigger if exists on_profile_role_change on public.profiles;
create trigger on_profile_role_change
  after update on public.profiles
  for each row
  execute function public.log_role_change();

-- ------------------------------------------------------------
-- Auth Hook officiel Supabase : appelé par GoTrue à CHAQUE tentative de
-- connexion par mot de passe (avant que la session ne soit créée).
-- Journalise l'échec/succès, et bloque après 5 échecs en 15 minutes pour
-- CET utilisateur précis.
--
-- Fail-open volontaire : toute erreur inattendue dans cette fonction
-- renvoie "continue" plutôt que de faire planter la connexion — un bug
-- ici ne doit jamais pouvoir verrouiller l'accès à toute l'app.
-- ------------------------------------------------------------
create or replace function public.hook_password_verification_attempt(event jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_valid boolean;
  recent_failures int;
begin
  begin
    v_user_id := (event->>'user_id')::uuid;
    v_valid := (event->>'valid')::boolean;

    insert into public.security_audit_log (event_type, user_id, metadata)
    values (
      case when v_valid then 'login_success' else 'login_failed' end,
      v_user_id,
      jsonb_build_object('via', 'password_verification_hook')
    );

    if v_valid then
      return jsonb_build_object('decision', 'continue');
    end if;

    select count(*) into recent_failures
    from public.security_audit_log
    where event_type = 'login_failed'
      and user_id = v_user_id
      and created_at > now() - interval '15 minutes';

    if recent_failures >= 5 then
      return jsonb_build_object(
        'decision', 'reject',
        'message', 'Trop de tentatives échouées. Réessayez dans 15 minutes.'
      );
    end if;

    return jsonb_build_object('decision', 'continue');
  exception when others then
    return jsonb_build_object('decision', 'continue');
  end;
end;
$$;

grant execute on function public.hook_password_verification_attempt(jsonb) to supabase_auth_admin;
revoke execute on function public.hook_password_verification_attempt(jsonb) from authenticated, anon, public;
