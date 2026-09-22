-- ============================================================
-- AkoraHub - Patch Phase 246 : interrupteur global "Stock géré par
-- ComptivA"
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (22/09/2026, demande explicite) : tout le stock est
-- désormais aussi saisi dans ComptivA (logiciel de comptabilité,
-- projet Supabase séparé — voir
-- phase245_patch_sync_stock_comptiva.sql). L'utilisatrice veut que
-- l'app arrête de se fier à `products.stock_quantity` pour bloquer les
-- commandes ou afficher "rupture de stock"/"stock bas" — ce chiffre
-- n'est plus tenu à jour côté AkoraHub.
--
-- Même modèle exact que le réglage "Bulle de chat flottante" (voir
-- phase68_patch_chat_bubble_toggle.sql) : colonne à part de `data`
-- (jsonb) sur company_settings pour ne jamais être écrasée par
-- l'enregistrement du formulaire "Profil entreprise", exposée en
-- lecture aux clients via la vue app_feature_flags (company_settings
-- est réservé au staff).
-- ============================================================

alter table public.company_settings
  add column if not exists stock_managed_externally boolean not null default false;

create or replace view public.app_feature_flags as
select floating_chat_bubble_enabled, stock_managed_externally
from public.company_settings
where id = 1;

grant select on public.app_feature_flags to authenticated, anon;
