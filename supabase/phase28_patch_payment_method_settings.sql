-- ============================================================
-- AkoraHub - Patch Phase 28 : Activation/désactivation des modes de paiement
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Permet à l'Admin d'activer/désactiver chaque mode de paiement proposé
-- au checkout (voir phase27_patch_orders_payment_method.sql pour la
-- liste des 5 modes) — utile si un numéro Mobile Money personnel devient
-- temporairement indisponible, ou pour retirer les modes manuels une fois
-- un vrai paiement en ligne en place. Lecture publique (le client doit
-- voir quels modes sont actifs sans être staff), écriture réservée à
-- l'Admin, même modèle que home_banners/flash_infos.
-- ============================================================

create table if not exists public.payment_method_settings (
  method_id text primary key,
  enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.payment_method_settings enable row level security;

drop policy if exists "payment_method_settings_select_all" on public.payment_method_settings;
create policy "payment_method_settings_select_all" on public.payment_method_settings
  for select using (true);

drop policy if exists "payment_method_settings_write_admin_only" on public.payment_method_settings;
create policy "payment_method_settings_write_admin_only" on public.payment_method_settings
  for all using (public.current_role_is_admin())
  with check (public.current_role_is_admin());

insert into public.payment_method_settings (method_id, enabled) values
  ('paiement_livraison', true),
  ('virement_bancaire', true),
  ('orange_money', true),
  ('mvola', true),
  ('airtel_money', true)
on conflict (method_id) do nothing;
