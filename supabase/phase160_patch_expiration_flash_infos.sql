-- ============================================================
-- AkoraHub - Patch Phase 160 : expiration automatique des flash infos
-- À exécuter une seule fois : Supabase Dashboard -> SQL Editor -> New query
--
-- Contexte (11/08, demande explicite) : les flash infos (bandeau
-- "Tongasoa daholo ô!" etc. sur l'Accueil) ne disparaissaient que si
-- l'Admin les désactivait manuellement — une annonce de lancement
-- oubliée restait visible indéfiniment. Ajoute une date d'expiration,
-- 48h par défaut pour les annonces déjà publiées (rétroactif, pour
-- que "Tongasoa daholo ô!" disparaisse rapidement plutôt que de
-- repartir sur 48h à partir de maintenant), configurable à la
-- création pour les nouvelles.
-- ============================================================

alter table public.flash_infos
  add column if not exists expires_at timestamptz;

update public.flash_infos
set expires_at = created_at + interval '48 hours'
where expires_at is null;

alter table public.flash_infos
  alter column expires_at set default (now() + interval '48 hours');

drop policy if exists "flash_infos_select_active_or_admin" on public.flash_infos;
create policy "flash_infos_select_active_or_admin" on public.flash_infos
  for select using (
    (active = true and (expires_at is null or expires_at > now()))
    or public.current_role_is_admin()
  );
