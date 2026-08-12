-- ============================================================
-- AkoraHub - Patch Phase 167 : accès restreint pour les rôles
-- Services et Livraison (Étape 2/2 du chantier rôles)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (12/08) : Phase 166 a ajouté les rôles 'services' et
-- 'livraison', volontairement SANS accès (current_role_is_staff() ne les
-- inclut pas). Ce script leur donne un accès précis et minimal :
-- - Livraison : lit/modifie UNIQUEMENT `orders` (statut, position du
--   livreur) — pas les prix ne sont pas cachés au niveau base (RLS ne
--   filtre pas par colonne), mais l'écran dédié (delivery_management.dart)
--   ne les affiche ni ne les modifie jamais.
-- - Services : lit/modifie UNIQUEMENT `service_requests` — déjà utilisé
--   par service_requests_management.dart (Phase 65/79).
-- - Les deux ont accès à `logistics_contacts`, une vue légère (nom,
--   société, téléphone, région, localisation) pour contacter le client
--   sans exposer tout `profiles` (fcm_token, loyalty_points, etc.).
-- ============================================================

create or replace function public.current_role_is_livraison()
returns boolean as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('livraison', 'admin')
  );
$$ language sql security definer stable;

create or replace function public.current_role_is_services()
returns boolean as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('services', 'admin')
  );
$$ language sql security definer stable;

-- --- orders : accès complémentaire pour Livraison (s'ajoute à
-- orders_select_own_or_staff / orders_update_staff, ne les remplace pas)
drop policy if exists "orders_select_livraison" on public.orders;
create policy "orders_select_livraison" on public.orders
  for select using (public.current_role_is_livraison());

drop policy if exists "orders_update_livraison" on public.orders;
create policy "orders_update_livraison" on public.orders
  for update using (public.current_role_is_livraison())
  with check (public.current_role_is_livraison());

-- --- service_requests : accès complémentaire pour Services
drop policy if exists "service_requests_select_services" on public.service_requests;
create policy "service_requests_select_services" on public.service_requests
  for select using (public.current_role_is_services());

drop policy if exists "service_requests_update_services" on public.service_requests;
create policy "service_requests_update_services" on public.service_requests
  for update using (public.current_role_is_services())
  with check (public.current_role_is_services());

-- --- Vue légère pour contacter le client (nom, société, téléphone,
-- région, localisation) — sans exposer le reste de `profiles`. Le WHERE
-- ne dépend que du rôle de l'appelant : soit toutes les lignes passent
-- (staff/services/livraison), soit aucune (client normal).
create or replace view public.logistics_contacts as
select id, full_name, company_name, phone, region, location
from public.profiles
where public.current_role_is_staff()
   or public.current_role_is_livraison()
   or public.current_role_is_services();

grant select on public.logistics_contacts to authenticated;
