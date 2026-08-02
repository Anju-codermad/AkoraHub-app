-- ============================================================
-- AkoraHub - Patch Phase 60 : Fiche client 360° (CRM, Lot 1/5) — SQL
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Nouvel écran admin regroupant, pour un client donné : commandes,
-- devis, factures, avis produits, activité Communauté, points de
-- fidélité et adresses de livraison. La quasi-totalité de ces tables
-- (orders/quotes/invoices/product_reviews/posts/profiles) sont déjà
-- lisibles par le staff via leurs policies `..._select_own_or_staff`
-- existantes — seuls deux ajouts sont nécessaires ici.
-- ============================================================

-- ------------------------------------------------------------
-- 1) delivery_addresses (Phase 57) : la policy de lecture existante
-- (`delivery_addresses_select_own`) ne couvre QUE le propriétaire, pas
-- le staff — contrairement à toutes les autres tables de la fiche
-- 360°. Sans ce correctif, la section "Adresses" de la fiche
-- reviendrait silencieusement vide pour l'Admin (RLS, pas d'erreur).
-- ------------------------------------------------------------
drop policy if exists "delivery_addresses_select_own_or_staff" on public.delivery_addresses;
create policy "delivery_addresses_select_own_or_staff" on public.delivery_addresses
  for select using (customer_id = auth.uid() or public.current_role_is_staff());

drop policy if exists "delivery_addresses_select_own" on public.delivery_addresses;

-- ------------------------------------------------------------
-- 2) Email du client — vit uniquement dans auth.users, jamais dupliqué
-- sur profiles. `find_profile_by_email` (Phase 1) va dans le sens
-- inverse (email -> profil) ; ici il faut l'inverse (id -> email) pour
-- l'afficher/le copier depuis la fiche 360°. Même principe de sécurité
-- : security definer pour lire auth.users, mais restreint au staff.
-- ------------------------------------------------------------
create or replace function public.staff_get_customer_email(customer_id uuid)
returns text as $$
  select u.email from auth.users u
  where u.id = customer_id
    and public.current_role_is_staff();
$$ language sql security definer stable;
