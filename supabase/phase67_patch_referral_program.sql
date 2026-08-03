-- ============================================================
-- AkoraHub - Patch Phase 67 : programme de parrainage
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : nouvelle barre de raccourcis dans le Profil client
-- (Paramètres, Parrainage, Assistance, Scanner un produit). Décision
-- utilisateur : PAS de récompense automatique pour l'instant — juste un
-- suivi parrain/filleul (code de parrainage + qui a été parrainé par
-- qui), le staff décide manuellement quoi offrir en dehors de l'app.
-- ============================================================

alter table public.profiles
  add column if not exists referral_code text,
  add column if not exists referred_by uuid references public.profiles(id);

-- Backfill des comptes existants (créés avant cette migration).
update public.profiles
set referral_code = upper(substr(md5(random()::text || id::text || clock_timestamp()::text), 1, 6))
where referral_code is null;

alter table public.profiles
  drop constraint if exists profiles_referral_code_unique;
alter table public.profiles
  add constraint profiles_referral_code_unique unique (referral_code);

-- Génère automatiquement un code de parrainage pour chaque nouveau
-- compte (le trigger `handle_new_user`, Phase 1, insère déjà la ligne
-- profiles au signup — celui-ci se déclenche pour toute insertion,
-- peu importe l'origine).
create or replace function public.generate_referral_code()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  candidate text;
begin
  if new.referral_code is not null then
    return new;
  end if;
  loop
    candidate := upper(substr(md5(random()::text || clock_timestamp()::text || new.id::text), 1, 6));
    exit when not exists (select 1 from public.profiles where referral_code = candidate);
  end loop;
  new.referral_code := candidate;
  return new;
end;
$$;

drop trigger if exists on_profile_generate_referral_code on public.profiles;
create trigger on_profile_generate_referral_code
  before insert on public.profiles
  for each row execute procedure public.generate_referral_code();

-- Résout un code de parrainage en id de profil, appelée à l'inscription
-- (avant toute session) — ne renvoie que l'id, jamais les autres
-- colonnes du profil du parrain.
create or replace function public.resolve_referral_code(p_code text)
returns uuid
language sql
security definer
set search_path = public
stable
as $$
  select id from public.profiles
  where referral_code = upper(trim(p_code))
  limit 1;
$$;

grant execute on function public.resolve_referral_code(text) to anon, authenticated;

-- La vue public_profiles (Phase 9/47/52 — nom/avatar des autres clients,
-- déjà accessible à tout utilisateur connecté) gagne `referred_by` et
-- `created_at` pour que l'écran "Parrainage" liste les filleuls d'un
-- utilisateur sans nouvelle policy RLS sur la table de base.
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
  created_at
from public.profiles;

grant select on public.public_profiles to authenticated, anon;
