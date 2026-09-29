-- ============================================================
-- AkoraHub - Patch Phase 250 : accusés de lecture + présence
-- (messagerie client ↔ staff)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (29/09/2026) : demande explicite "Statut de lecture &
-- présence" (coches ✓/✓✓, "Vu à HH:MM", "Vu(e) pour la dernière fois").
-- Les booléens `read_by_client`/`read_by_staff` existaient déjà
-- (phase8) mais sans horodatage — impossible d'afficher "Vu à HH:MM"
-- avec juste un booléen. Idem pour la présence : rien n'enregistrait
-- quand un utilisateur avait été actif pour la dernière fois.
--
-- Pas de nouvelle policy nécessaire : `messages_update_own_or_staff`
-- (phase8) autorise déjà la mise à jour de ces deux colonnes par leur
-- auteur légitime, et `protect_message_content` (phase155) ne les
-- protège pas (seuls content/sender_id/sender_role/is_request/
-- conversation_id/created_at sont verrouillés) — donc déjà librement
-- modifiables. Idem `profiles_update_own_or_staff` (phase1) pour
-- `last_seen_at`.
-- ============================================================

alter table public.messages
  add column if not exists read_by_staff_at timestamptz,
  add column if not exists read_by_client_at timestamptz;

alter table public.profiles
  add column if not exists last_seen_at timestamptz;

-- Expose last_seen_at via la vue publique (phase9, dernière révision en
-- phase162) : le client n'a pas le droit de lire la table `profiles`
-- d'un membre du staff directement (RLS), seulement via cette vue —
-- sans ça, impossible d'afficher "En ligne"/"Vu(e) à..." côté client
-- pour le staff.
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
  coalesce(loyalty_points, 0) as loyalty_points,
  role,
  last_seen_at
from public.profiles;

grant select on public.public_profiles to authenticated, anon;
