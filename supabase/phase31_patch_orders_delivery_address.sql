-- Phase 31 : adresse de livraison précisée par le client.
--
-- `orders.latitude`/`longitude` (phase5) existent déjà mais sont détectées
-- silencieusement (GPS, profil...) sans jamais être montrées au client ni au
-- staff sous forme de texte lisible. On ajoute une adresse texte, que le
-- client peut soit laisser pré-remplie automatiquement (géocodage inverse de
-- sa position), soit corriger/saisir lui-même avant de valider sa commande.

alter table public.orders
  add column if not exists delivery_address text;

comment on column public.orders.delivery_address is
  'Adresse de livraison précisée par le client (texte libre, pré-rempli par géocodage inverse de sa position GPS si disponible). Latitude/longitude (phase5) restent la source utilisée pour la carte de suivi.';
