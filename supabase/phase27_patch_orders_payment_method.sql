-- ============================================================
-- AkoraHub - Patch Phase 27 : Mode de paiement de la commande
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Ajoute le mode de paiement choisi par le client au checkout : paiement à
-- la livraison (comportement historique, resté implicite jusqu'ici), ou
-- l'un des 3 modes manuels (virement bancaire BNI, Orange Money, Mvola,
-- Airtel Money) demandés en attendant l'intégration d'un vrai paiement en
-- ligne (dossier marchand BNI/Mobile Money en cours). Aucune RLS
-- supplémentaire nécessaire : les policies existantes sur `orders`
-- couvrent déjà toutes les colonnes (voir phase5/phase25).
-- ============================================================

alter table public.orders
  add column if not exists payment_method text not null default 'paiement_livraison';

alter table public.orders
  drop constraint if exists orders_payment_method_check;
alter table public.orders
  add constraint orders_payment_method_check
    check (payment_method in (
      'paiement_livraison',
      'virement_bancaire',
      'orange_money',
      'mvola',
      'airtel_money'
    ));
