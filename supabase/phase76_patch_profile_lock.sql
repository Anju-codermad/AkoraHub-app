-- ============================================================
-- AkoraHub - Patch Phase 76 : profil verrouillé (privé)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : sur demande ("chaque utilisateur peut voir le profil des
-- autres sauf si l'un met son profil verrouillé", 06/08). Choix acté
-- avec l'utilisatrice pour ce que voit un visiteur NON ami d'un profil
-- verrouillé : juste nom + avatar + bouton "Ajouter en ami" (comme un
-- compte Instagram privé) — tout le reste (société, secteur, numéro,
-- publications) reste masqué tant que la demande d'ami n'est pas
-- acceptée. Réutilise le système d'amis déjà en place
-- (phase48_patch_friends_and_private_chat.sql) plutôt que d'inventer un
-- nouveau mécanisme d'accès.
-- ============================================================

alter table public.profiles
  add column if not exists profile_locked boolean not null default false;

-- Redéfinition de la vue public_profiles (phase9, étendue en phase47/52/67)
-- pour exposer le nouveau champ — colonnes existantes inchangées.
create or replace view public.public_profiles as
select
  id,
  full_name,
  company_name,
  client_type,
  avatar_url,
  case when share_phone_publicly then phone else null end as phone,
  role in ('admin','commercial','production','comptable') as is_staff,
  referred_by,
  created_at,
  profile_locked
from public.profiles;

grant select on public.public_profiles to authenticated, anon;
