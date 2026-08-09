-- ============================================================
-- AkoraHub - Patch Phase 146 : palier de fidélité dans public_profiles
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : redesign de la carte de publication dans la Communauté
-- (badge de palier fidélité — Bronze/Argent/Or, voir
-- lib/core/loyalty/loyalty_tiers.dart — à côté du nom de l'auteur).
-- `loyalty_points` n'était jusqu'ici visible que par le propriétaire
-- du profil (RLS de `profiles`) ; on l'ajoute à la vue publique
-- légère `public_profiles` (même mécanisme que phase9/47/52/67/76/79)
-- pour que le palier de N'IMPORTE QUEL auteur soit visible dans le fil.
-- ============================================================

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
  profile_locked,
  case
    when cover_urls is not null and cardinality(cover_urls) > 0 then cover_urls[1]
    else cover_url
  end as cover_photo_url,
  coalesce(loyalty_points, 0) as loyalty_points
from public.profiles;

grant select on public.public_profiles to authenticated, anon;
