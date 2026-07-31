-- ============================================================
-- AkoraHub - Patch Phase 35 : Rate limiting connexion via Edge Function
-- (remplace l'approche par Auth Hook du phase34, indisponible sur notre
-- plan Supabase actuel — voir explication ci-dessous)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Découverte (31/07) : le hook officiel "Password Verification Attempt"
-- (supabase/phase34_patch_security_audit_log.sql) s'affiche grisé dans
-- Authentication -> Hooks avec la mention "Team or Enterprise Plan
-- required" — indisponible sur le plan actuel. La fonction
-- `hook_password_verification_attempt` créée par phase34 reste dans la
-- base mais restera inutilisée tant que ce hook n'est pas activable (soit
-- via upgrade de plan, soit elle peut être supprimée plus tard) ; rien à
-- faire à son sujet, elle ne gêne pas.
--
-- Solution retenue : une Edge Function (`secure-login`) que l'app appelle
-- à la place de `auth.signInWithPassword` directement. Elle vérifie
-- d'abord le nombre d'échecs récents pour l'email concerné dans la table
-- ci-dessous, puis relaie elle-même la tentative au vrai endpoint GoTrue
-- (mot de passe) avec la clé service_role -- Supabase Auth reste seul à
-- valider le mot de passe, cette fonction ajoute juste une vérification
-- avant et une journalisation après.
-- ============================================================

create table if not exists public.login_rate_limit (
  email text primary key,
  failed_count int not null default 0,
  last_attempt_at timestamptz not null default now(),
  locked_until timestamptz
);

-- RLS activée SANS AUCUNE policy : totalement inaccessible à `anon`/
-- `authenticated`, seule la clé service_role (utilisée par l'Edge
-- Function) peut lire/écrire cette table (bypass RLS par défaut pour ce
-- rôle). Aucun accès direct ne doit jamais être possible depuis l'app.
alter table public.login_rate_limit enable row level security;
