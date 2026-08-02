-- ============================================================
-- AkoraHub - Patch Phase 52 : Communauté — badge "Officiel", publication
-- épinglée (Lot 2, achat direct sur post réutilise products/product_variants
-- existants, aucun changement de schéma nécessaire pour ça)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- ⚠️ Script idempotent : relancer en entier depuis le début est sans
-- risque.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Badge "Officiel" — expose uniquement un booléen (jamais le rôle
-- précis admin/commercial/production/comptable, pas pertinent côté
-- client) dans la vue publique déjà utilisée pour le nom/avatar des
-- autres clients (supabase/phase9_patch_public_profiles.sql, complétée
-- en phase47 avec le téléphone opt-in).
-- ------------------------------------------------------------
create or replace view public.public_profiles as
select
  id,
  full_name,
  company_name,
  client_type,
  avatar_url,
  case when share_phone_publicly then phone else null end as phone,
  role in ('admin','commercial','production','comptable') as is_staff
from public.profiles;

grant select on public.public_profiles to authenticated, anon;

-- ------------------------------------------------------------
-- 2) Publication épinglée — colonne + protection : seul le staff peut la
-- faire passer à true, quel que soit l'auteur de la ligne modifiée
-- (`posts_update_own`, Phase 3, autorise déjà le staff à modifier
-- n'importe quelle publication — mais un simple client a aussi le droit
-- de modifier SA PROPRE publication, et pourrait sinon s'épingler
-- lui-même). Une policy RLS ne peut pas distinguer "quelle colonne a
-- changé" ; on protège donc `is_pinned` avec un trigger, qui annule
-- silencieusement toute tentative venant d'un compte non-staff — même
-- principe que "la vraie protection est côté serveur", juste via un
-- trigger plutôt qu'une policy cette fois.
-- ------------------------------------------------------------
alter table public.posts
  add column if not exists is_pinned boolean not null default false;

create or replace function public.protect_posts_pin_column()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.current_role_is_staff() then
    if tg_op = 'INSERT' then
      new.is_pinned := false;
    else
      new.is_pinned := old.is_pinned;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists protect_posts_pin on public.posts;
create trigger protect_posts_pin
  before insert or update on public.posts
  for each row execute procedure public.protect_posts_pin_column();
