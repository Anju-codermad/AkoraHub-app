-- ============================================================
-- AkoraHub - Patch Phase 79 : carte de profil + amis en commun (profil public)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : sur demande, avec une image de référence ("carte de
-- profil" façon carte de visite), le style bandeau + avatar chevauchant
-- + carte blanche arrondie (déjà appliqué à "Mon profil", phase du
-- 05/08) s'applique maintenant au profil des AUTRES clients
-- (public_profile_screen.dart), avec en plus une ligne "amis en
-- commun".
--
-- 1) Expose la première photo de couverture dans la vue public_profiles
--    (jusqu'ici seulement visible par le propriétaire du profil).
-- 2) Fonction mutual_friends : amis communs entre le client connecté et
--    le profil consulté (status = 'acceptee' des deux côtés).
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
  end as cover_photo_url
from public.profiles;

grant select on public.public_profiles to authenticated, anon;

create or replace function public.mutual_friends(uid uuid, other_uid uuid)
returns table(friend_id uuid)
language sql
stable
security definer
set search_path = public
as $$
  with my_friends as (
    select case when requester_id = uid then addressee_id else requester_id end as friend_id
    from public.friendships
    where status = 'acceptee' and (requester_id = uid or addressee_id = uid)
  ),
  their_friends as (
    select case when requester_id = other_uid then addressee_id else requester_id end as friend_id
    from public.friendships
    where status = 'acceptee' and (requester_id = other_uid or addressee_id = other_uid)
  )
  select mf.friend_id from my_friends mf
  inner join their_friends tf on tf.friend_id = mf.friend_id;
$$;

grant execute on function public.mutual_friends(uuid, uuid) to authenticated;
