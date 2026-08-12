-- ============================================================
-- AkoraHub - Patch Phase 162 : corrige "Aucun membre de l'équipe
-- disponible" lors d'un appel client sur une conversation neuve
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (12/08, repéré en testant un appel depuis un tout nouveau
-- compte client) : chat_screen.dart (_resolveCalleeStaffId) cherche
-- "n'importe quel Admin/Commercial" à appeler quand aucun staff n'a
-- encore répondu dans la conversation. Cette recherche interrogeait
-- directement `profiles`, dont la RLS ("profiles_select_own_or_staff",
-- phase1_schema.sql) ne laisse un client voir QUE sa propre ligne — la
-- recherche ne trouvait donc jamais personne, même avec un Admin bien
-- présent en base. Même mécanisme de contournement que phase9/47/52/
-- 67/76/79/146 : on expose le rôle via la vue publique légère
-- `public_profiles`, déjà lisible par tout utilisateur connecté.
-- ============================================================

create or replace view public.public_profiles as
select
  id,
  full_name,
  company_name,
  client_type,
  avatar_url,
  case when share_phone_publicly then phone else null end as phone,
  role,
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
