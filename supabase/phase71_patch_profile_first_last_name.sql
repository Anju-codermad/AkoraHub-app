-- ============================================================
-- AkoraHub - Patch Phase 71 : séparer nom et prénom (profil client)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : le formulaire "Modifier mon profil" ne proposait qu'un seul
-- champ "Nom complet" (full_name). Ajout de first_name/last_name comme
-- vraie source de vérité, tout en gardant full_name à jour automatiquement
-- (trigger) pour ne pas casser les ~28 écrans qui l'affichent encore
-- (fiche produit, avis, admin, PDF, etc.).
-- ============================================================

alter table public.profiles
  add column if not exists first_name text,
  add column if not exists last_name text;

-- Découpage au mieux des profils existants (un seul essai, pas de
-- garantie vu l'absence de convention côté données déjà en base) :
-- premier mot = prénom, reste = nom.
update public.profiles
set
  first_name = coalesce(first_name,
    nullif(split_part(trim(full_name), ' ', 1), '')),
  last_name = coalesce(last_name,
    nullif(trim(substring(trim(full_name) from
      length(split_part(trim(full_name), ' ', 1)) + 1)), ''))
where full_name is not null and trim(full_name) <> ''
  and (first_name is null or last_name is null);

-- Recalcule full_name à chaque modification de first_name/last_name —
-- ne se déclenche que si l'un des deux change, donc les écrans qui
-- écrivent encore full_name directement (ex. inscription) continuent de
-- fonctionner sans y toucher.
create or replace function public.sync_profile_full_name()
returns trigger as $$
begin
  if new.first_name is not null or new.last_name is not null then
    new.full_name := nullif(trim(concat_ws(' ', new.first_name, new.last_name)), '');
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_sync_profile_full_name on public.profiles;
create trigger trg_sync_profile_full_name
  before insert or update of first_name, last_name on public.profiles
  for each row execute function public.sync_profile_full_name();
