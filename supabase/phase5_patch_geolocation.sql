-- ============================================================
-- Akora Fanadiovana - Patch Phase 5 : géolocalisation précise (profils)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : la Localisation automatique Niveau 1 (côté client) remplit déjà
-- le champ texte `location` via reverse-géocodage. Pour une livraison
-- fiable (adressage souvent imprécis à Madagascar), on ajoute un point GPS
-- exact en plus de l'adresse texte. Aucune colonne existante n'est modifiée
-- ni supprimée — patch additif uniquement.
-- ============================================================

alter table public.profiles
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;

-- Garde-fous : coordonnées GPS valides uniquement (ou NULL si non renseignées)
alter table public.profiles
  drop constraint if exists profiles_latitude_check;
alter table public.profiles
  add constraint profiles_latitude_check
    check (latitude is null or (latitude between -90 and 90));

alter table public.profiles
  drop constraint if exists profiles_longitude_check;
alter table public.profiles
  add constraint profiles_longitude_check
    check (longitude is null or (longitude between -180 and 180));

-- Aucun changement RLS nécessaire : les policies existantes sur `profiles`
-- ("profiles_select_own_or_staff" / "profiles_update_own_or_staff") couvrent
-- déjà toutes les colonnes de la table, y compris les nouvelles.

comment on column public.profiles.latitude is
  'Latitude GPS précise du client (Localisation Niveau 2), nullable, alimentée depuis profile_tab.dart (_useCurrentLocation).';
comment on column public.profiles.longitude is
  'Longitude GPS précise du client (Localisation Niveau 2), nullable, alimentée depuis profile_tab.dart (_useCurrentLocation).';
