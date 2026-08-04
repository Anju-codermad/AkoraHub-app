-- ============================================================
-- AkoraHub - Patch Phase 70 : vérification de mise à jour in-app
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte : en attendant la publication sur le Play Store (pas de
-- mécanisme de mise à jour automatique natif tant qu'on distribue via
-- GitHub Releases/Firebase App Distribution), l'app vérifie elle-même
-- au démarrage si une version plus récente existe, et propose de la
-- télécharger — identique côté client et admin (même code d'app).
--
-- Ligne unique (id=1) mise à jour par l'Edge Function
-- `update-latest-version` après chaque build CI réussi (clé service
-- role, contourne RLS) — aucune policy d'écriture ouverte aux clients.
-- ============================================================

create table if not exists public.app_latest_version (
  id int primary key default 1,
  version_name text not null,
  build_number int not null,
  release_notes text,
  download_url text not null default '',
  updated_at timestamptz not null default now(),
  constraint app_latest_version_singleton check (id = 1)
);

insert into public.app_latest_version (id, version_name, build_number, download_url)
values (1, '0.0.0', 0, '')
on conflict (id) do nothing;

alter table public.app_latest_version enable row level security;

-- Visible de tous (y compris avant connexion) : la vérification de mise
-- à jour doit fonctionner même côté écran de connexion.
drop policy if exists "app_latest_version_select_all" on public.app_latest_version;
create policy "app_latest_version_select_all" on public.app_latest_version
  for select using (true);
