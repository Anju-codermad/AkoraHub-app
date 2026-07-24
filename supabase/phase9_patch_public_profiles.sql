-- ============================================================
-- Akora Fanadiovana - Patch Phase 9 : profils clients publics (légers)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : la table `profiles` a une RLS restrictive
-- ("profiles_select_own_or_staff" — phase1_schema.sql) qui ne permet à un
-- client de lire QUE sa propre ligne (le staff voit tout). Ça bloque de
-- fait l'affichage du nom des AUTRES clients sur le Mur, dans les
-- commentaires, etc. — les jointures `profiles(...)` depuis `posts` /
-- `post_comments` retournent `null` pour l'auteur si ce n'est pas
-- l'utilisateur courant, d'où le repli sur "Utilisateur" déjà prévu
-- dans wall_tab.dart.
--
-- Plutôt que d'assouplir la RLS de `profiles` (qui exposerait aussi
-- téléphone/localisation à tout le monde), on expose une vue "légère"
-- ne contenant que les colonnes non sensibles, lisible par tout
-- utilisateur connecté.
-- ============================================================

create or replace view public.public_profiles as
select
  id,
  full_name,
  company_name,
  client_type,
  avatar_url
from public.profiles;

-- Note : par défaut (sans `security_invoker`), une vue s'exécute avec les
-- droits de son propriétaire (typiquement `postgres` côté Supabase, qui
-- contourne la RLS) — donc cette vue reste lisible pour tous même si la
-- RLS sous-jacente de `profiles` reste restrictive. Seules les colonnes
-- listées ci-dessus sont exposées : ni téléphone, ni localisation, ni
-- rôle, ni email.
grant select on public.public_profiles to authenticated, anon;
