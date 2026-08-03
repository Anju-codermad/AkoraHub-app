-- ============================================================
-- AkoraHub - Patch Phase 68 : activer/désactiver la bulle de chat
-- flottante, côté admin (global) ET côté client (personnel)
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Demande utilisateur : "les deux côtés peuvent choisir ce qu'ils
-- veulent" — un interrupteur global admin (coupe la bulle pour tous les
-- clients) ET un interrupteur personnel client (la cache juste pour
-- lui), indépendants l'un de l'autre.
-- ============================================================

-- Réglage global admin — colonne à part de `data` (jsonb) sur
-- company_settings pour ne pas risquer d'être écrasée par le prochain
-- enregistrement du formulaire "Profil entreprise" (qui ne réécrit que
-- les clés qu'il connaît, `id`/`data` — une vraie colonne séparée n'est
-- jamais touchée par cet upsert).
alter table public.company_settings
  add column if not exists floating_chat_bubble_enabled boolean not null default true;

-- Réglage personnel client — sur son propre profil, déjà couvert par
-- les policies RLS existantes (chacun modifie sa propre ligne).
alter table public.profiles
  add column if not exists hide_chat_bubble boolean not null default false;

-- company_settings est réservé au staff en lecture (Phase 4) — les
-- clients ont besoin de connaître UNIQUEMENT ce booléen pour savoir si
-- la bulle est autorisée globalement, sans accès au reste (adresse,
-- horaires...). Vue dédiée, même principe que public_profiles.
create or replace view public.app_feature_flags as
select floating_chat_bubble_enabled
from public.company_settings
where id = 1;

grant select on public.app_feature_flags to authenticated, anon;
