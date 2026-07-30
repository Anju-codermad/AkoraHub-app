-- ============================================================
-- AkoraHub - Patch Phase 25 : position du livreur (suivi de livraison)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : le staff indique manuellement la position du livreur à des
-- moments clés (départ, en route, arrivée) — pas de suivi GPS continu
-- (décision explicite de l'utilisateur : plus simple, pas de service en
-- arrière-plan, pas de consommation batterie/données supplémentaire, pas
-- de question de vie privée du livreur). Le client voit cette position
-- sur une carte (Google Maps) avec une ligne directe vers son adresse de
-- livraison — pas d'itinéraire routier réel (pas d'API Directions
-- payante, cohérent avec le calcul de distance à vol d'oiseau déjà
-- utilisé pour les frais de livraison, voir client_home/delivery_pricing.dart).
-- ============================================================

alter table public.orders
  add column if not exists driver_latitude double precision,
  add column if not exists driver_longitude double precision,
  add column if not exists driver_position_updated_at timestamptz;

alter table public.orders
  drop constraint if exists orders_driver_latitude_check;
alter table public.orders
  add constraint orders_driver_latitude_check
    check (driver_latitude is null or (driver_latitude between -90 and 90));

alter table public.orders
  drop constraint if exists orders_driver_longitude_check;
alter table public.orders
  add constraint orders_driver_longitude_check
    check (driver_longitude is null or (driver_longitude between -180 and 180));

-- Aucun changement RLS nécessaire : les policies existantes sur `orders`
-- ("orders_select_own_or_staff", "orders_update_staff") couvrent déjà
-- toutes les colonnes de la table, y compris les nouvelles — le staff
-- peut donc déjà mettre à jour ces 3 colonnes, et le client peut déjà
-- les lire sur ses propres commandes.

comment on column public.orders.driver_latitude is
  'Dernière position GPS connue du livreur, mise à jour manuellement par le staff (pas de suivi continu). Nullable — aucune carte affichée côté client tant que non renseignée.';
comment on column public.orders.driver_longitude is
  'Voir driver_latitude.';
comment on column public.orders.driver_position_updated_at is
  'Horodatage de la dernière mise à jour manuelle de la position du livreur — affiché côté client ("Position mise à jour il y a X min").';
