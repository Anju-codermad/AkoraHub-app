-- ============================================================
-- Akora Fanadiovana - Patch Phase 5b : géolocalisation précise (commandes)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : complète phase5_patch_geolocation.sql (colonnes sur `profiles`).
-- Ici on ajoute les mêmes colonnes sur `orders`, pour le cas où un client
-- commande vers une adresse de livraison différente de son profil (ex:
-- livrer au bureau plutôt qu'à domicile). Nullable : si non renseignées, le
-- backend/l'app peut se rabattre sur les coordonnées du profil client.
-- Patch additif uniquement, aucune colonne existante modifiée/supprimée.
-- ============================================================

alter table public.orders
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;

alter table public.orders
  drop constraint if exists orders_latitude_check;
alter table public.orders
  add constraint orders_latitude_check
    check (latitude is null or (latitude between -90 and 90));

alter table public.orders
  drop constraint if exists orders_longitude_check;
alter table public.orders
  add constraint orders_longitude_check
    check (longitude is null or (longitude between -180 and 180));

-- Aucun changement RLS nécessaire : les policies existantes sur `orders`
-- ("orders_select_own_or_staff", "orders_insert_own", "orders_update_staff")
-- couvrent déjà toutes les colonnes de la table, y compris les nouvelles.
-- Un client peut donc fournir latitude/longitude à la création de sa
-- commande (insert), mais ne peut pas les modifier après coup (update
-- réservé au staff) — cohérent avec le reste de la table.

comment on column public.orders.latitude is
  'Latitude GPS de l''adresse de livraison de cette commande, si différente du profil client. Nullable — repli sur profiles.latitude si absent.';
comment on column public.orders.longitude is
  'Longitude GPS de l''adresse de livraison de cette commande, si différente du profil client. Nullable — repli sur profiles.longitude si absent.';
